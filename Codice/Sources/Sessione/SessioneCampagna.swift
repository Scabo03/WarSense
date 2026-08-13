import Foundation
import Motore
import Dati

/// La DIAGNOSTICA di una chiusura esplicita della giornata (incarico 26): quali gruppi non avevano
/// agito quando il titolare ha chiuso la giornata, il loro stato, e le azioni loro disponibili. È il
/// dato che trasforma un blocco che il titolare non sa riprodurre in qualcosa di utilizzabile — se
/// un gruppo risulta non-agito e senza alcuna azione disponibile, è il blocco, colto sul fatto. La
/// Presentazione la scrive accanto al salvataggio, sicché viaggia con esso.
public struct DiagnosticaChiusura: Sendable, Codable {
    public struct GruppoNonAgito: Sendable, Codable {
        public let numero: Int
        public let nome: String
        public let parte: String
        public let stato: String
        public let azioniDisponibili: [String]
    }
    public let giorno: Int
    public let gruppiNonAgiti: [GruppoNonAgito]
    /// Vero se la giornata NON si sarebbe chiusa da sé: c'erano gruppi non-agiti. È il caso in cui
    /// la diagnostica va conservata; se è falso, il titolare ha chiuso una giornata già chiudibile.
    public var laGiornataNonSiSarebbeChiusa: Bool { !gruppiNonAgiti.isEmpty }
}

