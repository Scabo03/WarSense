import XCTest

/// Prova sul campo della catena dei testi esterni (incarico fase 5, sezione 2; 05 §8, RDA-09).
/// Verifica i comportamenti d'API da cui dipende l'intero impianto dei testi:
/// caricamento da cartella sostituibile, plurali del meccanismo di sistema (00 §14.3),
/// bundle radicato sul pacchetto di lingua, cache dei Bundle alla sostituzione dei file.
/// Non usa il modulo Dati: prova le API nude, perché il modulo verrà costruito sopra ciò che qui risulta vero.
final class CatenaTestiEsterniTest: XCTestCase {

    private var cartella: URL!

    override func setUpWithError() throws {
        cartella = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("catena-testi-\(UUID().uuidString)")
        let lproj = cartella.appendingPathComponent("it.lproj")
        try FileManager.default.createDirectory(at: lproj, withIntermediateDirectories: true)

        let strings = """
        "battaglia.turno" = "Turno %d";
        "gruppo.in_marcia" = "in marcia, %#@giorni@";
        """
        try strings.write(to: lproj.appendingPathComponent("Annunci.strings"), atomically: true, encoding: .utf8)

        let stringsdict = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>gruppo.in_marcia</key>
          <dict>
            <key>NSStringLocalizedFormatKey</key><string>in marcia, %#@giorni@</string>
            <key>giorni</key>
            <dict>
              <key>NSStringFormatSpecTypeKey</key><string>NSStringPluralRuleType</string>
              <key>NSStringFormatValueTypeKey</key><string>d</string>
              <key>one</key><string>%d giorno al termine</string>
              <key>other</key><string>%d giorni al termine</string>
            </dict>
          </dict>
        </dict></plist>
        """
        try stringsdict.write(to: lproj.appendingPathComponent("Annunci.stringsdict"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: cartella)
    }

    /// 1. Un Bundle costruito sulla cartella esterna risolve le chiavi dei .strings.
    func test_caricamento_da_cartella_esterna() throws {
        let bundle = try XCTUnwrap(Bundle(url: cartella))
        let frase = bundle.localizedString(forKey: "battaglia.turno", value: "‼️", table: "Annunci")
        XCTAssertEqual(String(format: frase, locale: Locale(identifier: "it"), 7), "Turno 7")
    }

    /// 2. I plurali sono risolti dal meccanismo di sistema (.stringsdict), non a mano (00 §14.3).
    func test_plurali_di_sistema_da_cartella_esterna() throws {
        let bundle = try XCTUnwrap(Bundle(url: cartella))
        let formato = bundle.localizedString(forKey: "gruppo.in_marcia", value: "‼️", table: "Annunci")
        let it = Locale(identifier: "it")
        XCTAssertEqual(String(format: formato, locale: it, 1), "in marcia, 1 giorno al termine")
        XCTAssertEqual(String(format: formato, locale: it, 3), "in marcia, 3 giorni al termine")
    }

    /// 3. Il bundle radicato direttamente sul pacchetto di lingua (it.lproj) funziona:
    /// è la forma con cui ogni testo dichiara la propria lingua (00 §14.4, 05 §8.3).
    func test_bundle_radicato_sul_pacchetto_di_lingua() throws {
        let lproj = cartella.appendingPathComponent("it.lproj")
        let bundle = try XCTUnwrap(Bundle(url: lproj))
        let formato = bundle.localizedString(forKey: "gruppo.in_marcia", value: "‼️", table: "Annunci")
        XCTAssertEqual(String(format: formato, locale: Locale(identifier: "it"), 2), "in marcia, 2 giorni al termine")
    }

    /// 4. Insidia della cache: Bundle è memorizzato per percorso, quindi la sostituzione dei file
    /// sullo stesso percorso può restituire testi vecchi. Il modulo Dati deve caricare da una
    /// copia di lavoro a percorso unico per sessione. Questa prova documenta il comportamento reale.
    func test_comportamento_cache_alla_sostituzione() throws {
        let lproj = cartella.appendingPathComponent("it.lproj")
        let primo = try XCTUnwrap(Bundle(url: cartella))
        _ = primo.localizedString(forKey: "battaglia.turno", value: "‼️", table: "Annunci")

        let strings = "\"battaglia.turno\" = \"Giro %d\";"
        try strings.write(to: lproj.appendingPathComponent("Annunci.strings"), atomically: true, encoding: .utf8)

        let secondo = try XCTUnwrap(Bundle(url: cartella))
        let rilettura = secondo.localizedString(forKey: "battaglia.turno", value: "‼️", table: "Annunci")

        // Copia di lavoro su percorso nuovo: deve leggere il contenuto aggiornato.
        let copia = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("catena-testi-copia-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: cartella, to: copia)
        defer { try? FileManager.default.removeItem(at: copia) }
        let terzo = try XCTUnwrap(Bundle(url: copia))
        let daCopia = terzo.localizedString(forKey: "battaglia.turno", value: "‼️", table: "Annunci")
        XCTAssertEqual(String(format: daCopia, locale: Locale(identifier: "it"), 4), "Giro 4",
                       "La copia di lavoro a percorso unico deve sempre leggere i file correnti")

        // Documenta (senza vincolare) se la rilettura sullo stesso percorso sia fresca o in cache.
        print("Rilettura sullo stesso percorso dopo sostituzione: \(rilettura)")
    }
}
