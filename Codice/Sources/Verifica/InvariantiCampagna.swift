import Foundation
import Dati
import Motore

/// Gli invarianti della campagna: ciò che non deve MAI accadere, quali che siano le
/// giornate generate (incarico, sezione 6). La sonda è separata dal Motore di
/// proposito: il Motore non deve controllare se stesso, altrimenti l'invariante e
/// la realizzazione condividerebbero i punti ciechi.
///
/// Ogni invariante è formulato in modo da poter essere VIOLATO: la sonda accetta
/// dall'esterno ciò che deve giudicare — lo stato, la transizione, la sequenza del
/// salto, la funzione di adiacenza — così che una prova possa darle in pasto un
/// caso guasto e accertare che se ne accorga. Un invariante che non si è mai visto
/// violare non è un invariante.
public struct SondaInvariantiCampagna: Sendable {

    /// Le violazioni possibili, una per invariante dell'incarico.
    public enum Violazione: Hashable, Sendable, CustomStringConvertible {
        case gruppoInPiuCaselle(gruppo: Int, caselle: Int)
        case dueGruppiNellaStessaCasella(riga: Int, colonna: Int)
        case gruppoFuoriDallaMappa(gruppo: Int)
        case azioneSpesaDueVolte(gruppo: Int)
        case azioneNonRegistrata(gruppo: Int)
        case gruppoEstraneoHaAgito(gruppo: Int)
        case saltoHaDimenticatoUnGruppo(gruppo: Int)
        case saltoHaPropostoUnGruppoCheHaAgito(gruppo: Int)
        case saltoHaRipetutoUnGruppo(gruppo: Int)
        case giornoNonAvanzato(prima: Int, dopo: Int)
        case giornoAvanzatoSenzaChiusura(prima: Int, dopo: Int)
        case azioniNonAzzerateAllaChiusura(gruppo: Int)
        case movimentoFraCaselleNonAdiacenti(da: String, a: String)
        case casellaPercorribileIrraggiungibile(riga: Int, colonna: Int)
        case registroFuoriOrdine(voce: Int)

        /// Il codice della violazione, senza spazi: l'uscita del programma di
        /// verifica è dato per chi sviluppa e non testo di prodotto (05 §12.6),
        /// e il collaudo dei confini sorveglia che nessuna frase per l'utente
        /// viva nel codice (00 §14.1). Il codice resta leggibile in una riga CSV.
        public var description: String {
            switch self {
            case .gruppoInPiuCaselle(let g, let n): return "gruppo_in_piu_caselle:gruppo=\(g):caselle=\(n)"
            case .dueGruppiNellaStessaCasella(let r, let c): return "due_gruppi_stessa_casella:riga=\(r):casella=\(c)"
            case .gruppoFuoriDallaMappa(let g): return "gruppo_fuori_dalla_mappa:gruppo=\(g)"
            case .azioneSpesaDueVolte(let g): return "azione_spesa_due_volte:gruppo=\(g)"
            case .azioneNonRegistrata(let g): return "azione_non_registrata:gruppo=\(g)"
            case .gruppoEstraneoHaAgito(let g): return "gruppo_ha_agito_da_se:gruppo=\(g)"
            case .saltoHaDimenticatoUnGruppo(let g): return "salto_ha_dimenticato:gruppo=\(g)"
            case .saltoHaPropostoUnGruppoCheHaAgito(let g): return "salto_ha_proposto_chi_ha_agito:gruppo=\(g)"
            case .saltoHaRipetutoUnGruppo(let g): return "salto_ha_ripetuto:gruppo=\(g)"
            case .giornoNonAvanzato(let a, let b): return "giorno_non_avanzato:prima=\(a):dopo=\(b)"
            case .giornoAvanzatoSenzaChiusura(let a, let b): return "giorno_avanzato_senza_chiusura:prima=\(a):dopo=\(b)"
            case .azioniNonAzzerateAllaChiusura(let g): return "azione_non_azzerata:gruppo=\(g)"
            case .movimentoFraCaselleNonAdiacenti(let a, let b): return "movimento_non_adiacente:da=\(a):a=\(b)"
            case .casellaPercorribileIrraggiungibile(let r, let c): return "casella_irraggiungibile:riga=\(r):casella=\(c)"
            case .registroFuoriOrdine(let v): return "registro_fuori_ordine:voce=\(v)"
            }
        }
    }

