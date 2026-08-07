import Foundation
import Dati
import Motore

/// Le SESSIONI COMPLETE: una campagna condotta dal primo giorno a un criterio di
/// arresto dichiarato, uno scontro condotto dallo schieramento alla conclusione.
///
/// ## Perché servono, accanto a ciò che già esiste
///
/// `BancoCampagna` genera giornate e `BancoScontri` gioca scontri, ma gli
/// invarianti che vi si applicano sono tutti del PASSO: guardano uno stato, o una
/// transizione, e nulla di ciò che si accumula. Un difetto che si manifesti soltanto
/// dopo venti giornate — un gruppo che sparisce, un giorno che salta, un registro
/// che perde una voce — non è violabile da un invariante di passo, perché ciascun
/// passo, preso da solo, è impeccabile.
///
/// ## Il criterio con cui gli invarianti di sessione sono stati scelti
///
/// Sono di sessione le proprietà che **non si possono enunciare guardando un solo
/// passo**: richiedono di confrontare la fine con l'inizio, oppure una sequenza
/// intera con un'altra sequenza intera. Ogni candidato è stato provato contro
/// questo criterio, e quelli che si riducevano a una proprietà di transizione sono
/// rimasti dove stavano, in `SondaInvariantiCampagna`.
///
/// Ne discendono i quattro della campagna: la monotonia del calendario sull'intera
/// sessione (un salto di giorni è invisibile al passo, che vede solo prima e dopo);
/// la conservazione dei gruppi fra il primo e l'ultimo stato; la corrispondenza fra
/// il registro accumulato e la sequenza dei comandi applicati; la riproducibilità,
/// cioè che la sequenza rigiocata dalla fabbrica dia la stessa impronta finale.
///
/// E i tre della battaglia: la monotonia del giro; l'irripetibilità delle lettere
/// dei reparti su tutta la battaglia (01 §9.4.3 le vuole «mai riusate», che è una
/// proprietà della storia e non dello stato); la riproducibilità della sequenza.
///
/// **Restano fuori, e per una ragione dichiarata**, il confine dell'annullamento
/// dopo un numero qualunque di annullamenti e riprese, e la rigiocatura del
/// giornale con le istantanee cancellate: entrambe sono proprietà della Sessione e
/// del suo giornale su disco, mentre questo banco vive nel Motore ed è sincrono per
/// costruzione (05 §12.1, RDA-58). Sono coperte da `AnnullamentoGiornataTest` e da
/// `SessioneCampagnaTest`, che girano dove quelle cose esistono.

// MARK: - Campagna

/// Gli invarianti che soltanto una sessione intera può violare.
public struct SondaSessioneCampagna: Sendable {

    public enum Violazione: Hashable, Sendable, CustomStringConvertible {
        /// Il calendario è SCESO fra due letture consecutive dell'intera sessione.
        /// I salti in avanti sono legittimi: con la marcia lunga, se tutti i gruppi
        /// sono in marcia le giornate scorrono a cascata in una sola applicazione
        /// (01 §5.6.11), e il giorno avanza di più di uno. Ciò che non deve mai
        /// accadere è che torni indietro.
        case calendarioNonMonotono(prima: Int, dopo: Int)
        /// Un gruppo è comparso o scomparso fra il primo e l'ultimo stato.
        case gruppiNonConservati(iniziali: Int, finali: Int)
        /// Le voci del registro non corrispondono al numero degli ordini impartiti
        /// più i compimenti di marcia (l'unico fatto non deciso dal giocatore in
        /// questa unità, 01 §5.17.1).
        case registroNonCorrispondeAgliOrdini(voci: Int, ordini: Int)
        /// La sequenza dei comandi, riapplicata dalla fabbrica, non riproduce lo
        /// stato finale della sessione.
        case rigiocaturaDivergente(attesa: String, trovata: String)

