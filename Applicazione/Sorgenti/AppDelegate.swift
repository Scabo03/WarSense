import UIKit

// Punto d'ingresso dell'applicazione. Nella fase B qui si monta la Presentazione
// vera (05 §9); per ora una schermata provvisoria per provare la catena di
// distribuzione, comunque pienamente leggibile da VoiceOver (00 §1).

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let finestra = UIWindow(frame: UIScreen.main.bounds)
        finestra.rootViewController = SchermataProvvisoria()
        finestra.makeKeyAndVisible()
        window = finestra
        return true
    }
}
