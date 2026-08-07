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
        // Invarianti della marcia lunga e della risoluzione di fine giornata.
        /// Un gruppo in marcia ha i giorni compiuti pari o superiori ai totali: è
        /// arrivato senza muoversi, cioè fra due caselle (01 §5.6.3.3).
        case gruppoFraDueCaselle(gruppo: Int)
        /// I giorni compiuti di una marcia escono da [0, totali]: i giorni mancanti
        /// sono negativi o superiori ai totali.
        case giorniMancantiFuoriIntervallo(gruppo: Int, mancanti: Int, totali: Int)
        /// La posizione visiva mostrata non è quella derivata dalla proporzione dei
        /// giorni (01 §5.6.3.4): il piano visivo diverge dalla grandezza di origine.
        case posizioneVisivaIncoerente(gruppo: Int, mostrata: Int, attesa: Int)
        /// Un gruppo in marcia ha ricevuto un ordine (01 §5.6.3.3).
        case gruppoInMarciaHaRicevutoOrdine(gruppo: Int)
        /// Una revoca non ha lasciato il gruppo nella casella di partenza con la
        /// giornata spesa e senza marcia residua (01 §5.6.3.3, RDA-100).
        case revocaNonConforme(gruppo: Int)
        // Invarianti della composizione e del volume (01 §5.6.0, §5.6.3).
        /// Un gruppo senza reparti, o con un reparto a atomi non positivi: nessun
        /// gruppo può essere vuoto (01 §5.6.0.2).
        case gruppoVuoto(gruppo: Int)
        /// Il volume riportato di un gruppo non è la somma di ciò che lo compone
        /// (01 §5.6.3): il volume diverge dalla composizione. Il valore riportato
        /// arriva dall'esterno, come la posizione visiva, così che una prova possa
        /// darne uno divergente e accertare che la sonda se ne accorga.
        case volumeIncoerente(gruppo: Int, riportato: Int, atteso: Int)

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
            case .gruppoFraDueCaselle(let g): return "gruppo_fra_due_caselle:gruppo=\(g)"
            case .giorniMancantiFuoriIntervallo(let g, let m, let t): return "giorni_mancanti_fuori_intervallo:gruppo=\(g):mancanti=\(m):totali=\(t)"
            case .posizioneVisivaIncoerente(let g, let m, let a): return "posizione_visiva_incoerente:gruppo=\(g):mostrata=\(m):attesa=\(a)"
            case .gruppoInMarciaHaRicevutoOrdine(let g): return "gruppo_in_marcia_ordinato:gruppo=\(g)"
            case .revocaNonConforme(let g): return "revoca_non_conforme:gruppo=\(g)"
            case .gruppoVuoto(let g): return "gruppo_vuoto:gruppo=\(g)"
            case .volumeIncoerente(let g, let r, let a): return "volume_incoerente:gruppo=\(g):riportato=\(r):atteso=\(a)"
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
        "gruppo_fra_due_caselle",
        "giorni_mancanti_fuori_intervallo",
        "posizione_visiva_incoerente",
        "gruppo_in_marcia_ordinato",
        "revoca_non_conforme",
        "gruppo_vuoto",
        "volume_incoerente",
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
            // Marcia lunga: nessuno stato intermedio fra due caselle, e giorni
            // compiuti sempre in [0, totali) (01 §5.6.3.3). Un gruppo con i giorni
            // compiuti pari o superiori ai totali è arrivato ma non mosso, cioè fra
            // due caselle; giorni compiuti fuori da [0, totali] sono impossibili.
            if let m = gruppo.marcia {
                if m.giorniCompiuti >= m.giorniTotali {
                    violazioni.append(.gruppoFraDueCaselle(gruppo: gruppo.id.numero))
                }
                if m.giorniCompiuti < 0 || m.giorniCompiuti > m.giorniTotali {
                    violazioni.append(.giorniMancantiFuoriIntervallo(
                        gruppo: gruppo.id.numero, mancanti: m.giorniMancanti, totali: m.giorniTotali))
                }
            }
            // Nessun gruppo vuoto (01 §5.6.0.2): composizione non vuota e ogni reparto
            // con atomi positivi. La fabbrica lo rende impossibile; la sonda lo
            // sorveglia perché la divisione dell'unità successiva vi lavorerà sopra.
            if gruppo.composizione.isEmpty || gruppo.composizione.contains(where: { $0.atomi <= 0 }) {
                violazioni.append(.gruppoVuoto(gruppo: gruppo.id.numero))
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
        // Un gruppo in marcia non riceve mai un ordine di marcia o di presidio
        // (01 §5.6.3.3): la validazione lo impedisce, l'invariante lo sorveglia. La
        // revoca fa eccezione, perché si compie PROPRIO su una marcia in corso.
        switch comando {
        case .marcia(let id, let destinazione, _):
            idAgente = id
            if let partenza = prima.gruppi[id]?.posizione, !adiacenti(partenza, destinazione) {
                violazioni.append(.movimentoFraCaselleNonAdiacenti(
                    da: "\(partenza.riga)-\(partenza.colonna)",
                    a: "\(destinazione.riga)-\(destinazione.colonna)"))
            }
            if prima.gruppi[id]?.inMarcia == true {
                violazioni.append(.gruppoInMarciaHaRicevutoOrdine(gruppo: id.numero))
            }
        case .presidio(let id):
            idAgente = id
            if prima.gruppi[id]?.inMarcia == true {
                violazioni.append(.gruppoInMarciaHaRicevutoOrdine(gruppo: id.numero))
            }
        case .revocaMarcia(let id):
            idAgente = id
            // La revoca lascia il gruppo nella casella di partenza, senza marcia
            // residua e con la giornata spesa (01 §5.6.3.3, RDA-100).
            if let g = dopo.gruppi[id] {
                let conforme = g.posizione == prima.gruppi[id]?.posizione
                    && g.marcia == nil && g.azioneSpesa
                if !conforme { violazioni.append(.revocaNonConforme(gruppo: id.numero)) }
            }
        }
        // «Azione spesa due volte» non si applica alla revoca: la revoca non è
        // un'azione (01 §5.6.8.1) e si compie su un gruppo che ha già la giornata
        // consumata dalla marcia, sicché l'azione risulta legittimamente già presa.
        if case .revocaMarcia = comando {} else if prima.gruppi[idAgente]?.azioneSpesa == true {
            violazioni.append(.azioneSpesaDueVolte(gruppo: idAgente.numero))
        }

        // Con la cascata (tutti i gruppi in marcia) una sola applicazione può
        // chiudere più giornate: il giorno avanza di TANTE quante le chiusure.
        let chiusure = eventi.reduce(0) {
            if case .giornataChiusa = $1 { return $0 + 1 } else { return $0 }
        }
        if chiusure > 0 {
            if dopo.giorno != prima.giorno + chiusure {
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

    // MARK: - Invariante della posizione visiva derivata

    /// Che la posizione visiva MOSTRATA di un gruppo in marcia corrisponda a quella
    /// DERIVATA dalla proporzione fra giorni compiuti e giorni totali, con
    /// troncamento per difetto su `posizioni` posizioni (01 §5.6.3.4). La posizione
    /// mostrata arriva dall'esterno — la calcola chi disegna, cioè la Presentazione
    /// (nel banco, `MotoreCampagna.avanzamentoVisivo`) — così che una prova possa
    /// darne una divergente e accertare che la sonda se ne accorga. In produzione la
    /// posizione mostrata è funzione pura dei giorni e non può divergere; l'invariante
    /// sorveglia che nessuna sede la conservi come grandezza autonoma.
    public func controllaPosizioniVisive(stato: StatoCampagna, posizioni: Int,
                                         mostrate: [IdGruppo: Int]) -> [Violazione] {
        var violazioni: [Violazione] = []
        for gruppo in stato.gruppiOrdinati {
            guard let m = gruppo.marcia else { continue }
            let attesa = m.giorniTotali > 0 ? (m.giorniCompiuti * posizioni) / m.giorniTotali : 0
            guard let mostrata = mostrate[gruppo.id] else { continue }
            if mostrata != attesa {
                violazioni.append(.posizioneVisivaIncoerente(
                    gruppo: gruppo.id.numero, mostrata: mostrata, attesa: attesa))
            }
        }
        return violazioni
    }

    // MARK: - Invariante del volume come somma della composizione

    /// Che il volume RIPORTATO di ciascun gruppo coincida con la somma, sui reparti,
    /// di atomi per `volume_per_atomo` (01 §5.6.3, §3.4.4). Come per la posizione
    /// visiva, il valore riportato arriva dall'esterno — lo calcola chi lo usa, cioè
    /// il Motore (`MotoreCampagna.volume`) — così che una prova possa darne uno
    /// divergente e accertare che la sonda se ne accorga. La tabella `volumePerAtomo`
    /// arriva anch'essa dall'esterno, perché la sonda è separata dai dati come dal
    /// Motore. In produzione il volume è funzione pura della composizione e non può
    /// divergere; l'invariante sorveglia che nessuna sede lo conservi come grandezza
    /// autonoma.
    public func controllaVolumi(stato: StatoCampagna,
                                volumePerAtomo: [IdentificatoreDati: Int64],
                                volumiRiportati: [IdGruppo: Int64]) -> [Violazione] {
        var violazioni: [Violazione] = []
        for gruppo in stato.gruppiOrdinati {
            guard let riportato = volumiRiportati[gruppo.id] else { continue }
            let atteso = gruppo.composizione.reduce(Int64(0)) { somma, reparto in
                somma + Int64(reparto.atomi) * (volumePerAtomo[reparto.archetipo] ?? 0)
            }
            if riportato != atteso {
                violazioni.append(.volumeIncoerente(gruppo: gruppo.id.numero,
                                                    riportato: Int(riportato), atteso: Int(atteso)))
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
