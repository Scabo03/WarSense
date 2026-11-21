Incarico 28 — Correzioni dall’esplorazione, chiusura della giornata, caso per meteo e guasti, e prove interattive approfondite

Che cos’è questo documento

È il primo messaggio di una sessione nuova. Vale per intero CLAUDE.md, comprese la convivenza con gli altri progetti, l’infrastruttura e la forma della consegna. Archivia questo incarico verbatim in Incarichi con il numero 28 e aggiorna l’indice. Prima di cominciare leggi il resoconto dell’incarico 27 e i suoi prodotti, in particolare il file delle osservazioni e il rapporto sui canali di automazione.

Lo stato di partenza, da verificare

Il principale è a 972aeb8, con la build 28 su TestFlight e la versione dei valori 0.12.0. I numeri sono usati fino a RDA-150 e S26. Resta sul remoto il ramo temporaneo riferimento-agosto. Accerta che locale e remoto coincidano e che l’albero di lavoro sia pulito; se trovi altro, fermati e dichiaralo.

Convivenza

Valgono le regole di CLAUDE.md: nessun disturbo agli altri progetti, ai loro simulatori e alle loro finestre. Se usi Device Hub o l’accesso d’assistenza di macOS, agisci soltanto sulle finestre degli apparecchi di WarSense.

Prima parte: le correzioni, e la build 29

La chiusura della giornata. Il tasto Chiudi la giornata ha un difetto trovato leggendo il codice. SessioneCampagna.chiudiGiornata chiama MotoreCampagna.chiudiLaGiornataForzata, che segna come spesa la giornata di tutti i gruppi che non l’hanno conclusa, compresi quelli dell’avversario, senza che l’avversario abbia mosso. Chi ordina tre gruppi, ne lascia fermo uno e preme il tasto, toglie il turno all’avversario; ripetuto ogni giorno, l’avversario non muove mai. È anche la causa dell’annuncio che conta i gruppi avversari fra quelli che non avevano agito. Il comportamento corretto è questo. Il tasto conclude la giornata soltanto per i gruppi del giocatore che non hanno agito, come un ordine di restare. Poi l’avversario svolge il suo turno normale, per la stessa via di sempre, e la giornata si chiude da sé. Il tasto deve restare una via d’uscita anche quando il blocco sta dalla parte dell’avversario: decidi come, e dichiaralo. L’annuncio conta soltanto i gruppi del giocatore; la diagnostica accanto al salvataggio conserva entrambe le parti, distinte. Aggiungi l’invariante per cui nessun comando del giocatore può far perdere all’avversario un’azione, con il suo mutante visto fallire. È un cambio di regola che incide su una partita in corso: dichiara la valutazione sulla versione dei valori.

Le osservazioni dell’esplorazione. Correggi tutte le osservazioni bloccanti e serie del file delle osservazioni dell’incarico 27, e le imperfezioni. Per il resoconto di battaglia vuoto, riproduci prima: sia su una battaglia ripresa e conclusa con la resa, sia su una battaglia giocata senza interruzioni fino alla fine. Per ogni osservazione: prima una prova che fallisce sul codice attuale, poi la correzione. Dove una correzione richiede una scelta di progetto non coperta dai documenti, per esempio sul supporto del carattere dinamico, cerca prima nei documenti; se la risposta non c’è, proponi senza decidere. Alla fine riesegui l’esplorazione dell’incarico 27 sugli stessi percorsi, e riporta che cosa è cambiato.

Il caso per meteo e guasti. Il titolare ha deciso che meteo e guasti delle macchine restano affidati al caso, come eccezione dichiarata. Riscrivi il punto 12.1 del documento 01 perché il caso esista nello scontro a campioni e, fuori da esso, soltanto nelle variazioni del meteo sul piano di campagna e nei guasti delle macchine da guerra, con la probabilità di guasto legata allo stato di manutenzione. È il perimetro della versione 3.7, con i suoi punti 12.2, 12.3 e 12.5 e il loro annuncio delle probabilità. Ripristina il perimetro nel punto 16.5, chiudi il punto aperto 16.7, e allinea il documento della modalità a campioni dove dice che le campagne sono deterministiche. Nel codice non c’è nulla da costruire: meteo e guasti non esistono ancora.

La forma del resoconto. La contraddizione segnalata in CLAUDE.md si risolve a favore della forma della consegna di CLAUDE.md: una riga per modifica, con commit e percorso, e una spiegazione per intero di ciò che dal repo non si vede. Aggiorna di conseguenza la regola in vigore in forma-dei-resoconti.md, e togli la voce da CLAUDE.md.

Una regola nuova in CLAUDE.md. Aggiungi fra le regole di lavoro stabili: il titolare non esegue prove a mano; ogni verifica si fa con le automazioni e i simulatori; ciò che non si riesce ad automatizzare si dichiara come scoperto nel resoconto, con le vie tentate, e non si passa al titolare come prova da fare.

