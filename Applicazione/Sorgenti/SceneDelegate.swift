import UIKit

// Monta l'ambiente dei dati e la schermata d'avvio nella scena dell'applicazione.
// È ciò che fino all'incarico 26 faceva `AppDelegate` nel ciclo di vita senza scene,
// spostato qui senza cambiamenti di comportamento perché l'SDK di iOS 27 esige le
// scene (vedi AppDelegate.swift). Una sola scena: `UIApplicationSupportsMultipleScenes`
// è falso in project.yml, come prima esisteva una sola finestra.

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scenaFinestra = scene as? UIWindowScene else { return }
        let finestra = UIWindow(windowScene: scenaFinestra)
        do {
            let ambiente = try Ambiente()
            finestra.rootViewController = SchermataAvvio(ambiente: ambiente)
        } catch {
            // Senza dati validi nemmeno di fabbrica l'applicazione non può partire:
            // resta la schermata di sistema vuota, caso impossibile con la fabbrica collaudata.
            finestra.rootViewController = UIViewController()
        }
        finestra.makeKeyAndVisible()
        window = finestra
    }
}
