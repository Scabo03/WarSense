import Foundation
import Dati

/// Il PONTE fra il regno e la campagna, nella modalità a sciami (incarico 30, RDA-162, RDA-166):
/// gemello di `PonteCampagnaBattaglia`. Due funzioni pure. La prima fa della campagna dell'anno uno
/// scenario — la mappa e le forze avversarie del fronte, le forze del regno al posto di quelle
/// fisse dello scenario, il calendario —; la seconda ricava dallo stato di una campagna conclusa
/// l'esito che il regno riceve. Lo scenario è iscritto nell'atto di fondazione della campagna, e
/// l'esito nel giornale del regno: nessuno dei due si ricalcola alla ripresa.
public enum PonteRegnoCampagna {

    public enum Errore: Error, Equatable {
        /// Le forze non sono della modalità a sciami.
        case forzeDiAltraModalita
        /// Il regno non ha formazioni armate da mandare (RDA-164).
        case nessunaFormazioneArmata
        /// Lo scenario del fronte non dà all'avversario alcun gruppo armato: la campagna si
        /// concluderebbe alla prima battaglia mai combattuta.
        case fronteSenzaAvversarioArmato
        case mappaIgnota(IdentificatoreDati)
        case formatoIgnoto(IdentificatoreDati)
    }

    /// Lo scenario della campagna dell'anno su un fronte. Le formazioni del regno partono tutte,
    /// nell'ordine in cui il regno le conserva: le prime occupano le caselle che lo scenario del
    /// fronte assegna ai gruppi del giocatore, nell'ordine dello scenario; le altre le caselle
    /// libere più vicine al proprio quartier generale, a parità di distanza nell'ordine di lettura
    /// (01 §5.2.1: il quartier generale è il punto di arrivo delle truppe inviate dalla patria).
    /// Se le formazioni sono più dei nomi o delle caselle disponibili, le formazioni armate in
    /// eccesso confluiscono nell'armata che le precede: nessuna forza resta in patria.
    public static func scenario(delFronte base: ScenarioCampagna, forze: ForzeDelRegno,
                                calendario: CalendarioDiCampagna,
                                valori: ValoriCampagna) throws -> ScenarioCampagna {
        guard case .sciami(var formazioni) = forze else { throw Errore.forzeDiAltraModalita }
        guard formazioni.contains(where: { $0.categoria.eArmata }) else {
            throw Errore.nessunaFormazioneArmata
        }
        guard base.gruppiAvversario.contains(where: { $0.categoria == "armato" }) else {
            throw Errore.fronteSenzaAvversarioArmato
        }
        guard let definizione = valori.mappe[base.mappa] else { throw Errore.mappaIgnota(base.mappa) }
        guard let formato = valori.formatiMappa[definizione.formato] else {
            throw Errore.formatoIgnoto(definizione.formato)
        }
        let mappa = MappaCampagna(definizione: definizione, formato: formato)
        let griglia = mappa.griglia

        // Il tetto: i nomi della lista chiusa che restano dopo quelli dell'avversario (01 §5.6.0.4)
        // e le caselle della mappa. Oltre, le armate in eccesso confluiscono nella precedente.
        let tetto = max(1, min(valori.nomiGruppi.count - base.gruppiAvversario.count,
                               griglia.tutteLeCaselle.count))
        while formazioni.count > tetto {
            guard let ultima = formazioni.lastIndex(where: { $0.categoria.eArmata }),
                  let precedente = formazioni[..<ultima].lastIndex(where: { $0.categoria.eArmata })
            else { break }
            formazioni[precedente].composizione += formazioni[ultima].composizione
            formazioni.remove(at: ultima)
        }

        // Le caselle: prima quelle dello scenario del fronte, poi le libere più vicine al quartier
        // generale. Deterministico: nessuna estrazione, e l'ordine a parità di distanza è di lettura.
        let quartierGenerale = mappa.quartierGenerale(di: .giocatore)
        var caselle: [Cella] = []
        for casella in base.gruppiGiocatore.map(\.casella) where !caselle.contains(casella) {
            caselle.append(casella)
        }
        let restanti = griglia.tutteLeCaselle
            .filter { !caselle.contains($0) }
            .sorted {
                let da = griglia.distanza(quartierGenerale, $0), db = griglia.distanza(quartierGenerale, $1)
                return da == db ? $0 < $1 : da < db
            }
        caselle += restanti

        var gruppi: [ScenarioCampagna.GruppoIniziale] = []
        for (indice, formazione) in formazioni.enumerated() where indice < caselle.count {
            let casella = caselle[indice]
            let composizione = formazione.composizione.map {
                ScenarioCampagna.RepartoIniziale(archetipo: $0.archetipo, atomi: $0.atomi)
            }
            switch formazione.categoria {
            case .armato:
                gruppi.append(.init(riga: casella.riga, colonna: casella.colonna, composizione: composizione))
            case .ricognizione(let competenza):
                gruppi.append(.init(riga: casella.riga, colonna: casella.colonna, composizione: composizione,
                                    categoria: "ricognizione", competenza: competenza))
            case .nonArmata(let carico, let sogliaProtezione):
                gruppi.append(.init(riga: casella.riga, colonna: casella.colonna, composizione: composizione,
                                    categoria: "non_armata", carico: carico, sogliaProtezione: sogliaProtezione))
            }
        }
        return ScenarioCampagna(mappa: base.mappa, gruppiGiocatore: gruppi,
                                gruppiAvversario: base.gruppiAvversario,
                                forzeNemiche: base.forzeNemiche,
                                struttureDiRifornimento: base.struttureDiRifornimento,
                                calendario: calendario)
    }

    /// L'esito che una campagna CONCLUSA porta al regno; nulla se la campagna non è conclusa o non
    /// dichiara un calendario. I superstiti sono i gruppi del giocatore com'erano alla conclusione,
    /// nell'ordine dei loro identificatori: tornano come formazioni, senza casella e senza nome. Le
    /// battaglie vinte e perse si contano sul registro, che le annota tutte (01 §5.17.1).
    public static func esito(da stato: StatoCampagna, fronte: IdentificatoreDati) -> EsitoCampagna? {
        guard let conclusione = stato.conclusione, let calendario = stato.calendario else { return nil }
        let superstiti = stato.gruppiOrdinati
            .filter { $0.parte == .giocatore }
            .map { FormazioneDelRegno(categoria: $0.categoria, composizione: $0.composizione) }
        var vinte = 0, perse = 0
        for voce in stato.registro {
            if case .battagliaConclusa(_, let giocatoreSconfitto) = voce.fatto {
                if giocatoreSconfitto { perse += 1 } else { vinte += 1 }
            }
        }
        return EsitoCampagna(fronte: fronte, anno: calendario.anno, modo: conclusione.modo,
                             vincitore: conclusione.vincitore, giornate: conclusione.giorno,
                             battaglieVinte: vinte, battagliePerse: perse,
                             superstiti: .sciami(superstiti))
    }
}