        public var description: String {
            switch self {
            case .calendarioNonMonotono(let a, let b):
                return "calendario_non_monotono:prima=\(a):dopo=\(b)"
            case .gruppiNonConservati(let a, let b):
                return "gruppi_non_conservati:iniziali=\(a):finali=\(b)"
            case .registroNonCorrispondeAgliOrdini(let v, let o):
                return "registro_non_corrisponde:voci=\(v):ordini=\(o)"
            case .rigiocaturaDivergente(let a, let b):
                return "rigiocatura_divergente:attesa=\(a.prefix(12)):trovata=\(b.prefix(12))"
            }
        }
    }

    /// I codici di tutti gli invarianti di sessione, in ordine fisso: il collaudo
    /// pretende che ciascuno abbia il proprio mutante, come per quelli di passo.
    public static let codiciNoti: [String] = [
        "calendario_non_monotono",
        "gruppi_non_conservati",
        "registro_non_corrisponde",
        "rigiocatura_divergente",
    ]

    public static func codice(di violazione: Violazione) -> String {
        String(violazione.description.split(separator: ":")[0])
    }

    public init() {}

    /// La storia di una sessione, nella forma minima che gli invarianti richiedono.
    /// La sonda riceve dall'esterno tutto ciò che giudica, come quella di passo
    /// (RDA-69): una prova può quindi darle una storia guasta e accertare che se ne
    /// accorga.
    public struct Storia: Sendable {
        public let giorniLetti: [Int]
        public let gruppiIniziali: Set<Int>
        public let gruppiFinali: Set<Int>
        public let vociDiRegistro: Int
        public let ordiniImpartiti: Int
        /// I compimenti di marcia osservati: fatti non decisi dal giocatore che
        /// aggiungono una voce al registro accanto agli ordini (01 §5.17.1).
        public let compimentiDiMarcia: Int
        public let improntaFinale: String
        public let improntaRigiocata: String

        public init(giorniLetti: [Int], gruppiIniziali: Set<Int>, gruppiFinali: Set<Int>,
                    vociDiRegistro: Int, ordiniImpartiti: Int, compimentiDiMarcia: Int = 0,
                    improntaFinale: String, improntaRigiocata: String) {
            self.giorniLetti = giorniLetti
            self.gruppiIniziali = gruppiIniziali
            self.gruppiFinali = gruppiFinali
            self.vociDiRegistro = vociDiRegistro
            self.ordiniImpartiti = ordiniImpartiti
            self.compimentiDiMarcia = compimentiDiMarcia
            self.improntaFinale = improntaFinale
            self.improntaRigiocata = improntaRigiocata
        }
    }

    public func controlla(_ storia: Storia) -> [Violazione] {
        var trovate: [Violazione] = []
        for (prima, dopo) in zip(storia.giorniLetti, storia.giorniLetti.dropFirst())
        where dopo < prima {
            trovate.append(.calendarioNonMonotono(prima: prima, dopo: dopo))
        }
        if storia.gruppiIniziali != storia.gruppiFinali {
            trovate.append(.gruppiNonConservati(iniziali: storia.gruppiIniziali.count,
                                                finali: storia.gruppiFinali.count))
        }
        // Ogni ordine lascia una voce; ogni compimento di marcia ne aggiunge un'altra
        // (S8, RDA-72; 01 §5.17.1). Il registro accumulato è la somma dei due.
        if storia.vociDiRegistro != storia.ordiniImpartiti + storia.compimentiDiMarcia {
            trovate.append(.registroNonCorrispondeAgliOrdini(voci: storia.vociDiRegistro,
                                                            ordini: storia.ordiniImpartiti))
        }
        if storia.improntaFinale != storia.improntaRigiocata {
            trovate.append(.rigiocaturaDivergente(attesa: storia.improntaFinale,
                                                  trovata: storia.improntaRigiocata))
        }
        return trovate
    }
}

/// Il banco delle sessioni complete di campagna.
public struct BancoSessioniCampagna: Sendable {
    public let motore: MotoreCampagna
    public let valoriCampagna: ValoriCampagna
    private let sondaDiPasso = SondaInvariantiCampagna()
    private let sondaDiSessione = SondaSessioneCampagna()