    /// I codici di TUTTI gli invarianti sorvegliati, in ordine fisso. Esiste perché
    /// il collaudo possa pretendere che ciascuno abbia il proprio mutante: senza
    /// questo elenco, un invariante aggiunto senza mutante passerebbe inosservato,
    /// ed è esattamente ciò che era accaduto a due di essi nella prima unità.
    /// Aggiungere un caso all'enumerativo senza aggiungerlo qui fa fallire il
    /// collaudo, perché il numero dichiarato non corrisponderebbe.
    public static let codiciNoti: [String] = [
        "gruppo_in_piu_caselle",
        "due_gruppi_stessa_casella",
        "gruppo_fuori_dalla_mappa",
        "azione_spesa_due_volte",
        "azione_non_registrata",
        "gruppo_ha_agito_da_se",
        "salto_ha_dimenticato",
        "salto_ha_proposto_chi_ha_agito",
        "salto_ha_ripetuto",
        "giorno_non_avanzato",
        "giorno_avanzato_senza_chiusura",
        "azione_non_azzerata",
        "movimento_non_adiacente",
        "casella_irraggiungibile",
        "registro_fuori_ordine",
    ]

    /// Il codice nudo, senza i valori: la parte prima dei due punti.
    public static func codice(di violazione: Violazione) -> String {
        String(violazione.description.split(separator: ":")[0])
    }

    public init() {}

    // MARK: - Invarianti dello stato

    /// Che un gruppo si trovi in due caselle; che due gruppi condividano una
    /// casella (01 §5.6.0.2); che un gruppo esca dai confini; che il registro sia
    /// fuori ordine di accadimento.
    public func controlla(stato: StatoCampagna) -> [Violazione] {
        var violazioni: [Violazione] = []
        var caselleDelGruppo: [IdGruppo: Int] = [:]
        var occupanti: [Cella: Int] = [:]
        for casella in stato.griglia.tutteLeCaselle {
            for gruppo in stato.gruppi.values where gruppo.posizione == casella {
                caselleDelGruppo[gruppo.id, default: 0] += 1
                occupanti[casella, default: 0] += 1
            }
        }
        for gruppo in stato.gruppiOrdinati {
            let quante = caselleDelGruppo[gruppo.id] ?? 0
            if quante != 1 {
                violazioni.append(quante == 0
                    ? .gruppoFuoriDallaMappa(gruppo: gruppo.id.numero)
                    : .gruppoInPiuCaselle(gruppo: gruppo.id.numero, caselle: quante))
            }
        }
        for casella in occupanti.keys.sorted() where occupanti[casella]! > 1 {
            violazioni.append(.dueGruppiNellaStessaCasella(riga: casella.riga, colonna: casella.colonna))
        }
        var precedente = Int.min
        for voce in stato.registro {
            if voce.giorno < precedente { violazioni.append(.registroFuoriOrdine(voce: voce.numero)) }
            precedente = voce.giorno
        }
        return violazioni
    }

    // MARK: - Invarianti della transizione

