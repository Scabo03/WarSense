import Foundation
import Dati
import Motore

/// La misura del corpo a corpo (incarico 09). Nessuna regola vive qui: si costruisce
/// uno stato con `BanchiDiMisura.campo`, si applicano comandi del Motore e si legge lo
/// stato che il Motore produce. La soglia di disingaggio si disattiva soltanto come
/// valori derivati (`ValoriVariati.disingaggioDisattivato`), mai come stato del Motore
/// né come canale che il gioco possa attraversare.
extension BanchiDiMisura {

    /// Il tetto degli scambi di una corsa di mischia. È un limite di MISURA, non un
    /// valore di gioco: non entra in alcuna formula del Motore. È scelto sopra il
    /// serbatoio più grosso in campo (macchina d'assedio, 5 atomi × 200 = 1000) diviso
    /// per il danno minimo (1), sicché ogni corsa in cui la distruzione è raggiungibile
    /// la raggiunga entro il tetto e non si registri come non conclusa per il tetto.
    var tettoScambiMischia: Int { 1200 }

    /// Perdite di uno sciame come proporzione in millesimi della sua consistenza d'ingresso.
    private func perditePermille(ingresso: Int64, serbatoio: Int64) -> Int64 {
        ingresso > 0 ? (ingresso - serbatoio) * 1000 / ingresso : 0
    }

    // MARK: - Corse per accoppiamento

    /// Una corsa di mischia uno-contro-uno fra due archetipi, con la stessa protezione
    /// ai due (come i duelli): l'attaccante ingaggia il bersaglio e i due si scambiano
    /// colpi a ogni scambio finché uno è distrutto, uno si disingaggia, o si raggiunge il
    /// tetto. «Scambio» è una risoluzione di mischia: il primo è l'ingaggio, che si
    /// risolve all'istante (01 §9.7.1), i successivi sono le risoluzioni d'inizio giro
    /// (01 §9.7). La corsa si legge diversamente a seconda del regime della soglia:
    /// a soglia attiva dà la fotografia (chi si sfila e con quante perdite); a soglia
    /// disattivata dà i turni per la distruzione e i turni per scattare la soglia reale,
    /// osservati sulla stessa corsa e quindi confrontabili.
    public struct CorsaMischia: Sendable {
        public let attaccante: IdentificatoreDati
        public let bersaglio: IdentificatoreDati
        public let protezione: TipoProtezione
        public let ingressoAttaccante: Int64
        public let ingressoBersaglio: Int64
        /// Danno inflitto al bersaglio nel primo scambio (l'ingaggio), a piena consistenza.
        public let inflittoPrimoScambio: Int64
        public let subitoPrimoScambio: Int64
        /// Scambi risolti fino all'esito (l'ingaggio conta 1).
        public let scambi: Int
        /// disfatta_bersaglio | disfatta_attaccante | disfatta_reciproca |
        /// disingaggio_attaccante | disingaggio_bersaglio | tetto
        public let esito: String
        public let chiSiSfila: String
        public let perditeChiSiSfilaPermille: Int64
        /// Scambio in cui il bersaglio raggiunge la PROPRIA soglia di disingaggio reale
        /// (osservato, indipendente dal regime); 0 se non la raggiunge entro l'esito.
        public let turnoSogliaBersaglio: Int
        public let turnoSogliaAttaccante: Int
        /// Scambio in cui il bersaglio è disfatto; 0 se il bersaglio non viene distrutto.
        public let turnoDistruzioneBersaglio: Int
        public let turnoDistruzioneAttaccante: Int
        public let residuoBersaglioPermille: Int64
        public let residuoAttaccantePermille: Int64
    }

