import Foundation
import Dati
import Motore

/// La stessa condotta del tattico, ma che percorre i PROPRI reparti in un ordine
/// scelto. Serve a misurare la profondità nuova introdotta dalla risoluzione
/// immediata: se l'ordine in cui si muovono i propri reparti conti davvero.
/// Prima della modifica non contava, perché i colpi si scambiavano tutti insieme
/// alla fine del giro; se dopo la modifica due ordini diversi danno lo stesso
/// esito, la profondità è dichiarata ma non esiste.
public struct CondottaPerOrdine: Condotta {
    let motore: MotoreBattaglia
    let tattico: TatticoBattaglia
    let crescente: Bool

    public init(motore: MotoreBattaglia, tattico: TatticoBattaglia, crescente: Bool) {
        self.motore = motore
        self.tattico = tattico
        self.crescente = crescente
    }

    public func prossimoComando(stato: StatoBattaglia, parte: Parte) -> ComandoBattaglia {
        let dalTattico = tattico.prossimoComando(stato: stato)
        switch dalTattico {
        case .seleziona, .piazza, .deseleziona, .dichiaraResa, .ritiraUnita:
            return dalTattico
        default:
            break
        }
        let nemici = stato.sciamiOrdinati.filter { $0.parte == parte.avversaria }
        guard !nemici.isEmpty else { return .fineTurno }
        var miei = stato.sciamiOrdinati.filter {
            $0.parte == parte && !$0.azioneSpesa && !stato.impegnato($0.id)
        }
        if !crescente { miei.reverse() }

        for sciame in miei {
            // Ingaggio del nemico più vicino, poi tiro, poi avanzata: le stesse
            // preferenze del tattico, cambiato soltanto l'ordine dei propri reparti.
            let vicino = nemici.min {
                let da = stato.griglia.distanza(sciame.posizione, $0.posizione)
                let db = stato.griglia.distanza(sciame.posizione, $1.posizione)
                return da != db ? da < db : $0.id < $1.id
            }!
            let ingaggio = ComandoBattaglia.ingaggia(sciame: sciame.id, bersaglio: vicino.id)
            if motore.valida(ingaggio, parte: parte, stato: stato).eValido { return ingaggio }
            for bersaglio in nemici {
                let tiro = ComandoBattaglia.tira(sciame: sciame.id, bersaglio: bersaglio.id)
                if motore.valida(tiro, parte: parte, stato: stato).eValido { return tiro }
            }
            let passi = stato.griglia.vicini(di: sciame.posizione)
                .filter { stato.occupante(di: $0) == nil && !stato.ostacoli.contains($0) }
                .sorted { a, b in
                    let da = stato.griglia.distanza(a, vicino.posizione)
                    let db = stato.griglia.distanza(b, vicino.posizione)
                    return da != db ? da < db : a < b
                }
            if let passo = passi.first,
               stato.griglia.distanza(passo, vicino.posizione)
                   < stato.griglia.distanza(sciame.posizione, vicino.posizione) {
                let mossa = ComandoBattaglia.muovi(sciame: sciame.id, percorso: [passo])
                if motore.valida(mossa, parte: parte, stato: stato).eValido { return mossa }
            }
        }
        return .fineTurno
    }
}
