import Foundation
import Dati

/// Cartelle di valori alternative (05 §12.1): il programma di verifica legge gli
/// stessi Contenuti del gioco, oppure una cartella indicata, oppure una cartella
/// derivata da quella di fabbrica con alcune voci sostituite.
///
/// La sostituzione avviene sui FILE e non su strutture costruite in memoria, per due
/// ragioni. La prima è che così la misura passa dal caricatore vero, con la sua
/// validazione (05 §7.8): una configurazione che il gioco rifiuterebbe non si può
/// misurare per sbaglio. La seconda è che è la forma già prevista per i vantaggi
/// nascosti (05 §12.5) e per la messa a punto su apparecchio (05 §7.2.1).
public enum ValoriVariati {

    /// Una sostituzione su un file che è un OGGETTO: file, chiave di primo livello, valore nuovo.
    public struct Sostituzione: Sendable {
        public let file: String
        public let chiave: String
        public let valore: Sendable
        public init(file: String, chiave: String, valore: Sendable) {
            self.file = file; self.chiave = chiave; self.valore = valore
        }
    }

    /// Una sostituzione su un file che è un ELENCO di oggetti: il campo indicato prende
    /// il valore nuovo in OGNI elemento dell'elenco. Serve alla misura del corpo a corpo
    /// (incarico 09, terzo punto), dove la soglia di disingaggio va disattivata per tutti
    /// gli archetipi insieme, e l'incarico chiede di realizzarla «come parametro dello
    /// scenario del programma di verifica, non come stato del Motore né come canale che
    /// il gioco possa attraversare». Come ogni sostituzione, passa dal caricatore vero e
    /// dalla sua validazione (05 §7.8): il valore deve quindi stare nell'intervallo
    /// ammesso, e per la soglia di disingaggio l'estremo ammesso è 1,0.
    public struct SostituzioneInElenco: Sendable {
        public let file: String
        public let campo: String
        public let valore: Sendable
        public init(file: String, campo: String, valore: Sendable) {
            self.file = file; self.campo = campo; self.valore = valore
        }
    }

    /// I vantaggi nascosti spenti: ogni interruttore a falso, ogni riduzione neutra.
    /// Serve a misurare le probabilità reali sottostanti (01 §13.1, 03 §7.1).
    public static var vantaggiSpenti: [Sostituzione] {
        [Sostituzione(file: "vantaggi-nascosti.json",
                      chiave: "ritirata_avversaria_solo_ultima_riga", valore: false),
         Sostituzione(file: "vantaggi-nascosti.json",
                      chiave: "riduzione_propensione_ritirata_avversaria", valore: 1.0),
         Sostituzione(file: "vantaggi-nascosti.json",
                      chiave: "annientamento_simultaneo_al_giocatore", valore: false)]
    }

    /// La soglia di disingaggio disattivata: portata a 1,0 su ogni archetipo di
    /// archetipi.json. È l'estremo che il caricatore ammette (05 §7.8 valida la soglia
    /// in (0, 1]); a 1,0 la mischia prosegue fino alla distruzione, perché un reparto
    /// vivo ha sempre serbatoio > 0 e quindi perdite/ingresso < 1, e il ramo di
    /// disingaggio in `MotoreBattaglia.risolvi` (guardia `perdite*1000/ingresso >= soglia`)
    /// non scatta mai. È un artificio di misura e non tocca né il Motore né i file di
    /// gioco: la cartella derivata è temporanea e vive solo per la corsa.
    public static var disingaggioDisattivato: [SostituzioneInElenco] {
        [SostituzioneInElenco(file: "archetipi.json", campo: "soglia_disingaggio", valore: 1.0)]
    }

    /// Costruisce una cartella di valori derivata e la carica. La cartella temporanea
    /// resta finché il chiamante non la rimuove: il percorso è restituito.
    public static func carica(base: URL,
                              sostituendo sostituzioni: [Sostituzione] = [],
                              inElenco elenco: [SostituzioneInElenco] = [])
        throws -> (valori: ValoriDiGioco, cartella: URL?) {
        guard !sostituzioni.isEmpty || !elenco.isEmpty else {
            return (try CaricatoreValori.carica(da: base), nil)
        }
        let cartella = FileManager.default.temporaryDirectory
            .appendingPathComponent("verifica-valori-" + UUID().uuidString)
        try FileManager.default.copyItem(at: base, to: cartella)

        // Sostituzioni sui file che sono oggetti.
        var perFile: [String: [Sostituzione]] = [:]
        for s in sostituzioni { perFile[s.file, default: []].append(s) }
        for (file, voci) in perFile.sorted(by: { $0.key < $1.key }) {
            let url = cartella.appendingPathComponent(file)
            guard var contenuto = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
                    as? [String: Any] else {
                throw ErroreDati(chiave: "errore.dati.file_malformato", file: file)
            }
            for voce in voci { contenuto[voce.chiave] = voce.valore }
            try JSONSerialization.data(withJSONObject: contenuto).write(to: url)
        }

        // Sostituzioni sui file che sono elenchi di oggetti: il campo cambia in ogni elemento.
        var perFileElenco: [String: [SostituzioneInElenco]] = [:]
        for s in elenco { perFileElenco[s.file, default: []].append(s) }
        for (file, voci) in perFileElenco.sorted(by: { $0.key < $1.key }) {
            let url = cartella.appendingPathComponent(file)
            guard var contenuto = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
                    as? [[String: Any]] else {
                throw ErroreDati(chiave: "errore.dati.file_malformato", file: file)
            }
            for indice in contenuto.indices {
                for voce in voci { contenuto[indice][voce.campo] = voce.valore }
            }
            try JSONSerialization.data(withJSONObject: contenuto).write(to: url)
        }

        return (try CaricatoreValori.carica(da: cartella), cartella)
    }

    /// Esegue un lavoro su valori derivati e rimuove la cartella temporanea al termine.
    public static func con<T>(base: URL,
                              sostituendo sostituzioni: [Sostituzione] = [],
                              inElenco elenco: [SostituzioneInElenco] = [],
                              _ lavoro: (ValoriDiGioco) throws -> T) throws -> T {
        let (valori, cartella) = try carica(base: base, sostituendo: sostituzioni, inElenco: elenco)
        defer { if let cartella { try? FileManager.default.removeItem(at: cartella) } }
        return try lavoro(valori)
    }
}