    /// Tutte le corse di mischia, per ogni protezione, ogni attaccante, ogni bersaglio
    /// (l'insieme completo degli accoppiamenti: nessuno resta un buco). `soglieReali`
    /// sono le soglie del gioco distribuito, passate a parte perché a soglia disattivata
    /// i valori del Motore le portano a 1,0 e non le si potrebbe più leggere dallo stato.
    public func corseMischia(soglieReali: [IdentificatoreDati: Scalato?]) throws -> [CorsaMischia] {
        var esito: [CorsaMischia] = []
        for protezione in TipoProtezione.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            for attaccante in archetipiOrdinati {
                for bersaglio in archetipiOrdinati {
                    esito.append(try corsaSingola(attaccante: attaccante, bersaglio: bersaglio,
                                                  protezione: protezione,
                                                  soglieReali: soglieReali))
                }
            }
        }
        return esito
    }

    private func corsaSingola(attaccante: IdentificatoreDati, bersaglio: IdentificatoreDati,
                              protezione: TipoProtezione,
                              soglieReali: [IdentificatoreDati: Scalato?]) throws -> CorsaMischia {
        let cellaAttaccante = intorno[0], cellaBersaglio = centro
        let costruito = try campo([
            Collocazione(parte: .giocatore, archetipo: attaccante,
                         protezione: protezione, cella: cellaAttaccante),
            Collocazione(parte: .avversario, archetipo: bersaglio,
                         protezione: protezione, cella: cellaBersaglio),
        ])
        var stato = costruito.0
        let ids = costruito.1
        let idA = ids[0], idB = ids[1]
        let ingA = stato.sciami[idA]!.serbatoio
        let ingB = stato.sciami[idB]!.serbatoio
        // Soglia reale del gioco distribuito; nil = reparto elitario, che non raggiunge
        // mai la propria soglia perché non ne ha (incarico 10).
        let sogliaA: Scalato? = soglieReali[attaccante] ?? nil
        let sogliaB: Scalato? = soglieReali[bersaglio] ?? nil

        // Primo scambio: l'ingaggio si risolve all'istante (01 §9.7.1).
        stato = motore.applica(.ingaggia(sciame: idA, bersaglio: idB), parte: .giocatore, stato: stato).0
        let inflittoPrimo = ingB - (stato.sciami[idB]?.serbatoio ?? 0)
        let subitoPrimo = ingA - (stato.sciami[idA]?.serbatoio ?? 0)

        var scambi = 1
        var turnoSogliaB = 0, turnoSogliaA = 0
        var turnoDistrB = 0, turnoDistrA = 0
        var chiSiSfila = "", perditeSfila: Int64 = 0
        var esitoTesto = ""

        func osservaSoglie() {
            let serbB = stato.sciami[idB]?.serbatoio ?? 0
            let serbA = stato.sciami[idA]?.serbatoio ?? 0
            if turnoSogliaB == 0, let sB = sogliaB,
               perditePermille(ingresso: ingB, serbatoio: serbB) >= sB.grezzo {
                turnoSogliaB = scambi
            }
            if turnoSogliaA == 0, let sA = sogliaA,
               perditePermille(ingresso: ingA, serbatoio: serbA) >= sA.grezzo {
                turnoSogliaA = scambi
            }
        }
        osservaSoglie()

        let bersaglioVivoPrimo = stato.sciami[idB] != nil
        let attaccanteVivoPrimo = stato.sciami[idA] != nil
        if !bersaglioVivoPrimo || !attaccanteVivoPrimo {
            if !bersaglioVivoPrimo { turnoDistrB = scambi }
            if !attaccanteVivoPrimo { turnoDistrA = scambi }
            esitoTesto = !bersaglioVivoPrimo && !attaccanteVivoPrimo ? "disfatta_reciproca"
                : (!bersaglioVivoPrimo ? "disfatta_bersaglio" : "disfatta_attaccante")
        } else {
            while stato.sciami[idA] != nil && stato.sciami[idB] != nil
                    && stato.esito == nil && scambi < tettoScambiMischia {
                if stato.contatti.isEmpty {
                    // Disingaggio: uno dei due ha lasciato la mischia (regime a soglia attiva).
                    let mossoB = stato.sciami[idB]?.posizione != cellaBersaglio
                    let mossoA = stato.sciami[idA]?.posizione != cellaAttaccante
                    if mossoB {
                        chiSiSfila = "bersaglio"
                        perditeSfila = perditePermille(ingresso: ingB, serbatoio: stato.sciami[idB]!.serbatoio)
                    } else if mossoA {
                        chiSiSfila = "attaccante"
                        perditeSfila = perditePermille(ingresso: ingA, serbatoio: stato.sciami[idA]!.serbatoio)
                    }
                    esitoTesto = mossoB ? "disingaggio_bersaglio"
                        : (mossoA ? "disingaggio_attaccante" : "tetto")
                    break
                }
                stato = giroDiMischia(stato).0
                scambi += 1
                osservaSoglie()
                if stato.sciami[idB] == nil { turnoDistrB = scambi }
                if stato.sciami[idA] == nil { turnoDistrA = scambi }
            }
            if esitoTesto.isEmpty {
                let bVivo = stato.sciami[idB] != nil, aVivo = stato.sciami[idA] != nil
                if !bVivo && !aVivo { esitoTesto = "disfatta_reciproca" }
                else if !bVivo { esitoTesto = "disfatta_bersaglio" }
                else if !aVivo { esitoTesto = "disfatta_attaccante" }
                else if stato.contatti.isEmpty {
                    // Il ciclo è uscito sull'assenza di contatti al primo controllo del giro nuovo.
                    let mossoB = stato.sciami[idB]?.posizione != cellaBersaglio
                    let mossoA = stato.sciami[idA]?.posizione != cellaAttaccante
                    if mossoB {
                        chiSiSfila = "bersaglio"
                        perditeSfila = perditePermille(ingresso: ingB, serbatoio: stato.sciami[idB]!.serbatoio)
                        esitoTesto = "disingaggio_bersaglio"
                    } else if mossoA {
                        chiSiSfila = "attaccante"
                        perditeSfila = perditePermille(ingresso: ingA, serbatoio: stato.sciami[idA]!.serbatoio)
                        esitoTesto = "disingaggio_attaccante"
                    } else { esitoTesto = "tetto" }
                } else { esitoTesto = "tetto" }
            }
        }

        let residuoB = stato.sciami[idB].map { $0.serbatoio * 1000 / max(1, ingB) } ?? 0
        let residuoA = stato.sciami[idA].map { $0.serbatoio * 1000 / max(1, ingA) } ?? 0
        return CorsaMischia(
            attaccante: attaccante, bersaglio: bersaglio, protezione: protezione,
            ingressoAttaccante: ingA, ingressoBersaglio: ingB,
            inflittoPrimoScambio: inflittoPrimo, subitoPrimoScambio: subitoPrimo,
            scambi: scambi, esito: esitoTesto,
            chiSiSfila: chiSiSfila, perditeChiSiSfilaPermille: perditeSfila,
            turnoSogliaBersaglio: turnoSogliaB, turnoSogliaAttaccante: turnoSogliaA,
            turnoDistruzioneBersaglio: turnoDistrB, turnoDistruzioneAttaccante: turnoDistrA,
            residuoBersaglioPermille: residuoB, residuoAttaccantePermille: residuoA)
    }

    // MARK: - Modificatori congiunti: accerchiamento e limite dei bersagli

    public struct MischiaAccerchiata: Sendable {
        public let assalitori: Int
        public let coefficienteAccerchiamentoPermille: Int64
        /// Danno inflitto al bersaglio nel primo scambio (l'ingaggio dell'ultimo assalitore
        /// più la risoluzione), sommato su tutti gli assalitori.
        public let inflittoPrimoGiro: Int64
        public let subitoPrimoGiro: Int64
        public let rapportoPermille: Int64
        /// Scambi per distruggere il bersaglio a soglia disattivata; 0 se non avviene.
        public let scambiPerDistruggere: Int
        public let bersaglioGiuAPrimoGiro: Bool
    }

    /// Da uno a `concorrentiMassimi` assalitori identici contro un bersaglio identico, la
    /// misura CONGIUNTA dei due modificatori (incarico 09, quinto): l'accerchiamento
    /// accresce il danno degli assalitori (01 §9.10.2) e il limite dei bersagli riduce la
    /// risposta del bersaglio oltre il secondo (01 §9.11), e i due lavorano nella stessa
    /// direzione. Si misura quanto cambia l'esito del contatto fra uno-contro-uno e più
    /// assalitori: il primo scambio e, a soglia disattivata, gli scambi per la distruzione.
    public func mischiaAccerchiata() throws -> [MischiaAccerchiata] {
        var esito: [MischiaAccerchiata] = []
        for numero in 1...valori.combattimento.concorrentiMassimi {
            var (stato, ids) = try campo(
                (0..<numero).map { Collocazione(parte: .giocatore,
                                                archetipo: banchi.assalitoreDiRiferimento,
                                                protezione: banchi.protezioneDiRiferimento,
                                                cella: intorno[$0]) }
                + [Collocazione(parte: .avversario, archetipo: banchi.bersaglioDiRiferimento,
                                protezione: banchi.protezioneDiRiferimento, cella: centro)])
            let idBersaglio = ids.removeLast()
            let ingressoBersaglio = stato.sciami[idBersaglio]!.serbatoio
            let ingressiAssalitori = ids.map { stato.sciami[$0]!.serbatoio }
            for id in ids {
                let comando = ComandoBattaglia.ingaggia(sciame: id, bersaglio: idBersaglio)
                guard motore.valida(comando, parte: .giocatore, stato: stato).eValido else { continue }
                stato = motore.applica(comando, parte: .giocatore, stato: stato).0
            }
            // Primo scambio completo: gli ingaggi immediati più una risoluzione d'inizio giro.
            let dopoUnGiro = giroDiMischia(stato).0
            let inflitto = ingressoBersaglio - (dopoUnGiro.sciami[idBersaglio]?.serbatoio ?? 0)
            var subito: Int64 = 0
            for (i, id) in ids.enumerated() {
                subito += ingressiAssalitori[i] - (dopoUnGiro.sciami[id]?.serbatoio ?? 0)
            }
            let giuAPrimoGiro = dopoUnGiro.sciami[idBersaglio] == nil
            // Scambi per la distruzione (il chiamante fornisce il Motore a soglia disattivata).
            var corsa = stato
            var scambi = 1
            while corsa.sciami[idBersaglio] != nil && corsa.esito == nil && scambi < tettoScambiMischia {
                corsa = giroDiMischia(corsa).0
                scambi += 1
                if !corsa.contatti.contains(where: { $0.coinvolge(idBersaglio) }) { break }
            }
            let scambiPerDistruggere = corsa.sciami[idBersaglio] == nil ? scambi : 0
            esito.append(MischiaAccerchiata(
                assalitori: numero,
                coefficienteAccerchiamentoPermille: motore.coefficienteAccerchiamento(concorrenti: numero).grezzo,
                inflittoPrimoGiro: inflitto, subitoPrimoGiro: subito,
                rapportoPermille: (inflitto * 1000) / max(1, subito),
                scambiPerDistruggere: scambiPerDistruggere,
                bersaglioGiuAPrimoGiro: giuAPrimoGiro))
        }
        return esito
    }
}

