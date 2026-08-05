import Foundation
import Motore
import Dati

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
        let statoIniziale = try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna)
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
        let (nuovoStato, eventi) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovoStato
        // La chiusura della giornata è un confine significativo: vi si scatta
        // un'istantanea e vi si registra il marcatore che l'azzeramento userà
        // (05 §6.2, §6.4, §6.5).
        var giornataChiusa = false
        for evento in eventi { if case .giornataAperta = evento { giornataChiusa = true } }
        if giornataChiusa {
            try giornale.appendi(.aperturaGiornata(giorno: stato.giorno))
            try Self.scattaIstantanea(giornale: giornale, stato: stato,
                                      cartella: cartella, forzata: true)
        } else {
            try Self.scattaIstantanea(giornale: giornale, stato: stato,
                                      cartella: cartella, forzata: false)
        }
        return (esito, eventi)
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

    /// L'indice di riga dell'ultimo ordine impartito dalla parte, se esiste.
    private func ultimoOrdine(di parte: Parte) -> Int? {
        for riga in giornale.righe.reversed() {
            guard case .comandoCampagna(let p, _) = riga.voce else { continue }
            return p == parte ? riga.numero : nil
        }
        return nil
    }

    /// Vero se l'ordine indicato appartiene alla giornata in corso, oppure è quello
    /// la cui conferma l'ha aperta e nella giornata nuova non è ancora accaduto
    /// nulla. Falso per gli ordini di giornate passate.
    ///
    /// Si legge dal giornale e non dallo stato perché lo stato si ricostruisce
    /// riapplicando i comandi: dopo un annullamento sarebbe indistinguibile da una
    /// giornata appena aperta, e il confine sparirebbe alla prima ripresa.
    private func ordineDentroIlConfine(_ ordine: Int) -> Bool {
        var aperturaCorrente = 0
        for riga in giornale.righe.reversed() {
            if case .aperturaGiornata = riga.voce { aperturaCorrente = riga.numero; break }
        }
        if ordine > aperturaCorrente { return true } // ordine della giornata in corso
        // L'ordine precede l'apertura: è quello che ha chiuso la giornata prima.
        // Si concede finché nella giornata nuova non è accaduto nulla.
        return !giornale.righe.dropFirst(aperturaCorrente).contains {
            if case .annullamentoCampagna = $0.voce { return true } else { return false }
        }
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
            scenario: giornale.fondazioneCampagna.scenario, valoriCampagna: valoriCampagna)
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
                                           valoriCampagna: ValoriCampagna) throws
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
        return (try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna), 0)
    }
}
