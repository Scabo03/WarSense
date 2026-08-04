// swift-tools-version: 6.0
// Pacchetto del gioco. Struttura dei bersagli e regole di dipendenza: documento 05, §1.2 e §1.3.
// I confini sono imposti dal compilatore e verificati dal collaudo ConfiniTest (05 §14.5).
import PackageDescription

let package = Package(
    name: "WarSense",
    defaultLocalization: "it",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Dati", targets: ["Dati"]),
        .library(name: "Motore", targets: ["Motore"]),
        .library(name: "Sessione", targets: ["Sessione"]),
        .library(name: "Contenuti", targets: ["Contenuti"]),
        .library(name: "Segnali", targets: ["Segnali"]),
    ],
    targets: [
        // Dati: caricamento e validazione dei file dei valori e dei testi. Importa soltanto Foundation.
        .target(name: "Dati"),
        // Motore: logica di gioco. Importa soltanto Foundation e Dati.
        .target(name: "Motore", dependencies: ["Dati"]),
        // Sessione: orchestratore, giornale, istantanee. Importa soltanto Motore, Dati e Foundation.
        .target(name: "Sessione", dependencies: ["Motore", "Dati"]),
        // Contenuti: i file veri (valori, testi). Nessun codice oltre l'esposizione del bundle.
        .target(name: "Contenuti", resources: [.copy("Valori"), .copy("Testi"), .copy("Suoni"),
                                               .copy("Scenari")]),
        // Segnali: punto centrale dei segnali. Compila su ogni piattaforma: nucleo puro
        // più parti di piattaforma dietro compilazione condizionale (RDA-48).
        .target(name: "Segnali", dependencies: ["Motore", "Dati"]),
        // Verifica: il programma di verifica del bilanciamento, senza interfaccia (fase C,
        // 05 §12). È una libreria perché il fumo delle simulazioni sia collaudabile
        // come qualunque altro bersaglio (05 §14.7, RDA-58); l'eseguibile è il solo
        // guscio da riga di comando.
        .target(name: "Verifica", dependencies: ["Sessione", "Motore", "Dati", "Contenuti"]),
        .executableTarget(name: "StrumentoVerifica", dependencies: ["Verifica"]),
        // Collaudo.
        .testTarget(name: "DatiTest", dependencies: ["Dati", "Contenuti"]),
        .testTarget(name: "MotoreTest", dependencies: ["Motore", "Dati", "Contenuti"]),
        .testTarget(name: "SessioneTest", dependencies: ["Sessione", "Motore", "Dati", "Contenuti"]),
        .testTarget(name: "SegnaliTest", dependencies: ["Segnali", "Dati", "Contenuti"]),
        .testTarget(name: "VerificaTest", dependencies: ["Verifica", "Motore", "Dati", "Contenuti"]),
        .testTarget(name: "ConfiniTest", dependencies: []),
    ]
)