/// La provenienza delle perdite in una battaglia (incarico 09, quarto): quanta parte
/// viene dal tiro e quanta dalla mischia, e se qualche contatto ha prodotto una
/// distruzione. Non aggiunge alcun canale di sola misura: legge la variazione di
/// `perditeSubite` (RDA-46) fra prima e dopo ciascun comando e gli eventi `.sciameDisfatto`
/// che il comando produce. `perditeSubite` cresce solo in `applicaDanno`; l'evacuazione
/// della ritirata combattuta non lo tocca e non produce `.sciameDisfatto`, quindi non è
/// contata né come perdita né come distruzione.
public struct ProvenienzaBattaglia: Sendable {
    let motore: MotoreBattaglia
    public init(motore: MotoreBattaglia) { self.motore = motore }

    public struct Esito: Sendable {
        public let perditeTiro: [Parte: Int64]
        public let perditeMischia: [Parte: Int64]
        public let distruzioniInMischia: Int
        public let distruzioniInTiro: Int
        /// Reingaggi: contatti formati su una coppia già staccata (01 §9.8.3). Misura
        /// quanto la regola del secondo contatto è esercitata (incarico 10).
        public let reingaggi: Int
        /// Disingaggi automatici avvenuti nella battaglia (eventi `.disingaggio`).
        public let disingaggi: Int
        public let concluso: Bool
        public let modo: String
    }

