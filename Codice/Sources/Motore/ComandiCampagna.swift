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
    /// Sosta con raccolta automatica (01 §5.6.5, §5.6.8.1): il gruppo si ferma,
    /// s'accampa e raccoglie quanto serve nelle zone circostanti, in automatico. È
    /// un'AZIONE dell'elenco chiuso, non una voce nuova, e consuma la giornata. È la
    /// via ordinaria quando la catena si interrompe (01 §5.6.5.1): riduce di uno la
    /// sosta dovuta dal taglio, e quando la sosta è saldata il gruppo torna rifornito
    /// (RDA-107). Vale sia per l'autonomia sia per la sosta imposta dal taglio.
    case sostaConRaccolta(gruppo: IdGruppo)
    /// ESPLORAZIONE (01 §5.4, §5.6.8.1): riservata alle formazioni di ricognizione. Consuma
    /// l'azione della giornata; l'esploratore resta dov'è e osserva un'area più ampia del
    /// raggio ordinario. Il costo vero è in RISCHIO — gli esploratori possono perdersi,
    /// tornare a mani vuote o farsi notare — reso DETERMINISTICO dal confronto fra la loro
    /// competenza e l'insidiosità della zona (01 §5.4, §12): nessuna estrazione. Voce
    /// dell'elenco chiuso 01 §5.6.8.1, non nuova.
    case esplorazione(gruppo: IdGruppo)
    /// IMBOSCATA (01 §5.11, §5.6.8.1): riservata ai gruppi armati. Colloca il gruppo in
    /// agguato nella propria casella; resta lì attraverso le giornate, e se un gruppo armato
    /// avversario vi entra l'imboscata scatta alla risoluzione di fine giornata. Voce
    /// dell'elenco chiuso.
    case imboscata(gruppo: IdGruppo)
    /// REVOCA dell'imboscata (01 §5.11, RDA-76): come la revoca della marcia, NON è un'azione
    /// (01 §5.6.8.1) e si compie in qualunque momento su un gruppo appostato, che così torna
    /// libero di agire dalla giornata successiva. Il gruppo ha già consumato la propria
    /// giornata restando in agguato e non compie altro il giorno in cui lo si revoca (come la
    /// revoca della marcia, RDA-100). Non entra nel registro: non è fra i fatti che l'incarico
    /// vi fa entrare, e la revoca della marcia vi sta solo per un'eccezione dichiarata (RDA-104).
    case revocaImboscata(gruppo: IdGruppo)
    /// SABOTAGGIO (01 §5.10.2, §5.6.8.1): lo può ordinare un gruppo armato o una formazione di
    /// ricognizione che condivide la casella con una formazione non armata avversaria (01 §6.1,
    /// §5.10). Consuma l'azione e disperde la formazione bersaglio, il cui carico è perduto.
    /// Compiuto da un gruppo armato riesce sempre; compiuto da esploratori riesce solo se la
    /// loro competenza raggiunge la soglia di protezione del bersaglio, altrimenti fallisce e
    /// gli esploratori si fanno notare (deterministico, 01 §12). Il bersaglio è la formazione
    /// non armata avversaria co-locata, non un parametro del comando: non apre battaglia (01 §5.10).
    case sabotaggio(gruppo: IdGruppo)
    /// STUDIO APPROFONDITO (01 §5.10.2, §5.6.8.1): riservato alle formazioni di ricognizione che
    /// condividono la casella con una formazione non armata avversaria. Consuma l'azione e porta
    /// a confermato la conoscenza della formazione studiata — composizione, carico e direzione
    /// di marcia (01 §5.10.2). Non apre battaglia. Il bersaglio è la formazione co-locata.
    case studioApprofondito(gruppo: IdGruppo)
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
    /// Nuovo della campagna: il gruppo deve fermarsi a rifornirsi (01 §5.2.2.4) e non
    /// può marciare finché la sosta dovuta non è saldata. È ciò che il giocatore sente
    /// se prova a marciare un gruppo tenuto fermo dal taglio (RDA-107).
    case deveRifornirsi = "comando.non_valido.deve_rifornirsi"
    /// Nuovo della campagna: l'azione è riservata a una categoria che il gruppo non ha
    /// (01 §5.2, §5.6.8.1). Esplorazione e studio approfondito sono delle sole formazioni di
    /// ricognizione; l'imboscata dei soli gruppi armati; il sabotaggio di armati o esploratori,
    /// mai di una formazione non armata. La Presentazione offre solo le azioni ammesse dalla
    /// categoria; questo rifiuto morde su un giornale estraneo o manomesso.
    case categoriaNonAmmessa = "comando.non_valido.categoria_non_ammessa"
    /// Nuovo della campagna: sabotaggio o studio ordinato dove non c'è una formazione non armata
    /// avversaria da colpire (01 §5.10): il bersaglio è la formazione co-locata, e senza di essa
    /// l'azione non ha oggetto.
    case nessunBersaglio = "comando.non_valido.nessun_bersaglio"
    /// Nuovo della campagna: la revoca dell'imboscata è stata chiesta per un gruppo che non è in
    /// agguato (01 §5.11). Come la revoca della marcia su un gruppo non in marcia, morde su un
    /// giornale estraneo o manomesso.
    case gruppoNonInAgguato = "comando.non_valido.gruppo_non_in_agguato"
}

