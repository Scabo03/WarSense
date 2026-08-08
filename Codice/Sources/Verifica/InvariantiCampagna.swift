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
        // Invarianti della divisione e della riunione (01 §5.6.0.2, §5.6.0.3).
        /// La somma dei reparti del gruppo di origine e del distaccamento, dopo una
        /// divisione, non eguaglia i reparti del gruppo di prima: la divisione ha
        /// perso o inventato un reparto (01 §5.6.0.2).
        case divisioneNonConserva(gruppo: Int)
        /// Un gruppo diviso o riunito ha guadagnato un'azione: il gruppo di origine o
        /// il distaccamento non risulta avere agito dopo la divisione, oppure il
        /// risultante di una riunione non ha l'azione spesa se e solo se almeno uno
        /// dei due la aveva (01 §5.6.0.2, §5.6.0.3). Regalerebbe una giornata.
        case guadagnoDiAzione(gruppo: Int)
        // Invarianti del rifornimento (01 §5.2.2).
        /// I contatori del rifornimento escono da [0, 2]: nessun gruppo può restare
        /// senza provviste, o dover sosta, per più di due turni (01 §5.2.2.4).
        case rifornimentoFuoriIntervallo(gruppo: Int, senza: Int, sosta: Int)
        /// Il contatore della marcia forzata è stato alimentato: questa unità lo tiene
        /// DISTINTO da quello delle provviste e non lo tocca (01 §5.2.2.5). L'invariante
        /// cade quando la marcia forzata sarà costruita e alimenterà il proprio conto.
        case marciaForzataInattesa(gruppo: Int, turni: Int)
        /// Un gruppo che DEVE rifornirsi ha ricevuto un ordine di marcia: la sosta
        /// dovuta non si elude marciando (01 §5.2.2.4).
        case sostaElusaMarciando(gruppo: Int)
        /// Un gruppo in una zona di rifornimento risulta senza provviste dopo la
        /// chiusura della giornata: in zona il taglio non ha effetto (01 §5.2.2.6).
        case zonaTagliata(gruppo: Int)
        /// Il rifornimento di un gruppo si è interrotto senza che una forza nemica fosse
        /// in una delle sue caselle alle spalle: il taglio dipende SOLO da quelle
        /// (01 §5.2.2.2). La sonda ricava le caselle per conto proprio.
        case taglioDaCasellaNonPrescritta(gruppo: Int)

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
            case .divisioneNonConserva(let g): return "divisione_non_conserva:gruppo=\(g)"
            case .guadagnoDiAzione(let g): return "guadagno_azione:gruppo=\(g)"
            case .rifornimentoFuoriIntervallo(let g, let s, let d): return "rifornimento_fuori_intervallo:gruppo=\(g):senza=\(s):sosta=\(d)"
            case .marciaForzataInattesa(let g, let t): return "marcia_forzata_inattesa:gruppo=\(g):turni=\(t)"
            case .sostaElusaMarciando(let g): return "sosta_elusa_marciando:gruppo=\(g)"
            case .zonaTagliata(let g): return "zona_tagliata:gruppo=\(g)"
            case .taglioDaCasellaNonPrescritta(let g): return "taglio_da_casella_non_prescritta:gruppo=\(g)"
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
        "divisione_non_conserva",
        "guadagno_azione",
        "rifornimento_fuori_intervallo",
        "marcia_forzata_inattesa",
        "sosta_elusa_marciando",
        "zona_tagliata",
        "taglio_da_casella_non_prescritta",
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
            // Rifornimento (01 §5.2.2.4): i due contatori restano in [0, 2] — oltre il
            // secondo turno non si prosegue. La marcia forzata è un contatore DISTINTO
            // (§5.2.2.5) che questa unità non alimenta: resta a zero, e se non lo è,
            // qualcosa lo ha confuso con quello delle provviste.
            if gruppo.turniSenzaProvviste < 0 || gruppo.turniSenzaProvviste > 2
                || gruppo.sostaDovuta < 0 || gruppo.sostaDovuta > 2 {
                violazioni.append(.rifornimentoFuoriIntervallo(
                    gruppo: gruppo.id.numero,
                    senza: gruppo.turniSenzaProvviste, sosta: gruppo.sostaDovuta))
            }
            if gruppo.turniMarciaForzata != 0 {
                violazioni.append(.marciaForzataInattesa(gruppo: gruppo.id.numero,
                                                         turni: gruppo.turniMarciaForzata))
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
        // Il gruppo che AGISCE, per le verifiche generiche. La revoca e la riunione
        // NON sono azioni (01 §5.6.8.1) e non hanno un agente: le loro regole proprie
        // si controllano a parte, e le verifiche generiche dell'azione si saltano.
        var idAgente: IdGruppo? = nil
        // I gruppi che nascono in questa transizione (il distaccamento di una
        // divisione): sono ESENTI dalla regola «nessuno agisce da sé», perché nascono
        // legittimamente avendo già agito (01 §5.6.0.2).
        var natiOra = Set<IdGruppo>()
        // Se la transizione ha CHIUSO la giornata, l'azione spesa si azzera per la
        // giornata nuova (01 §5.6.0.6): le regole sull'azione della divisione e della
        // riunione si verificano sullo stato PRIMA di quell'azzeramento, cioè non si
        // controllano quando una chiusura è avvenuta. La conservazione dei reparti,
        // invece, non dipende dalla chiusura e si controlla sempre.
        let giornoChiuso = eventi.contains { if case .giornataChiusa = $0 { return true } else { return false } }

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
            // La sosta dovuta non si elude marciando (01 §5.2.2.4): un gruppo che deve
            // rifornirsi non può ricevere un ordine di marcia.
            if prima.gruppi[id]?.deveRifornirsi == true {
                violazioni.append(.sostaElusaMarciando(gruppo: id.numero))
            }
        case .presidio(let id):
            idAgente = id
            if prima.gruppi[id]?.inMarcia == true {
                violazioni.append(.gruppoInMarciaHaRicevutoOrdine(gruppo: id.numero))
            }
        case .revocaMarcia(let id):
            // La revoca lascia il gruppo nella casella di partenza, senza marcia
            // residua e con la giornata spesa (01 §5.6.3.3, RDA-100). Non è un'azione.
            if let g = dopo.gruppi[id] {
                let conforme = g.posizione == prima.gruppi[id]?.posizione
                    && g.marcia == nil && g.azioneSpesa
                if !conforme { violazioni.append(.revocaNonConforme(gruppo: id.numero)) }
            }
        case .divisione(let id, let repartiStaccati, _):
            idAgente = id
            // Il distaccamento nasce ora ed è esente dalla regola «nessuno agisce da sé».
            if case .gruppoDiviso(_, _, let distaccamento, _, _) = eventi.first(where: {
                if case .gruppoDiviso = $0 { return true } else { return false } }) {
                natiOra.insert(distaccamento)
            }
            violazioni.append(contentsOf: controllaDivisione(
                id: id, prima: prima, dopo: dopo, eventi: eventi, giornoChiuso: giornoChiuso))
        case .riunione(let id, let idAltro):
            violazioni.append(contentsOf: controllaRiunione(
                id: id, idAltro: idAltro, prima: prima, dopo: dopo, giornoChiuso: giornoChiuso))
        case .sostaConRaccolta(let id):
            // La sosta con raccolta è un'azione (01 §5.6.8.1) e ha un agente: spende la
            // giornata come marcia e presidio. Un gruppo in marcia non la può ordinare.
            idAgente = id
            if prima.gruppi[id]?.inMarcia == true {
                violazioni.append(.gruppoInMarciaHaRicevutoOrdine(gruppo: id.numero))
            }
        }

        // «Azione spesa due volte»: solo per i comandi-AZIONE (marcia, presidio,
        // divisione), che hanno un agente. La revoca e la riunione non sono azioni.
        if let idAgente, prima.gruppi[idAgente]?.azioneSpesa == true {
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
            // Rifornimento a fine giornata (01 §5.2.2). La sonda ricava PER CONTO PROPRIO
            // le caselle alle spalle e le zone, così che un errore di geometria del
            // Motore non le sfugga (la sonda non chiama il Motore).
            for gruppo in dopo.gruppiOrdinati {
                // In zona il taglio non ha effetto: un gruppo in zona non resta senza
                // provviste dopo la chiusura (01 §5.2.2.6).
                if inZonaDiRifornimento(gruppo.posizione, dopo), gruppo.turniSenzaProvviste > 0 {
                    violazioni.append(.zonaTagliata(gruppo: gruppo.id.numero))
                }
                // Il taglio dipende SOLO dalle caselle prescritte (01 §5.2.2.2): se le
                // provviste sono peggiorate, una forza nemica deve stare alle spalle e il
                // gruppo non deve essere in zona.
                let prima2 = prima.gruppi[gruppo.id]?.turniSenzaProvviste ?? 0
                if gruppo.turniSenzaProvviste > prima2 {
                    let alleSpalle = caselleAlleSpalle(di: gruppo, in: dopo)
                    let taglioLegittimo = !inZonaDiRifornimento(gruppo.posizione, dopo)
                        && alleSpalle.contains(where: dopo.forzeNemiche.contains)
                    if !taglioLegittimo {
                        violazioni.append(.taglioDaCasellaNonPrescritta(gruppo: gruppo.id.numero))
                    }
                }
            }
        } else {
            if dopo.giorno != prima.giorno {
                violazioni.append(.giornoAvanzatoSenzaChiusura(prima: prima.giorno, dopo: dopo.giorno))
            }
            if let idAgente, dopo.gruppi[idAgente]?.azioneSpesa != true {
                violazioni.append(.azioneNonRegistrata(gruppo: idAgente.numero))
            }
            // Nessun gruppo PREESISTENTE (che non fosse l'agente) può aver speso
            // l'azione da sé. I gruppi nati ora sono esenti; la riunione non ha agente
            // e la sua regola sull'azione è controllata a parte.
            if let idAgente {
                for gruppo in dopo.gruppiOrdinati
                where gruppo.id != idAgente && !natiOra.contains(gruppo.id) {
                    if gruppo.azioneSpesa && prima.gruppi[gruppo.id]?.azioneSpesa != true {
                        violazioni.append(.gruppoEstraneoHaAgito(gruppo: gruppo.id.numero))
                    }
                }
            }
        }
        return violazioni
    }

    /// La divisione conserva i reparti e non regala azioni (01 §5.6.0.2): i reparti
    /// del gruppo di origine dopo, PIÙ quelli del distaccamento, eguagliano come
    /// multiinsieme i reparti del gruppo di prima; e sia l'origine sia il distaccamento
    /// hanno l'azione spesa (nessuno dei due può agire ancora).
    private func controllaDivisione(id: IdGruppo, prima: StatoCampagna, dopo: StatoCampagna,
                                    eventi: [EventoCampagna], giornoChiuso: Bool) -> [Violazione] {
        var violazioni: [Violazione] = []
        guard case .gruppoDiviso(_, _, let idDistacco, _, _) = eventi.first(where: {
            if case .gruppoDiviso = $0 { return true } else { return false } }),
              let origineDopo = dopo.gruppi[id], let distacco = dopo.gruppi[idDistacco],
              let originePrima = prima.gruppi[id] else { return violazioni }
        func multiinsieme(_ reparti: [Reparto]) -> [Reparto: Int] {
            var conti: [Reparto: Int] = [:]
            for r in reparti { conti[r, default: 0] += 1 }
            return conti
        }
        if multiinsieme(origineDopo.composizione + distacco.composizione)
            != multiinsieme(originePrima.composizione) {
            violazioni.append(.divisioneNonConserva(gruppo: id.numero))
        }
        // Sia l'origine sia il distaccamento hanno l'azione spesa (nessuno può agire
        // ancora oggi), salvo che la giornata si sia chiusa e l'azione azzerata.
        if !giornoChiuso {
            if !origineDopo.azioneSpesa { violazioni.append(.guadagnoDiAzione(gruppo: id.numero)) }
            if !distacco.azioneSpesa { violazioni.append(.guadagnoDiAzione(gruppo: idDistacco.numero)) }
        }
        return violazioni
    }

    /// La riunione non regala un'azione (01 §5.6.0.3): il risultante ha l'azione spesa
    /// SE E SOLO SE almeno uno dei due confluiti la aveva. Il risultante è quello dei
    /// due che sopravvive in `dopo`.
    private func controllaRiunione(id: IdGruppo, idAltro: IdGruppo,
                                   prima: StatoCampagna, dopo: StatoCampagna,
                                   giornoChiuso: Bool) -> [Violazione] {
        // Chiusa la giornata, l'azione si azzera e la regola non si applica.
        guard !giornoChiuso, let a = prima.gruppi[id], let b = prima.gruppi[idAltro] else { return [] }
        let idRisultante = dopo.gruppi[id] != nil ? id : idAltro
        guard let risultante = dopo.gruppi[idRisultante] else { return [] }
        let attesa = a.azioneSpesa || b.azioneSpesa
        return risultante.azioneSpesa == attesa ? [] : [.guadagnoDiAzione(gruppo: idRisultante.numero)]
    }

    // MARK: - Geometria del rifornimento, ricavata dalla sonda per conto proprio

    /// Le caselle alle spalle di un gruppo (01 §5.2.2.2), RICAVATE QUI e non chieste al
    /// Motore: la sonda non deve condividere i punti ciechi di ciò che giudica. La
    /// direzione viene dal quartier generale reale della parte del gruppo, comprese le
    /// due condizioni di bordo (riga retrostante inesistente, colonna di bordo).
    private func caselleAlleSpalle(di gruppo: Gruppo, in stato: StatoCampagna) -> Set<Cella> {
        let pos = gruppo.posizione
        let qg = stato.mappa.quartierGenerale(di: gruppo.parte)
        let passo = qg.riga == pos.riga ? 0 : (qg.riga > pos.riga ? 1 : -1)
        let righe = passo == 0 ? [pos.riga] : [pos.riga, pos.riga + passo]
        var celle = Set<Cella>()
        for r in righe {
            for c in [pos.colonna - 1, pos.colonna, pos.colonna + 1] {
                let cella = Cella(riga: r, colonna: c)
                if stato.griglia.contiene(cella) { celle.insert(cella) }
            }
        }
        return celle
    }

    /// Vero se la casella è in una zona di rifornimento (01 §5.2.2.6): distanza di
    /// Čebyšëv al più uno da una struttura. Anche questa la sonda la ricava da sé.
    private func inZonaDiRifornimento(_ cella: Cella, _ stato: StatoCampagna) -> Bool {
        stato.struttureDiRifornimento.contains {
            max(abs($0.riga - cella.riga), abs($0.colonna - cella.colonna)) <= 1
        }
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