    public func replica(stato iniziale: StatoBattaglia,
                        tattici: [Parte: TatticoBattaglia], giriMassimi: Int) -> Esito {
        var stato = iniziale
        var tiro: [Parte: Int64] = [:], mischia: [Parte: Int64] = [:]
        var distMischia = 0, distTiro = 0, reingaggi = 0, disingaggi = 0
        var comandi = 0
        let tetto = giriMassimi * 200
        while stato.esito == nil && stato.giro <= giriMassimi && comandi < tetto {
            let parte = stato.parteDiTurno
            let comando = tattici[parte]!.prossimoComando(stato: stato)
            // Reingaggio: la coppia che sta per ingaggiare si era già staccata (01 §9.8.3).
            if case .ingaggia(let a, let b) = comando, stato.coppieStaccate.contains(Coppia(a, b)) {
                reingaggi += 1
            }
            let prima = stato.perditeSubite
            let (dopo, eventi) = motore.applica(comando, parte: parte, stato: stato)
            for p in Parte.allCases {
                let delta = (dopo.perditeSubite[p] ?? 0) - (prima[p] ?? 0)
                guard delta != 0 else { continue }
                switch comando {
                case .tira: tiro[p, default: 0] += delta
                case .ingaggia, .fineTurno: mischia[p, default: 0] += delta
                default: break
                }
            }
            for e in eventi {
                if case .disingaggio = e { disingaggi += 1 }
                guard case .sciameDisfatto = e else { continue }
                switch comando {
                case .tira: distTiro += 1
                case .ingaggia, .fineTurno: distMischia += 1
                default: break
                }
            }
            stato = dopo
            comandi += 1
        }
        return Esito(perditeTiro: tiro, perditeMischia: mischia,
                     distruzioniInMischia: distMischia, distruzioniInTiro: distTiro,
                     reingaggi: reingaggi, disingaggi: disingaggi,
                     concluso: stato.esito != nil, modo: stato.esito?.modo.rawValue ?? "non_concluso")
    }
}
