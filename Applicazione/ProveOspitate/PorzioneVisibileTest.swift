import XCTest
import Dati
import Motore
import UIKit
@testable import WarSense

/// La porzione visibile della griglia di battaglia e della mappa di campagna non
/// collassa mai: in ogni orientamento e in ogni taglia di carattere accessibile
/// resta maggiore di zero e mostra almeno una riga intera di celle (principio 1,
/// 00 §1.2, 00 §10.4). Prima del rimedio il deck (in battaglia) e la banda dei
/// comandi (in campagna), crescendo con la tipografia dinamica, azzeravano la
/// porzione visibile della griglia in orizzontale e a caratteri grandi (S10): sul
/// dispositivo la griglia era irraggiungibile anche ai gesti di VoiceOver.
///
/// La misura è geometrica; l'apparecchio è quello su cui la prova gira, la finestra
/// prende la dimensione dello schermo (scambiata per l'orizzontale) e la taglia è
/// imposta con `traitOverrides`. Le aree sicure sono quelle che la finestra riceve.
@MainActor
final class PorzioneVisibileTest: XCTestCase {

    private struct Esito { let viewport: CGFloat; let contenuto: CGFloat; let righeVisibili: Int }

    private let taglie: [(String, UIContentSizeCategory)] =
        [("predefinita", .large), ("AXXXL", .accessibilityExtraExtraExtraLarge)]

    private func finestra(oriz: Bool) -> UIWindow {
        let b = UIScreen.main.bounds
        let w = oriz ? max(b.width, b.height) : min(b.width, b.height)
        let h = oriz ? min(b.width, b.height) : max(b.width, b.height)
        return UIWindow(frame: CGRect(x: 0, y: 0, width: w, height: h))
    }

    private func attendi(_ vuote: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<250 where vuote() { try await Task.sleep(nanoseconds: 20_000_000) }
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    private func esito(scroll: UIScrollView, cornici: [Int: [CGRect]]) -> Esito {
        let inf = scroll.contentOffset.y
        let sup = inf + scroll.bounds.height
        var righe = 0
        for (_, celle) in cornici where !celle.isEmpty {
            if celle.allSatisfy({ $0.minY >= inf - 0.5 && $0.maxY <= sup + 0.5 }) { righe += 1 }
        }
        return Esito(viewport: scroll.bounds.height, contenuto: scroll.contentSize.height,
                     righeVisibili: righe)
    }

    private func esitoBattaglia(oriz: Bool, taglia: UIContentSizeCategory) async throws -> Esito {
        let ambiente = try WarSense.Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let fin = finestra(oriz: oriz)
        fin.rootViewController = schermata
        fin.makeKeyAndVisible()
        fin.traitOverrides.preferredContentSizeCategory = taglia
        schermata.loadViewIfNeeded()
        try await attendi { schermata.elementiPerProva.isEmpty }
        fin.layoutIfNeeded()
        defer { fin.isHidden = true; fin.rootViewController = nil }
        let scroll = try XCTUnwrap(schermata.grigliaPerProva.superview as? UIScrollView)
        var perRiga: [Int: [CGRect]] = [:]
        for (cella, el) in schermata.elementiPerProva {
            perRiga[cella.riga, default: []].append(el.accessibilityFrameInContainerSpace)
        }
        return esito(scroll: scroll, cornici: perRiga)
    }

    private func esitoMappa(_ campagna: PartitaCampagna.Taglia, oriz: Bool,
                           taglia: UIContentSizeCategory) async throws -> Esito {
        let ambiente = try WarSense.Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: campagna)
        let schermata = SchermataMappaCampagna(partita: partita)
        let fin = finestra(oriz: oriz)
        fin.rootViewController = schermata
        fin.makeKeyAndVisible()
        fin.traitOverrides.preferredContentSizeCategory = taglia
        schermata.loadViewIfNeeded()
        try await attendi { schermata.elementiPerProva.isEmpty }
        fin.layoutIfNeeded()
        defer { fin.isHidden = true; fin.rootViewController = nil }
        let scroll = try XCTUnwrap(schermata.grigliaPerProva.superview as? UIScrollView)
        var perRiga: [Int: [CGRect]] = [:]
        for (cella, el) in schermata.elementiPerProva {
            perRiga[cella.riga, default: []].append(el.accessibilityFrameInContainerSpace)
        }
        return esito(scroll: scroll, cornici: perRiga)
    }

    func test_00_10_4_la_griglia_di_battaglia_non_collassa() async throws {
        for oriz in [false, true] {
            for (nome, cat) in taglie {
                let e = try await esitoBattaglia(oriz: oriz, taglia: cat)
                let dove = "battaglia \(oriz ? "oriz" : "vert")/\(nome)"
                print("PV \(dove) viewport=\(e.viewport) contenuto=\(e.contenuto) righe=\(e.righeVisibili)")
                XCTAssertGreaterThan(e.viewport, 0, "\(dove): porzione visibile azzerata")
                XCTAssertGreaterThanOrEqual(e.righeVisibili, 1,
                    "\(dove): nessuna riga intera di celle visibile (viewport \(e.viewport))")
            }
        }
    }

    func test_00_10_4_la_mappa_di_campagna_non_collassa() async throws {
        for campagna in PartitaCampagna.Taglia.allCases {
            for oriz in [false, true] {
                for (nome, cat) in taglie {
                    let e = try await esitoMappa(campagna, oriz: oriz, taglia: cat)
                    let dove = "mappa \(campagna.rawValue) \(oriz ? "oriz" : "vert")/\(nome)"
                    print("PV \(dove) viewport=\(e.viewport) contenuto=\(e.contenuto) righe=\(e.righeVisibili)")
                    XCTAssertGreaterThan(e.viewport, 0, "\(dove): porzione visibile azzerata")
                    XCTAssertGreaterThanOrEqual(e.righeVisibili, 1,
                        "\(dove): nessuna riga intera di celle visibile (viewport \(e.viewport))")
                }
            }
        }
    }
}
