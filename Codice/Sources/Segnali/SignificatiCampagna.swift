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
             .direzioneDedotta(let casella):
            // Senza nome della formazione (02 §6.4.1): il giorno e il luogo, attivabile per
            // portarvi il fuoco (02 §6.6). Il sabotaggio, lo studio, lo scatto e la deduzione
            // dichiarano il fatto e dove, mai il nome dell'avversario.
            return testi.frase(chiave, voce.giorno, casella.riga, casella.colonna)
        case .ordineAnnullato, .giornataAzzerata:
            return testi.frase(chiave, voce.giorno)
        }
    }
}