    /// Che un gruppo agisca due volte nella stessa giornata; che il giorno resti
    /// fermo o torni indietro alla chiusura, o avanzi senza chiusura; che le azioni
    /// non si azzerino alla giornata nuova; che un movimento avvenga fra caselle
    /// non adiacenti.
    public func controlla(prima: StatoCampagna, comando: ComandoCampagna,
                          dopo: StatoCampagna, eventi: [EventoCampagna],
                          adiacenti: (Cella, Cella) -> Bool) -> [Violazione] {
        var violazioni: [Violazione] = []
        let idAgente: IdGruppo
        switch comando {
        case .marcia(let id, let destinazione, _):
            idAgente = id
            if let partenza = prima.gruppi[id]?.posizione, !adiacenti(partenza, destinazione) {
                violazioni.append(.movimentoFraCaselleNonAdiacenti(
                    da: "\(partenza.riga)-\(partenza.colonna)",
                    a: "\(destinazione.riga)-\(destinazione.colonna)"))
            }
        case .presidio(let id):
            idAgente = id
        }
        if prima.gruppi[idAgente]?.azioneSpesa == true {
            violazioni.append(.azioneSpesaDueVolte(gruppo: idAgente.numero))
        }

        let chiusa = eventi.contains { if case .giornataChiusa = $0 { return true } else { return false } }
        if chiusa {
            if dopo.giorno != prima.giorno + 1 {
                violazioni.append(.giornoNonAvanzato(prima: prima.giorno, dopo: dopo.giorno))
            }
            for gruppo in dopo.gruppiOrdinati where gruppo.azioneSpesa {
                violazioni.append(.azioniNonAzzerateAllaChiusura(gruppo: gruppo.id.numero))
            }
        } else {
            if dopo.giorno != prima.giorno {
                violazioni.append(.giornoAvanzatoSenzaChiusura(prima: prima.giorno, dopo: dopo.giorno))
            }
            if dopo.gruppi[idAgente]?.azioneSpesa != true {
                violazioni.append(.azioneNonRegistrata(gruppo: idAgente.numero))
            }
            // Nessun altro gruppo può aver speso l'azione: nessuno agisce da sé.
            for gruppo in dopo.gruppiOrdinati where gruppo.id != idAgente {
                if gruppo.azioneSpesa && prima.gruppi[gruppo.id]?.azioneSpesa != true {
                    violazioni.append(.gruppoEstraneoHaAgito(gruppo: gruppo.id.numero))
                }
            }
        }
        return violazioni
    }

    // MARK: - Invariante del salto diretto

    /// Che il salto dimentichi un gruppo che non ha ancora agito, o ne proponga uno
    /// che ha già agito, o ne ripeta uno prima di aver percorso tutti gli altri.
    /// La sequenza arriva dall'esterno: così una prova può darne una guasta.
    public func controllaSalto(stato: StatoCampagna, sequenza: [IdGruppo],
                               parte: Parte = .giocatore) -> [Violazione] {
        var violazioni: [Violazione] = []
        let attesi = Set(stato.gruppiInAttesa(di: parte).map(\.id))
        var visti = Set<IdGruppo>()
        for id in sequenza {
            if let gruppo = stato.gruppi[id], gruppo.azioneSpesa {
                violazioni.append(.saltoHaPropostoUnGruppoCheHaAgito(gruppo: id.numero))
            }
            if !visti.insert(id).inserted {
                violazioni.append(.saltoHaRipetutoUnGruppo(gruppo: id.numero))
            }
        }
        for id in attesi.subtracting(visti).sorted() {
            violazioni.append(.saltoHaDimenticatoUnGruppo(gruppo: id.numero))
        }
        return violazioni
    }

    // MARK: - Invariante di percorribilità

    /// Che una casella dichiarata percorribile risulti irraggiungibile (01 §5.1.2:
    /// la mappa è interamente percorribile, non esistono caselle interdette).
    /// L'adiacenza arriva dall'esterno: così una prova può darne una guasta.
    public func controllaRaggiungibilita(griglia: GrigliaCampagna,
                                         da origine: Cella,
                                         vicini: (Cella) -> [Cella]) -> [Violazione] {
        var visitate: Set<Cella> = [origine]
        var fronte = [origine]
        while let corrente = fronte.popLast() {
            for vicino in vicini(corrente) where visitate.insert(vicino).inserted {
                fronte.append(vicino)
            }
        }
        return griglia.tutteLeCaselle
            .filter { !visitate.contains($0) }
            .map { .casellaPercorribileIrraggiungibile(riga: $0.riga, colonna: $0.colonna) }
    }
}
