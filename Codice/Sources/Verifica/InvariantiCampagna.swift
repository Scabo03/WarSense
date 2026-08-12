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
        // Invarianti della conoscenza incompleta (01 §5.3, §12).
        /// La memoria di conoscenza è cambiata senza che una giornata si chiudesse: un
        /// ricordo non retrocede mai da confermato se non col passare del tempo, e il
        /// tempo passa solo alla chiusura della giornata (01 §5.3, §5.6.11).
        case conoscenzaRegreditaSenzaTempo(parte: String)
        /// Un'età dell'informazione negativa: sarebbe conoscenza dal futuro, cioè il
        /// gioco che dichiara il falso su uno stato di conoscenza (01 §12), il che non
        /// è mai ammesso.
        case conoscenzaFalsa(parte: String, riga: Int, colonna: Int)
        // Invarianti dell'avversario (01 §5.6.11, §5.11.1, incarico 18).
        /// Il registro del giocatore ha acquisito un fatto che la sua conoscenza non gli
        /// ha dato: un avvistamento avversario su una casella che NON osserva, o un fatto
        /// di rifornimento di un gruppo AVVERSARIO. Nessuna informazione deve raggiungere
        /// il giocatore se non dai suoi stati di conoscenza e dal registro dei fatti che
        /// gli competono (01 §5.6.11). La sonda ricava l'osservazione da fuori.
        case registroRivelaIgnoto(voce: Int)
        /// La vista dell'avversario contiene una casella del giocatore che l'avversario
        /// NON osserva: deciderebbe su informazione che non possiede (01 §5.11.1). È il
        /// controllo che rende impossibile — non solo sconsigliato — leggere lo stato
        /// reale: se la proiezione perde tenuta, questa sonda se ne accorge.
        case vistaAvversariaRivelaIgnoto(riga: Int, colonna: Int)
        // Invarianti della ricognizione, delle imboscate e dello studio (incarico 19).
        /// Un ESPLORATORE è l'intruso di un'imboscata scattata in sospeso: gli esploratori non
        /// inneschiano MAI una battaglia (01 §5.4.1), e l'unica battaglia della campagna è
        /// quella da imboscata.
        case esploratoriInBattaglia(gruppo: Int)
        /// Un'imboscata è scattata all'ingresso di un gruppo NON armato: scatta soltanto
        /// all'ingresso di un gruppo armato (01 §5.11).
        case imboscataDaIngressoNonArmato(intruso: Int)
        /// Un sabotaggio RIUSCITO non ha disperso la formazione bersaglio: il sabotaggio la
        /// disperde e ne perde il carico (01 §5.10.2).
        case sabotaggioNonDisperde(riga: Int, colonna: Int)
        /// Lo studio approfondito ha portato a confermato più della sola formazione co-locata,
        /// o una che non ne è bersaglio lecito (01 §5.10.2).
        case studioConfermatoIndebito(gruppo: Int)
        /// Una nuova azione (esplorazione, imboscata, sabotaggio, studio) non ha consumato la
        /// giornata dell'agente: una giornata guadagnata (01 §5.6.0.5).
        case nuovaAzioneNonConclude(gruppo: Int)
        /// Una formazione dichiarata STUDIATA non è una formazione non armata avversaria: il
        /// gioco dichiarerebbe il falso su una conoscenza (01 §12, §5.10.2).
        case studiatoNonAvversario(gruppo: Int)
        /// Un gruppo APPOSTATO che non ha speso l'azione (01 §5.11, incarico 21): l'imboscata è
        /// un'azione che CONSUMA la giornata, sicché ogni appostato ha `azioneSpesa`. Un appostato
        /// senza azione spesa non si azzererebbe all'apertura e riaprirebbe la cascata (incarico 20).
        case appostatoConAzioneNonSpesa(gruppo: Int)
        /// L'OCCULTAMENTO violato (01 §5.11.1, incarico 21): la casella di un gruppo appostato è
        /// CONFERMATA per l'avversario che non l'ha scoperta — il gioco dichiarerebbe il falso, o
        /// mostrerebbe l'appostato che dovrebbe restare occulto. La conoscenza dell'altra parte,
        /// su una casella con un appostato non scoperto, non è mai confermato.
        case occultamentoViolato(parte: String, riga: Int, colonna: Int)
        /// Una PARTITA non terminata entro il numero dichiarato di giornate (01 §5.6.0.6, incarico
        /// 21): il turno dell'avversario, o la cascata delle chiusure, non si è fermato nel limite.
        /// È il difetto dell'incarico 20 reso un cancello che FALLISCE invece di appendere.
        case partitaNonTerminata(giornate: Int)
        // Invarianti dell'avvistamento (01 §5.6.11, incarico 22).
        /// In una partita CONTRO l'avversario il giocatore non ha avvistato NEMMENO UNA formazione
        /// avversaria dal principio alla fine (incarico 22): è il difetto che il collaudo non aveva
        /// visto e che il titolare ha visto giocando — un avversario che non si manifesta mai
        /// equivale a non esserci. Con un raggio di osservazione troppo piccolo accadeva; ora è un
        /// cancello che FALLISCE. Vale solo dove un avversario c'è: senza, non c'è nulla da avvistare.
        case nessunAvvistamentoInPartita
        /// Un AVVISTAMENTO dichiarato a cui non corrisponde una formazione avversaria realmente
        /// osservata su quella casella (incarico 22): il gioco dichiarerebbe il falso, la violazione
        /// più grave. L'avvistamento nasce solo dove il giocatore OSSERVA e una formazione avversaria
        /// è arrivata (01 §5.6.11); se il fatto compare senza la formazione, l'annuncio mentirebbe.
        case avvistamentoSenzaFormazione(riga: Int, colonna: Int)
        // Invariante dello scenario iniziale (01 §5.2, incarico 23).
        /// Uno scenario di campagna GIOCABILE non schiera una delle tre categorie per una delle due
        /// parti (incarico 23): è il difetto che ha reso inutili due build — lo scenario che arriva
        /// in mano al giocatore conteneva soltanto gruppi armati, senza avversario, senza
        /// ricognizione, senza formazioni non armate, sicché gli esploratori non esistevano in
        /// partita e il nemico non si incontrava. Reso un cancello, non più un'omissione silenziosa.
        case categoriaMancanteNelloScenario(scenario: String, parte: String, categoria: String)
        // Invarianti del passaggio alla battaglia e del ritorno (01 §6, §15, incarico 24).
        /// Le forze che TORNANO in campagna non coincidono coi superstiti della battaglia (01
        /// §15.7): una forza si è persa o si è duplicata nel passaggio fra i due piani. È
        /// l'invariante principale del passaggio — nessun atomo si crea né sparisce nella traduzione.
        case forzaNonConservataNelPassaggio(parte: String, superstiti: Int, riportata: Int)
        /// Il ritorno in campagna è scorretto (01 §15.2.3, §15.5, §10.6): un gruppo annientato è
        /// rimasto sulla mappa, o un superstite è sparito, o la sua composizione ridotta non
        /// combacia coi superstiti, o il vincitore non è nella casella contesa, o lo sconfitto non
        /// è arretrato. Il `motivo` dice quale.
        case ritornoInCampagnaScorretto(gruppo: Int, motivo: String)
        /// Il BLOCCO della battaglia in sospeso non blocca ciò che deve, o blocca ciò che non deve
        /// (01 §6.4): con una battaglia in sospeso un comando di campagna non è respinto col motivo
        /// dovuto, oppure — senza battaglia — un comando è respinto proprio con quel motivo.
        case bloccoBattagliaNonEffettivo(atteso: Bool)
        /// L'esito di una battaglia RIGIOCATA dai suoi comandi diverge dall'originale (05 §6.3): la
        /// battaglia non è deterministica, e il giornale non la riproduce identica.
        case rigiocaturaBattagliaDivergente(casella: String)

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
            case .conoscenzaRegreditaSenzaTempo(let p): return "conoscenza_regredita_senza_tempo:parte=\(p)"
            case .conoscenzaFalsa(let p, let r, let c): return "conoscenza_falsa:parte=\(p):riga=\(r):casella=\(c)"
            case .registroRivelaIgnoto(let v): return "registro_rivela_ignoto:voce=\(v)"
            case .vistaAvversariaRivelaIgnoto(let r, let c): return "vista_avversaria_rivela_ignoto:riga=\(r):casella=\(c)"
            case .esploratoriInBattaglia(let g): return "esploratori_in_battaglia:gruppo=\(g)"
            case .imboscataDaIngressoNonArmato(let i): return "imboscata_da_ingresso_non_armato:intruso=\(i)"
            case .sabotaggioNonDisperde(let r, let c): return "sabotaggio_non_disperde:riga=\(r):casella=\(c)"
            case .studioConfermatoIndebito(let g): return "studio_confermato_indebito:gruppo=\(g)"
            case .nuovaAzioneNonConclude(let g): return "nuova_azione_non_conclude:gruppo=\(g)"
            case .studiatoNonAvversario(let g): return "studiato_non_avversario:gruppo=\(g)"
            case .appostatoConAzioneNonSpesa(let g): return "appostato_senza_azione:gruppo=\(g)"
            case .occultamentoViolato(let p, let r, let c): return "occultamento_violato:parte=\(p):riga=\(r):casella=\(c)"
            case .partitaNonTerminata(let g): return "partita_non_terminata:giornate=\(g)"
            case .nessunAvvistamentoInPartita: return "nessun_avvistamento_in_partita"
            case .avvistamentoSenzaFormazione(let r, let c): return "avvistamento_senza_formazione:riga=\(r):casella=\(c)"
            case .categoriaMancanteNelloScenario(let s, let p, let c): return "categoria_mancante_nello_scenario:scenario=\(s):parte=\(p):categoria=\(c)"
            case .forzaNonConservataNelPassaggio(let p, let s, let r): return "forza_non_conservata_nel_passaggio:parte=\(p):superstiti=\(s):riportata=\(r)"
            case .ritornoInCampagnaScorretto(let g, let m): return "ritorno_in_campagna_scorretto:gruppo=\(g):motivo=\(m)"
            case .bloccoBattagliaNonEffettivo(let a): return "blocco_battaglia_non_effettivo:atteso=\(a)"
            case .rigiocaturaBattagliaDivergente(let c): return "rigiocatura_battaglia_divergente:casella=\(c)"
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
        "conoscenza_regredita_senza_tempo",
        "conoscenza_falsa",
        "registro_rivela_ignoto",
        "vista_avversaria_rivela_ignoto",
        "esploratori_in_battaglia",
        "imboscata_da_ingresso_non_armato",
        "sabotaggio_non_disperde",
        "studio_confermato_indebito",
        "nuova_azione_non_conclude",
        "studiato_non_avversario",
        "appostato_senza_azione",
        "occultamento_violato",
        "partita_non_terminata",
        "nessun_avvistamento_in_partita",
        "avvistamento_senza_formazione",
        "categoria_mancante_nello_scenario",
        "forza_non_conservata_nel_passaggio",
        "ritorno_in_campagna_scorretto",
        "blocco_battaglia_non_effettivo",
        "rigiocatura_battaglia_divergente",
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
        // Gli occupanti si contano PER PARTE: una casella ospita al più una formazione
        // della stessa parte (01 §5.6.0.2), ma la compresenza di un gruppo del giocatore
        // e di uno avversario è ammessa (01 §6.1), sicché due gruppi di parti DIVERSE
        // nella stessa casella non sono una violazione (incarico 18).
        var occupanti: [Cella: [Parte: Int]] = [:]
        for casella in stato.griglia.tutteLeCaselle {
            for gruppo in stato.gruppi.values where gruppo.posizione == casella {
                caselleDelGruppo[gruppo.id, default: 0] += 1
                occupanti[casella, default: [:]][gruppo.parte, default: 0] += 1
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
        for casella in occupanti.keys.sorted()
        where occupanti[casella]!.values.contains(where: { $0 > 1 }) {
            violazioni.append(.dueGruppiNellaStessaCasella(riga: casella.riga, colonna: casella.colonna))
        }
        var precedente = Int.min
        for voce in stato.registro {
            if voce.giorno < precedente { violazioni.append(.registroFuoriOrdine(voce: voce.numero)) }
            precedente = voce.giorno
        }
        // La memoria di conoscenza non porta mai un'età negativa: un'età è i turni
        // trascorsi dall'ultima osservazione, che non può essere il futuro (01 §12).
        for parte in Parte.allCases {
            for (cella, eta) in stato.conoscenza[parte] ?? [:] where eta < 0 {
                violazioni.append(.conoscenzaFalsa(parte: parte.rawValue,
                                                   riga: cella.riga, colonna: cella.colonna))
            }
        }
        // Le imboscate scattate in attesa di battaglia (01 §5.11, incarico 19): l'intruso è
        // sempre un gruppo ARMATO — l'imboscata scatta solo all'ingresso di un armato (§5.11) —
        // e mai un esploratore, che non innesca battaglia (§5.4.1). La sonda lo verifica sullo
        // stato, dove lo scatto ha lasciato traccia. Un intruso già rimosso non si controlla.
        for imboscata in stato.imboscateInSospeso {
            guard let intruso = stato.gruppi[imboscata.intruso] else { continue }
            if intruso.categoria.eRicognizione {
                violazioni.append(.esploratoriInBattaglia(gruppo: intruso.id.numero))
            }
            if !intruso.categoria.eArmata {
                violazioni.append(.imboscataDaIngressoNonArmato(intruso: intruso.id.numero))
            }
        }
        // Le formazioni STUDIATE (01 §5.10.2, incarico 19): ciascuna, se esiste ancora, è una
        // formazione non armata AVVERSARIA — lo studio riguarda il nemico. Dichiararne studiata
        // una propria o una armata sarebbe dichiarare il falso su una conoscenza (01 §12). Una
        // studiata poi sabotata sparisce da `studiati`: un id che non c'è più è lecito.
        for parte in Parte.allCases {
            for id in stato.studiati[parte] ?? [] {
                guard let g = stato.gruppi[id] else { continue }
                if g.parte == parte || !g.categoria.eNonArmata {
                    violazioni.append(.studiatoNonAvversario(gruppo: id.numero))
                }
            }
        }
        // L'imboscata CONSUMA l'azione (01 §5.11, incarico 21): un gruppo appostato ha sempre
        // `azioneSpesa`. È ciò che garantisce che si azzeri all'apertura della giornata e che la
        // cascata delle chiusure termini (il difetto dell'incarico 20). Un appostato senza azione
        // spesa la violerebbe.
        for gruppo in stato.gruppiOrdinati where gruppo.ordineImboscata && !gruppo.azioneSpesa {
            violazioni.append(.appostatoConAzioneNonSpesa(gruppo: gruppo.id.numero))
        }
        return violazioni
    }

    /// L'OCCULTAMENTO dell'imboscata (01 §5.11.1, incarico 21): su una casella con un gruppo
    /// APPOSTATO, la conoscenza dell'ALTRA parte — che questa sonda riceve dall'esterno, così da
    /// giudicarla senza rifarla col medesimo codice — non è mai «confermato», a meno che quella
    /// parte non abbia SCOPERTO l'imboscata con la ricognizione. Se lo fosse, il gioco dichiarerebbe
    /// il falso o mostrerebbe l'appostato che deve restare occulto. Vale simmetricamente.
    public func controllaOccultamento(stato: StatoCampagna,
                                      conoscenzaDelNemico: (Parte, Cella) -> StatoConoscenza) -> [Violazione] {
        var violazioni: [Violazione] = []
        for gruppo in stato.gruppiOrdinati where gruppo.ordineImboscata {
            let nemico: Parte = gruppo.parte == .giocatore ? .avversario : .giocatore
            let cella = gruppo.posizione
            guard stato.imboscateScoperte[nemico]?.contains(cella) != true else { continue }
            if case .confermato = conoscenzaDelNemico(nemico, cella) {
                violazioni.append(.occultamentoViolato(parte: nemico.rawValue,
                                                       riga: cella.riga, colonna: cella.colonna))
            }
        }
        return violazioni
    }

    /// La TERMINAZIONE (01 §5.6.0.6, incarico 21): una partita si chiude entro il numero DICHIARATO
    /// di giornate. Se i giorni trascorsi eccedono il limite, il turno dell'avversario o la cascata
    /// delle chiusure non si è fermato — il difetto dell'incarico 20 — e questo è un cancello che
    /// FALLISCE. Con l'imboscata che consuma l'azione (decisione 1) non accade; se accadesse, lo
    /// scenario che lo produce va dichiarato, non nascosto con un freno.
    public func controllaTerminazione(giorniTrascorsi: Int, limite: Int) -> [Violazione] {
        giorniTrascorsi > limite ? [.partitaNonTerminata(giornate: giorniTrascorsi)] : []
    }

    /// L'AVVISTAMENTO AVVENUTO (01 §5.6.11, incarico 22): in una partita CONTRO l'avversario il
    /// giocatore, muovendosi normalmente, avvista almeno una formazione avversaria dal principio
    /// alla fine. Se non ne avvista nessuna, l'avversario non si è mai manifestato — il difetto che
    /// il titolare vide giocando la build 23 e che il collaudo non aveva colto. Il conteggio arriva
    /// dall'esterno (lo produce il banco lungo la corsa), come per la terminazione, così che la
    /// sonda giudichi senza rifare la partita col medesimo codice. Negli scenari SENZA avversario
    /// non c'è nulla da avvistare e l'invariante tace.
    public func controllaAvvistamentoAvvenuto(avvistamenti: Int, conAvversario: Bool) -> [Violazione] {
        (conAvversario && avvistamenti == 0) ? [.nessunAvvistamentoInPartita] : []
    }

    /// LE TRE CATEGORIE NELLO SCENARIO INIZIALE (01 §5.2, incarico 23): uno scenario di campagna
    /// GIOCABILE deve schierare, per ENTRAMBE le parti, un gruppo armato, una formazione di
    /// ricognizione e una formazione non armata. È il difetto che il programma di verifica non
    /// vedeva — genera i propri scenari e non guarda ciò che arriva in mano al giocatore — e che ha
    /// reso inutili due build: gli esploratori costruiti nel Motore non esistevano nella partita, e
    /// l'avversario non c'era. La sonda riceve lo scenario dall'esterno, come gli altri cancelli
    /// parametrici, così da giudicare i tre scenari giocabili di `scenari-campagna.json`.
    public func controllaCategorieScenario(nome: String, scenario: ScenarioCampagna) -> [Violazione] {
        var violazioni: [Violazione] = []
        for (parte, gruppi) in [("giocatore", scenario.gruppiGiocatore),
                                ("avversario", scenario.gruppiAvversario)] {
            let categorie = Set(gruppi.map(\.categoria))
            for categoria in ["armato", "ricognizione", "non_armata"] where !categorie.contains(categoria) {
                violazioni.append(.categoriaMancanteNelloScenario(
                    scenario: nome, parte: parte, categoria: categoria))
            }
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
        case .esplorazione(let id):
            // Azione degli esploratori (01 §5.4). Con l'esito perduti l'esploratore è RIMOSSO:
            // in quel caso non c'è agente da controllare — non ha eluso una giornata, è sparito
            // — e le verifiche generiche dell'azione si saltano. Se resta, è l'agente. Che gli
            // esploratori non inneschino mai battaglia lo sorveglia `esploratori_senza_battaglia`.
            if dopo.gruppi[id] != nil { idAgente = id }
        case .imboscata(let id):
            // L'imboscata ora CONSUMA l'azione (incarico 21): il gruppo appostato è l'agente e la
            // giornata gli è spesa, come le altre azioni. Sorvegliato dalle verifiche generiche.
            idAgente = id
            if prima.gruppi[id]?.inMarcia == true {
                violazioni.append(.gruppoInMarciaHaRicevutoOrdine(gruppo: id.numero))
            }
        case .sabotaggio(let id), .studioApprofondito(let id):
            // Azioni con un agente che resta (sabotaggio e studio non rimuovono chi agisce, ma
            // il bersaglio): spendono la giornata come le altre.
            idAgente = id
        }

        // «Azione spesa due volte»: solo per i comandi-AZIONE (marcia, presidio,
        // divisione), che hanno un agente. La revoca e la riunione non sono azioni.
        if let idAgente, prima.gruppi[idAgente]?.azioneSpesa == true {
            violazioni.append(.azioneSpesaDueVolte(gruppo: idAgente.numero))
        }

        // Il sabotaggio RIUSCITO disperde la formazione bersaglio e il suo carico (01 §5.10.2):
        // dopo, nessuna formazione non armata avversaria occupa la casella dell'attore.
        if case .sabotaggio(let id) = comando,
           eventi.contains(where: { if case .sabotaggioCompiuto(_, _, _, true) = $0 { return true } else { return false } }),
           let attore = prima.gruppi[id] {
            let avversa: Parte = attore.parte == .giocatore ? .avversario : .giocatore
            if dopo.gruppi.values.contains(where: {
                $0.parte == avversa && $0.posizione == attore.posizione && $0.categoria.eNonArmata }) {
                violazioni.append(.sabotaggioNonDisperde(riga: attore.posizione.riga,
                                                         colonna: attore.posizione.colonna))
            }
        }
        // Lo studio confema SOLO la formazione co-locata (01 §5.10.2): la differenza di
        // `studiati` è al più quella formazione, avversaria, non armata e sulla casella
        // dell'attore. Portare a confermato più del dovuto è confermare ciò che i documenti
        // non prevedono.
        if case .studioApprofondito(let id) = comando, let attore = prima.gruppi[id] {
            let nuovi = (dopo.studiati[attore.parte] ?? []).subtracting(prima.studiati[attore.parte] ?? [])
            let leciti = nuovi.allSatisfy { idStudiato in
                guard let g = prima.gruppi[idStudiato] else { return false }
                return g.parte != attore.parte && g.categoria.eNonArmata && g.posizione == attore.posizione
            }
            if nuovi.count > 1 || !leciti {
                violazioni.append(.studioConfermatoIndebito(gruppo: id.numero))
            }
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
                    // Forze OSTILI alla parte DEL GRUPPO (incarico 18): per il giocatore i
                    // gruppi avversari e le forze ferme, per l'avversario i gruppi del
                    // giocatore. La sonda le ricava per conto proprio, senza chiamare il
                    // Motore, così che un errore di simmetria del Motore non le sfugga.
                    let ostili = caselleOstili(a: gruppo.parte, in: dopo)
                    let taglioLegittimo = !inZonaDiRifornimento(gruppo.posizione, dopo)
                        && alleSpalle.contains(where: ostili.contains)
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
            // Le nuove azioni (esplorazione, imboscata, sabotaggio, studio) consumano la
            // giornata dell'agente (01 §5.6.0.5, incarico 19): senza chiusura, l'agente — se
            // ancora presente — ha CONCLUSO la giornata (azione spesa o in agguato). Un agente
            // che potrebbe ancora agire avrebbe guadagnato una giornata. L'esploratore perduto
            // è rimosso e non si controlla.
            switch comando {
            case .esplorazione(let id), .imboscata(let id),
                 .sabotaggio(let id), .studioApprofondito(let id):
                if let g = dopo.gruppi[id], !g.haConclusoLaGiornata {
                    violazioni.append(.nuovaAzioneNonConclude(gruppo: id.numero))
                }
            default: break
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
            // La memoria di conoscenza invecchia — REGREDISCE — solo alla chiusura della
            // giornata (01 §5.6.11, §5.3): senza chiusura può soltanto MIGLIORARE, mai
            // retrocedere. Un ricordo può nascere o rinfrescarsi a zero (esplorazione, studio,
            // esploratori notati: incarico 19), ma nessuna età esistente può CRESCERE e nessun
            // ricordo può SPARIRE senza il passare del tempo — quella è la regressione da
            // confermato che l'invariante vieta.
            for parte in Parte.allCases {
                let prima2 = prima.conoscenza[parte] ?? [:]
                let dopo2 = dopo.conoscenza[parte] ?? [:]
                for (cella, etaPrima) in prima2 {
                    guard let etaDopo = dopo2[cella] else {
                        violazioni.append(.conoscenzaRegreditaSenzaTempo(parte: parte.rawValue)); break
                    }
                    if etaDopo > etaPrima {
                        violazioni.append(.conoscenzaRegreditaSenzaTempo(parte: parte.rawValue)); break
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

    /// Le caselle occupate da forze ostili a una parte (01 §5.2.2.2), ricavate QUI e non
    /// chieste al Motore: i gruppi della parte opposta, più — per il solo giocatore — le
    /// forze ferme dello scenario (incarico 18). Serve alla legittimità del taglio, che
    /// è simmetrica: la sonda la ricalcola per conto proprio.
    private func caselleOstili(a parte: Parte, in stato: StatoCampagna) -> Set<Cella> {
        var celle = Set(stato.gruppi.values.lazy.filter { $0.parte != parte }.map(\.posizione))
        if parte == .giocatore { celle.formUnion(stato.forzeNemiche) }
        return celle
    }

    // MARK: - Invarianti dell'avversario (01 §5.6.11, §5.11.1, incarico 18)

    /// Che il registro del giocatore non acquisisca ciò che la sua conoscenza non gli ha
    /// dato (01 §5.6.11). Ogni fatto NUOVO — in `dopo` e non in `prima` — è ammesso solo
    /// se è un avvistamento avversario su una casella che il giocatore OSSERVA, oppure un
    /// fatto che riguarda un suo gruppo. Un avvistamento su casella non osservata, o un
    /// fatto di rifornimento di un gruppo AVVERSARIO, è una fuga d'informazione.
    /// L'osservazione arriva dall'esterno, così che la sonda non rifaccia il calcolo del
    /// Motore con lo stesso codice.
    public func controllaRegistro(prima: StatoCampagna, dopo: StatoCampagna,
                                  osservataDalGiocatore: (Cella) -> Bool) -> [Violazione] {
        var violazioni: [Violazione] = []
        // I nomi dei gruppi del giocatore, prima e dopo: un nome non si riusa fra le parti
        // (01 §5.6.0.4), sicché individua una sola parte e serve a dire se un fatto la tocca.
        var nomiGiocatore = Set(dopo.gruppi.values.filter { $0.parte == .giocatore }.map(\.nome))
        nomiGiocatore.formUnion(prima.gruppi.values.filter { $0.parte == .giocatore }.map(\.nome))
        guard dopo.registro.count > prima.registro.count else { return violazioni }
        for voce in dopo.registro.suffix(dopo.registro.count - prima.registro.count) {
            switch voce.fatto {
            case .formazioneAvversariaAvvistata(let casella):
                // L'avvistamento è del solo giocatore e senza nome: legittimo solo dove il
                // giocatore OSSERVA (01 §5.6.11). Un avvistamento su una casella che non osserva
                // è una fuga d'informazione; ma non basta osservare — a un avvistamento DEVE
                // corrispondere una formazione avversaria realmente su quella casella (incarico 22),
                // altrimenti il gioco dichiarerebbe il falso, la violazione più grave. Le due
                // condizioni sono distinte: la prima è ciò che il giocatore NON dovrebbe sapere, la
                // seconda ciò che NON è vero. La presenza dell'avversario si legge sullo stato dopo,
                // che è quello in cui il fatto è stato annotato (l'arrivo che l'ha prodotto).
                if !osservataDalGiocatore(casella) {
                    violazioni.append(.registroRivelaIgnoto(voce: voce.numero))
                } else if !dopo.gruppi.values.contains(where: {
                    $0.parte == .avversario && $0.posizione == casella }) {
                    violazioni.append(.avvistamentoSenzaFormazione(riga: casella.riga, colonna: casella.colonna))
                }
            case .formazioneStudiata(let casella), .direzioneDedotta(let casella):
                // Studio e deduzione dell'itinerario sono del solo giocatore e senza nome:
                // legittimi solo dove il giocatore OSSERVA — dove il suo esploratore è sulla
                // casella studiata, o entro il raggio della colonna dedotta (01 §5.6.11, §5.10.1).
                if !osservataDalGiocatore(casella) {
                    violazioni.append(.registroRivelaIgnoto(voce: voce.numero))
                }
            case .marciaRevocata(let g, _),
                 .rifornimentoInterrotto(let g, _), .sostaDiRifornimento(let g, _),
                 .rifornimentoRipreso(let g, _),
                 .esploratoriPerduti(let g, _), .esploratoriNotati(let g, _):
                // Fatti che portano il nome di una formazione: devono riguardare un gruppo del
                // giocatore. Gli esploratori dell'AVVERSARIO che si perdono o si fanno notare
                // restano nel suo perimetro e non entrano nel registro del giocatore.
                if !nomiGiocatore.contains(g) {
                    violazioni.append(.registroRivelaIgnoto(voce: voce.numero))
                }
            case .formazioneSabotata, .imboscataScattata, .imboscataScoperta,
                 .battagliaInnescata, .battagliaConclusa:
                // L'innesco e la conclusione di una battaglia sono sempre fra parti opposte e
                // coinvolgono sempre il giocatore (con due sole parti), a una casella di cui è
                // parte: nessun ignoto da rivelare, come per lo scatto d'imboscata e il sabotaggio.
                // Sabotaggio, scatto e SCOPERTA d'imboscata sono sempre fra parti opposte: con
                // due sole parti coinvolgono sempre il giocatore — come attore o come vittima — a
                // una casella di cui è parte (il suo bersaglio, la sua colonna, il suo agguato,
                // l'imboscata avversaria che i SUOI esploratori hanno scoperto). La scoperta è
                // annotata solo per il giocatore che scopre (scopriLeImboscate), sicché non c'è
                // ignoto da rivelare; e la casella può non essere più osservata col raggio
                // ordinario dopo la scoperta (l'esplorazione vede più lontano, §5.4), sicché non
                // se ne esige l'osservazione.
                break
            case .ordineAnnullato, .giornataAzzerata:
                break
            }
        }
        return violazioni
    }

    /// Che la vista dell'avversario non riveli una posizione del giocatore che
    /// l'avversario non osserva (01 §5.11.1): ogni casella in `note` deve essere davvero
    /// osservata dall'avversario E ospitare un gruppo del giocatore. La vista e
    /// l'osservazione arrivano dall'esterno, così che la sonda giudichi la proiezione
    /// senza rifarla col medesimo codice. È il controllo che rende la cecità un
    /// invariante e non una disciplina.
    public func controllaVistaAvversario(stato: StatoCampagna, note: Set<Cella>,
                                         osservataDallAvversario: (Cella) -> Bool) -> [Violazione] {
        var violazioni: [Violazione] = []
        for cella in note.sorted() {
            let ospitaGiocatore = stato.gruppi.values.contains {
                $0.parte == .giocatore && $0.posizione == cella
            }
            if !osservataDallAvversario(cella) || !ospitaGiocatore {
                violazioni.append(.vistaAvversariaRivelaIgnoto(riga: cella.riga, colonna: cella.colonna))
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

    // MARK: - Invarianti del passaggio alla battaglia e del ritorno (01 §6, §15, incarico 24)

    /// (1) Che NESSUNA FORZA si perda o si duplichi nel passaggio (01 §15.7): gli atomi che
    /// tornano in campagna per ciascuna parte coincidono con quelli dei superstiti della battaglia.
    /// I superstiti li conta il banco dallo stato finale della battaglia (sciami in campo e riserve)
    /// e li passa dall'esterno, così che la sonda giudichi la traduzione del Ponte senza rifarla.
    public func controllaConservazioneForze(esito: EsitoInCampagna,
                                            superstiti: [Parte: Int]) -> [Violazione] {
        var violazioni: [Violazione] = []
        for parte in Parte.allCases {
            let riportata = esito.composizione(di: parte).reduce(0) { $0 + $1.atomi }
            let attesi = superstiti[parte] ?? 0
            if riportata != attesi {
                violazioni.append(.forzaNonConservataNelPassaggio(
                    parte: parte.rawValue, superstiti: attesi, riportata: riportata))
            }
        }
        return violazioni
    }

    /// (2) Che un gruppo ANNIENTATO sparisca dalla mappa e uno che RIPIEGA sopravviva ridotto e
    /// arretrato (01 §15.2.3, §15.5, §10.6): sullo stato di campagna DOPO il ritorno, ogni gruppo
    /// con superstiti vuoti nell'esito non c'è più; ogni gruppo con superstiti c'è ancora, con la
    /// composizione dei superstiti, e alla casella dovuta — il vincitore nella contesa, lo
    /// sconfitto arretrato.
    public func controllaRitornoInCampagna(inSospeso: BattagliaInSospeso, esito: EsitoInCampagna,
                                           dopo: StatoCampagna) -> [Violazione] {
        var violazioni: [Violazione] = []
        let vincitore = esito.vincitore
        for parte in Parte.allCases {
            let id = esito.gruppo(di: parte)
            let composizione = esito.composizione(di: parte)
            if composizione.isEmpty {
                if dopo.gruppi[id] != nil {
                    violazioni.append(.ritornoInCampagnaScorretto(gruppo: id.numero, motivo: "annientato_non_sparito"))
                }
                continue
            }
            guard let gruppo = dopo.gruppi[id] else {
                violazioni.append(.ritornoInCampagnaScorretto(gruppo: id.numero, motivo: "superstite_sparito"))
                continue
            }
            if gruppo.atomiTotali != composizione.reduce(0, { $0 + $1.atomi }) {
                violazioni.append(.ritornoInCampagnaScorretto(gruppo: id.numero, motivo: "superstite_non_ridotto"))
            }
            if parte == vincitore, gruppo.posizione != inSospeso.casella {
                violazioni.append(.ritornoInCampagnaScorretto(gruppo: id.numero, motivo: "vincitore_fuori_casella"))
            }
            if parte == esito.sconfitto, gruppo.posizione == inSospeso.casella {
                violazioni.append(.ritornoInCampagnaScorretto(gruppo: id.numero, motivo: "sconfitto_non_arretrato"))
            }
        }
        return violazioni
    }

    /// (3) Che una battaglia in sospeso BLOCCHI ciò che deve e nient'altro (01 §6.4): con una
    /// battaglia in sospeso, la validazione di un comando di campagna deve respingerlo col motivo
    /// `battaglia_in_sospeso`; senza, non deve respingerlo con quel motivo. L'esito della
    /// validazione arriva dall'esterno, così che la sonda non rifaccia il Motore.
    public func controllaBloccoBattaglia(haBattagliaInSospeso: Bool,
                                         motivoDelComando: MotivoNonValidoCampagna?) -> [Violazione] {
        let bloccato = motivoDelComando == .battagliaInSospeso
        if haBattagliaInSospeso != bloccato {
            return [.bloccoBattagliaNonEffettivo(atteso: haBattagliaInSospeso)]
        }
        return []
    }

    /// (4) Che l'esito di una battaglia RIGIOCATA dai suoi comandi sia identico (05 §6.3): le due
    /// impronte — quella della battaglia giocata e quella rigiocata dalla stessa sequenza — le
    /// calcola il banco e le passa dall'esterno; se divergono, la battaglia non è deterministica.
    public func controllaRigiocaturaBattaglia(casella: Cella, improntaGiocata: String,
                                              improntaRigiocata: String) -> [Violazione] {
        improntaGiocata == improntaRigiocata ? []
            : [.rigiocaturaBattagliaDivergente(casella: "\(casella.riga)-\(casella.colonna)")]
    }
}
