import Foundation
import Dati
import Motore

/// La misura della FREQUENZA DELLE BATTAGLIE (incarico 29): partite intere sugli scenari dei tre
/// formati del gioco (`scenari-campagna.json`, gli stessi che aprono i pulsanti dell'avvio), giocate
/// fino alla loro fine naturale — una parte resta senza gruppi armati e non può più combattere,
/// com'è definita dalla prova delle partite intere dell'incarico 26 — o fino a un limite dichiarato di
/// giornate. Per ciascuna partita: quante battaglie nascono e in quali giornate, quando nasce la prima,
/// quanto dura la partita e come finisce.
///
/// Non tara nulla e non contiene regole proprie: ogni esito viene dal Motore, l'avversario muove con la
/// sua condotta deterministica (`CondottaAvversaria`, la stessa della Sessione) e le battaglie si
/// combattono come al banco (`BancoCampagna.giocaBattaglieInSospeso`: modello di scontro provvisorio,
/// due tattici deterministici). Ciò che lo strumento aggiunge è la CONDOTTA DEL GIOCATORE, in due modi:
///
/// - `competente`: la condotta del banco (`BancoCampagna.corri`), riprodotta regola per regola. Per
///   ottenere partite diverse — senza, ogni formato darebbe una partita sola, perché nella campagna non
///   c'è caso — le regole periodiche si leggono su `giorno + sfasamento` e la destinazione di marcia è
///   la `(numero del gruppo + sfasamento)`-esima fra le valide; con sfasamento 0 la condotta è quella del
///   banco, e `MisuraFrequenzaBattaglieTest` lo verifica sull'impronta finale.
/// - `prudente`: il modello del tester della sessione dell'incarico 28 (`scripts/tester.py`, nella forma
///   con cui ha giocato): i gruppi in attesa nell'ordine di lettura; un gruppo armato marcia di una
///   casella verso nord, se è libera da propri gruppi e la marcia è valida, in media una volta su due
///   (il tester ne muoveva uno su due: qui con probabilità un mezzo, estratta col seme della partita);
///   altrimenti esplora se può, presidia se può, sosta con raccolta. In battaglia combatte il tattico del
///   banco: la resa del tester dopo il quattordicesimo turno non è riprodotta.
///
/// Il seme varia SOLTANTO le scelte del giocatore: non tocca il Motore, che resta deterministico.
public struct MisuraFrequenzaBattaglie: Sendable {

    public enum Condotta: String, CaseIterable, Sendable, Codable {
        case competente, prudente
    }

    public enum Fine: String, Sendable, Codable {
        /// L'avversario non ha più gruppi armati: la partita è vinta.
        case avversarioSenzaArmati = "avversario_senza_armati"
        /// Il giocatore non ha più gruppi armati: la partita è persa.
        case giocatoreSenzaArmati = "giocatore_senza_armati"
        /// Il limite di giornate è raggiunto senza una fine naturale.
        case limite
        /// La partita non avanza più (nessuna giornata nuova entro il tetto di passi): un difetto.
        case ferma
    }

    /// Una partita misurata: la riga dei dati grezzi.
    public struct Partita: Sendable, Codable {
        public let formato: String
        public let condotta: Condotta
        public let seme: UInt64
        public let giornate: Int
        public let battaglie: Int
        public let giornateDelleBattaglie: [Int]
        public let primaBattaglia: Int?
        public let vinte: Int
        public let perse: Int
        public let daImboscata: Int
        public let fine: Fine
        public let armatiGiocatore: Int
        public let armatiAvversario: Int
        /// Perché la partita si è fermata, se si è fermata (fine `ferma`): il dato per capirlo.
        public let motivoFerma: String?
        enum CodingKeys: String, CodingKey {
            case formato, condotta, seme, giornate, battaglie, vinte, perse, fine
            case giornateDelleBattaglie = "giornate_delle_battaglie"
            case primaBattaglia = "prima_battaglia"
            case daImboscata = "da_imboscata"
            case armatiGiocatore = "armati_giocatore"
            case armatiAvversario = "armati_avversario"
            case motivoFerma = "motivo_ferma"
        }
    }

    let banco: BancoCampagna
    var motore: MotoreCampagna { banco.motore }

    public init(motore: MotoreCampagna, valoriCampagna: ValoriCampagna) {
        banco = BancoCampagna(motore: motore, valoriCampagna: valoriCampagna,
                              scenari: ScenariCampagna.vuoti)
    }