    public init(motore: MotoreCampagna, valoriCampagna: ValoriCampagna) {
        self.motore = motore
        self.valoriCampagna = valoriCampagna
    }

    /// Come i gruppi stanno sulla mappa all'inizio della sessione.
    public enum Disposizione: String, CaseIterable, Sendable {
        case raccolti, sparpagliati
    }

    /// La condotta con cui la sessione si gioca. Due condotte deterministiche e
    /// opposte nella scelta della destinazione: una sola condotta esplorerebbe una
    /// sola forma di campagna, e gli invarianti di accumulo non vedrebbero che
    /// quella. Nessuna estrazione del caso (RDA-59).
    public enum Condotta: String, CaseIterable, Sendable {
        case avanti, indietro
    }

    public struct Sessione: Sendable {
        public let mappa: IdentificatoreDati
        public let gruppi: Int
        public let disposizione: Disposizione
        public let condotta: Condotta
        public let giornate: Int
        public let ordini: Int
        public let violazioniDiPasso: [String]
        public let violazioniDiSessione: [String]
        public let improntaFinale: String
    }

    /// Il criterio di arresto, dichiarato: la sessione finisce quando il calendario
    /// ha superato il numero di giornate stabilito, oppure quando nessun gruppo
    /// attende più una decisione — condizione che oggi non si dà, perché ogni gruppo
    /// riceve sempre un ordine, ma che va prevista perché il criterio sia completo.
    public func gioca(mappa: IdentificatoreDati, gruppi: [ScenarioCampagna.GruppoIniziale],
                      disposizione: Disposizione, condotta: Condotta,
                      giornate: Int) throws -> Sessione {
        let scenario = ScenarioCampagna(mappa: mappa, gruppiGiocatore: gruppi)
        let iniziale = try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                                 archetipiNoti: Set(motore.valori.archetipi.keys))
        var stato = iniziale
        var violazioniDiPasso = Set<String>()
        var comandi: [ComandoCampagna] = []
        var giorniLetti = [stato.giorno]

        violazioniDiPasso.formUnion(sondaDiPasso.controlla(stato: stato).map(\.description))

        let giornoIniziale = stato.giorno
        var rete = 0
        var compimenti = 0
        let tettoDeiPassi = giornate * (gruppi.count + 2) + 10
        while stato.giorno < giornoIniziale + giornate {
            rete += 1
            guard rete <= tettoDeiPassi else { break }
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            violazioniDiPasso.formUnion(
                sondaDiPasso.controllaSalto(stato: stato,
                                            sequenza: sequenzaDelSalto(vista, stato))
                    .map(\.description))
            // Le posizioni visive derivate: si sorveglia che non divergano dai giorni.
            let mostrate = Dictionary(uniqueKeysWithValues: stato.gruppiInMarcia().map {
                ($0.id, motore.avanzamentoVisivo(giorniCompiuti: $0.marcia!.giorniCompiuti,
                                                 giorniTotali: $0.marcia!.giorniTotali))
            })
            violazioniDiPasso.formUnion(sondaDiPasso.controllaPosizioniVisive(
                stato: stato, posizioni: valoriCampagna.marcia.posizioniVisive,
                mostrate: mostrate).map(\.description))
            guard let comando = Self.prossimoOrdine(stato: stato, vista: vista,
                                                    condotta: condotta) else { break }
            let prima = stato
            let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
            violazioniDiPasso.formUnion(
                sondaDiPasso.controlla(prima: prima, comando: comando, dopo: dopo, eventi: eventi,
                                       adiacenti: prima.griglia.adiacenti).map(\.description))
            violazioniDiPasso.formUnion(sondaDiPasso.controlla(stato: dopo).map(\.description))
            compimenti += eventi.reduce(0) {
                if case .marciaCompiuta = $1 { return $0 + 1 } else { return $0 }
            }
            comandi.append(comando)
            stato = dopo
            giorniLetti.append(stato.giorno)
        }

