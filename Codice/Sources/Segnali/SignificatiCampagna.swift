import Foundation
import Dati
import Motore

/// La traduzione degli eventi della campagna in significato e annuncio (05 §10.7),
/// gemella di `TraduttoreEventi` per la battaglia: stessa struttura, stesse regole,
/// perché il giocatore impari un modo solo (00 §7.1). Parte neutra e collaudabile:
/// nessun canale di piattaforma.
public struct TraduttoreEventiCampagna: Sendable {
    let testi: Testi
    /// La parte che ascolta: gli eventi si annunciano dal suo punto di vista.
    let parte: Parte

    public init(testi: Testi, parte: Parte) {
        self.testi = testi
        self.parte = parte
    }

    /// Il significato di segnale per l'evento, se l'evento ne merita uno.
    ///
    /// La chiusura della giornata NON ha segnale tattile né sonoro proprio: il tetto
    /// dei significati di 02 §11.5 è chiuso a quindici e l'elenco degli eventi
    /// rimasti fuori con suono dedicato è anch'esso chiuso (02 §11.7.1). La
    /// chiusura è d'altronde la conseguenza immediata dell'ultimo ordine del
    /// giocatore, che porta già il segnale di conferma, e resta recuperabile nel
    /// registro (02 §6.6.1). Aggiungere un sedicesimo significato per un fatto che
    /// arriva sempre subito dopo un segnale sarebbe carico senza informazione.
    public func significato(per evento: EventoCampagna) -> SignificatoSegnale? {
        switch evento {
        case .marciaOrdinata, .presidioOrdinato, .marciaRevocata: return .conferma
        // La divisione e la riunione sono decise dal giocatore e portano il segnale di
        // conferma del proprio ordine, come la marcia e il presidio: nessun sedicesimo
        // significato (02 §11.5).
        case .gruppoDiviso, .gruppiRiuniti: return .conferma
        // Il compimento di una marcia lunga è un fatto non deciso dal giocatore e ha
        // il proprio significato tattile già assegnato: `marcia_completata`, famiglia
        // della navigazione (02 §11.7.1). Non è una conferma di un ordine.
        case .marciaCompiuta: return .marciaCompletata
        // Il rifornimento che si interrompe e la sosta imposta che ne consegue portano
        // lo stesso segnale dedicato `rifornimento_interrotto` (02 §11.7.1): un solo
        // richiamo tattile «bada al rifornimento», e le parole dicono se è il primo
        // giorno di digiuno o la sosta imposta. Il tetto dei significati resta chiuso
        // (02 §11.5): non se ne aggiunge uno per la sosta.
        case .rifornimentoInterrotto, .sostaDiRifornimento: return .rifornimentoInterrotto
        // La ripresa è una buona notizia e non chiede attenzione: nessun segnale
        // tattile proprio — non esiste nel tetto chiuso e non se ne aggiunge — ma
        // l'annuncio parlato la dice (02 §8.7), come per la chiusura della giornata.
        case .rifornimentoRipreso: return nil
        case .giornataChiusa, .giornataAperta: return nil
        // L'avvistamento di una formazione avversaria si annuncia a parole (02 §8.2.1),
        // ma NON ha un significato tattile proprio: il tetto dei quindici è chiuso
        // (02 §11.5) e l'elenco dei suoni dedicati (02 §11.7.1) non lo prevede; non se ne
        // conia uno, come per la ripresa del rifornimento. Il fuoco non è rubato.
        case .formazioneAvversariaAvvistata: return nil
        // Le azioni ORDINATE dal giocatore — esplorare, appostarsi, sabotare, studiare — portano
        // il segnale di conferma del proprio ordine, come la marcia e il presidio: nessun
        // sedicesimo significato (02 §11.5). L'esito parlato dice com'è andata (riuscita, a mani
        // vuote, notati, perduti; sabotaggio riuscito o fallito). Non esiste più la revoca
        // dell'imboscata (incarico 21): l'imboscata è un'azione che si rinnova.
        case .esplorazioneCompiuta, .imboscataOrdinata,
             .sabotaggioCompiuto, .studioCompiuto:
            return .conferma
        // Lo scatto dell'imboscata ha il proprio significato tattile GIÀ assegnato nel tetto
        // chiuso: `imboscata`, famiglia dell'allarme (02 §11.7.1, significato 12). Vale sempre —
        // imboscante o vittima — perché il giocatore è parte dello scatto.
        case .imboscataScattata: return .imboscata
        // La SCOPERTA di un'imboscata avversaria e la deduzione dell'itinerario si annunciano a
        // parole (02 §8.2.1) ed entrano nel registro, ma NON hanno segnale tattile: il tetto dei
        // quindici è chiuso (02 §11.5), come per l'avvistamento. Alla scoperta NON si dà l'allarme
        // dello scatto, che direbbe il falso — «è scattata» invece di «l'hai scoperta».
        case .imboscataScoperta, .direzioneDedotta: return nil
        // Una battaglia innescata ha il proprio significato tattile GIÀ registrato nel tetto
        // chiuso: `battaglia_in_sospeso`, famiglia dell'allarme (02 §11.7.1, significato 13),
        // predisposto senza produttore da una sessione precedente e ora acceso (incarico 24).
        // Vale sempre: il giocatore è parte di ogni battaglia.
        case .battagliaInnescata: return .battagliaInSospeso
        // La conclusione della battaglia si annuncia a parole (l'esito) ed entra nel registro,
        // ma NON aggiunge un significato tattile: il tetto è chiuso (02 §11.5) e il ritorno alla
        // mappa avviene per scelta del giocatore, non ruba il fuoco.
        case .battagliaConclusa: return nil
        }
    }

