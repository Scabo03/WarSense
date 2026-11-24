import Foundation
import Dati
import Motore

/// PERCHÉ UNA BATTAGLIA NON SI CONCLUDE AL BANCO (incarico 32). Le misure che giocano campagne intere
/// fermano la partita quando una battaglia non arriva a un esito entro i tetti del banco, e fino
/// all'incarico 31 dicevano soltanto questo. Qui la battaglia fermata si guarda: quanti giri e quanti
/// passi ha fatto, che cosa hanno ordinato le due parti negli ultimi passi, chi resta in campo e se può
/// ancora muovere, che cosa resta nei mazzi e se si può ancora piazzare. Da queste grandezze, e da
/// nient'altro, si ricava la CAUSA, con un codice stabile.
///
/// Non contiene regole del gioco: ciò che è possibile lo chiede al Motore, comando per comando.
public struct DiagnosiBattaglia: Sendable, Codable, Hashable {

    /// Le cause riconosciute. L'ultima raccoglie ciò che nessuna delle altre spiega.
    public enum Causa: String, Sendable, Codable, CaseIterable {
        /// Il tattico alterna la selezione di elementi del mazzo che non può piazzare, e non chiude mai
        /// il turno.
        case selezioneAlternata = "selezione_alternata"
        /// Nessun contatto, e in entrambe le parti nessun reparto ha più un ordine che cambi qualcosa:
        /// le due parti si passano il turno.
        case nessunoPuoAgire = "nessuno_puo_agire"
        /// Nessun contatto, e una parte sola potrebbe ancora agire ma il suo tattico non lo fa.
        case attesaReciproca = "attesa_reciproca"
        /// Ci sono contatti in corso che non decidono lo scontro entro il tetto.
        case mischiaSenzaFine = "mischia_senza_fine"
        /// Nessuna delle precedenti.
        case altra
    }

    /// Un reparto ancora in campo.
    public struct Reparto: Sendable, Codable, Hashable {
        public let parte: String
        public let archetipo: String
        public let atomiIniziali: Int64
        public let atomiPresenti: Int64
        public let volume: Int64
        public let riga: Int
        public let colonna: Int
        public let impegnato: Bool
        /// Vero se il Motore, a inizio turno e con il bilancio pieno, ammetterebbe un suo passo.
        public let puoMuovere: Bool
    }

    /// Ciò che resta in un mazzo.
    public struct Riserva: Sendable, Codable, Hashable {
        public let parte: String
        public let archetipo: String
        public let atomi: Int64
        public let esemplari: Int
        public let volume: Int64
        /// Vero se il Motore ammetterebbe di piazzarla in almeno una cella, a inizio turno.
        public let piazzabile: Bool
    }

    public let giri: Int
    public let passi: Int
    public let causa: Causa
    public let primoOccupante: String
    public let imboscata: Bool
    public let resaDichiarataDa: String?
    /// I mazzi con cui la battaglia è cominciata: «archetipo×atomi», per parte.
    public let mazzi: [String: [String]]
    public let inCampo: [Reparto]
    public let riserve: [Riserva]
    public let contatti: Int
    /// Gli ordini degli ultimi passi, contati per parte e per specie.
    public let ultimiOrdini: [String: [String: Int]]

    enum CodingKeys: String, CodingKey {
        case giri, passi, causa, imboscata, mazzi, riserve, contatti
        case primoOccupante = "primo_occupante"
        case resaDichiarataDa = "resa_dichiarata_da"
        case inCampo = "in_campo"
        case ultimiOrdini = "ultimi_ordini"
    }

    /// La specie di un comando, come codice stabile (05 §12.6).
    static func specie(_ comando: ComandoBattaglia) -> String {
        switch comando {
        case .seleziona: return "seleziona"
        case .deseleziona: return "deseleziona"
        case .piazza: return "piazza"
        case .muovi: return "muovi"
        case .tira: return "tira"
        case .ingaggia: return "ingaggia"
        case .dichiaraResa: return "dichiara_resa"
        case .ritiraUnita: return "ritira_unita"
        case .disingaggiaSuOrdine: return "disingaggia_su_ordine"
        case .fineTurno: return "fine_turno"
        }
    }