        // La rigiocatura: la stessa sequenza, dalla fabbrica, senza null'altro.
        let rigiocato = rigioca(comandi, scenario: scenario)

        let storia = SondaSessioneCampagna.Storia(
            giorniLetti: giorniLetti,
            gruppiIniziali: Set(iniziale.gruppi.keys.map(\.numero)),
            gruppiFinali: Set(stato.gruppi.keys.map(\.numero)),
            vociDiRegistro: stato.registro.count,
            ordiniImpartiti: comandi.count,
            compimentiDiMarcia: compimenti,
            improntaFinale: stato.impronta(),
            improntaRigiocata: rigiocato)

        return Sessione(mappa: mappa, gruppi: gruppi.count, disposizione: disposizione,
                        condotta: condotta, giornate: stato.giorno - giornoIniziale, ordini: comandi.count,
                        violazioniDiPasso: violazioniDiPasso.sorted(),
                        violazioniDiSessione: sondaDiSessione.controlla(storia).map(\.description),
                        improntaFinale: stato.impronta())
    }

    /// LA CONDOTTA, in un punto solo. Deterministica e senza alcuna estrazione
    /// (RDA-59): il gruppo è quello che il salto diretto propone — cioè la sequenza
    /// che compirebbe chi si affida al salto — e l'ordine è il presidio quando il
    /// giorno è multiplo di tre o quando non esiste destinazione alcuna, la marcia
    /// altrimenti, sulla destinazione scelta dal numero del gruppo e dal giorno.
    ///
    /// Sta qui e non nei due chiamanti perché il banco la gioca nel Motore e il
    /// collaudo ospitato la gioca al dito: due condotte separate divergerebbero, ed
    /// è già accaduto — la prima stesura sceglieva il gruppo con `gruppiOrdinati` da
    /// un lato e con il salto dall'altro, e le impronte non coincidevano appena i
    /// gruppi erano più d'uno.
    public static func prossimoOrdine(stato: StatoCampagna, vista: VistaCampagna,
                                      condotta: Condotta) -> ComandoCampagna? {
        guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { return nil }
        let destinazioni = vista.destinazioniValide(per: gruppo.id)
        if destinazioni.isEmpty || stato.giorno % 3 == 0 {
            return .presidio(gruppo: gruppo.id)
        }
        let indice = (gruppo.id.numero &+ stato.giorno) % destinazioni.count
        let scelta = condotta == .avanti ? indice : destinazioni.count - 1 - indice
        return vista.comandoDiMarcia(per: gruppo.id, a: destinazioni[scelta])
    }

    /// Riapplica una sequenza di comandi a uno stato nato dalla fabbrica e
    /// restituisce l'impronta finale. È la rigiocatura di 05 §13.2 al livello del
    /// Motore: il giornale su disco e le istantanee sono materia della Sessione.
    public func rigioca(_ comandi: [ComandoCampagna], scenario: ScenarioCampagna) -> String {
        guard var stato = try? FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                                     archetipiNoti: Set(motore.valori.archetipi.keys))
        else { return "" }
        for comando in comandi {
            guard motore.valida(comando, parte: .giocatore, stato: stato).eValido else { return "" }
            stato = motore.applica(comando, parte: .giocatore, stato: stato).0
        }
        return stato.impronta()
    }

    private func sequenzaDelSalto(_ vista: VistaCampagna, _ stato: StatoCampagna) -> [IdGruppo] {
        var sequenza: [IdGruppo] = []
        var corrente: Cella? = nil
        for _ in 0..<stato.gruppiInAttesa().count {
            guard let prossimo = vista.prossimoGruppoInAttesa(dopo: corrente) else { break }
            sequenza.append(prossimo.id)
            corrente = prossimo.posizione
        }
        return sequenza
    }

    /// Tutte le sessioni da giocare: ogni formato di mappa, ogni conteggio di gruppi
    /// da uno al massimo che la mappa consente, le due disposizioni. Non sono
    /// configurazioni comode: il massimo è il caso limite dello stipamento.
    /// La CONFIGURAZIONE di una sessione: che cosa la individua, senza giocarla.
    /// Esiste perché l'elenco delle sessioni abbia una definizione sola: il banco
    /// le gioca nel Motore, e il collaudo ospitato gioca le stesse attraverso
    /// l'interfaccia. Due elenchi separati sarebbero divergiti al primo cambiamento.
    public struct Configurazione: Sendable, Hashable {
        public let mappa: IdentificatoreDati
        public let gruppi: [ScenarioCampagna.GruppoIniziale]
        public let disposizione: Disposizione
        public let condotta: Condotta
        public var scenario: ScenarioCampagna {
            ScenarioCampagna(mappa: mappa, gruppiGiocatore: gruppi)
        }
    }

    /// Tutte le configurazioni da giocare: ogni formato di mappa, ogni conteggio di
    /// gruppi da uno al massimo che la mappa consente, le due disposizioni, le due
    /// condotte. Non sono configurazioni comode: il massimo è il caso limite dello
    /// stipamento.
    public func configurazioni(mappe: [IdentificatoreDati: DefinizioneMappa],
                               formati: [IdentificatoreDati: FormatoMappa],
                               gruppiMassimi: Int) -> [Configurazione] {
        var esito: [Configurazione] = []
        for identificatore in mappe.keys.sorted() {
            guard let definizione = mappe[identificatore],
                  let formato = formati[definizione.formato] else { continue }
            let tetto = min(gruppiMassimi, formato.righe * formato.colonne - 1)
            for quanti in 1...tetto {
                for disposizione in Disposizione.allCases {
                    let posti = posizioni(quanti: quanti, formato: formato,
                                          disposizione: disposizione)
                    for condotta in Condotta.allCases {
                        esito.append(Configurazione(mappa: identificatore, gruppi: posti,
                                                    disposizione: disposizione,
                                                    condotta: condotta))
                    }
                }
            }
        }
        return esito
    }

    public func tutteLeSessioni(mappe: [IdentificatoreDati: DefinizioneMappa],
                                formati: [IdentificatoreDati: FormatoMappa],
                                gruppiMassimi: Int, giornate: Int) throws -> [Sessione] {
        try configurazioni(mappe: mappe, formati: formati, gruppiMassimi: gruppiMassimi)
            .map { try gioca(mappa: $0.mappa, gruppi: $0.gruppi, disposizione: $0.disposizione,
                             condotta: $0.condotta, giornate: giornate) }
    }

    /// Le posizioni iniziali: raccolte presso l'angolo del proprio quartier generale
    /// oppure sparpagliate a passo fisso sulla mappa. Deterministiche entrambe.
    func posizioni(quanti: Int, formato: FormatoMappa,
                           disposizione: Disposizione) -> [ScenarioCampagna.GruppoIniziale] {
        let caselle = (1...formato.righe).flatMap { riga in
            (1...formato.colonne).map { (riga, $0) }
        }
        switch disposizione {
        case .raccolti:
            // Dalla riga più arretrata in avanti: è la prima giornata di una campagna.
            let ordinate = caselle.sorted { ($0.0, $0.1) > ($1.0, $1.1) }
            return ordinate.prefix(quanti).enumerated().map {
                .init(riga: $0.element.0, colonna: $0.element.1,
                      composizione: Self.composizionePerIndice($0.offset)) }
        case .sparpagliati:
            let passo = max(1, caselle.count / max(1, quanti))
            return (0..<quanti).map { indice in
                let posto = caselle[(indice * passo) % caselle.count]
                return .init(riga: posto.0, colonna: posto.1,
                             composizione: Self.composizionePerIndice(indice))
            }
        }
    }

    /// La composizione di un gruppo generato, variata per indice così che le sessioni
    /// complete esercitino marce di volumi diversi (01 §5.6.3): le tre fasce danno
    /// zero, uno e due giorni aggiuntivi alla soglia dei dati.
    static func composizionePerIndice(_ i: Int) -> [ScenarioCampagna.RepartoIniziale] {
        switch i % 3 {
        case 0:  return [.init(archetipo: "fanteria_leggera", atomi: 6)]
        case 1:  return [.init(archetipo: "fanteria_leggera", atomi: 18),
                         .init(archetipo: "fanteria_pesante", atomi: 8)]
        default: return [.init(archetipo: "fanteria_pesante", atomi: 24),
                         .init(archetipo: "cavalleria_manovrata", atomi: 12)]
        }
    }
}

