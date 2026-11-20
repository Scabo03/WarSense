import UIKit

// Punto d'ingresso dell'applicazione.
//
// Dall'SDK di iOS 27 il ciclo di vita a scene è OBBLIGATORIO: un'applicazione
// compilata con quell'SDK che crea la propria finestra qui, senza dichiarare una
// configurazione di scena, non parte nemmeno («UIScene life cycle is required for
// apps built with this SDK», incarico 27). La finestra e la schermata d'avvio si
// montano quindi nel delegato di scena (`SceneDelegate`), dichiarato nell'Info.plist
// da `UIApplicationSceneManifest` in project.yml. Qui non resta nulla da fare.

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}