/// L'orchestratore di una campagna (05 §1.7): unico proprietario dello stato
/// corrente e unico scrittore del giornale, con la stessa disciplina della
/// battaglia — scrittura confermata prima che l'esito diventi visibile, istantanee
/// ai confini significativi, eventi della riapplicazione soppressi.
public actor SessioneCampagna {

    public enum ErroreSessione: Error, Sendable {
        /// Salvataggio con versione dei valori incompatibile: dichiarato e non aperto (00 §15.2).
        case salvataggioIncompatibile(attesa: String, trovata: String)
        case schemaIncompatibile(atteso: Int, trovato: Int)
        case giornaleCorrotto(riga: Int)
        case scritturaFallita
        case operazioneNonDisponibile
        /// L'annullamento è stato chiesto oltre la giornata in corso (05 §6.5).
        /// Il rifiuto non è silenzioso: porta con sé il proprio motivo del
        /// vocabolario chiuso, che la Presentazione annuncia (00 §9).
        case oltreLaGiornataInCorso
    }

    private let motore: MotoreCampagna
    private let giornale: Giornale
    private let cartella: URL
    public private(set) var stato: StatoCampagna
    /// La condotta deterministica dell'avversario (RDA-114): senza stato, la Sessione la
    /// «pompa» dopo il turno del giocatore (RDA-41). Non è una seconda via per i comandi
    /// avversari: quelli passano dallo stesso `giornale.appendi` + `motore.applica` del
    /// giocatore (RDA-42); la condotta decide soltanto QUALE comando, sulla vista ristretta.
    private let condotta = CondottaAvversaria()
    /// Ogni quante righe si scatta un'istantanea: numero di struttura, non di gioco (05 §6.2).
    private static let passoIstantanee = 200

    // MARK: - Nascita e ripresa

    public init(nuova scenario: ScenarioCampagna, valori: ValoriDiGioco,
                valoriCampagna: ValoriCampagna, versioneTesti: String,
                cartella: URL, seme: UInt64, identificatore: String) throws {
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        self.cartella = cartella
        self.motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        let fondazione = FondazioneCampagna(versioneSchema: FondazioneCampagna.schemaCorrente,
                                            versioneValori: valori.versioneEffettiva,
                                            versioneTesti: versioneTesti,
                                            seme: seme, identificatore: identificatore,
                                            scenario: scenario)
        self.giornale = try Giornale.nuovo(a: cartella.appendingPathComponent("giornale.jsonl"),
                                           fondazione: fondazione)
        let statoIniziale = try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                                      archetipiNoti: Set(valori.archetipi.keys))
        self.stato = statoIniziale
        // Il marcatore di apertura giornata è il punto cui l'azzeramento risale (05 §6.4).
        try giornale.appendi(.aperturaGiornata(giorno: statoIniziale.giorno))
        try Self.scattaIstantanea(giornale: giornale, stato: statoIniziale,
                                  cartella: cartella, forzata: true)
    }

    /// Riprende dal giornale: istantanea più recente più riapplicazione (05 §6.3).
    public init(riprendi cartella: URL, valori: ValoriDiGioco,
                valoriCampagna: ValoriCampagna) throws {
        self.cartella = cartella
        self.motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        self.giornale = try Giornale.apri(a: cartella.appendingPathComponent("giornale.jsonl"))
        let fondazione = giornale.fondazioneCampagna

        guard fondazione.versioneSchema == FondazioneCampagna.schemaCorrente else {
            throw ErroreSessione.schemaIncompatibile(atteso: FondazioneCampagna.schemaCorrente,
                                                     trovato: fondazione.versioneSchema)
        }
        // Compatibilità sulla versione base (RDA-45): il suffisso locale è un'avvertenza.
        let baseSalvataggio = String(fondazione.versioneValori.split(separator: "+")[0])
        let compatibile = fondazione.versioneValori == valori.versioneEffettiva
            || valori.versioniCompatibili.contains(baseSalvataggio)
        guard compatibile else {
            throw ErroreSessione.salvataggioIncompatibile(attesa: valori.versioneEffettiva,
                                                          trovata: fondazione.versioneValori)
        }

        self.stato = try Self.ricostruisci(giornale: giornale, cartella: cartella,
                                           nonOltre: giornale.righe.count,
                                           motore: motore, valoriCampagna: valoriCampagna)
        // Se il giornale si è interrotto a metà del turno dell'avversario — alcuni suoi
        // comandi scritti, la giornata non ancora chiusa — la ripresa lo completa dallo
        // stesso punto: la condotta è deterministica e decide i gruppi rimasti come li
        // avrebbe decisi dal vivo, appendendoli al giornale. A un confine pulito (turno
        // del giocatore) è un'operazione a vuoto. Gli eventi non raggiungono nessuno in
        // ripresa (05 §6.3).
        try Self.svolgiTurnoAvversario(giornale: giornale, motore: motore,
                                       condotta: condotta, cartella: cartella, stato: &self.stato)
    }

    // MARK: - Esecuzione (05 §1.7)

    /// Valida, appende al giornale con conferma di scrittura, applica, consegna gli
    /// eventi. Un comando non valido non viene applicato né registrato.
    public func esegui(_ comando: ComandoCampagna, parte: Parte)
        throws -> (esito: EsitoValidazioneCampagna, eventi: [EventoCampagna]) {
        let esito = motore.valida(comando, parte: parte, stato: stato)
        guard esito.eValido else { return (esito, []) }
        do { try giornale.appendi(.comandoCampagna(parte: parte, comando: comando)) }
        catch { throw ErroreSessione.scritturaFallita }
        let (nuovoStato, eventiComando) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovoStato
        var eventi = eventiComando
        // Il comando del giocatore può chiudere la giornata da solo — quando non c'è
        // avversario da muovere, cioè i suoi gruppi sono già tutti conclusi o in marcia
        // lunga — e allora i marcatori si scrivono qui. Altrimenti la chiusura è rinviata
        // al turno dell'avversario, che scatta appena il giocatore ha concluso.
        try Self.registraChiusura(eventiComando, avversarioHaAgito: false,
                                  giornale: giornale, cartella: cartella, stato: stato)
        if parte == .giocatore {
            eventi += try Self.svolgiTurnoAvversario(giornale: giornale, motore: motore,
                                                     condotta: condotta, cartella: cartella,
                                                     stato: &stato)
        }
        // La proiezione è l'ultima difesa: alla Presentazione arrivano soltanto gli
        // eventi che il giocatore è titolato a conoscere (01 §5.6.11, RDA-115).
        return (esito, motore.proiettaPerIlGiocatore(eventi, stato: stato))
    }

    /// Riporta in campagna l'esito di una battaglia conclusa (01 §15, incarico 24): iscrive
    /// l'esito nel giornale — è il punto in cui i due giornali si toccano — e lo piega sullo
    /// stato, rimuovendo la battaglia in sospeso. Se con ciò l'ultima battaglia si conclude, la
    /// campagna si sblocca (01 §15.8) e, ove serva, l'avversario riprende il proprio turno nella
    /// giornata ripresa. Rifiuta se la battaglia indicata non è in sospeso: non si conclude ciò
    /// che non è aperto.
    public func concludiBattaglia(_ esito: EsitoInCampagna) throws {
        guard stato.battaglieInSospeso.contains(where: { $0.identificatore == esito.identificatore }) else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        do { try giornale.appendi(.battagliaConclusa(esito: esito)) }
        catch { throw ErroreSessione.scritturaFallita }
        // Il ritorno spende la giornata dei combattenti e la CHIUDE se erano gli ultimi in attesa
        // (incarico 25): i marcatori di quella chiusura vanno nel giornale, o il confine
        // dell'annullamento perderebbe l'apertura della giornata nuova (05 §6.5). I marcatori NON
        // toccano la ricostruzione (`ricostruisci` li salta), sicché la rigiocatura resta identica.
        let eventi = motore.applicaEsitoInCampagna(esito, in: &stato)
        try Self.registraChiusura(eventi, avversarioHaAgito: false,
                                  giornale: giornale, cartella: cartella, stato: stato)
        try Self.scattaIstantanea(giornale: giornale, stato: stato, cartella: cartella, forzata: true)
        // Sbloccata la campagna, se i gruppi del giocatore hanno già tutti concluso la giornata
        // ripresa (raro: p. es. l'unico gruppo che restava è caduto), l'avversario deve muovere.
        try Self.svolgiTurnoAvversario(giornale: giornale, motore: motore,
                                       condotta: condotta, cartella: cartella, stato: &stato)
    }

    /// La CHIUSURA ESPLICITA della giornata (incarico 26, decisione del titolare): una via d'uscita
    /// sempre disponibile perché il giocatore non resti bloccato da un difetto in una partita in
    /// corso. Chiude la giornata quale che sia lo stato dei gruppi, la iscrive nel giornale — sicché
    /// sopravvive a un riavvio — e ne registra i marcatori. Ritorna la DIAGNOSTICA di ciò che la
    /// rendeva necessaria: i gruppi che non avevano agito, il loro stato, le azioni loro disponibili.
    /// La chiusura automatica (01 §5.6.0.6) resta: questo comando si aggiunge, non la sostituisce.
    @discardableResult
    public func chiudiGiornata() throws -> DiagnosticaChiusura {
        // La diagnostica si raccoglie PRIMA della chiusura, sullo stato che l'ha resa necessaria:
        // ogni gruppo non-agito, il suo stato dichiarato, e le azioni che gli erano disponibili.
        let nonAgiti = stato.gruppi.values
            .filter { !$0.haConclusoLaGiornata }
            .sorted { $0.id.numero < $1.id.numero }
            .map { g in
                DiagnosticaChiusura.GruppoNonAgito(
                    numero: g.id.numero, nome: g.nome, parte: g.parte.rawValue,
                    stato: g.statoDichiarato.chiaveTesto,
                    azioniDisponibili: azioniDisponibili(per: g, in: stato))
            }
        let diagnostica = DiagnosticaChiusura(giorno: stato.giorno, gruppiNonAgiti: nonAgiti)

        do { try giornale.appendi(.giornataChiusaDalGiocatore(giorno: stato.giorno)) }
        catch { throw ErroreSessione.scritturaFallita }
        let eventi = motore.chiudiLaGiornataForzata(&stato)
        try Self.registraChiusura(eventi, avversarioHaAgito: false,
                                  giornale: giornale, cartella: cartella, stato: stato)
        return diagnostica
    }

    /// Le azioni disponibili a un gruppo non-agito, come codici stabili (05 §12.6): lo stesso
    /// insieme di candidati dell'invariante della giocabilità (`ordinabile`), qui elencato invece
    /// che ridotto a un booleano, perché la diagnostica dica quali azioni c'erano — o che non ce
    /// n'era alcuna, il caso del blocco.
    private func azioniDisponibili(per gruppo: Gruppo, in stato: StatoCampagna) -> [String] {
        var codici: [String] = []
        func ammette(_ comando: ComandoCampagna) -> Bool {
            motore.valida(comando, parte: gruppo.parte, stato: stato).eValido
        }
        if ammette(.presidio(gruppo: gruppo.id)) { codici.append("presidio") }
        if ammette(.sostaConRaccolta(gruppo: gruppo.id)) { codici.append("sosta_con_raccolta") }
        if stato.griglia.vicini(di: gruppo.posizione).contains(where: {
            ammette(.marcia(gruppo: gruppo.id, a: $0,
                            giorni: motore.costoInGiorni(da: gruppo.posizione, a: $0, stato: stato)))
        }) { codici.append("marcia") }
        if gruppo.categoria.eRicognizione, ammette(.esplorazione(gruppo: gruppo.id)) { codici.append("esplorazione") }
        if gruppo.categoria.eArmata, ammette(.imboscata(gruppo: gruppo.id)) { codici.append("imboscata") }
        return codici
    }

    /// Muove l'avversario dopo che tutti i gruppi del giocatore hanno agito (01 §5.6.11):
    /// finché nessun gruppo del giocatore attende e un gruppo avversario sì, la condotta
    /// decide un comando per il gruppo di id minore che attende, che si appende al
    /// giornale e si applica come qualunque comando (RDA-42). L'ultimo comando avversario
    /// chiude la giornata, che si risolve e ne apre una nuova; se la nuova si apre con i
    /// soli gruppi del giocatore in marcia lunga, l'avversario torna a muovere. Termina
    /// perché ogni chiusura avanza il giorno e le marce si compiono in un numero finito
    /// di giorni. È il PUNTO in cui l'avversario passa dalla stessa via del giocatore.
    ///
    /// STATICO perché lo usa anche l'inizializzatore di ripresa, che è nonisolated e non
    /// può chiamare un metodo isolato dell'attore: opera sui parametri, non su `self`.
    @discardableResult
    private static func svolgiTurnoAvversario(giornale: Giornale, motore: MotoreCampagna,
                                              condotta: CondottaAvversaria, cartella: URL,
                                              stato: inout StatoCampagna) throws -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        while stato.gruppiInAttesa(di: .giocatore).isEmpty,
              stato.battaglieInSospeso.isEmpty, // una battaglia in sospeso ferma anche l'avversario (01 §6.4)
              !stato.gruppiInAttesa(di: .avversario).isEmpty {
            let vista = motore.vistaAvversario(stato: stato)
            guard let comando = condotta.prossimoComando(vista: vista) else { break }
            do { try giornale.appendi(.comandoCampagna(parte: .avversario, comando: comando)) }
            catch { throw ErroreSessione.scritturaFallita }
            let (nuovoStato, ev) = motore.applica(comando, parte: .avversario, stato: stato)
            stato = nuovoStato
            eventi += ev
            try registraChiusura(ev, avversarioHaAgito: true,
                                 giornale: giornale, cartella: cartella, stato: stato)
        }
        return eventi
    }

    /// Scrive i marcatori e scatta l'istantanea quando una serie di eventi ha CHIUSO la
    /// giornata (05 §6.2, §6.4, §6.5). Una sola coppia di marcatori anche quando più
    /// giornate si chiudono a cascata dentro una stessa applicazione: la riapplicazione
    /// del comando ripercorre la cascata e riproduce lo stato finale. Il marcatore di
    /// risoluzione, che SIGILLA l'ordine di chiusura contro l'annullamento (05 §6.5,
    /// RDA-102), si scrive quando la chiusura ha compiuto una marcia OPPURE quando
    /// l'avversario ha agito nella giornata: le sue mosse, ancorché non viste, sono una
    /// risoluzione che rifare equivarrebbe alla prova a rovescio (incarico 18, RDA-115).
    private static func registraChiusura(_ eventi: [EventoCampagna], avversarioHaAgito: Bool,
                                         giornale: Giornale, cartella: URL,
                                         stato: StatoCampagna) throws {
        let giornataChiusa = eventi.contains {
            if case .giornataAperta = $0 { return true } else { return false }
        }
        guard giornataChiusa else {
            try scattaIstantanea(giornale: giornale, stato: stato, cartella: cartella, forzata: false)
            return
        }
        let haCompiutoUnaMarcia = eventi.contains {
            if case .marciaCompiuta = $0 { return true } else { return false }
        }
        if haCompiutoUnaMarcia || avversarioHaAgito {
            try giornale.appendi(.risoluzioneGiornata(giorno: stato.giorno))
        }
        try giornale.appendi(.aperturaGiornata(giorno: stato.giorno))
        try scattaIstantanea(giornale: giornale, stato: stato, cartella: cartella, forzata: true)
    }

    /// L'anteprima è la validazione (05 §3.2).
    public func anteprima(_ comando: ComandoCampagna, parte: Parte) -> EsitoValidazioneCampagna {
        motore.valida(comando, parte: parte, stato: stato)
    }

    public func vista(per parte: Parte) -> VistaCampagna {
        VistaCampagna(motore: motore, stato: stato, parte: parte)
    }

    public func impronta() -> String { stato.impronta() }
    public var fondazione: FondazioneCampagna { giornale.fondazioneCampagna }
    public var numeroRigheGiornale: Int { giornale.righe.count }

    // MARK: - Annullamento e azzeramento (05 §6.4, 00 §13.8)

    /// Che cosa l'annullamento ha fatto. La riapertura della giornata si dichiara
    /// perché il giocatore possa distinguerla da un annullamento ordinario: è un
    /// cambiamento di stato rilevante e va annunciato (00 §11.4).
    public struct EsitoAnnullamento: Hashable, Sendable {
        public let giornataRiaperta: Bool
        public let giorno: Int
    }

    /// Ritira l'ultimo ordine impartito, DENTRO IL CONFINE DELLA GIORNATA IN CORSO.
    ///
    /// La giornata è un budget che si consuma, e 00 §13.8 vuole che ogni budget che
    /// si consuma abbia l'annullamento dell'ultima operazione: «senza annullamento
    /// il giocatore paga un errore di manovra come se fosse stata una scelta
    /// tattica». Dentro la giornata l'annullamento è quindi pieno.
    ///
    /// 05 §6.5 elenca la chiusura della giornata fra i punti di conferma oltre i
    /// quali l'annullamento non retrocede, e il confine vale ADESSO e non quando
    /// l'avversario esisterà: annullare dopo la chiusura, in presenza di mosse
    /// avversarie e di risoluzioni di fine giornata, equivarrebbe alla prova a
    /// rovescio e vanificherebbe l'informazione imperfetta, l'imboscata e il valore
    /// della ricognizione; e una libertà concessa e poi tolta costa al giocatore
    /// più di una libertà mai concessa (decisione del titolare, RDA-73; la deroga
    /// precedente era RDA-70).
    ///
    /// Il confine NON è il ripristino del comportamento della build 11, in cui
    /// l'ordine dato all'ultimo gruppo era irreversibile per la sua POSIZIONE nella
    /// sequenza e non per la sua natura, in violazione di 00 §13.8. L'ordine la cui
    /// conferma chiude la giornata si annulla, e annullarlo riapre la giornata
    /// appena chiusa: è l'ultimo gesto del giocatore, e l'annullamento ritira
    /// l'ultimo gesto. Vale però finché la giornata nuova è intatta, cioè finché in
    /// essa non è accaduto nulla — né un ordine né un annullamento. Da quel momento
    /// quell'ordine appartiene a una giornata passata e l'annullamento è rifiutato,
    /// con il proprio motivo dichiarato (00 §9, principio 9).
    @discardableResult
    public func annulla(parte: Parte) throws -> EsitoAnnullamento {
        guard let ultimo = ultimoOrdine(di: parte) else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        guard ordineDentroIlConfine(ultimo) else {
            throw ErroreSessione.oltreLaGiornataInCorso
        }
        let giornoPrima = stato.giorno
        // Si tronca ALLA riga dell'ordine: se ne va l'ordine e con esso ogni
        // marcatore che gli è seguito, cioè l'apertura della giornata successiva.
        try ritira(a: ultimo, azzeramento: false)
        return EsitoAnnullamento(giornataRiaperta: stato.giorno != giornoPrima, giorno: stato.giorno)
    }

    /// Ritira tutti gli ordini della giornata annullabile, cioè la più recente che
    /// ne contenga almeno uno (05 §6.4), con lo stesso confine dell'annullamento.
    /// Se la giornata corrente si è appena aperta perché la precedente si è chiusa,
    /// la giornata annullabile è quella chiusa, e l'azzeramento la riapre vuota.
    @discardableResult
    public func azzera(parte: Parte) throws -> EsitoAnnullamento {
        guard let ultimo = ultimoOrdine(di: parte) else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        guard ordineDentroIlConfine(ultimo) else {
            throw ErroreSessione.oltreLaGiornataInCorso
        }
        var indiceMarcatore = 0
        for riga in giornale.righe.prefix(ultimo).reversed() {
            if case .aperturaGiornata = riga.voce { indiceMarcatore = riga.numero; break }
        }
        let giornoPrima = stato.giorno
        try ritira(a: indiceMarcatore + 1, azzeramento: true)
        return EsitoAnnullamento(giornataRiaperta: stato.giorno != giornoPrima, giorno: stato.giorno)
    }

    /// L'indice di riga dell'ultimo ordine impartito dalla parte, se esiste. Salta i
    /// comandi dell'ALTRA parte: dopo il turno dell'avversario l'ultimo comando del
    /// giornale è suo, ma l'ordine che il giocatore può considerare di annullare è il
    /// proprio ultimo, che il confine sigilla se la giornata si è chiusa (incarico 18).
    /// Prima dell'avversario — dentro il proprio turno — l'ultimo comando è comunque del
    /// giocatore, sicché l'annullamento nella giornata in corso resta quello di prima.
    private func ultimoOrdine(di parte: Parte) -> Int? {
        for riga in giornale.righe.reversed() {
            if case .comandoCampagna(let p, _) = riga.voce, p == parte { return riga.numero }
        }
        return nil
    }

    /// Vero se l'ordine indicato appartiene alla giornata in corso, oppure è quello
    /// la cui conferma l'ha aperta e la chiusura che ne è seguita NON ha compiuto una
    /// marcia e nella giornata nuova non è ancora accaduto nulla. Falso altrimenti.
    ///
    /// Con la risoluzione di fine giornata il confine di 05 §6.5 torna a mordere: se
    /// la chiusura ha compiuto una marcia lunga, il giocatore ne ha ascoltato
    /// l'arrivo, e annullare l'ordine che l'ha chiusa sarebbe rifare la mossa sapendo
    /// com'è andata. La deroga di RDA-73 — che concedeva l'annullamento dell'ordine
    /// di chiusura finché la giornata nuova era intatta — resta valida SOLTANTO per
    /// le chiusure senza fatti: quando la chiusura non compie nulla, 00 §13.8
    /// (annullare l'ultimo gesto, principio supremo dell'accessibilità) prevale e
    /// l'ordine resta annullabile; quando compie una marcia, 05 §6.5 prevale e il
    /// rifiuto è dichiarato con `campagna.non_si_torna_oltre_la_giornata` (RDA-102).
    ///
    /// Si legge dal giornale e non dallo stato perché lo stato si ricostruisce
    /// riapplicando i comandi: dopo un annullamento sarebbe indistinguibile da una
    /// giornata appena aperta, e il confine sparirebbe alla prima ripresa. Il
    /// marcatore `risoluzioneGiornata` vive nel giornale per la stessa ragione.
    private func ordineDentroIlConfine(_ ordine: Int) -> Bool {
        var aperturaCorrente = 0
        for riga in giornale.righe.reversed() {
            if case .aperturaGiornata = riga.voce { aperturaCorrente = riga.numero; break }
        }
        if ordine > aperturaCorrente { return true } // ordine della giornata in corso
        // L'ordine precede l'apertura: è quello che ha chiuso la giornata prima.
        let giornataNuovaIntatta = !giornale.righe.dropFirst(aperturaCorrente).contains {
            if case .annullamentoCampagna = $0.voce { return true } else { return false }
        }
        // Fra l'ordine di chiusura e l'apertura sta il marcatore di risoluzione se e
        // solo se quella chiusura ha compiuto una marcia.
        let chiusuraHaCompiutoUnaMarcia = giornale.righe[ordine..<aperturaCorrente].contains {
            if case .risoluzioneGiornata = $0.voce { return true } else { return false }
        }
        return giornataNuovaIntatta && !chiusuraHaCompiutoUnaMarcia
    }

    private func ritira(a numeroRighe: Int, azzeramento: Bool) throws {
        try giornale.tronca(a: numeroRighe)
        try eliminaIstantanee(oltre: numeroRighe)
        stato = try Self.ricostruisci(giornale: giornale, cartella: cartella,
                                      nonOltre: numeroRighe, motore: motore,
                                      valoriCampagna: motore.valoriCampagna)
        // L'annullamento è un fatto avvenuto e va annotato (01 §5.17). Il giornale
        // è l'unico posto dove possa sopravvivere: nello stato, che si ricostruisce
        // riapplicando i comandi, un ordine ritirato non lascia traccia.
        try giornale.appendi(.annullamentoCampagna(giorno: stato.giorno, azzeramento: azzeramento))
        motore.annota(azzeramento ? .giornataAzzerata : .ordineAnnullato, in: &stato)
        try Self.scattaIstantanea(giornale: giornale, stato: stato,
                                  cartella: cartella, forzata: true)
    }

    // MARK: - Ricostruzione, istantanee (05 §6.2, §6.3)

    private struct Istantanea: Codable {
        let righeApplicate: Int
        let stato: StatoCampagna
        enum CodingKeys: String, CodingKey {
            case righeApplicate = "righe_applicate"
            case stato
        }
    }

    /// Istantanea più recente più riapplicazione dei comandi successivi. Durante la
    /// riapplicazione gli eventi non raggiungono nessuno (05 §6.3).
    private static func ricostruisci(giornale: Giornale, cartella: URL, nonOltre limite: Int,
                                     motore: MotoreCampagna,
                                     valoriCampagna: ValoriCampagna) throws -> StatoCampagna {
        var (statoCorrente, daRiga) = try istantaneaMigliore(
            in: cartella, nonOltre: limite,
            scenario: giornale.fondazioneCampagna.scenario, valoriCampagna: valoriCampagna,
            archetipiNoti: Set(motore.valori.archetipi.keys))
        for riga in giornale.righe.prefix(limite).dropFirst(daRiga) {
            switch riga.voce {
            case .comandoCampagna(let parte, let comando):
                guard motore.valida(comando, parte: parte, stato: statoCorrente).eValido else {
                    throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
                }
                (statoCorrente, _) = motore.applica(comando, parte: parte, stato: statoCorrente)
            case .annullamentoCampagna(_, let azzeramento):
                // Il fatto torna nel registro come al momento in cui è avvenuto:
                // senza questo, la voce sparirebbe alla ripresa della campagna.
                motore.annota(azzeramento ? .giornataAzzerata : .ordineAnnullato, in: &statoCorrente)
            case .battagliaConclusa(let esito):
                // Il ritorno in campagna si RIPIEGA identico rigiocando (incarico 24): l'esito è
                // iscritto come dato, sicché la campagna ritrova i superstiti e le caselle senza
                // rileggere i file della battaglia. È così che l'esito sopravvive a un riavvio.
                _ = motore.applicaEsitoInCampagna(esito, in: &statoCorrente)
            case .giornataChiusaDalGiocatore:
                // La chiusura esplicita del titolare (incarico 26): rigiocata, chiude la giornata
                // forzatamente, sicché lo stato dopo un riavvio è quello che il giocatore ha lasciato.
                _ = motore.chiudiLaGiornataForzata(&statoCorrente)
            default:
                continue
            }
        }
        return statoCorrente
    }

    private static func scattaIstantanea(giornale: Giornale, stato: StatoCampagna,
                                         cartella: URL, forzata: Bool) throws {
        let conta = giornale.righe.count
        guard forzata || conta % passoIstantanee == 0 else { return }
        let istantanea = Istantanea(righeApplicate: conta, stato: stato)
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let dati = try codificatore.encode(istantanea)
        let url = cartella.appendingPathComponent("istantanea-\(conta).json")
        try dati.write(to: url, options: .atomic) // scrittura atomica (05 §6.8)
    }

    private func eliminaIstantanee(oltre limite: Int) throws {
        for (indice, url) in Self.istantaneeDisponibili(in: cartella) where indice > limite {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func istantaneeDisponibili(in cartella: URL) -> [(Int, URL)] {
        let contenuti = (try? FileManager.default.contentsOfDirectory(
            at: cartella, includingPropertiesForKeys: nil)) ?? []
        return contenuti.compactMap { url in
            let nome = url.lastPathComponent
            guard nome.hasPrefix("istantanea-"), nome.hasSuffix(".json"),
                  let indice = Int(nome.dropFirst("istantanea-".count).dropLast(".json".count))
            else { return nil }
            return (indice, url)
        }.sorted { $0.0 < $1.0 }
    }

    /// L'istantanea valida più recente non oltre il limite, o lo stato di fabbrica.
    /// Un'istantanea corrotta fa scalare alla precedente (05 §6.8).
    private static func istantaneaMigliore(in cartella: URL, nonOltre limite: Int,
                                           scenario: ScenarioCampagna,
                                           valoriCampagna: ValoriCampagna,
                                           archetipiNoti: Set<IdentificatoreDati>) throws
        -> (StatoCampagna, Int) {
        let candidate = istantaneeDisponibili(in: cartella)
            .filter { $0.0 <= limite }
            .sorted { $0.0 > $1.0 }
        for (indice, url) in candidate {
            if let dati = try? Data(contentsOf: url),
               let istantanea = try? JSONDecoder().decode(Istantanea.self, from: dati) {
                return (istantanea.stato, indice)
            }
        }
        return (try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                          archetipiNoti: archetipiNoti), 0)
    }
}