/// L'esito DETERMINISTICO di un'esplorazione (01 §5.4): la riuscita discende dalla
/// competenza degli esploratori e dalle condizioni, mai da un'estrazione (01 §12). I quattro
/// esiti sono in ordine di margine decrescente fra competenza e insidiosità della zona:
/// riuscita, a mani vuote, notati, perduti.
public enum EsitoEsplorazione: String, Codable, Hashable, Sendable, CaseIterable {
    /// L'area esplorata diventa conoscenza fresca dell'esploratore (01 §5.3).
    case riuscita
    /// Gli esploratori tornano a mani vuote: nessuna conoscenza acquisita, ma incolumi.
    case aManiVuote
    /// Gli esploratori si fanno NOTARE: la loro casella diventa avvistata per l'avversario
    /// (01 §5.4, §5.10.2), e nessuna conoscenza è acquisita.
    case notati
    /// Gli esploratori si PERDONO: la formazione va perduta (01 §5.4.2, personale formato).
    case perduti
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
    /// Il rifornimento di un gruppo si è interrotto: forze nemiche alle spalle
    /// (01 §5.2.2.2). Fatto non deciso dal giocatore, alla risoluzione di fine giornata.
    case rifornimentoInterrotto(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// Un gruppo è stato costretto alla sosta di rifornimento (01 §5.2.2.4).
    case sostaDiRifornimento(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// Il rifornimento di un gruppo è ripreso — nemici tolti dalle spalle o zona di
    /// rifornimento raggiunta (01 §5.2.2, §5.2.2.6).
    case rifornimentoRipreso(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// Una formazione avversaria è stata AVVISTATA dal giocatore in una casella che
    /// osserva (01 §5.6.11, 02 §8.2.1): la sola mossa avversaria che il giocatore
    /// apprende passa dagli stati di conoscenza, e questo evento la annuncia dove la
    /// conoscenza è confermato. NON porta il nome della formazione né il suo volume
    /// (02 §6.4.1): dichiara il fatto — una formazione avversaria, e dove — e nulla di
    /// più. È l'analogo di campagna di `battaglia.spostamento_avversario`. La parte
    /// avversaria non riceve mai questo evento sui gruppi del giocatore, perché
    /// l'evento è già proiettato per l'osservatore (`proiettaPerIlGiocatore`).
    case formazioneAvversariaAvvistata(casella: Cella)
    /// Un'esplorazione si è compiuta, con il suo ESITO deterministico (01 §5.4). L'annuncio
    /// varia con l'esito: area rivelata, a mani vuote, notati, perduti. Porta la PARTE che
    /// esplora — e non solo l'identificatore del gruppo — perché con l'esito `perduti` il
    /// gruppo è rimosso e non sarebbe più rintracciabile per stabilire a chi consegnare
    /// l'annuncio: la proiezione lo consegna al solo giocatore guardando la parte.
    case esplorazioneCompiuta(parte: Parte, gruppo: IdGruppo, nome: IdentificatoreDati,
                              casella: Cella, esito: EsitoEsplorazione)
    /// Un gruppo armato si è messo in AGGUATO nella propria casella (01 §5.11): l'ordine di
    /// imboscata è confermato. Fatto deciso dal giocatore: annuncio di conferma, non registro.
    case imboscataOrdinata(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// L'ordine di imboscata è stato REVOCATO (01 §5.11, RDA-76): il gruppo torna libero.
    /// Annuncio di conferma; non entra nel registro.
    case imboscataRevocata(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// Un SABOTAGGIO si è compiuto (01 §5.10.2): `riuscito` è falso solo per esploratori la cui
    /// competenza non raggiunge la soglia del bersaglio, che così si fanno notare. È del gruppo
    /// che sabota, consegnato al solo giocatore quando è il suo (il sabotaggio subìto dal
    /// giocatore gli arriva dal registro, come il taglio del rifornimento).
    case sabotaggioCompiuto(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella, riuscito: Bool)
    /// Uno STUDIO APPROFONDITO si è compiuto (01 §5.10.2): la conoscenza della formazione
    /// studiata è ora confermata. È del gruppo che studia, consegnato al solo giocatore.
    case studioCompiuto(gruppo: IdGruppo, nome: IdentificatoreDati, casella: Cella)
    /// Un'IMBOSCATA è SCATTATA alla risoluzione di fine giornata (01 §5.11, §5.6.11): un gruppo
    /// armato avversario è entrato nella casella di un gruppo appostato. Sempre fra parti opposte
    /// e sempre a una casella di cui il giocatore è parte, sicché gli si consegna sempre —
    /// imboscante o vittima — come gli avvistamenti e i confini di giornata.
    case imboscataScattata(casella: Cella)
    /// Una DEDUZIONE sulla direzione di marcia di una colonna avversaria (01 §5.10.1): prodotta
    /// solo per il giocatore dai suoi esploratori, si consegna sempre.
    case direzioneDedotta(casella: Cella)
}
