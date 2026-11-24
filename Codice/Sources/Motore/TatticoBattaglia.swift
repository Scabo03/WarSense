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
        if convieneUscireDalloStallo(stato: stato),
           motore.valida(.dichiaraResa, parte: parte, stato: stato).eValido {
            return .dichiaraResa
        }
        return .fineTurno
    }

    // MARK: - Resa e ritirata

    /// La soglia di perdite oltre la quale il tattico dichiara la resa, espressa
    /// come proporzione delle forze impiegate (01 §10.2, RDA-46): tolleranza alle
    /// perdite divisa per la propensione effettiva alla ritirata. Oltre l'unità la
    /// soglia è irraggiungibile e la resa non avviene mai.
    ///
    /// È pubblica perché il programma di verifica la misuri leggendola, anziché
    /// riscrivere altrove la formula (05 §12, incarico della fase C).
    public var sogliaDiResa: Scalato {
        let propensione = propensioneRitirataEffettiva
        guard propensione > .zero else { return Scalato(intero: Int64.max / Scalato.fattore) }
        return ufficiale.tolleranzaPerdite / propensione
    }

    /// La resa conviene quando le perdite raggiungono la soglia (01 §13.2): con la
    /// propensione ridotta dal vantaggio nascosto la soglia sale e la resa resta
    /// possibile ma rara.
    private func convieneLaResa(stato: StatoBattaglia) -> Bool {
        guard propensioneRitirataEffettiva > .zero else { return false }
        return motore.proporzionePerdite(per: parte, stato: stato) >= sogliaDiResa
    }

    /// LO STALLO (01 §10.7.1; incarico 32): le due parti non possono più incontrarsi, per quanto
    /// avanzino, oppure nessuna delle due può più avvicinarsi all'altra. È l'avversario a uscirne,
    /// ritirandosi: la sconfitta è una decisione e non un calcolo (01 §15.2.4), e una battaglia in cui
    /// nessuno può raggiungere l'altro non può restare aperta. Accade a due schieramenti troppo
    /// ingombranti per avanzare, come i due gruppi di ventiquattro fanti pesanti e dodici cavalieri degli
    /// scenari.
    private func convieneUscireDalloStallo(stato: StatoBattaglia) -> Bool {
        parte == .avversario && stato.resaDichiarataDa == nil
            && (motore.nonPossonoPiuIncontrarsi(stato) || motore.nessunoPuoAvvicinarsi(stato))
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
        // L'avversario evacua soltanto dalla propria riga più arretrata: chi sta più avanti vi torna.
        if parte == .avversario, vantaggi.ritirataAvversariaSoloUltimaRiga {
            for sciame in stato.sciamiOrdinati where sciame.parte == parte && !sciame.azioneSpesa {
                let indietro = stato.griglia.celleArretrate(di: sciame.posizione, per: parte)
                    .filter { stato.occupante(di: $0) == nil && !stato.ostacoli.contains($0) }.sorted()
                for cella in indietro
                where motore.valida(.muovi(sciame: sciame.id, percorso: [cella]), parte: parte, stato: stato).eValido {
                    return .muovi(sciame: sciame.id, percorso: [cella])
                }
            }
        }
        return nil
    }

    // MARK: - Piazzamento

    /// Piazza il primo elemento del mazzo che, così com'è il turno, può scendere in campo: lo
    /// seleziona se non è quello selezionato, poi lo piazza. Un elemento che il Motore non ammette in
    /// alcuna cella — perché il volume che resta non basta — NON si seleziona (incarico 32). Fino alla
    /// build 32 il tattico selezionava comunque il primo elemento diverso da quello selezionato, e con
    /// un elemento impiazzabile seguito da un altro ancora da piazzare alternava la selezione dei due
    /// senza chiudere mai il turno: è la causa di tutte le battaglie che al banco non si concludevano
    /// (33 nella misura della frequenza, 78 nel banco del regno).
    private func comandoDiPiazzamento(stato: StatoBattaglia) -> ComandoBattaglia? {
        guard let elementi = stato.deck[parte] else { return nil }
        let celle = celleDiPiazzamentoOrdinate(stato: stato)
        for (indice, elemento) in elementi.enumerated() where elemento.esemplari > 0 {
            var selezionato = stato
            selezionato.selezione[parte] = indice
            guard let cella = celle.first(where: {
                motore.valida(.piazza(cella: $0), parte: parte, stato: selezionato).eValido
            }) else { continue }
            if stato.selezione[parte] == indice { return .piazza(cella: cella) }
            let selezione = ComandoBattaglia.seleziona(indiceDeck: indice)
            if motore.valida(selezione, parte: parte, stato: stato).eValido { return selezione }
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
                // Il primo passo che avvicina e che il volume basta a pagare (incarico 32). Fino alla
                // build 32 si provava soltanto il più vicino di tutti, e chi non poteva pagarlo — una
                // riga più avanti — restava fermo anche quando un altro passo, di lato, lo portava a
                // contatto: la battaglia non finiva.
                for passo in passi
                where stato.griglia.distanza(passo, vicino.posizione)
                        < stato.griglia.distanza(sciame.posizione, vicino.posizione)
                    && motore.valida(.muovi(sciame: sciame.id, percorso: [passo]),
                                     parte: parte, stato: stato).eValido {
                    return .muovi(sciame: sciame.id, percorso: [passo])
                }
            }
        }
        return nil
    }

    /// Tira al bersaglio a portata contro cui il proiettile fisso del reparto rende
    /// di più (01 §3.3.1, §9.9); parità risolte per distanza e poi per identificatore.
    private func comandoDiTiro(sciame: Sciame, nemici: [Sciame],
                               stato: StatoBattaglia) -> ComandoBattaglia? {
        let archetipo = motore.valori.archetipi[sciame.archetipo]!
        guard let offesa = archetipo.offesaTiro, sciame.munizioni > 0 else { return nil }
        let bersagli = nemici.sorted { a, b in
            let ea = motore.efficacia(offesa: offesa, protezione: motore.valori.protezioni[a.protezione]!)
            let eb = motore.efficacia(offesa: offesa, protezione: motore.valori.protezioni[b.protezione]!)
            if ea != eb { return ea > eb }
            let da = stato.griglia.distanza(sciame.posizione, a.posizione)
            let db = stato.griglia.distanza(sciame.posizione, b.posizione)
            return da != db ? da < db : a.id < b.id
        }
        for bersaglio in bersagli {
            let comando = ComandoBattaglia.tira(sciame: sciame.id, bersaglio: bersaglio.id)
            if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
        }
        return nil
    }
}
