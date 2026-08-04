import Foundation

/// Espone la copia di fabbrica dei contenuti (05 §7.1): l'albero Valori e l'albero Testi.
public enum Contenuti {
    public static var valoriDiFabbrica: URL { Bundle.module.url(forResource: "Valori", withExtension: nil)! }
    public static var testiDiFabbrica: URL { Bundle.module.url(forResource: "Testi", withExtension: nil)! }
    public static var suoniDiFabbrica: URL { Bundle.module.url(forResource: "Suoni", withExtension: nil)! }
    /// Gli scenari dichiarativi del programma di verifica (03 §9.6, 05 §12.2).
    public static var scenariDiVerifica: URL { Bundle.module.url(forResource: "Scenari", withExtension: nil)! }
}