// MARK: - Battaglia

/// Gli invarianti che soltanto uno scontro intero può violare.
public struct SondaSessioneBattaglia: Sendable {

    public enum Violazione: Hashable, Sendable, CustomStringConvertible {
        case giroNonMonotono(prima: Int, dopo: Int)
        /// Una lettera di reparto è stata assegnata due volte nella stessa parte:
        /// 01 §9.4.3 le vuole «mai riusate», che è proprietà della storia e non
        /// dello stato — nello stato una lettera libera e una mai usata sono
        /// indistinguibili.
        case letteraRiusata(parte: String, lettera: Int)
        case rigiocaturaDivergente(attesa: String, trovata: String)

        public var description: String {
            switch self {
            case .giroNonMonotono(let a, let b): return "giro_non_monotono:prima=\(a):dopo=\(b)"
            case .letteraRiusata(let p, let l): return "lettera_riusata:parte=\(p):lettera=\(l)"
            case .rigiocaturaDivergente(let a, let b):
                return "rigiocatura_divergente_battaglia:attesa=\(a.prefix(12)):trovata=\(b.prefix(12))"
            }
        }
    }

    public static let codiciNoti: [String] = [
        "giro_non_monotono",
        "lettera_riusata",
        "rigiocatura_divergente_battaglia",
    ]

