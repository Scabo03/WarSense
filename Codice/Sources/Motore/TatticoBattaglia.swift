import Foundation
import Dati

/// Il tattico avversario di prima stesura (05 §5.3, 05 §15.3). Interamente
/// deterministico come ogni parte del Motore (01 §12.1): le sue scelte discendono
/// da propensioni e valutazioni, mai da estrazioni (05 §4.3); le parità si
/// risolvono per ordine di identificatore. Produce comandi ordinari, validati
/// dallo stesso percorso di chiunque (05 §5.1): non è un'eccezione al ciclo.
public struct TatticoBattaglia: Sendable {
    let motore: MotoreBattaglia
    public let ufficiale: DefinizioneUfficiale
    public let parte: Parte

    public init(motore: MotoreBattaglia, ufficiale: DefinizioneUfficiale, parte: Parte) {
        self.motore = motore
        self.ufficiale = ufficiale
        self.parte = parte
    }

    /// La metà della scala delle propensioni: sopra si agisce, sotto si attende.
    private var meta: Scalato { Scalato(millesimi: 500) }

    /// La propensione alla ritirata, ridotta dal vantaggio nascosto quando il
    /// tattico comanda l'avversario del giocatore (01 §13.2, 05 §5.5).
    private var propensioneRitirataEffettiva: Scalato {
        guard parte == .avversario else { return ufficiale.propensioneRitirata }
        return ufficiale.propensioneRitirata * motore.valori.vantaggi.riduzionePropensioneRitirataAvversaria
    }

    /// Il prossimo comando per il proprio turno. Restituisce sempre un comando
    /// valido; quando non resta nulla di utile, la fine del turno.
    public func prossimoComando(stato: StatoBattaglia) -> ComandoBattaglia {
        guard stato.esito == nil, stato.parteDiTurno == parte else { return .fineTurno }

        if let comando = comandoDiRitirata(stato: stato) { return comando }
        if stato.resaDichiarataDa == nil, convieneLaResa(stato: stato),
           motore.valida(.dichiaraResa, parte: parte, stato: stato).eValido {
            return .dichiaraResa
        }
        if let comando = comandoDiPiazzamento(stato: stato) { return comando }
        if let comando = comandoDiReparto(stato: stato) { return comando }
        return .fineTurno
    }

    // MARK: - Resa e ritirata

    /// La resa conviene quando le perdite superano la tolleranza rapportata alla
    /// propensione: con la propensione ridotta dal vantaggio nascosto la soglia
    /// sale e la resa resta possibile ma rara (01 §13.2).
    private func convieneLaResa(stato: StatoBattaglia) -> Bool {
        let perdite = motore.proporzionePerdite(per: parte, stato: stato)
        let propensione = propensioneRitirataEffettiva
        guard propensione > .zero else { return false }
        let soglia = ufficiale.tolleranzaPerdite / propensione
        return perdite >= soglia
    }

    private func comandoDiRitirata(stato: StatoBattaglia) -> ComandoBattaglia? {
        guard stato.resaDichiarataDa == parte else { return nil }
        let vantaggi = motore.valori.vantaggi
        for sciame in stato.sciamiOrdinati where sciame.parte == parte {
            if parte == .avversario && vantaggi.ritirataAvversariaSoloUltimaRiga {
                // L'avversario ritira soltanto dalla propria riga più arretrata (01 §13.2).
                guard stato.griglia.avanzamento(di: sciame.posizione, per: parte) == 0 else { continue }
            }
            if motore.valida(.ritiraUnita(sciame: sciame.id), parte: parte, stato: stato).eValido {
                return .ritiraUnita(sciame: sciame.id)
            }
        }
        return nil
    }

    // MARK: - Piazzamento

    private func comandoDiPiazzamento(stato: StatoBattaglia) -> ComandoBattaglia? {
        guard let elementi = stato.deck[parte] else { return nil }
        for (indice, elemento) in elementi.enumerated() where elemento.esemplari > 0 {
            if stato.selezione[parte] != indice {
                if motore.valida(.seleziona(indiceDeck: indice), parte: parte, stato: stato).eValido {
                    return .seleziona(indiceDeck: indice)
                }
                continue
            }
            for cella in celleDiPiazzamentoOrdinate(stato: stato) {
                if motore.valida(.piazza(cella: cella), parte: parte, stato: stato).eValido {
                    return .piazza(cella: cella)
                }
            }
        }
        return nil
    }

