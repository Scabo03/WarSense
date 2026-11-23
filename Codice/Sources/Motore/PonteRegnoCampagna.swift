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

    /// Lo scenario della campagna dell'anno su un fronte (incarico 31). Partono le formazioni che il
    /// giocatore non tiene in patria, ciascuna col proprio NOME, nell'ordine in cui il regno le
    /// conserva: quelle che ci sono già occupano le caselle che lo scenario del fronte assegna ai
    /// gruppi del giocatore, nell'ordine dello scenario, e poi le caselle libere più vicine al
    /// proprio quartier generale, a parità di distanza nell'ordine di lettura. Le reclute
    /// dell'ultimo inverno entrano come ARRIVI DALLA PATRIA (01 §5.2.1): quelle pronte in primavera
    /// con la prima giornata, quelle pronte in estate e in autunno con la prima giornata di quella
    /// stagione, a campagna aperta. Le formazioni tenute in patria, e quelle che maturano soltanto
    /// con l'inverno successivo, non partono: il loro nome è riservato, perché nessun gruppo nato
    /// sul fronte lo prenda.
    ///
    /// Se le formazioni che partono subito sono più dei nomi o delle caselle disponibili, le armate
    /// in eccesso confluiscono nell'armata che le precede.
    public static func scenario(delFronte base: ScenarioCampagna, forze: ForzeDelRegno,
                                calendario: CalendarioDiCampagna,
                                valori: ValoriCampagna) throws -> ScenarioCampagna {
        guard case .sciami(let tutte, _) = forze else { throw Errore.forzeDiAltraModalita }
        var formazioni = tutte.filter { $0.parteConLaCampagna && $0.arrivo == nil }
        let inArrivo = tutte.filter { $0.parteConLaCampagna && $0.arrivo != nil }
        let restano = tutte.filter { !$0.parteConLaCampagna }
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

        // Il tetto: le caselle della mappa, e i nomi della lista chiusa che restano all'avversario
        // dopo quelli che il regno tiene per sé (01 §5.6.0.4). Oltre il tetto delle caselle le
        // armate in eccesso confluiscono nella precedente; se all'avversario non restassero nomi,
        // confluiscono finché ne restano.
        func nomiLiberi() -> Int {
            let inUso = Set(formazioni.map(\.nome)).union(inArrivo.map(\.nome)).union(restano.map(\.nome))
            return valori.nomiGruppi.filter { !inUso.contains($0) }.count
        }
        while formazioni.count + inArrivo.count > griglia.tutteLeCaselle.count
                || nomiLiberi() < base.gruppiAvversario.count {
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
        let libere = griglia.tutteLeCaselle
            .filter { !caselle.contains($0) }
            .sorted {
                let da = griglia.distanza(quartierGenerale, $0), db = griglia.distanza(quartierGenerale, $1)
                return da == db ? $0 < $1 : da < db
            }
        caselle += libere

        func dichiarata(_ categoria: CategoriaFormazione) -> (String, Int?, Int?, Int?) {
            switch categoria {
            case .armato: return ("armato", nil, nil, nil)
            case .ricognizione(let competenza): return ("ricognizione", competenza, nil, nil)
            case .nonArmata(let carico, let sogliaProtezione): return ("non_armata", nil, carico, sogliaProtezione)
            }
        }

        var gruppi: [ScenarioCampagna.GruppoIniziale] = []
        for (indice, formazione) in formazioni.enumerated() where indice < caselle.count {
            let casella = caselle[indice]
            let (categoria, competenza, carico, soglia) = dichiarata(formazione.categoria)
            gruppi.append(.init(riga: casella.riga, colonna: casella.colonna,
                                composizione: formazione.composizione.map(ScenarioCampagna.RepartoIniziale.init),
                                categoria: categoria, competenza: competenza, carico: carico,
                                sogliaProtezione: soglia, nome: formazione.nome))
        }

        // Gli arrivi: la prima giornata della stagione in cui la formazione è pronta.
        var arrivi: [ScenarioCampagna.ArrivoProgrammato] = []
        for formazione in inArrivo {
            guard let stagione = formazione.arrivo,
                  let posizione = Stagione.operative.firstIndex(of: stagione) else { continue }
            let (categoria, competenza, carico, soglia) = dichiarata(formazione.categoria)
            arrivi.append(.init(giorno: posizione * calendario.giornatePerStagione + 1, nome: formazione.nome,
                                composizione: formazione.composizione.map(ScenarioCampagna.RepartoIniziale.init),
                                categoria: categoria, competenza: competenza, carico: carico,
                                sogliaProtezione: soglia))
        }

        return ScenarioCampagna(mappa: base.mappa, gruppiGiocatore: gruppi,
                                gruppiAvversario: base.gruppiAvversario,
                                forzeNemiche: base.forzeNemiche,
                                struttureDiRifornimento: base.struttureDiRifornimento,
                                calendario: calendario,
                                nomiRiservati: restano.map(\.nome),
                                arrivi: arrivi)
    }

    /// L'esito che una campagna CONCLUSA porta al regno; nulla se la campagna non è conclusa o non
    /// dichiara un calendario. I superstiti sono i gruppi del giocatore com'erano alla conclusione,
    /// nell'ordine dei loro identificatori: tornano come formazioni, col NOME che portavano sul
    /// fronte (incarico 31). Con loro tornano gli arrivi dalla patria che la campagna non ha fatto
    /// in tempo a ricevere, ancora in arrivo: non erano mai partiti. Le battaglie vinte e perse si
    /// contano sul registro, che le annota tutte (01 §5.17.1).
    public static func esito(da stato: StatoCampagna, fronte: IdentificatoreDati) -> EsitoCampagna? {
        guard let conclusione = stato.conclusione, let calendario = stato.calendario else { return nil }
        var superstiti = stato.gruppiOrdinati
            .filter { $0.parte == .giocatore }
            .map { FormazioneDelRegno(nome: $0.nome, categoria: $0.categoria, composizione: $0.composizione) }
        for arrivo in stato.arriviInAttesa ?? [] {
            superstiti.append(FormazioneDelRegno(nome: arrivo.nome, categoria: arrivo.categoria,
                                                 composizione: arrivo.composizione,
                                                 arrivo: calendario.stagione(del: arrivo.giorno)))
        }
        var vinte = 0, perse = 0
        for voce in stato.registro {
            if case .battagliaConclusa(_, let giocatoreSconfitto) = voce.fatto {
                if giocatoreSconfitto { perse += 1 } else { vinte += 1 }
            }
        }
        return EsitoCampagna(fronte: fronte, anno: calendario.anno, modo: conclusione.modo,
                             vincitore: conclusione.vincitore, giornate: conclusione.giorno,
                             battaglieVinte: vinte, battagliePerse: perse,
                             superstiti: .sciami(formazioni: superstiti, prossimoNome: 0))
    }
}
