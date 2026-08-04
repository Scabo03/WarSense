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

    /// Ritira l'ultimo ordine impartito, QUALE CHE SIA ciò che gli è seguito.
    ///
    /// La giornata è un budget che si consuma, e 00 §13.8 vuole che ogni budget che
    /// si consuma abbia l'annullamento dell'ultima operazione: «senza annullamento
    /// il giocatore paga un errore di manovra come se fosse stata una scelta
    /// tattica». L'ordine più esposto all'errore è proprio l'ultimo della giornata,
    /// perché il giocatore lo impartisce per muovere un gruppo e ne ottiene per
    /// soprammercato un passaggio di giornata che non ha chiesto: se quello non si
    /// annullasse, un gesto compiuto per fare una cosa ne produrrebbe un'altra,
    /// irreversibile.
    ///
    /// 05 §6.5 elenca la chiusura della giornata fra i punti di conferma oltre i
    /// quali l'annullamento non retrocede. La ragione di quel punto di conferma è
    /// ciò che SEGUE la chiusura — le mosse avversarie e le risoluzioni di fine
    /// giornata, come 05 §6.4 dice esplicitamente («finché l'avversario non ha
    /// agito») — e in questa unità non esiste né l'una né l'altra cosa: la chiusura
    /// incrementa il contatore e riazzera le azioni, e nulla è stato giocato che
    /// l'annullamento debba disfare. Quando lo stratega avversario e le risoluzioni
    /// di fine giornata esisteranno, il punto di conferma tornerà a mordere come il
    /// documento prescrive, e il posto dove imporlo è questa funzione. Registrato
    /// come scostamento e in RDA-70.
    @discardableResult
    public func annulla(parte: Parte) throws -> EsitoAnnullamento {
        guard let ultimo = ultimoOrdine(di: parte) else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        let giornoPrima = stato.giorno
        // Si tronca ALLA riga dell'ordine: se ne va l'ordine e con esso ogni
        // marcatore che gli è seguito, cioè l'apertura della giornata successiva.
        try ritira(a: ultimo)
        return EsitoAnnullamento(giornataRiaperta: stato.giorno != giornoPrima, giorno: stato.giorno)
    }

    /// Ritira tutti gli ordini della giornata annullabile, cioè la più recente che
    /// ne contenga almeno uno (05 §6.4). Se la giornata corrente si è appena aperta
    /// perché la precedente si è chiusa, la giornata annullabile è quella chiusa, e
    /// l'azzeramento la riapre vuota.
    @discardableResult
    public func azzera(parte: Parte) throws -> EsitoAnnullamento {
        guard let ultimo = ultimoOrdine(di: parte) else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        var indiceMarcatore = 0
        for riga in giornale.righe.prefix(ultimo).reversed() {
            if case .aperturaGiornata = riga.voce { indiceMarcatore = riga.numero; break }
        }
        let giornoPrima = stato.giorno
        try ritira(a: indiceMarcatore + 1)
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

    private func ritira(a numeroRighe: Int) throws {
        try giornale.tronca(a: numeroRighe)
        try eliminaIstantanee(oltre: numeroRighe)
        stato = try Self.ricostruisci(giornale: giornale, cartella: cartella,
                                      nonOltre: numeroRighe, motore: motore,
                                      valoriCampagna: motore.valoriCampagna)
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
            guard case .comandoCampagna(let parte, let comando) = riga.voce else { continue }
            guard motore.valida(comando, parte: parte, stato: statoCorrente).eValido else {
                throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
            }
            (statoCorrente, _) = motore.applica(comando, parte: parte, stato: statoCorrente)
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
