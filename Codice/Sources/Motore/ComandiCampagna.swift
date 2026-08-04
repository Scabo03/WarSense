import Foundation
import Dati

/// I comandi discreti della campagna (05 §3.3). Codifica stabile e versionata:
/// i casi si aggiungono, non si rinominano (05 §13.1) — e l'aggiunta non tocca la
/// codifica di quelli esistenti, perché la codifica sintetizzata usa il NOME del
/// caso come chiave (prova in `CompatibilitaGiornaleTest`).
///
/// L'elenco chiuso delle azioni di giornata è quello di 01 §5.6.8.1, sedici voci.
/// Questa unità ne realizza due: la marcia di una casella e il presidio, cioè
/// restare fermi. Le altre quattordici appartengono alle unità che le introducono
/// e non si dichiarano a vuoto.
public enum ComandoCampagna: Hashable, Codable, Sendable {
    /// Marcia in una casella adiacente (01 §5.6.1). In questa unità lo scatto
    /// costa sempre una giornata: il costo in giorni, che dipende dal terreno,
    /// dalla strada e dal volume della colonna (01 §5.6.3.2), è dell'unità
    /// successiva insieme alla marcia lunga.
    case marcia(gruppo: IdGruppo, a: Cella)
    /// Presidio: restare fermi in guardia (01 §5.6.0.6, §5.6.8.1). Stare fermi è
    /// un'azione ordinabile e non un'omissione: un gruppo che non ha agito è
    /// sempre un gruppo che attende una decisione.
    case presidio(gruppo: IdGruppo)
}

/// I motivi chiusi di non ammissibilità sulla mappa (05 §3.2). Ogni caso
/// corrisponde a un termine del vocabolario chiuso; dove la condizione è la stessa
/// della battaglia si riusa lo stesso termine, perché il principio 7 vuole un solo
/// vocabolario in tutto il gioco.
public enum MotivoNonValidoCampagna: String, Codable, Hashable, Sendable, CaseIterable {
    /// Termine condiviso con la battaglia: la casella ospita già una formazione.
    case occupata = "cella.occupata"
    /// Termine condiviso: l'azione della giornata è già stata spesa.
    case azioneGiaSpesa = "comando.non_valido.azione_gia_spesa"
    /// Nuovo della campagna: la destinazione non è adiacente. L'adiacenza è
    /// ortogonale e senza diagonali (01 §5.1), e la casella resta l'unità dello
    /// spostamento: non esistono percorsi di più caselle in un turno (01 §5.6.3.1).
    case nonAdiacente = "casella.non_adiacente"
    /// Nuovo della campagna: la destinazione è fuori dai confini della mappa.
    case fuoriMappa = "casella.fuori_mappa"
    /// Nuovo della campagna: il gruppo indicato non esiste o non è del giocatore.
    case gruppoIgnoto = "comando.non_valido.gruppo_ignoto"
}

/// Esito della validazione di un comando di campagna: la validazione e l'anteprima
/// annunciata sono la stessa cosa (05 §3.2).
public enum EsitoValidazioneCampagna: Hashable, Sendable {
    case valido
    case nonValido(MotivoNonValidoCampagna)

    public var eValido: Bool { if case .valido = self { return true } else { return false } }
    public var motivo: MotivoNonValidoCampagna? {
        if case .nonValido(let m) = self { return m } else { return nil }
    }
}

/// Gli eventi astratti della campagna (05 §3.7): fatti, mai annunci (00 §3.2).
public enum EventoCampagna: Hashable, Codable, Sendable {
    /// Un gruppo è entrato nella casella indicata (01 §5.6.1).
    case marciaEseguita(gruppo: IdGruppo, indiceNome: Int, da: Cella, a: Cella)
    /// Un gruppo è rimasto fermo in guardia (01 §5.6.8.1).
    case presidioOrdinato(gruppo: IdGruppo, indiceNome: Int, casella: Cella)
    /// La giornata si è chiusa perché tutti i gruppi hanno agito (01 §5.6.0.6):
    /// non esiste alcun comando di fine giornata.
    case giornataChiusa(giorno: Int)
    /// La giornata nuova si è aperta e il contatore dei giorni è avanzato.
    case giornataAperta(giorno: Int)
}
