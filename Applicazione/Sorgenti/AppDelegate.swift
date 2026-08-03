import UIKit

// Punto d'ingresso: monta l'ambiente dei dati e la schermata d'avvio.
// La schermata provvisoria della catena di distribuzione è superata dalla fase B.

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let finestra = UIWindow(frame: UIScreen.main.bounds)
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
        return true
    }
}