    /// L'ordine delle celle di piazzamento: dal centro con tendenza bassa,
    /// dai fianchi con tendenza all'accerchiamento alta (01 §14.3). Deterministico.
    private func celleDiPiazzamentoOrdinate(stato: StatoBattaglia) -> [Cella] {
        let f = motore.valori.formati[stato.formato]!
        let righe = stato.griglia.righeDiPiazzamento(per: parte, quante: f.righeDiPiazzamento)
        let centro = (stato.griglia.colonne + 1) * 500 // centro in millesimi di colonna
        let daiFianchi = ufficiale.tendenzaAccerchiamento >= meta
        var celle: [Cella] = []
        for riga in (parte == .avversario ? Array(righe) : Array(righe).reversed()) {
            let colonne = (1...stato.griglia.colonne).sorted { a, b in
                let da = abs(a * 1000 - centro), db = abs(b * 1000 - centro)
                if da != db { return daiFianchi ? da > db : da < db }
                return a < b
            }
            celle.append(contentsOf: colonne.map { Cella(riga: riga, colonna: $0) })
        }
        return celle
    }

    // MARK: - Azioni dei reparti

    private func comandoDiReparto(stato: StatoBattaglia) -> ComandoBattaglia? {
        let nemici = stato.sciamiOrdinati.filter { $0.parte == parte.avversaria }
        guard !nemici.isEmpty else { return nil }
        for sciame in stato.sciamiOrdinati
        where sciame.parte == parte && !sciame.azioneSpesa && !stato.impegnato(sciame.id) {
            let vicino = nemici.min {
                let da = stato.griglia.distanza(sciame.posizione, $0.posizione)
                let db = stato.griglia.distanza(sciame.posizione, $1.posizione)
                return da != db ? da < db : $0.id < $1.id
            }!
            if let tiro = comandoDiTiro(sciame: sciame, nemici: nemici, stato: stato) { return tiro }
            if ufficiale.propensioneAttacco >= meta,
               motore.valida(.ingaggia(sciame: sciame.id, bersaglio: vicino.id),
                             parte: parte, stato: stato).eValido {
                return .ingaggia(sciame: sciame.id, bersaglio: vicino.id)
            }
            if ufficiale.propensioneAttacco >= meta {
                let passi = stato.griglia.vicini(di: sciame.posizione)
                    .filter { stato.occupante(di: $0) == nil && !stato.ostacoli.contains($0) }
                    .sorted { a, b in
                        let da = stato.griglia.distanza(a, vicino.posizione)
                        let db = stato.griglia.distanza(b, vicino.posizione)
                        return da != db ? da < db : a < b
                    }
                if let passo = passi.first,
                   stato.griglia.distanza(passo, vicino.posizione)
                        < stato.griglia.distanza(sciame.posizione, vicino.posizione),
                   motore.valida(.muovi(sciame: sciame.id, percorso: [passo]),
                                 parte: parte, stato: stato).eValido {
                    return .muovi(sciame: sciame.id, percorso: [passo])
                }
            }
        }
        return nil
    }

    /// Tira al bersaglio più vicino a portata, con il proiettile più efficace;
    /// entro il solo disturbo tira soltanto chi ha propensione all'attacco alta,
    /// perché le scariche si conservano per la fascia che uccide (01 §9.6).
    private func comandoDiTiro(sciame: Sciame, nemici: [Sciame],
                               stato: StatoBattaglia) -> ComandoBattaglia? {
        let archetipo = motore.valori.archetipi[sciame.archetipo]!
        guard !archetipo.offeseTiro.isEmpty, sciame.munizioni > 0 else { return nil }
        let bersagli = nemici.sorted {
            let da = stato.griglia.distanza(sciame.posizione, $0.posizione)
            let db = stato.griglia.distanza(sciame.posizione, $1.posizione)
            return da != db ? da < db : $0.id < $1.id
        }
        for bersaglio in bersagli {
            let distanza = stato.griglia.distanza(sciame.posizione, bersaglio.posizione)
            let entroPericolosita = distanza <= motore.gittataEffettiva(archetipo.gittataPericolosita, stato: stato)
            guard entroPericolosita || ufficiale.propensioneAttacco >= meta else { continue }
            // Il proiettile più efficace contro la protezione del bersaglio; parità per nome.
            let proiettili = archetipo.offeseTiro.keys.sorted { $0.rawValue < $1.rawValue }
            let scelto = proiettili.max { a, b in
                let ea = motore.efficacia(offesa: archetipo.offeseTiro[a]!,
                                          protezione: motore.valori.protezioni[bersaglio.protezione]!)
                let eb = motore.efficacia(offesa: archetipo.offeseTiro[b]!,
                                          protezione: motore.valori.protezioni[bersaglio.protezione]!)
                return ea != eb ? ea < eb : a.rawValue > b.rawValue
            }!
            let comando = ComandoBattaglia.tira(sciame: sciame.id, bersaglio: bersaglio.id, proiettile: scelto)
            if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
        }
        return nil
    }
}