    /// Un generatore deterministico col seme (SplitMix64), proprio dello strumento: il Motore non ne usa.
    struct Generatore {
        var stato: UInt64
        mutating func prossimo() -> UInt64 {
            stato &+= 0x9E37_79B9_7F4A_7C15
            var z = stato
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        mutating func mezzo() -> Bool { prossimo() & 1 == 1 }
    }

    private func armati(_ parte: Parte, _ stato: StatoCampagna) -> Int {
        stato.gruppi(di: parte).filter { $0.categoria.eArmata }.count
    }

    /// Gioca una partita intera. `fermaAllaFineNaturale` falso serve soltanto alla prova di fedeltà col
    /// banco, che corre un numero fisso di giornate.
    public func gioca(scenario: ScenarioCampagna, formato: String, condotta: Condotta, seme: UInt64,
                      limiteGiornate: Int, fermaAllaFineNaturale: Bool = true) throws -> Partita {
        try giocaConStato(scenario: scenario, formato: formato, condotta: condotta, seme: seme,
                          limiteGiornate: limiteGiornate, fermaAllaFineNaturale: fermaAllaFineNaturale).0
    }

    /// La partita e lo stato in cui finisce: lo stato serve alla prova di fedeltà col banco.
    func giocaConStato(scenario: ScenarioCampagna, formato: String, condotta: Condotta, seme: UInt64,
                       limiteGiornate: Int, fermaAllaFineNaturale: Bool = true) throws -> (Partita, StatoCampagna) {
        var stato = try FabbricaCampagna.crea(scenario: scenario, valori: banco.valoriCampagna,
                                              archetipiNoti: banco.archetipiNoti)
        var generatore = Generatore(stato: seme)
        // Lo sfasamento della condotta competente: 420 è il minimo comune multiplo dei periodi 3–7.
        let sfasamento = condotta == .competente ? Int(seme % 420) : 0
        var giornoUltimaRiunione = Int.min
        var giornateBattaglie: [Int] = []
        var vinte = 0, perse = 0, daImboscata = 0
        let giornoIniziale = stato.giorno
        var passi = 0
        var giornoDelControllo = stato.giorno, passiNelGiorno = 0
        var fine: Fine = .limite
        var motivoFerma: String?
        let tettoPassiPerGiornata = 400

        /// Le battaglie in sospeso, giocate col modello del banco (`giocaBattagliaComeAlBanco`). Una
        /// battaglia che non si conclude entro i tetti del banco ferma la partita e si registra.
        func giocaLeBattaglie() -> String? {
            while let battaglia = stato.battaglieInSospeso.first {
                guard let esito = giocaBattagliaComeAlBanco(battaglia, stato: stato) else {
                    return "battaglia non conclusa entro \(Self.tettoGiri) giri, giorno \(battaglia.giorno), casella \(battaglia.casella.riga),\(battaglia.casella.colonna)\(battaglia.daImboscata ? ", da imboscata" : "")"
                }
                _ = motore.applicaEsitoInCampagna(esito, in: &stato)
                giornateBattaglie.append(battaglia.giorno)
                if battaglia.daImboscata { daImboscata += 1 }
                if esito.sconfitto == .giocatore { perse += 1 } else { vinte += 1 }
            }
            return nil
        }

        partita: while true {
            passi += 1
            if stato.giorno != giornoDelControllo { giornoDelControllo = stato.giorno; passiNelGiorno = 0 }
            passiNelGiorno += 1
            if passiNelGiorno > tettoPassiPerGiornata {
                fine = .ferma; motivoFerma = "oltre \(tettoPassiPerGiornata) passi nel giorno \(stato.giorno)"; break
            }
            if !stato.battaglieInSospeso.isEmpty {
                if let motivo = giocaLeBattaglie() { fine = .ferma; motivoFerma = motivo; break }
                continue
            }
            if fermaAllaFineNaturale {
                if armati(.giocatore, stato) == 0 { fine = .giocatoreSenzaArmati; break }
                if armati(.avversario, stato) == 0 { fine = .avversarioSenzaArmati; break }
            }
            if stato.giorno - giornoIniziale >= limiteGiornate { fine = .limite; break }

            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            let comando: ComandoCampagna?
            switch condotta {
            case .competente:
                comando = condottaCompetente(stato: stato, vista: vista, sfasamento: sfasamento,
                                             giornoUltimaRiunione: &giornoUltimaRiunione)
            case .prudente:
                comando = condottaPrudente(stato: stato, vista: vista, generatore: &generatore)
            }
            if let comando {
                if motore.valida(comando, parte: .giocatore, stato: stato).eValido {
                    stato = motore.applica(comando, parte: .giocatore, stato: stato).0
                } else {
                    // Un ordine che il Motore respinge non si dà: il gruppo resta. Non accade con le due
                    // condotte (scelgono fra comandi validati), ma la misura non si ferma sull'errore.
                    fine = .ferma
                    motivoFerma = "comando respinto al giorno \(stato.giorno): \(comando) — \(motore.valida(comando, parte: .giocatore, stato: stato))"
                    break partita
                }
            } else if stato.gruppiInAttesa(di: .giocatore).isEmpty == false {
                fine = .ferma; motivoFerma = "nessun ordine con gruppi in attesa al giorno \(stato.giorno)"; break partita
            }
            // Il turno dell'avversario, come al banco (01 §5.6.11): quando il giocatore ha concluso.
            var passiAvversario = 0
            while stato.gruppiInAttesa(di: .giocatore).isEmpty, stato.battaglieInSospeso.isEmpty,
                  !stato.gruppiInAttesa(di: .avversario).isEmpty {
                passiAvversario += 1
                if passiAvversario > 2000 {
                    fine = .ferma; motivoFerma = "avversario oltre 2000 passi al giorno \(stato.giorno)"; break partita
                }
                guard let comandoAvversario = banco.condotta.prossimoComando(
                    vista: motore.vistaAvversario(stato: stato)) else { break }
                stato = motore.applica(comandoAvversario, parte: .avversario, stato: stato).0
            }
            // Nessuno attende e la giornata non si è chiusa: la chiude il tasto del giocatore (01 §5.6.0.6).
            if stato.gruppiInAttesa(di: .giocatore).isEmpty, stato.gruppiInAttesa(di: .avversario).isEmpty,
               stato.battaglieInSospeso.isEmpty, comando == nil {
                _ = motore.concludiLaGiornataDelGiocatore(&stato)
            }
        }
        _ = passi
        return (Partita(formato: formato, condotta: condotta, seme: seme,
                       giornate: stato.giorno - giornoIniziale, battaglie: giornateBattaglie.count,
                       giornateDelleBattaglie: giornateBattaglie.map { $0 - giornoIniziale + 1 },
                       primaBattaglia: giornateBattaglie.first.map { $0 - giornoIniziale + 1 },
                       vinte: vinte, perse: perse, daImboscata: daImboscata, fine: fine,
                       armatiGiocatore: armati(.giocatore, stato), armatiAvversario: armati(.avversario, stato),
                       motivoFerma: motivoFerma),
                stato)
    }

