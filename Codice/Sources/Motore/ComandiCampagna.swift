import Foundation
import Dati

/// I comandi discreti della campagna (05 §3.3). Codifica stabile e versionata:
/// i casi si aggiungono, non si rinominano (05 §13.1) — e l'aggiunta non tocca la
/// codifica di quelli esistenti, perché la codifica sintetizzata usa il NOME del
/// caso come chiave (prova in `CompatibilitaGiornaleTest`).
///
/// L'elenco chiuso delle azioni di giornata è quello di 01 §5.6.8.1, sedici voci.
/// Questa unità ne realizza due: la marcia di una o più giornate e il presidio,
/// cioè restare fermi. A queste si aggiunge la REVOCA della marcia, che 01 §5.6.8.1
/// dichiara espressamente NON un'azione (non consuma la giornata): è un comando
/// proprio e non un annullamento (RDA-76). Le altre azioni appartengono alle unità
/// che le introducono e non si dichiarano a vuoto.
public enum ComandoCampagna: Hashable, Codable, Sendable {
    /// Marcia in una casella adiacente (01 §5.6.1), con il COSTO IN GIORNI dello
    /// scatto (01 §5.6.3.1, §5.6.3.3). Il costo viaggia dentro il comando e non si
    /// ricalcola alla riapplicazione: il giornale è anche il formato di salvataggio,
    /// e una campagna ripresa deve ripercorrere gli scatti che è costata, non quelli
    /// che costerebbero oggi (RDA-75). Il valore viene dai dati (`marcia-campagna.json`),
    /// dove i pesi della casella di partenza e di arrivo, la strada e la strettoia
    /// confluiscono nella medesima grandezza; con costo maggiore di uno la marcia è
    /// lunga e il gruppo resta nella casella di partenza finché non l'ha compiuta.
    case marcia(gruppo: IdGruppo, a: Cella, giorni: Int)
    /// Presidio: restare fermi in guardia (01 §5.6.0.6, §5.6.8.1). Stare fermi è
    /// un'azione ordinabile e non un'omissione: un gruppo che non ha agito è
    /// sempre un gruppo che attende una decisione.
    case presidio(gruppo: IdGruppo)
    /// Revoca dell'ordine di marcia (01 §5.6.3.3, §5.6.8.1, RDA-76). Si può compiere
    /// in qualunque momento e costa TUTTI i giorni già spesi. Non è un'azione e non
    /// consuma la giornata; ma il gruppo che revoca ha già speso la propria giornata
    /// con l'ordine di marcia e non compie altro quel giorno (decisione del titolare,
    /// RDA-100): perde i giorni spesi e resta senza azione per la giornata corrente.
    /// Comando proprio che si AGGIUNGE alla sequenza, non un troncamento del giornale.
    case revocaMarcia(gruppo: IdGruppo)
    /// Divisione del gruppo (01 §5.6.0.2, §5.6.8.1): COSTA l'azione della giornata.
    /// Il giocatore sceglie quali reparti staccare — per indice nella composizione,
    /// perché la divisione lavora su reparti INTERI e non sui singoli atomi — e la
    /// casella adiacente `a` in cui collocare il distaccamento, che non nasce mai
    /// nella casella di origine. Il distaccamento nasce avendo GIÀ AGITO, perché il
    /// collocamento è uno spostamento; e il gruppo di origine spende l'azione con la
    /// divisione. Nessuna delle due parti può restare vuota. Il distaccamento riceve
    /// un nome nuovo dalla lista chiusa (RDA-106).
    case divisione(gruppo: IdGruppo, repartiStaccati: [Int], a: Cella)
    /// Riunione di due gruppi adiacenti (01 §5.6.0.3, §5.6.8.1): NON costa l'azione,
    /// perché non è un'azione. Il gruppo risultante conserva il nome del MAGGIORE dei
    /// due (per volume, a parità l'id minore) e la sua casella; l'altro sparisce e il
    /// suo nome non si riusa. Il risultante si considera avere già agito se almeno uno
    /// dei due vi confluiti aveva già agito, o un gruppo che ha marciato potrebbe
    /// fondersi con uno fermo e rimettersi in marcia lo stesso giorno (RDA-106).
    case riunione(gruppo: IdGruppo, con: IdGruppo)
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
    /// Nuovo della campagna: il costo in giorni dichiarato dal comando non è
    /// quello che i dati prescrivono per quello scatto (01 §5.6.3.1). Non nasce
    /// da un gesto del giocatore — la Presentazione il costo lo chiede al Motore —
    /// ma da un giornale estraneo o manomesso, e va dichiarato come ogni altro
    /// rifiuto invece di essere applicato in silenzio.
    case costoNonCoerente = "comando.non_valido.costo_non_coerente"
    /// Nuovo della campagna: l'annullamento non retrocede oltre la giornata in
    /// corso (05 §6.5). Non è il rifiuto di un comando ma di un annullamento, e
    /// riusa questo insieme perché il vocabolario dei motivi è uno solo (00 §9.4).
    case oltreLaGiornataInCorso = "campagna.non_si_torna_oltre_la_giornata"
    /// Nuovo della campagna: la revoca è stata chiesta per un gruppo che non è in
    /// marcia (01 §5.6.3.3). Non nasce da un gesto del giocatore — la revoca si offre
    /// soltanto per i gruppi in marcia — ma da un giornale estraneo o manomesso, e
    /// va dichiarato come ogni altro rifiuto invece di essere applicato in silenzio.
    case gruppoNonInMarcia = "comando.non_valido.gruppo_non_in_marcia"
    /// Nuovo della campagna: il gruppo è in marcia lunga, cioè inchiodato, e non può
    /// dividersi né riunirsi finché non l'ha compiuta (01 §5.6.3.5: «è di fatto
    /// immobile … e non può sfilarsi se non perdendo i giorni già spesi»). È ciò che
    /// il giocatore sente se prova a dividere o riunire un gruppo in marcia (RDA-106).
    case gruppoInchiodato = "comando.non_valido.gruppo_inchiodato"
    /// Nuovo della campagna: la divisione lascerebbe una parte vuota, oppure nomina
    /// reparti inesistenti o ripetuti (01 §5.6.0.2: nessuna delle due parti può
    /// restare vuota, e si lavora su reparti interi). La Presentazione offre solo
    /// selezioni valide; questo rifiuto morde su un giornale estraneo o manomesso.
    case divisioneImpropria = "comando.non_valido.divisione_impropria"
    /// Nuovo della campagna: i due gruppi non si possono riunire — è lo stesso gruppo,
    /// o non sono adiacenti, o non sono entrambi del giocatore (01 §5.6.0.3).
    case riunioneImpropria = "comando.non_valido.riunione_impropria"
    /// Nuovo della campagna: la lista chiusa dei nomi è esaurita e il distaccamento
    /// non riceverebbe un nome (01 §5.6.0.4). I nomi non si riusano, sicché la lista
    /// impone un tetto pratico al numero di gruppi CREATI in una campagna, in tensione
    /// dichiarata con 01 §5.6.0.1 («non esiste alcun tetto»): scostamento S16, mitigato
    /// da una lista ampia; il tetto morde solo su campagne con moltissime divisioni.
    case nomiEsauriti = "comando.non_valido.nomi_esauriti"
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
    /// Un gruppo ha ricevuto l'ordine di marciare verso una casella adiacente, che
    /// gli costerà `giorni` (01 §5.6.1, §5.6.3.1). NON è ancora entrato: con la
    /// marcia lunga l'ingresso avviene alla risoluzione di fine giornata.
    case marciaOrdinata(gruppo: IdGruppo, nome: IdentificatoreDati, da: Cella, a: Cella, giorni: Int)
    /// Una marcia si è COMPIUTA e il gruppo è entrato nella casella di arrivo, alla
    /// chiusura della giornata (01 §5.6.3.3, §5.17.1). Fatto non deciso dal giocatore.
    case marciaCompiuta(gruppo: IdGruppo, nome: IdentificatoreDati, da: Cella, a: Cella)
    /// Una marcia è stata revocata: il gruppo resta in `casella` e perde `giorniPersi`
    /// giorni (01 §5.6.3.3, RDA-76).
    case marciaRevocata(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella, giorniPersi: Int)
    /// Un gruppo è rimasto fermo in guardia (01 §5.6.8.1).
    case presidioOrdinato(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// La giornata si è chiusa perché tutti i gruppi hanno concluso (01 §5.6.0.6):
    /// non esiste alcun comando di fine giornata.
    case giornataChiusa(giorno: Int)
    /// La giornata nuova si è aperta e il contatore dei giorni è avanzato.
    case giornataAperta(giorno: Int)
    /// Un gruppo si è diviso: il distaccamento `distaccamento`, di nome `nomeDistaccamento`,
    /// è nato nella casella adiacente `a` (01 §5.6.0.2). Fatto DECISO dal giocatore:
    /// fa l'annuncio immediato ma non entra nel registro (01 §5.17.1, RDA-104).
    case gruppoDiviso(gruppo: IdGruppo, nome: IdentificatoreDati,
                      distaccamento: IdGruppo, nomeDistaccamento: IdentificatoreDati, a: Cella)
    /// Due gruppi si sono riuniti nel gruppo `risultante`, di nome `nome`, nella
    /// casella `casella`; il gruppo `assorbito` è sparito (01 §5.6.0.3).
    case gruppiRiuniti(risultante: IdGruppo, nome: IdentificatoreDati,
                       assorbito: IdGruppo, casella: Cella)
}