    public static func codice(di violazione: Violazione) -> String {
        String(violazione.description.split(separator: ":")[0])
    }

    public init() {}

    public struct Storia: Sendable {
        public let giriLetti: [Int]
        /// Le lettere assegnate, nell'ordine, per ciascuna parte.
        public let lettereAssegnate: [Parte: [Int]]
        public let improntaFinale: String
        public let improntaRigiocata: String

        public init(giriLetti: [Int], lettereAssegnate: [Parte: [Int]],
                    improntaFinale: String, improntaRigiocata: String) {
            self.giriLetti = giriLetti
            self.lettereAssegnate = lettereAssegnate
            self.improntaFinale = improntaFinale
            self.improntaRigiocata = improntaRigiocata
        }
    }

    public func controlla(_ storia: Storia) -> [Violazione] {
        var trovate: [Violazione] = []
        for (prima, dopo) in zip(storia.giriLetti, storia.giriLetti.dropFirst()) where dopo < prima {
            trovate.append(.giroNonMonotono(prima: prima, dopo: dopo))
        }
        for parte in [Parte.giocatore, .avversario] {
            var viste = Set<Int>()
            for lettera in storia.lettereAssegnate[parte] ?? [] {
                if !viste.insert(lettera).inserted {
                    trovate.append(.letteraRiusata(parte: String(describing: parte),
                                                   lettera: lettera))
                }
            }
        }
        if storia.improntaFinale != storia.improntaRigiocata {
            trovate.append(.rigiocaturaDivergente(attesa: storia.improntaFinale,
                                                  trovata: storia.improntaRigiocata))
        }
        return trovate
    }
}

/// Il banco delle sessioni complete di battaglia: dallo schieramento alla
/// conclusione, su composizioni di mazzo che i copioni esistenti non producono.
public struct BancoSessioniBattaglia: Sendable {
    public let motore: MotoreBattaglia
    private let sonda = SondaSessioneBattaglia()

    public init(motore: MotoreBattaglia) { self.motore = motore }