    // MARK: - Le battaglie, come al banco

    /// I tetti con cui il banco combatte una battaglia nata in campagna (`BancoCampagna`).
    static let tettoGiri = 400
    static let tettoPassi = 40_000

    /// Combatte una battaglia in sospeso come `BancoCampagna.giocaBattaglieInSospeso`: lo scenario dal
    /// ponte col modello di scontro del banco, due tattici deterministici col primo ufficiale, gli stessi
    /// tetti. Restituisce l'esito da piegare in campagna, o nulla se la battaglia non si conclude: il banco
    /// in quel caso si fermerebbe sulla precondizione del ponte, la misura lo registra.
    func giocaBattagliaComeAlBanco(_ battaglia: BattagliaInSospeso, stato: StatoCampagna) -> EsitoInCampagna? {
        let motoreB = MotoreBattaglia(valori: motore.valori)
        guard let uffId = banco.modelloScontro.ufficialeAvversario,
              let ufficiale = motore.valori.ufficiali[uffId] else { return nil }
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: banco.modelloScontro)
        guard var sb = try? FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0 else { return nil }
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motoreB, ufficiale: ufficiale, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motoreB, ufficiale: ufficiale, parte: .avversario)]
        var passi = 0
        while sb.esito == nil, sb.giro <= Self.tettoGiri, passi < Self.tettoPassi {
            passi += 1
            let parte = sb.parteDiTurno
            sb = motoreB.applica(tattici[parte]!.prossimoComando(stato: sb), parte: parte, stato: sb).0
        }
        guard sb.esito != nil else { return nil }
        return PonteCampagnaBattaglia.esito(da: sb, per: battaglia, stato: stato, valori: motore.valori)
    }

    // MARK: - La condotta competente: quella del banco, con lo sfasamento

    /// Le regole di `BancoCampagna.corri`, nello stesso ordine (riunione, divisione, revoca, poi il
    /// prossimo gruppo del salto: ricognizione, sabotaggio, imboscata, rifornimento, marcia o presidio),
    /// con i periodi letti su `giorno + sfasamento`. Il tasto «Chiudi la giornata» del banco
    /// (`chiudeLaGiornataOgni`) non è usato. Di quella sequenza si dà il PRIMO ordine che il Motore
    /// accetta: il banco dà il primo e basta, e sui suoi scenari è sempre valido (altrimenti `applica`
    /// non lo accetterebbe); con uno sfasamento può non esserlo — un gruppo armato che deve rifornirsi e
    /// si trova su una formazione non armata avversaria riceverebbe il sabotaggio, che il Motore respinge
    /// —, e allora vale la regola successiva, come farebbe un giocatore.
    func condottaCompetente(stato: StatoCampagna, vista: VistaCampagna, sfasamento: Int,
                            giornoUltimaRiunione: inout Int) -> ComandoCampagna? {
        func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: stato).eValido }
        let giorno = stato.giorno + sfasamento
        if giorno % 4 == 1, stato.giorno != giornoUltimaRiunione, stato.gruppi.count > 2,
           let (a, b) = banco.coppiaRiunibile(stato), valido(.riunione(gruppo: a, con: b)) {
            giornoUltimaRiunione = stato.giorno
            return .riunione(gruppo: a, con: b)
        }
        if giorno % 7 == 3, let (g, staccati, dest) = banco.divisionePossibile(vista, stato),
           valido(.divisione(gruppo: g, repartiStaccati: staccati, a: dest)) {
            return .divisione(gruppo: g, repartiStaccati: staccati, a: dest)
        }
        if giorno % 5 == 2, let marciante = stato.gruppiInMarcia().first, valido(.revocaMarcia(gruppo: marciante.id)) {
            return .revocaMarcia(gruppo: marciante.id)
        }
        guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { return nil }
        var candidati: [ComandoCampagna] = []
        if gruppo.categoria.eRicognizione {
            if let bersaglio = motore.bersaglioNonArmato(su: gruppo.posizione, parte: .giocatore, stato: stato) {
                let giaStudiato = stato.studiati[.giocatore]?.contains(bersaglio.id) == true
                candidati.append(giaStudiato ? .sabotaggio(gruppo: gruppo.id) : .studioApprofondito(gruppo: gruppo.id))
            } else {
                candidati.append(.esplorazione(gruppo: gruppo.id))
            }
        } else {
            if gruppo.categoria.eArmata,
               motore.bersaglioNonArmato(su: gruppo.posizione, parte: .giocatore, stato: stato) != nil {
                candidati.append(.sabotaggio(gruppo: gruppo.id))
            }
            if gruppo.categoria.eArmata, gruppo.sostaDovuta < 2, !gruppo.deveRifornirsi,
               banco.armatoAvversarioAdiacente(a: gruppo, stato: stato) {
                candidati.append(.imboscata(gruppo: gruppo.id))
            }
            if gruppo.categoria.eArmata, giorno % 6 == 4, gruppo.sostaDovuta < 2, !gruppo.deveRifornirsi {
                candidati.append(.imboscata(gruppo: gruppo.id))
            }
            if gruppo.deveRifornirsi { candidati.append(.sostaConRaccolta(gruppo: gruppo.id)) }
            if gruppo.turniSenzaProvviste == 1, giorno % 3 == 0 { candidati.append(.sostaConRaccolta(gruppo: gruppo.id)) }
            if motore.rifornimentoTagliato(di: gruppo, stato: stato) { candidati.append(.presidio(gruppo: gruppo.id)) }
            let destinazioni = vista.destinazioniValide(per: gruppo.id)
            if destinazioni.isEmpty || giorno % 3 == 0 {
                candidati.append(.presidio(gruppo: gruppo.id))
            } else if let marcia = vista.comandoDiMarcia(
                per: gruppo.id, a: destinazioni[(gruppo.id.numero + sfasamento) % destinazioni.count]) {
                candidati.append(marcia)
            }
        }
        // L'ultimo riparo: un gruppo non-agito ha sempre almeno un ordine valido (invariante della
        // giocabilità, incarico 25).
        candidati += [.presidio(gruppo: gruppo.id), .sostaConRaccolta(gruppo: gruppo.id)]
        return candidati.first(where: valido)
    }

    // MARK: - La condotta prudente: il modello del tester

    /// Il prossimo gruppo in attesa nell'ordine di lettura, e il suo ordine secondo il tester.
    func condottaPrudente(stato: StatoCampagna, vista: VistaCampagna,
                          generatore: inout Generatore) -> ComandoCampagna? {
        guard let gruppo = stato.gruppiInAttesa(di: .giocatore).min(by: { $0.posizione < $1.posizione })
        else { return nil }
        func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: stato).eValido }
        let nord = Cella(riga: gruppo.posizione.riga - 1, colonna: gruppo.posizione.colonna)
        if gruppo.categoria.eArmata, stato.griglia.contiene(nord),
           stato.occupante(di: nord, parte: .giocatore) == nil,
           vista.destinazioniValide(per: gruppo.id).contains(nord), generatore.mezzo(),
           let marcia = vista.comandoDiMarcia(per: gruppo.id, a: nord), valido(marcia) {
            return marcia
        }
        if valido(.esplorazione(gruppo: gruppo.id)) { return .esplorazione(gruppo: gruppo.id) }
        if valido(.presidio(gruppo: gruppo.id)) { return .presidio(gruppo: gruppo.id) }
        return .sostaConRaccolta(gruppo: gruppo.id)
    }

    // MARK: - Il riepilogo

    /// Una cella della tabella: formato e condotta.
    public struct Riepilogo: Sendable {
        public let formato: String
        public let condotta: Condotta
        public let partite: Int
        public let battaglieOgniDieciGiornate: Double
        public let mediaBattagliePerPartita: Double
        public let primaBattagliaMediana: Int?
        public let partiteSenzaBattaglie: Int
        public let giornateMediana: Int
        public let giornateMinimo: Int
        public let giornateMassimo: Int
        public let fini: [Fine: Int]
        public let giornateMedianeFinoAllaFineNaturale: Int?
    }

    public static func riepiloga(_ partite: [Partita]) -> [Riepilogo] {
        func mediana(_ v: [Int]) -> Int? {
            guard !v.isEmpty else { return nil }
            let o = v.sorted(); return o[o.count / 2]
        }
        var celle: [String: [Partita]] = [:]
        for p in partite { celle[p.formato + "|" + p.condotta.rawValue, default: []].append(p) }
        return celle.keys.sorted().compactMap { chiave in
            guard let gruppo = celle[chiave], let prima = gruppo.first else { return nil }
            let giornate = gruppo.map(\.giornate)
            let totaleGiornate = giornate.reduce(0, +)
            let totaleBattaglie = gruppo.map(\.battaglie).reduce(0, +)
            var fini: [Fine: Int] = [:]
            for p in gruppo { fini[p.fine, default: 0] += 1 }
            let naturali = gruppo.filter { $0.fine == .avversarioSenzaArmati || $0.fine == .giocatoreSenzaArmati }
            return Riepilogo(formato: prima.formato, condotta: prima.condotta, partite: gruppo.count,
                             battaglieOgniDieciGiornate: totaleGiornate == 0 ? 0
                                : Double(totaleBattaglie) * 10 / Double(totaleGiornate),
                             mediaBattagliePerPartita: Double(totaleBattaglie) / Double(gruppo.count),
                             primaBattagliaMediana: mediana(gruppo.compactMap(\.primaBattaglia)),
                             partiteSenzaBattaglie: gruppo.filter { $0.battaglie == 0 }.count,
                             giornateMediana: mediana(giornate) ?? 0,
                             giornateMinimo: giornate.min() ?? 0, giornateMassimo: giornate.max() ?? 0,
                             fini: fini,
                             giornateMedianeFinoAllaFineNaturale: mediana(naturali.map(\.giornate)))
        }
    }
}

