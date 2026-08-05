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
        case .marciaEseguita, .presidioOrdinato: return .conferma
        case .giornataChiusa, .giornataAperta: return nil
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
        case .marciaEseguita(_, let chiave, _, let a):
            return testi.frase("campagna.marcia_eseguita", verbosita: verbosita,
                               nome(chiave), a.riga, a.colonna)
        case .presidioOrdinato(_, let chiave, let casella):
            return testi.frase("campagna.presidio_ordinato", verbosita: verbosita,
                               nome(chiave), casella.riga, casella.colonna)
        case .giornataChiusa:
            // Un fatto solo, una frase sola: l'apertura porta già la chiusura.
            return nil
        case .giornataAperta(let giorno):
            return testi.frase("campagna.giornata_aperta", verbosita: verbosita, giorno)
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
        case .marciaOrdinata(let gruppo, _, let a):
            return testi.frase(chiave, voce.giorno, nome(gruppo), a.riga, a.colonna)
        case .presidioOrdinato(let gruppo, let casella):
            return testi.frase(chiave, voce.giorno, nome(gruppo), casella.riga, casella.colonna)
        case .ordineAnnullato, .giornataAzzerata:
            return testi.frase(chiave, voce.giorno)
        }
    }
}
