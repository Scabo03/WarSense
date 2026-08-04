import Foundation
import Dati
import Motore

/// Una condotta che manovra, costruita per imitare il modo di giocare del titolare
/// e metterlo a confronto con quello del tattico, che concentra.
///
/// Avvertenza dichiarata: è una IMITAZIONE scritta da chi misura, non il titolare.
/// Se perde, la misura dice che questa condotta perde contro il tattico, non che
/// manovrare sia impossibile. Vale come indizio forte se perde anche là dove il
/// vantaggio dovrebbe esserci per costruzione, cioè nel contatto multiplo.
///
/// Che cosa fa, nell'ordine:
/// 1. schiera come il tattico, perché il confronto riguardi la condotta e non lo schieramento;
/// 2. non ingaggia MAI per primo con la fanteria pesante, per non offrirla al contatto multiplo;
/// 3. preferisce ingaggiare un bersaglio GIÀ ingaggiato da un proprio reparto, cioè cerca il due e tre contro uno;
/// 4. tira al bersaglio più VICINO, per sfruttare la vicinanza, anziché al più adatto;
/// 5. avanza con i reparti leggeri, che costano meno volume, e tiene indietro i pesanti finché non c'è un bersaglio già impegnato.
public struct CondottaManovriera: Condotta {

    let motore: MotoreBattaglia
    let tattico: TatticoBattaglia
    /// Gli archetipi che questa condotta considera pesanti, cioè da non esporre per
    /// primi: quelli il cui volume per atomo supera la mediana degli archetipi.
    let pesanti: Set<IdentificatoreDati>

    public init(motore: MotoreBattaglia, tattico: TatticoBattaglia) {
        self.motore = motore
        self.tattico = tattico
        let volumi = motore.valori.archetipi.values.map(\.volumePerAtomo).sorted()
        let mediana = volumi[volumi.count / 2]
        self.pesanti = Set(motore.valori.archetipi.values
            .filter { $0.volumePerAtomo >= mediana && $0.offesaTiro == nil }
            .map(\.identificatore))
    }

    public func prossimoComando(stato: StatoBattaglia, parte: Parte) -> ComandoBattaglia {
        // 1. Lo schieramento è quello del tattico: si confrontano le condotte, non i mazzi.
        let dalTattico = tattico.prossimoComando(stato: stato)
        switch dalTattico {
        case .seleziona, .piazza, .deseleziona, .dichiaraResa, .ritiraUnita:
            return dalTattico
        default:
            break
        }

        let nemici = stato.sciamiOrdinati.filter { $0.parte == parte.avversaria }
        guard !nemici.isEmpty else { return .fineTurno }
        let miei = stato.sciamiOrdinati.filter {
            $0.parte == parte && !$0.azioneSpesa && !stato.impegnato($0.id)
        }

        // 2 e 3. Ingaggi: prima di tutto piombare su chi è già impegnato dai miei.
        let giaImpegnatiDaiMiei = Set(stato.contatti.compactMap { contatto -> IdSciame? in
            for id in [contatto.primo, contatto.secondo]
            where stato.sciami[id]?.parte == parte {
                return contatto.altro(rispettoA: id)
            }
            return nil
        })
        for sciame in miei {
            for bersaglio in nemici where giaImpegnatiDaiMiei.contains(bersaglio.id) {
                let comando = ComandoBattaglia.ingaggia(sciame: sciame.id, bersaglio: bersaglio.id)
                if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
            }
        }
        // Ingaggio di apertura consentito ai soli reparti NON pesanti: la pesante
        // non si offre per prima, perché chi ingaggia per primo può essere circondato
        // nel turno successivo dell'avversario.
        for sciame in miei where !pesanti.contains(sciame.archetipo) {
            for bersaglio in nemici {
                let comando = ComandoBattaglia.ingaggia(sciame: sciame.id, bersaglio: bersaglio.id)
                if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
            }
        }

        // 4. Tiro al bersaglio più vicino, per sfruttare la vicinanza.
        for sciame in miei {
            let perDistanza = nemici.sorted { a, b in
                let da = stato.griglia.distanza(sciame.posizione, a.posizione)
                let db = stato.griglia.distanza(sciame.posizione, b.posizione)
                return da != db ? da < db : a.id < b.id
            }
            for bersaglio in perDistanza {
                let comando = ComandoBattaglia.tira(sciame: sciame.id, bersaglio: bersaglio.id)
                if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
            }
        }

        // 5. Avanzano i leggeri; i pesanti si muovono solo verso un bersaglio già impegnato.
        for sciame in miei {
            let bersagliUtili = pesanti.contains(sciame.archetipo)
                ? nemici.filter { giaImpegnatiDaiMiei.contains($0.id) }
                : nemici
            guard let vicino = bersagliUtili.min(by: { a, b in
                let da = stato.griglia.distanza(sciame.posizione, a.posizione)
                let db = stato.griglia.distanza(sciame.posizione, b.posizione)
                return da != db ? da < db : a.id < b.id
            }) else { continue }
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
                let comando = ComandoBattaglia.muovi(sciame: sciame.id, percorso: [passo])
                if motore.valida(comando, parte: parte, stato: stato).eValido { return comando }
            }
        }
        return .fineTurno
    }
}
