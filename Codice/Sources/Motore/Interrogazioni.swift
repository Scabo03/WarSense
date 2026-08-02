import Foundation
import Dati

/// Le interrogazioni di sola lettura per la Presentazione (05 §9.4): la vista di una
/// parte è filtrata dall'unica eccezione alla trasparenza, l'opacità dell'imboscata
/// (01 §9.3.2.1). La Presentazione non calcola mai un dato di gioco.
public struct VistaBattaglia: Sendable {
    let motore: MotoreBattaglia
    let stato: StatoBattaglia
    let parte: Parte

    public init(motore: MotoreBattaglia, stato: StatoBattaglia, parte: Parte) {
        self.motore = motore; self.stato = stato; self.parte = parte
    }

    /// Vero se, per questa parte, gli sciami avversari sono nascosti (turno opaco: 01 §9.3.2.1).
    public var opacitaAttiva: Bool {
        if case .opacita = stato.sorpresa { return parte != stato.primoOccupante }
        if case .vantaggio = stato.sorpresa { return parte != stato.primoOccupante }
        return false
    }

    /// Lo sciame visibile in una cella, secondo la vista della parte.
    public func occupanteVisibile(di cella: Cella) -> Sciame? {
        guard let sciame = stato.occupante(di: cella) else { return nil }
        if opacitaAttiva && sciame.parte != parte { return nil }
        return sciame
    }

    /// Gli sciami visibili, nell'ordine di lettura delle loro celle.
    public var sciamiVisibili: [Sciame] {
        stato.sciamiOrdinati
            .filter { !(opacitaAttiva && $0.parte != parte) }
            .sorted { $0.posizione < $1.posizione }
    }

    /// Le celle valide per l'elemento selezionato, con i costi dichiarati:
    /// alimenta il rotore delle celle valide (02 §7.2) e gli annunci di cella (02 §3.3).
    public func celleValidePerSelezione() -> [(cella: Cella, costi: CostiDichiarati)] {
        guard stato.selezione[parte] != nil else { return [] }
        return stato.griglia.tutteLeCelle.compactMap { cella in
            guard case .valido(let costi) = motore.valida(.piazza(cella: cella), parte: parte, stato: stato)
            else { return nil }
            return (cella, costi)
        }
    }

    /// L'esito di validazione di un piazzamento sulla cella: è l'anteprima annunciata (05 §3.2).
    public func anteprimaPiazzamento(su cella: Cella) -> EsitoValidazione {
        motore.valida(.piazza(cella: cella), parte: parte, stato: stato)
    }

    /// L'informazione di stato della battaglia (02 §6.4): budget residuo, turno,
    /// riga avversaria più avanzata, righe alla soglia durante la ritirata.
    public struct InformazioneDiStato: Hashable, Sendable {
        public let volumeResiduo: Int64
        public let numeroGiro: Int
        public let rigaAvversariaPiuAvanzata: Int?
        public let righeAllaSogliaDiRitirata: Int?
    }

    public var informazioneDiStato: InformazioneDiStato {
        let avversaria = parte.avversaria
        let avanzamenti = stato.sciami.values
            .filter { $0.parte == avversaria && !(opacitaAttiva) }
            .map { stato.griglia.avanzamento(di: $0.posizione, per: avversaria) }
        let rigaPiuAvanzata: Int? = avanzamenti.max().map { avanzamento in
            avversaria == .giocatore ? stato.griglia.righe - avanzamento : 1 + avanzamento
        }
        var righeAllaSoglia: Int? = nil
        if let ritirante = stato.resaDichiarataDa, ritirante == parte {
            let f = motore.valori.formati[stato.formato]!
            let sogliaAvanzamento = stato.griglia.righe - 1 - f.righeSogliaRitirata
            let massimo = avanzamenti.max() ?? 0
            righeAllaSoglia = max(0, sogliaAvanzamento - massimo)
        }
        return InformazioneDiStato(volumeResiduo: stato.bilancio[parte]?.disponibile ?? 0,
                                   numeroGiro: stato.giro,
                                   rigaAvversariaPiuAvanzata: rigaPiuAvanzata,
                                   righeAllaSogliaDiRitirata: righeAllaSoglia)
    }
}