    public struct Sessione: Sendable {
        public let composizione: String
        public let primoOccupante: Parte
        public let ufficiale: IdentificatoreDati
        public let imboscata: Bool
        public let concluso: Bool
        public let giri: Int
        public let comandi: Int
        public let riserveRimaste: Int
        public let violazioni: [String]
    }

    /// Le composizioni di mazzo. Le due che i copioni d'oro producono sono a mazzi
    /// pari e a mazzi con riserve; qui si aggiungono quelle che non producono: un
    /// solo archetipo per parte, un mazzo minimo contro uno pieno, e un mazzo che
    /// eccede di proposito il volume schierabile, sicché resti sempre qualcosa in
    /// riserva a fine battaglia (01 §9.3.5: il deck è riserva vera).
    public struct Composizione: Sendable {
        public let nome: String
        public let giocatore: [ScenarioBattaglia.ElementoScenario]
        public let avversario: [ScenarioBattaglia.ElementoScenario]
    }

    public func gioca(_ composizione: Composizione, formato: IdentificatoreDati,
                      caratteristica: IdentificatoreDati, primoOccupante: Parte,
                      ufficiale: IdentificatoreDati, imboscata: Bool,
                      giriMassimi: Int) throws -> Sessione {
        let scenario = ScenarioBattaglia(
            formato: formato, caratteristica: caratteristica,
            primoOccupante: primoOccupante, imboscata: imboscata,
            deckGiocatore: composizione.giocatore, deckAvversario: composizione.avversario,
            ufficialeAvversario: ufficiale)
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0
        guard let ufficialeVero = motore.valori.ufficiali[ufficiale] else {
            throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: "ufficiali.json")
        }
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficialeVero, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficialeVero, parte: .avversario),
        ]

        var giriLetti = [stato.giro]
        var lettere: [Parte: [Int]] = [.giocatore: [], .avversario: []]
        var comandiApplicati: [(Parte, ComandoBattaglia)] = []
        var conosciute: [Parte: Set<IdSciame>] = [.giocatore: [], .avversario: []]
        var comandi = 0
        let tettoComandi = giriMassimi * 200

        while stato.esito == nil && stato.giro <= giriMassimi && comandi < tettoComandi {
            let parte = stato.parteDiTurno
            let comando = tattici[parte]!.prossimoComando(stato: stato)
            stato = motore.applica(comando, parte: parte, stato: stato).0
            comandiApplicati.append((parte, comando))
            comandi += 1
            giriLetti.append(stato.giro)
            // Le lettere si raccolgono man mano che i reparti compaiono: è la
            // storia delle assegnazioni, che lo stato finale non conserva.
            for sciame in stato.sciamiOrdinati where !conosciute[sciame.parte]!.contains(sciame.id) {
                conosciute[sciame.parte]!.insert(sciame.id)
                lettere[sciame.parte]!.append(sciame.lettera)
            }
        }

        let rigiocata = rigioca(comandiApplicati, scenario: scenario)
        let storia = SondaSessioneBattaglia.Storia(
            giriLetti: giriLetti, lettereAssegnate: lettere,
            improntaFinale: stato.impronta(), improntaRigiocata: rigiocata)

        return Sessione(composizione: composizione.nome, primoOccupante: primoOccupante,
                        ufficiale: ufficiale, imboscata: imboscata, concluso: stato.esito != nil, giri: stato.giro, comandi: comandi,
                        riserveRimaste: (stato.deck[.giocatore] ?? []).reduce(0) { $0 + $1.esemplari },
                        violazioni: sonda.controlla(storia).map(\.description))
    }

    public func rigioca(_ comandi: [(Parte, ComandoBattaglia)],
                        scenario: ScenarioBattaglia) -> String {
        guard var stato = try? FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0
        else { return "" }
        for (parte, comando) in comandi {
            guard motore.valida(comando, parte: parte, stato: stato).eValido else { return "" }
            stato = motore.applica(comando, parte: parte, stato: stato).0
        }
        return stato.impronta()
    }
}