    /// Lo stato di una parte a inizio del proprio turno, col bilancio pieno: serve a dire che cosa le
    /// è possibile senza che la spesa del turno in corso lo nasconda.
    private static func aInizioTurno(_ parte: Parte, _ stato: StatoBattaglia,
                                     _ motore: MotoreBattaglia) -> StatoBattaglia {
        var s = stato
        s.parteDiTurno = parte
        let budget = motore.valori.formati[stato.formato]?.budgetVolumeBase ?? 0
        let riporto = motore.valori.formati[stato.formato]?.quotaRiporto.applicato(a: budget) ?? 0
        // Una parte che non ha mai avuto il turno non ha ancora un bilancio: si parte da quello
        // dell'altra, i cui valori si riscrivono comunque qui sotto.
        if s.bilancio[parte] == nil { s.bilancio[parte] = s.bilancio[parte.avversaria] }
        s.bilancio[parte]?.baseTurno = budget
        s.bilancio[parte]?.riportoEntrante = riporto
        s.bilancio[parte]?.spesa = 0
        for id in s.sciami.keys where s.sciami[id]!.parte == parte { s.sciami[id]!.azioneSpesa = false }
        return s
    }

    static func puoMuovere(_ sciame: Sciame, _ stato: StatoBattaglia, _ motore: MotoreBattaglia) -> Bool {
        let s = aInizioTurno(sciame.parte, stato, motore)
        return stato.griglia.vicini(di: sciame.posizione).contains {
            motore.valida(.muovi(sciame: sciame.id, percorso: [$0]), parte: sciame.parte, stato: s).eValido
        }
    }

    static func piazzabile(indice: Int, parte: Parte, _ stato: StatoBattaglia, _ motore: MotoreBattaglia) -> Bool {
        var s = aInizioTurno(parte, stato, motore)
        s.selezione[parte] = indice
        return stato.griglia.tutteLeCelle.contains {
            motore.valida(.piazza(cella: $0), parte: parte, stato: s).eValido
        }
    }

    /// Guarda una battaglia fermata dai tetti del banco.
    init(stato: StatoBattaglia, iniziale: StatoBattaglia, passi: Int,
         ultimi: [(Parte, ComandoBattaglia)], motore: MotoreBattaglia) {
        giri = stato.giro
        self.passi = passi
        primoOccupante = stato.primoOccupante.rawValue
        if case .trasparente = iniziale.sorpresa { imboscata = false } else { imboscata = true }
        resaDichiarataDa = stato.resaDichiarataDa?.rawValue
        var m: [String: [String]] = [:]
        for parte in Parte.allCases {
            m[parte.rawValue] = (iniziale.deck[parte] ?? []).map { "\($0.archetipo)x\($0.atomi)" }
        }
        mazzi = m
        inCampo = stato.sciamiOrdinati.map { s in
            let pv = motore.valori.archetipi[s.archetipo]?.puntiVitaPerAtomo ?? 1
            return Reparto(parte: s.parte.rawValue, archetipo: s.archetipo, atomiIniziali: s.atomiIniziali,
                           atomiPresenti: s.atomiPresenti(puntiVitaPerAtomo: pv, minimo: motore.valori.minimi.atomiMinimiSciameVivo),
                           volume: motore.volume(di: s), riga: s.posizione.riga, colonna: s.posizione.colonna,
                           impegnato: stato.impegnato(s.id), puoMuovere: Self.puoMuovere(s, stato, motore))
        }
        var r: [Riserva] = []
        for parte in Parte.allCases {
            for (indice, e) in (stato.deck[parte] ?? []).enumerated() where e.esemplari > 0 {
                r.append(Riserva(parte: parte.rawValue, archetipo: e.archetipo, atomi: e.atomi, esemplari: e.esemplari,
                                 volume: e.atomi * (motore.valori.archetipi[e.archetipo]?.volumePerAtomo ?? 0),
                                 piazzabile: Self.piazzabile(indice: indice, parte: parte, stato, motore)))
            }
        }
        riserve = r
        contatti = stato.contatti.count
        var conti: [String: [String: Int]] = [:]
        for (parte, comando) in ultimi { conti[parte.rawValue, default: [:]][Self.specie(comando), default: 0] += 1 }
        ultimiOrdini = conti

        let specie = Set(conti.values.flatMap { $0.keys })
        if !conti.isEmpty, specie == ["seleziona"] {
            causa = .selezioneAlternata
        } else if contatti == 0, specie.isSubset(of: ["fine_turno", "seleziona", "deseleziona"]) {
            let qualcuno = inCampo.contains { $0.puoMuovere && !$0.impegnato } || r.contains { $0.piazzabile }
            causa = qualcuno ? .attesaReciproca : .nessunoPuoAgire
        } else if contatti > 0 {
            causa = .mischiaSenzaFine
        } else {
            causa = .altra
        }
    }

    /// La diagnosi in una riga di coppie chiave-valore, per `motivo_ferma`.
    var inUnaRiga: String {
        "giri=\(giri):passi=\(passi):causa=\(causa.rawValue)"
    }
}