Due pulizie. Porta i bersagli di prova alla modalità del linguaggio Swift 6, come proposto nel resoconto dell’incarico 27; se richiede di indebolire una prova, fermati su quel punto e dichiaralo. Cancella il ramo riferimento-agosto, in locale e sul remoto, dopo aver verificato che il suo unico commit non fuso sia la modifica temporanea dell’integrazione continua: il titolare lo autorizza espressamente.

La build 29. Con il collaudo completo e la corsa delle sessioni verdi, carica la build 29 e verifica su App Store Connect come d’uso. La nota per il titolare dice in poche righe che cosa è cambiato per chi gioca.

Seconda parte: le prove interattive approfondite

L’esplorazione dell’incarico 27 era un unico script automatico. Questa è una cosa diversa: una sessione da tester, che gioca e reagisce a ciò che vede e sente, interamente guidata dalle automazioni.

Device Hub. Il resoconto dell’incarico 27 concludeva che i simulatori girano senza finestra, perché in Xcode 27 l’applicazione Simulator non esiste più. Xcode 27 l’ha sostituita con Device Hub, con identificativo com.apple.dt.Devices, che mostra una vista dal vivo e interattiva dell’apparecchio. Accerta se Device Hub, insieme all’accesso d’assistenza di macOS o a qualunque strumento di controllo dello schermo disponibile in questa sessione, dà un canale per guidare l’app dal vivo, e con quali limiti. È noto che Device Hub non consente i gesti a due dita. Aggiorna il rapporto sui canali.

La sessione da tester. Procedi a passi brevi: un’azione, l’ascolto di ciò che VoiceOver pronuncia, lo stato dello schermo, poi la decisione sul passo successivo. Usa il canale migliore fra quelli accertati. Gioca partite intere sui tre formati fino alla loro conclusione naturale. Includi le parti che l’incarico 27 non ha raggiunto: il piazzamento, la designazione dei bersagli, le battaglie nate in campagna, il ripiegamento e il ritorno in campagna. Includi anche l’annullamento e l’azzeramento, il resoconto di fine battaglia e il tasto per chiudere la giornata già corretto. Cerca di proposito i percorsi sbagliati: annullare a metà, tornare indietro, ripetere un comando, scegliere un bersaglio non valido, chiudere e riaprire l’app nel mezzo di un’azione e riprendere, ruotare l’apparecchio nel mezzo di un’azione, cambiare la taglia del testo e accendere o spegnere VoiceOver a partita in corso. Dopo ogni azione verifica dove va il fuoco e se l’annuncio è quello che il documento 02 prescrive. Fallo su iPhone e su iPad.

I gesti che le prove standard non sanno fare. Rotore, tocco magico, strofinio, azioni personalizzate e doppio tocco ovunque non si sintetizzano con le prove d’interfaccia standard. Questa parte serve proprio a chiudere questo vuoto. Prova tutte le vie per guidarli in automatico, e usa quelle che funzionano: i comandi da tastiera di VoiceOver con la tastiera fisica, inviati dalle prove d’interfaccia o come battute di tasti nella finestra di Device Hub, verificando quali gesti coprono; Device Hub guidato con l’accesso d’assistenza di macOS; ogni altro canale che trovi. Verifica inoltre ciascun gesto un livello sotto, nelle prove ospitate, chiamando direttamente ciò che il gesto attiva: le ricerche dei rotori personalizzati, i gestori del tocco magico e dell’uscita, le azioni personalizzate. Controlla effetto e annuncio. Ciò che alla fine resta impossibile da guidare in automatico va dichiarato come scoperto, con le vie tentate e la ragione per cui non funzionano.

Gli annunci. Il servizio VoiceOver delle prove restituisce ciò che si pronuncia sul fuoco, non gli annunci. Verifica gli annunci che seguono le azioni attraverso lo strato dei segnali del gioco nelle prove ospitate, senza creare canali che esistano soltanto per il collaudo, e nell’esplorazione dove coincidono con la pronuncia.

Che cosa produrre. Come nell’incarico 27: le osservazioni con gravità e passi per ripeterle, ciò che è confermato funzionare, le trascrizioni, una selezione di schermate. In questa parte non correggere: registra, e le correzioni andranno in un incarico successivo. Questa parte costa molte operazioni, ed è voluto.

Ordine e priorità

La prima parte va chiusa per intero, build 29 compresa, prima di cominciare la seconda. Se la capacità non basta per tutta la seconda parte, fermati alla fine di un percorso completo e dichiaralo.

Consegna

Come prescrive CLAUDE.md. In più, nel resoconto: per ogni osservazione dell’incarico 27, se è corretta, con quale commit e con quale prova; per la seconda parte, quale canale hai usato per ciascun percorso; e per ciascun gesto, se è stato guidato in automatico, verificato solo un livello sotto, oppure è rimasto scoperto.