    /// Il nome parlato di un gruppo (01 §5.6.0.4): termine del vocabolario chiuso.
    private func nome(_ chiave: IdentificatoreDati) -> String {
        testi.termine("gruppo.nome." + chiave).testo
    }

    /// L'annuncio per l'evento, già risolto nel livello di verbosità e nella lingua.
    /// Restituisce nulla per gli eventi che non producono annuncio proattivo.
    public func annuncio(per evento: EventoCampagna, verbosita: Verbosita) -> TestoLocalizzato? {
        switch evento {
        case .marciaOrdinata(_, let chiave, _, let a, let giorni):
            // La marcia ordinata dichiara i giorni: la grandezza di origine che chi
            // ascolta riceve (01 §5.6.3.3), con il plurale di sistema.
            return testi.frase("campagna.marcia_ordinata", verbosita: verbosita,
                               nome(chiave), a.riga, a.colonna, giorni)
        case .marciaCompiuta(_, let chiave, _, let a):
            return testi.frase("campagna.marcia_compiuta", verbosita: verbosita,
                               nome(chiave), a.riga, a.colonna)
        case .marciaRevocata(_, let chiave, _, let giorniPersi):
            return testi.frase("campagna.marcia_revocata", verbosita: verbosita,
                               nome(chiave), giorniPersi)
        case .presidioOrdinato(_, let chiave, let casella):
            return testi.frase("campagna.presidio_ordinato", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .gruppoDiviso(_, _, _, let chiaveDistaccamento, let a):
            // L'annuncio nomina il DISTACCAMENTO e dove è nato: è il fatto nuovo, e il
            // gruppo di origine resta dove il giocatore lo vede (01 §5.6.0.2).
            return testi.frase("campagna.gruppo_diviso", verbosita: verbosita,
                               nome(chiaveDistaccamento), a.riga, a.colonna)
        case .gruppiRiuniti(_, let chiave, _, let casella):
            return testi.frase("campagna.gruppi_riuniti", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .giornataChiusa:
            // Un fatto solo, una frase sola: l'apertura porta già la chiusura.
            return nil
        case .giornataAperta(let giorno):
            return testi.frase("campagna.giornata_aperta", verbosita: verbosita, giorno)
        // I fatti del rifornimento si annunciano dal punto della catena in cui accadono,
        // col salto alla casella (02 §6.6). La ripresa è un annuncio a sé, distinto dallo
        // stato «rifornito» che non si annuncia mai (02 §8.7): dice il passaggio, non la
        // quiete.
        case .rifornimentoInterrotto(_, let chiave, let casella):
            return testi.frase("campagna.rifornimento_interrotto", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .sostaDiRifornimento(_, let chiave, let casella):
            return testi.frase("campagna.sosta_di_rifornimento", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .rifornimentoRipreso(_, let chiave, let casella):
            return testi.frase("campagna.rifornimento_ripreso", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .formazioneAvversariaAvvistata(let casella):
            // Il fatto e il luogo, senza nome né volume (02 §6.4.1): «una formazione
            // avversaria, e dove». È la mossa avversaria che il giocatore apprende.
            return testi.frase("campagna.formazione_avvistata", verbosita: verbosita,
                               casella.riga, casella.colonna)
        case .esplorazioneCompiuta(_, _, let chiave, let casella, let esito):
            // L'annuncio varia con l'esito deterministico (01 §5.4): area rivelata, a mani
            // vuote, notati, perduti. Ciascuno la propria frase, col nome dell'esploratore e,
            // dove serve, il luogo per portarvi il fuoco.
            switch esito {
            case .riuscita:
                return testi.frase("campagna.esplorazione_riuscita", verbosita: verbosita,
                                   nome(chiave), casella.riga, casella.colonna)
            case .aManiVuote:
                return testi.frase("campagna.esplorazione_a_mani_vuote", verbosita: verbosita,
                                   nome(chiave))
            case .notati:
                return testi.frase("campagna.esploratori_notati", verbosita: verbosita,
                                   nome(chiave), casella.riga, casella.colonna)
            case .perduti:
                return testi.frase("campagna.esploratori_perduti", verbosita: verbosita,
                                   nome(chiave), casella.riga, casella.colonna)
            }
        case .imboscataOrdinata(_, let chiave, let casella):
            return testi.frase("campagna.imboscata_ordinata", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .imboscataScoperta(_, let casella):
            // La scoperta: la ricognizione ha trovato un'imboscata avversaria, e dove (02 §6.4.1).
            // Senza il nome dell'appostato (non lo si conosce). La parte è sempre il giocatore
            // quando l'annuncio lo raggiunge (proiettaPerIlGiocatore lo filtra).
            return testi.frase("campagna.imboscata_scoperta", verbosita: verbosita,
                               casella.riga, casella.colonna)
        case .sabotaggioCompiuto(_, let chiave, let casella, let riuscito):
            // Riuscito: una formazione avversaria è dispersa in un luogo. Fallito: gli
            // esploratori si sono fatti notare. Il nome è quello del gruppo che sabota (proprio).
            return riuscito
                ? testi.frase("campagna.sabotaggio_riuscito", verbosita: verbosita,
                              nome(chiave), casella.riga, casella.colonna)
                : testi.frase("campagna.sabotaggio_fallito", verbosita: verbosita,
                              nome(chiave), casella.riga, casella.colonna)
        case .studioCompiuto(_, let chiave, let casella):
            return testi.frase("campagna.formazione_studiata", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .imboscataScattata(let casella):
            // Il fatto e il luogo (02 §6.4.1): «un'imboscata è scattata, e dove». Vale
            // imboscante o vittima; il giocatore ne è parte.
            return testi.frase("campagna.imboscata_scattata", verbosita: verbosita,
                               casella.riga, casella.colonna)
        case .direzioneDedotta(let casella):
            // La deduzione: una colonna segue una strada, e da dove è stata osservata
            // (01 §5.10.1). Senza nome della colonna (02 §6.4.1).
            return testi.frase("campagna.direzione_dedotta", verbosita: verbosita,
                               casella.riga, casella.colonna)
        case .battagliaInnescata(let casella, let daImboscata):
            // Il fatto e il luogo: «battaglia in sospeso, e dove». L'annuncio distingue lo scontro
            // nato da un'imboscata da quello ordinario, così che il giocatore sappia se avrà — o
            // subirà — il vantaggio della sorpresa (01 §9.3.2). Non forza il passaggio (02 §5.6).
            return testi.frase(daImboscata ? "campagna.battaglia_innescata_imboscata"
                                           : "campagna.battaglia_innescata",
                               verbosita: verbosita, casella.riga, casella.colonna)
        case .battagliaConclusa(let casella, let giocatoreSconfitto):
            // Chi torna sulla mappa sente com'è andata: vinta o persa, e dove (01 §15.3).
            return testi.frase(giocatoreSconfitto ? "campagna.battaglia_persa"
                                                   : "campagna.battaglia_vinta",
                               verbosita: verbosita, casella.riga, casella.colonna)
        }
    }

    /// La frase di una voce del registro (02 §6.6): compiuta, con il giorno
    /// dichiarato, una frase intera per ciascun fatto e mai una somma di parole
    /// (00 §14.2). È l'UNICO punto del programma che compone le frasi del registro:
    /// finché ne esistevano due — una qui e una nella Presentazione — nulla
    /// obbligava le due a dire la stessa cosa.
    public func voceDiRegistro(_ voce: VoceRegistro) -> TestoLocalizzato {
        let chiave = voce.fatto.chiaveTesto
        switch voce.fatto {
        case .marciaRevocata(let gruppo, let casella):
            return testi.frase(chiave, voce.giorno, nome(gruppo), casella.riga, casella.colonna)
        case .rifornimentoInterrotto(let gruppo, let casella),
             .sostaDiRifornimento(let gruppo, let casella),
             .rifornimentoRipreso(let gruppo, let casella):
            return testi.frase(chiave, voce.giorno, nome(gruppo), casella.riga, casella.colonna)
        case .esploratoriPerduti(let gruppo, let casella),
             .esploratoriNotati(let gruppo, let casella):
            // Gli esploratori del giocatore, col loro nome e il luogo dove esploravano
            // (01 §5.4): un fatto proprio, attivabile per portarvi il fuoco.
            return testi.frase(chiave, voce.giorno, nome(gruppo), casella.riga, casella.colonna)
        case .formazioneAvversariaAvvistata(let casella),
             .formazioneSabotata(let casella),
             .formazioneStudiata(let casella),
             .imboscataScattata(let casella),
             .imboscataScoperta(let casella),
             .direzioneDedotta(let casella),
             .battagliaInnescata(let casella),
             .battagliaConclusa(let casella, _):
            // Senza nome della formazione (02 §6.4.1): il giorno e il luogo, attivabile per
            // portarvi il fuoco (02 §6.6). Il sabotaggio, lo studio, lo scatto, la SCOPERTA
            // dell'imboscata, la deduzione, l'innesco e la conclusione di una battaglia dichiarano
            // il fatto e dove; l'innesco e la conclusione hanno frasi distinte per l'esito, ma il
            // giorno e il luogo bastano ai dati della voce (la chiaveTesto già distingue vinta/persa).
            return testi.frase(chiave, voce.giorno, casella.riga, casella.colonna)
        case .ordineAnnullato, .giornataAzzerata:
            return testi.frase(chiave, voce.giorno)
        }
    }
}
