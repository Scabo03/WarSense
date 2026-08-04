import Foundation
import Contenuti

/// Le cartelle di fabbrica, esposte dalla libreria perché il guscio da riga di
/// comando non debba importare Contenuti (05 §1.3: i confini valgono anche qui).
public enum Ambiente {
    public static var valoriDiFabbrica: URL { Contenuti.valoriDiFabbrica }
    public static var scenariDiFabbrica: URL { Contenuti.scenariDiVerifica }
    /// Gli scenari di campagna stanno in una sottocartella, perché il caricatore
    /// degli scenari di scontro legge tutti i file della propria cartella.
    public static var scenariCampagnaDiFabbrica: URL {
        Contenuti.scenariDiVerifica.appendingPathComponent("Campagne")
    }
}
