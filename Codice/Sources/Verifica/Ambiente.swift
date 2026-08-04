import Foundation
import Contenuti

/// Le cartelle di fabbrica, esposte dalla libreria perché il guscio da riga di
/// comando non debba importare Contenuti (05 §1.3: i confini valgono anche qui).
public enum Ambiente {
    public static var valoriDiFabbrica: URL { Contenuti.valoriDiFabbrica }
    public static var scenariDiFabbrica: URL { Contenuti.scenariDiVerifica }
}
