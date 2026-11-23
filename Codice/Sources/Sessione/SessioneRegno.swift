import Foundation
import Motore
import Dati

/// L'orchestratore del regno (05 §1.7; incarico 30, RDA-162): unico proprietario dello stato del
/// regno e unico scrittore del suo giornale, con la stessa disciplina del fronte e della battaglia —
/// la scrittura è confermata prima che l'esito diventi visibile, e gli eventi della riapplicazione
/// non raggiungono nessuno.
///
/// Il regno è il terzo strato. La campagna dell'anno vive in uno slot annidato, con il proprio
/// giornale e la propria Sessione; il giornale del regno ne riceve soltanto l'esito, come riga a sé
/// (`campagnaConclusaNelRegno`), sicché rigiocarlo riproduce il regno senza rileggere i file della
/// campagna. Il giornale del regno è breve — pochi comandi per anno —: lo stato si ricostruisce
/// dall'atto di fondazione riapplicando tutte le righe, senza istantanee (05 §6.2: le istantanee
/// servono soltanto alla velocità, la verità è il giornale).
public actor SessioneRegno {

    public enum ErroreSessione: Error, Sendable, Equatable {
        /// Salvataggio con versione dei valori incompatibile: dichiarato e non aperto (00 §15.2).
        case salvataggioIncompatibile(attesa: String, trovata: String)
        case schemaIncompatibile(atteso: Int, trovato: Int)
        case giornaleCorrotto(riga: Int)
        case scritturaFallita
        /// Nessuna spesa da annullare o da azzerare nella stazione in corso (00 §13.8).
        case nienteDaRitirare
        /// L'esito riportato non è quello della campagna che il regno ha aperta.
        case esitoNonAtteso
        /// La campagna non si può aprire: il motivo è quello del vocabolario chiuso.
        case aperturaRespinta
    }

    private let motore: MotoreRegno
    private let giornale: Giornale
    public private(set) var stato: StatoRegno

    /// Il nome del file del giornale dentro lo slot.
    public static let nomeGiornale = "giornale.jsonl"

    // MARK: - Nascita e ripresa

    public init(nuovo valori: ValoriRegno, versioneValori: String, versioneTesti: String,
                cartella: URL, seme: UInt64, identificatore: String) throws {
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        self.motore = MotoreRegno(valori: valori)
        let iniziale = try motore.statoIniziale()
        let fondazione = FondazioneRegno(versioneSchema: FondazioneRegno.schemaCorrente,
                                         versioneValori: versioneValori, versioneTesti: versioneTesti,
                                         seme: seme, identificatore: identificatore,
                                         modalita: FondazioneRegno.modalitaASciami,
                                         statoIniziale: iniziale)
        self.giornale = try Giornale.nuovo(a: cartella.appendingPathComponent(Self.nomeGiornale),
                                           fondazione: fondazione)
        self.stato = iniziale
    }

    /// Riprende dal giornale: stato di fondazione più riapplicazione di ogni riga (05 §6.3).
    public init(riprendi cartella: URL, valori: ValoriRegno, versioneValori: String,
                versioniCompatibili: [String]) throws {
        self.motore = MotoreRegno(valori: valori)
        // Lo schema si legge dall'intestazione PRIMA di aprire il giornale (incarico 31): un regno
        // di uno schema precedente non si decodifica più nella forma di oggi, e aprirlo lo
        // tratterebbe da file corrotto. Lo si dichiara incompatibile e lo si lascia com'è (00 §15.2).
        let percorso = cartella.appendingPathComponent(Self.nomeGiornale)
        if let trovato = Giornale.schemaDelRegno(a: percorso), trovato != FondazioneRegno.schemaCorrente {
            throw ErroreSessione.schemaIncompatibile(atteso: FondazioneRegno.schemaCorrente, trovato: trovato)
        }
        self.giornale = try Giornale.apri(a: percorso)
        guard let fondazione = giornale.fondazioneRegno else {
            throw ErroreSessione.giornaleCorrotto(riga: 0)
        }
        guard fondazione.versioneSchema == FondazioneRegno.schemaCorrente else {
            throw ErroreSessione.schemaIncompatibile(atteso: FondazioneRegno.schemaCorrente,
                                                     trovato: fondazione.versioneSchema)
        }
        // Compatibilità sulla versione base (RDA-45): il suffisso locale è un'avvertenza.
        let baseSalvataggio = String(fondazione.versioneValori.split(separator: "+")[0])
        guard fondazione.versioneValori == versioneValori
                || versioniCompatibili.contains(baseSalvataggio) else {
            throw ErroreSessione.salvataggioIncompatibile(attesa: versioneValori,
                                                          trovata: fondazione.versioneValori)
        }
        self.stato = try Self.ricostruisci(giornale: giornale, motore: motore)
    }

    // MARK: - Esecuzione (05 §1.7)

    /// Valida, appende al giornale con conferma di scrittura, applica, consegna gli eventi. Un
    /// comando non valido non viene applicato né registrato.
    public func esegui(_ comando: ComandoRegno)
        throws -> (esito: EsitoValidazioneRegno, eventi: [EventoRegno]) {
        let esito = motore.valida(comando, stato: stato)
        guard esito.eValido else { return (esito, []) }
        do { try giornale.appendi(.comandoRegno(comando: comando)) }
        catch { throw ErroreSessione.scritturaFallita }
        let (nuovo, eventi) = motore.applica(comando, stato: stato)
        stato = nuovo
        return (esito, eventi)
    }

    /// L'anteprima è la validazione (05 §3.2).
    public func anteprima(_ comando: ComandoRegno) -> EsitoValidazioneRegno {
        motore.valida(comando, stato: stato)
    }

    /// Riporta in patria l'esito della campagna conclusa (01 §2.6): lo iscrive nel giornale del
    /// regno — è il punto in cui i due giornali si toccano — e lo piega sullo stato. Rifiuta l'esito
    /// di una campagna che il regno non ha aperta: non si conclude ciò che non è aperto.
    @discardableResult
    public func concludiCampagna(_ esito: EsitoCampagna) throws -> [EventoRegno] {
        guard motore.accetta(esito, stato: stato) else { throw ErroreSessione.esitoNonAtteso }
        do { try giornale.appendi(.campagnaConclusaNelRegno(esito: esito)) }
        catch { throw ErroreSessione.scritturaFallita }
        return motore.applicaEsito(esito, in: &stato)
    }

    // MARK: - La campagna dell'anno (RDA-162, RDA-166)

    /// Il nome dello slot annidato della campagna dell'anno, dentro lo slot del regno.
    public static let cartellaCampagna = "campagna"

    /// Apre la campagna dell'anno su un fronte: fa nascere la Sessione del fronte nello slot
    /// annidato, con le forze del regno e il calendario dell'anno, e poi registra il comando nel
    /// giornale del regno. In quest'ordine, perché un'interruzione fra i due passi lasci un regno
    /// che non ha ancora aperto nulla e uno slot orfano, che la prossima apertura sostituisce —
    /// mai un regno che dichiara aperta una campagna che non esiste.
    public func apriCampagna(fronte: IdentificatoreDati, scenarioDelFronte: ScenarioCampagna,
                             valori: ValoriDiGioco, valoriCampagna: ValoriCampagna,
                             versioneTesti: String, cartellaDelRegno: URL, seme: UInt64,
                             identificatore: String)
        throws -> (campagna: SessioneCampagna?, esito: EsitoValidazioneRegno, eventi: [EventoRegno]) {
        let comando = ComandoRegno.apriCampagna(fronte: fronte)
        let esito = motore.valida(comando, stato: stato)
        guard esito.eValido else { return (nil, esito, []) }
        let campagna = try nasceLaCampagna(scenarioDelFronte: scenarioDelFronte, valori: valori,
                                           valoriCampagna: valoriCampagna, versioneTesti: versioneTesti,
                                           cartellaDelRegno: cartellaDelRegno, seme: seme,
                                           identificatore: identificatore)
        do { try giornale.appendi(.comandoRegno(comando: comando)) }
        catch { throw ErroreSessione.scritturaFallita }
        let (nuovo, eventi) = motore.applica(comando, stato: stato)
        stato = nuovo
        return (campagna, esito, eventi)
    }

    /// Fa nascere la Sessione del fronte per la campagna che il regno dichiara aperta ma il cui slot
    /// non esiste più (uno slot perduto): le forze del regno non sono cambiate dall'apertura, e lo
    /// scenario si ricompone identico. Nulla se il regno non ha una campagna aperta.
    public func ricreaCampagnaAperta(scenarioDelFronte: ScenarioCampagna, valori: ValoriDiGioco,
                                     valoriCampagna: ValoriCampagna, versioneTesti: String,
                                     cartellaDelRegno: URL, seme: UInt64,
                                     identificatore: String) throws -> SessioneCampagna? {
        guard stato.campagna.fronteAperto != nil else { return nil }
        return try nasceLaCampagna(scenarioDelFronte: scenarioDelFronte, valori: valori,
                                   valoriCampagna: valoriCampagna, versioneTesti: versioneTesti,
                                   cartellaDelRegno: cartellaDelRegno, seme: seme,
                                   identificatore: identificatore)
    }

    private func nasceLaCampagna(scenarioDelFronte: ScenarioCampagna, valori: ValoriDiGioco,
                                 valoriCampagna: ValoriCampagna, versioneTesti: String,
                                 cartellaDelRegno: URL, seme: UInt64,
                                 identificatore: String) throws -> SessioneCampagna {
        let calendario = CalendarioDiCampagna(anno: stato.anno,
                                              giornatePerStagione: motore.valori.giornatePerStagione)
        let scenario = try PonteRegnoCampagna.scenario(delFronte: scenarioDelFronte, forze: stato.forze,
                                                       calendario: calendario, valori: valoriCampagna)
        let cartella = cartellaDelRegno.appendingPathComponent(Self.cartellaCampagna)
        try? FileManager.default.removeItem(at: cartella)
        return try SessioneCampagna(nuova: scenario, valori: valori, valoriCampagna: valoriCampagna,
                                    versioneTesti: versioneTesti, cartella: cartella, seme: seme,
                                    identificatore: identificatore)
    }

    /// Se la campagna aperta si è conclusa, ne riporta l'esito in patria e restituisce gli eventi;
    /// nulla se non è conclusa o se il regno non ha una campagna aperta. Lo stato della campagna è
    /// quello che la sua Sessione dà: l'esito ne è funzione pura (`PonteRegnoCampagna.esito`).
    public func riceviEsito(dalla campagna: StatoCampagna) throws -> [EventoRegno]? {
        guard let fronte = stato.campagna.fronteAperto,
              let esito = PonteRegnoCampagna.esito(da: campagna, fronte: fronte) else { return nil }
        return try concludiCampagna(esito)
    }

    // MARK: - Annullamento e azzeramento delle spese (05 §6.4, 00 §13.8)

    /// L'indice della prima riga della stazione in corso: quella che segue il punto di conferma,
    /// cioè il comando che l'ha aperta (05 §6.5). Le sole righe che vi possono stare sono gli ordini.
    private var inizioDellaStazione: Int {
        for riga in giornale.righe.reversed() {
            if case .comandoRegno(let comando) = riga.voce, case .ordina = comando { continue }
            return riga.numero + 1
        }
        return 1
    }

    /// Quante spese si possono ancora ritirare: gli ordini della stazione in corso.
    public var speseRitirabili: Int { giornale.righe.count - inizioDellaStazione }

    /// Ritira l'ultima spesa della stazione in corso e la restituisce. Il bilancio è un budget che
    /// si consuma (00 §13.8); l'annullamento non retrocede oltre l'apertura della stazione, che è
    /// un punto di conferma (05 §6.5).
    @discardableResult
    public func annullaSpesa() throws -> LavoroOrdinato {
        guard speseRitirabili > 0, let ultimo = stato.lavori.last else {
            throw ErroreSessione.nienteDaRitirare
        }
        try giornale.tronca(a: giornale.righe.count - 1)
        stato = try Self.ricostruisci(giornale: giornale, motore: motore)
        return ultimo
    }

    /// Ritira tutte le spese della stazione in corso e ne restituisce il numero.
    @discardableResult
    public func azzeraSpese() throws -> Int {
        let quante = speseRitirabili
        guard quante > 0 else { throw ErroreSessione.nienteDaRitirare }
        try giornale.tronca(a: inizioDellaStazione)
        stato = try Self.ricostruisci(giornale: giornale, motore: motore)
        return quante
    }

    // MARK: - Letture

    public func impronta() -> String { stato.impronta() }
    public var numeroRigheGiornale: Int { giornale.righe.count }
    public var fondazione: FondazioneRegno? { giornale.fondazioneRegno }
    public var valori: ValoriRegno { motore.valori }

    /// Il costo di una voce, com'è adesso (05 §9.4: la Presentazione non calcola mai un dato di
    /// gioco): con la misura che la voce porta con sé, o con quella del bersaglio. Nullo se la voce
    /// chiede un bersaglio e quello indicato non esiste.
    public func costo(di voce: VoceDelRegno, bersaglio: BersaglioMilitare? = nil) -> Riserve? {
        motore.costo(di: voce, bersaglio: bersaglio, stato: stato)
    }

    /// Gli elementi delle forze su cui una voce si può ancora ordinare in questo inverno.
    public func bersagli(di voce: VoceDelRegno) -> [BersaglioMilitare] {
        motore.bersagli(di: voce, stato: stato)
    }

    // MARK: - Ricostruzione (05 §6.3)

    /// Lo stato di fondazione più ogni riga del giornale, riapplicata. Una riga che il Motore non
    /// convalida è un giornale corrotto, dichiarato e non applicato in silenzio.
    private static func ricostruisci(giornale: Giornale, motore: MotoreRegno) throws -> StatoRegno {
        guard let fondazione = giornale.fondazioneRegno else {
            throw ErroreSessione.giornaleCorrotto(riga: 0)
        }
        var stato = fondazione.statoIniziale
        for riga in giornale.righe.dropFirst() {
            switch riga.voce {
            case .comandoRegno(let comando):
                guard motore.valida(comando, stato: stato).eValido else {
                    throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
                }
                (stato, _) = motore.applica(comando, stato: stato)
            case .campagnaConclusaNelRegno(let esito):
                guard motore.accetta(esito, stato: stato) else {
                    throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
                }
                _ = motore.applicaEsito(esito, in: &stato)
            default:
                throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
            }
        }
        return stato
    }
}