extension ScenariCampagna {
    /// Nessuno scenario del banco: la misura della frequenza gioca gli scenari del gioco.
    static let vuoti = try! JSONDecoder().decode(
        ScenariCampagna.self,
        from: Data(#"{"giornate_generate":0,"gruppi_per_la_misura_dei_passi":[],"scenari":[]}"#.utf8))
}

/// La misura della frequenza delle battaglie come la esegue lo strumento da riga di comando: carica i
/// valori e gli scenari del gioco dalla cartella dei valori, gioca `partite` partite intere per ciascun
/// formato e ciascuna condotta (semi da 0 a `partite` − 1), in parallelo sui nuclei della macchina, e
/// restituisce i dati grezzi e il riepilogo.
public enum FrequenzaBattaglieDaRigaDiComando {
    public struct Rapporto: Sendable {
        public let grezzi: String
        public let testo: String
        public let partite: [MisuraFrequenzaBattaglie.Partita]
    }

    public static let formati = ["campagna_piccola", "campagna_media", "campagna_grande"]

    public static func esegui(cartellaValori: URL, partite: Int, giornateMassime: Int) throws -> Rapporto {
        let valori = try CaricatoreValori.carica(da: cartellaValori)
        let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
        let dati = try Data(contentsOf: cartellaValori.appendingPathComponent("scenari-campagna.json"))
        let scenari = try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)
        let misura = MisuraFrequenzaBattaglie(motore: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                                              valoriCampagna: valoriCampagna)
        struct Compito: Sendable { let formato: String; let condotta: MisuraFrequenzaBattaglie.Condotta; let seme: UInt64 }
        var tutti: [Compito] = []
        for formato in formati {
            for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
                for seme in 0..<partite { tutti.append(Compito(formato: formato, condotta: condotta, seme: UInt64(seme))) }
            }
        }
        let compiti = tutti
        let esiti = Esiti(conteggio: compiti.count)
        DispatchQueue.concurrentPerform(iterations: compiti.count) { indice in
            let c = compiti[indice]
            guard let scenario = scenari[c.formato] else { return }
            let partita = try? misura.gioca(scenario: scenario, formato: c.formato, condotta: c.condotta,
                                            seme: c.seme, limiteGiornate: giornateMassime)
            esiti.metti(partita, a: indice)
        }
        let giocate = esiti.tutti()
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let grezzi = giocate.compactMap { try? String(data: codificatore.encode($0), encoding: .utf8) }
            .joined(separator: "\n") + "\n"
        var righe: [String] = []
        righe.append("frequenza.versione_valori=\(valori.versioneEffettiva)")
        righe.append("frequenza.partite_per_cella=\(partite) giornate_massime=\(giornateMassime) partite_giocate=\(giocate.count) su \(compiti.count)")
        righe.append("formato|condotta|partite|battaglie_ogni_10_giornate|battaglie_per_partita|prima_battaglia_mediana|partite_senza_battaglie|giornate_mediana|giornate_min|giornate_max|fine_avversario_senza_armati|fine_giocatore_senza_armati|fine_limite|ferma|giornate_mediane_fino_alla_fine_naturale")
        for r in MisuraFrequenzaBattaglie.riepiloga(giocate) {
            righe.append([r.formato, r.condotta.rawValue, "\(r.partite)",
                          String(format: "%.2f", r.battaglieOgniDieciGiornate),
                          String(format: "%.2f", r.mediaBattagliePerPartita),
                          r.primaBattagliaMediana.map(String.init) ?? "-",
                          "\(r.partiteSenzaBattaglie)", "\(r.giornateMediana)", "\(r.giornateMinimo)",
                          "\(r.giornateMassimo)",
                          "\(r.fini[.avversarioSenzaArmati] ?? 0)", "\(r.fini[.giocatoreSenzaArmati] ?? 0)",
                          "\(r.fini[.limite] ?? 0)", "\(r.fini[.ferma] ?? 0)",
                          r.giornateMedianeFinoAllaFineNaturale.map(String.init) ?? "-"].joined(separator: "|"))
        }
        return Rapporto(grezzi: grezzi, testo: righe.joined(separator: "\n"), partite: giocate)
    }

    /// Il raccoglitore degli esiti delle partite giocate in parallelo.
    final class Esiti: @unchecked Sendable {
        private var valori: [MisuraFrequenzaBattaglie.Partita?]
        private let serratura = NSLock()
        init(conteggio: Int) { valori = Array(repeating: nil, count: conteggio) }
        func metti(_ partita: MisuraFrequenzaBattaglie.Partita?, a indice: Int) {
            serratura.lock(); valori[indice] = partita; serratura.unlock()
        }
        func tutti() -> [MisuraFrequenzaBattaglie.Partita] { valori.compactMap { $0 } }
    }
}
