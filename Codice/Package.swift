// swift-tools-version: 6.0
// Pacchetto del gioco. Struttura dei bersagli e regole di dipendenza: documento 05, §1.2 e §1.3.
// I confini sono imposti dal compilatore e verificati dal collaudo ConfiniTest (05 §14.5).
import PackageDescription

let package = Package(
    name: "WarSense",
    defaultLocalization: "it",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        // Dati: caricamento e validazione dei file dei valori e dei testi. Importa soltanto Foundation.
        .target(name: "Dati"),
        // Motore: logica di gioco. Importa soltanto Foundation e Dati.
        .target(name: "Motore", dependencies: ["Dati"]),
        // Sessione: orchestratore, giornale, istantanee. Importa soltanto Motore, Dati e Foundation.
        .target(name: "Sessione", dependencies: ["Motore", "Dati"]),
        // Contenuti: i file veri (valori, testi). Nessun codice oltre l'esposizione del bundle.
        .target(name: "Contenuti", resources: [.copy("Valori"), .copy("Testi")]),
        // Verifica: programma di verifica del bilanciamento, senza interfaccia (fase C).
        .executableTarget(name: "Verifica", dependencies: ["Sessione", "Motore", "Dati", "Contenuti"]),
        // Collaudo.
        .testTarget(name: "DatiTest", dependencies: ["Dati", "Contenuti"]),
        .testTarget(name: "MotoreTest", dependencies: ["Motore", "Dati", "Contenuti"]),
        .testTarget(name: "SessioneTest", dependencies: ["Sessione", "Motore", "Dati", "Contenuti"]),
        .testTarget(name: "ConfiniTest", dependencies: []),
    ]
)
