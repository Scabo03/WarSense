import Foundation
import Dati
import Motore
import Segnali

/// Costruisce le etichette e i valori degli elementi accessibili della mappa
/// (05 §10.7), con la stessa disciplina del costruttore di battaglia: testa fissa
/// che non si taglia mai, ordine registrato delle informazioni (02 §3.8.1),
/// verbosità che taglia dalla coda (00 §9.5). Puro e collaudabile: nessun
/// riferimento all'interfaccia, nessun dato di gioco calcolato qui (00 §3.2).
struct CostruttoreAnnunciCampagna {
    let testi: Testi
    let motore: MotoreCampagna
    let stato: StatoCampagna
    let verbosita: Verbosita

    var vista: VistaCampagna { VistaCampagna(motore: motore, stato: stato, parte: .giocatore) }

    /// La designazione in corso nella schermata (02 §9.2.1). Come in battaglia vive
    /// nella Presentazione e non nello stato di partita (scostamento S2): nessun
    /// comando viene emesso finché la scelta non è confermata.
    enum Designazione: Equatable {
        case nessuna
        case marcia(gruppo: IdGruppo)
    }

    // MARK: - Etichetta di casella

    /// L'etichetta completa di una casella. La testa fissa non si taglia mai (02 §3.9).
    /// Con una designazione in corso la disponibilità precede la testa, esattamente
    /// come in battaglia con un elemento selezionato (02 §3.3).
    func etichettaCasella(_ casella: Cella, designazione: Designazione = .nessuna) -> String {
        var parti: [String] = []
        if case .marcia(let id) = designazione {
            switch vista.anteprimaMarcia(da: id, a: casella) {
            case .valido:
                // La disponibilità dichiara il COSTO IN GIORNI dello scatto e la
                // CONSEGUENZA dell'inchiodamento, prima dell'ordine (01 §5.6.3.5,
                // correzione del titolare, RDA-104): l'ordine parte direttamente da
                // questa voce, senza pannello, e chi ascolta deve sentire prima di
                // attivarla che il gruppo resterà fermo fino all'arrivo e non potrà
                // sfilarsi senza perdere i giorni spesi. Chi vede riceve la stessa
                // informazione dai nove pallini dell'avanzamento (01 §5.6.3.4): è la
                // parità ottenuta per due vie diverse. Il plurale di sistema sui giorni.
                let giorni = vista.comandoDiMarcia(per: id, a: casella).flatMap {
                    if case .marcia(_, _, let g) = $0 { return g } else { return nil }
                } ?? 1
                parti.append(testi.frase("casella.disponibile", giorni).testo)
                parti.append(testi.frase("casella.inchioda").testo)
            case .nonValido(let motivo): parti.append(testi.termine(motivo.rawValue).testo)
            }
        }
        parti.append(testi.frase("casella.testa", casella.riga, casella.colonna).testo)
        parti.append(contentsOf: contenutoCasella(casella))
        return parti.joined(separator: ", ")
    }

    /// La frase dello stato dichiarato di un gruppo (01 §5.16.1). «In marcia» porta
    /// i giorni mancanti e declina al plurale, quindi passa dagli Annunci; gli altri
    /// due termini sono del vocabolario chiuso semplice.
    func fraseStato(_ stato: StatoGruppo) -> String {
        switch stato {
        case .inAttesa, .haAgito: return testi.termine(stato.chiaveTesto).testo
        case .inMarcia(let giorniMancanti): return testi.frase(stato.chiaveTesto, giorniMancanti).testo
        }
    }

    /// Il contenuto nell'ordine registrato da 02 §3.8.1, ricavato dall'UNICO elenco
    /// di ciò che la casella dichiara (`VistaCampagna.vociDiCasella`). Lo stato di
    /// conoscenza appartiene a un'unità successiva e si salta senza lasciare traccia;
    /// il rifornimento dell'occupante e la zona di rifornimento entrano ora.
    ///
    /// Il ciclo su quell'elenco non ha un ramo di ripiego: un caso aggiunto
    /// all'enumerativo senza la propria frase non compila. È così che la
    /// separazione fra il piano sonoro e quello visivo diventa impossibile per
    /// costruzione anziché per disciplina (RDA-74).
    ///
    /// I tagli di verbosità partono dalla coda: il livello sintetico tiene la sola
    /// identità di ciò che occupa la casella E la sua prima anomalia, il rifornimento
    /// (02 §3.8.1) — che un gruppo sia senza provviste è troppo per lasciarlo cadere
    /// col resto. Il resto della coda cade nel sintetico, come in battaglia.
    private func contenutoCasella(_ casella: Cella) -> [String] {
        let voci = vista.vociDiCasella(casella)
        var parti: [String] = []
        for voce in voci {
            let eTesta: Bool
            switch voce {
            case .conoscenza, .occupante, .rifornimento: eTesta = true
            default: eTesta = false
            }
            if !eTesta, verbosita == .sintetico { break }
            parti.append(frase(di: voce))
        }
        // «Libera» si dice soltanto quando la casella non dichiara nulla: una
        // casella con acqua o con una strada non è vuota di informazione.
        if voci.isEmpty, verbosita != .sintetico {
            parti.append(testi.frase("casella.libera").testo)
        }
        return parti
    }

    /// La frase di una voce di casella. Esaustiva per costruzione.
    private func frase(di voce: VistaCampagna.VoceDiCasella) -> String {
        switch voce {
        case .conoscenza(let stato):
            // «avvistato» porta i turni trascorsi col plurale di sistema (02 §4.2);
            // gli altri stati sono termini chiusi semplici del vocabolario.
            if case .avvistato(let turni) = stato {
                return testi.frase(stato.chiaveTesto, turni).testo
            }
            return testi.termine(stato.chiaveTesto).testo
        case .occupante(let gruppo):
            return testi.frase("casella.occupante_proprio", nomeGruppo(gruppo),
                               fraseStato(gruppo.statoDichiarato)).testo
        case .rifornimento(let rifornimento):
            // Lo stato di rifornimento dell'occupante è un termine chiuso: la chiave
            // porta già il giorno (primo/secondo) o la sosta, e non prende numeri.
            return testi.termine(rifornimento.chiaveTesto).testo
        case .zonaDiRifornimento:
            // La zona riusa il termine chiuso «in zona di rifornimento» (02 §4.4.5):
            // è la stessa cosa, e non se ne conia uno nuovo per la casella.
            return testi.termine("rifornimento.in_zona").testo
        case .quartierGenerale(let parte):
            return testi.termine(parte == .giocatore
                                 ? "casella.quartier_generale"
                                 : "casella.quartier_generale_avversario").testo
        case .terreno(let terreno):
            return testi.termine("terreno." + terreno.rawValue).testo
        case .strada(let strada):
            return testi.termine("strada." + strada.rawValue).testo
        case .strettoia:
            return testi.termine("casella.strettoia").testo
        }
    }

    /// Il segno disegnato per una voce di casella: la controparte visiva della
    /// frase, presa dalla medesima enumerazione e quindi mai in ritardo su di essa.
    private func segno(di voce: VistaCampagna.VoceDiCasella) -> String? {
        switch voce {
        case .conoscenza(let stato):
            switch stato {
            case .inesplorato: return "?"
            case .presunto: return "~"
            case .avvistato: return "'"
            case .confermato: return nil
            }
        case .occupante(let gruppo): return inizialeGruppo(gruppo)
        case .rifornimento(let rifornimento):
            switch rifornimento {
            case .senzaProvviste: return "!"
            case .inSosta: return "S"
            case .inZona: return nil
            }
        case .zonaDiRifornimento: return "R"
        case .quartierGenerale(let parte): return parte == .giocatore ? "Q" : "q"
        case .terreno(let terreno):
            switch terreno {
            case .bosco: return "B"
            case .acqua: return "A"
            case .aperto: return nil
            }
        case .strada: return "="
        case .strettoia: return "><"
        }
    }

    /// Il nome parlato di un gruppo (01 §5.6.0.4): termine del vocabolario chiuso.
    func nomeGruppo(_ gruppo: Gruppo) -> String {
        testi.termine("gruppo.nome." + gruppo.nome).testo
    }

    /// L'iniziale che compare a schermo sulla casella: ciò che si sente si vede.
    func inizialeGruppo(_ gruppo: Gruppo) -> String {
        String(nomeGruppo(gruppo).prefix(1))
    }

    /// I segni disegnati sulla casella per chi guarda, nello stesso ordine in cui
    /// si annunciano e ricavati dallo STESSO elenco: ciò che si sente si vede.
    /// L'occupante è escluso perché ha già il proprio segno al centro della casella.
    func segniCasella(_ casella: Cella) -> String? {
        let segni = vista.vociDiCasella(casella).compactMap { voce -> String? in
            if case .occupante = voce { return nil }
            return segno(di: voce)
        }
        return segni.isEmpty ? nil : segni.joined()
    }

    // MARK: - Pannello della casella (00 §7.4, 02 §9)

    /// Il titolo del pannello di un gruppo.
    func titoloPannello(_ gruppo: Gruppo) -> String {
        testi.frase("pannello.casella_titolo", nomeGruppo(gruppo),
                    gruppo.posizione.riga, gruppo.posizione.colonna).testo
    }

    // MARK: - Informazione di stato (02 §6.4, §6.5.1.3)

    /// L'ordine è quello fisso di 02 §6.5.1.3, ridotto a ciò che esiste: giorno,
    /// gruppi che hanno agito sul totale, gruppi in marcia e — in coda — gruppi senza
    /// rifornimento. Le condizioni assenti non si nominano.
    func informazioneDiStato() -> String {
        let info = vista.informazioneDiStato
        // I gruppi in marcia lunga si dichiarano a parte (01 §5.16): quattro forme,
        // secondo che vi siano gruppi in marcia e che qualcuno abbia già agito.
        var frase: String
        if info.gruppiInMarcia > 0 {
            if info.gruppiCheHannoAgito == 0 {
                frase = testi.frase("campagna.stato_solo_marcia", info.giorno,
                                    info.gruppiInMarcia, info.gruppiTotali).testo
            } else {
                frase = testi.frase("campagna.stato_con_marcia", info.giorno,
                                    info.gruppiCheHannoAgito, info.gruppiTotali, info.gruppiInMarcia).testo
            }
        } else if info.gruppiCheHannoAgito == 0 {
            frase = testi.frase("campagna.stato_tutti_fermi", info.giorno, info.gruppiTotali).testo
        } else {
            frase = testi.frase("campagna.stato", info.giorno,
                                info.gruppiCheHannoAgito, info.gruppiTotali).testo
        }
        // I gruppi senza rifornimento sono una categoria a sé (01 §5.16): si dichiarano
        // in coda quando ce ne sono, e la condizione assente non si nomina (02 §8.7.1).
        if info.gruppiSenzaRifornimento > 0 {
            frase += testi.frase("campagna.stato_senza_rifornimento",
                                 info.gruppiSenzaRifornimento).testo
        }
        return frase
    }

    /// L'annuncio di apertura: la mappa, le sue dimensioni e dove sta il proprio
    /// quartier generale, che è il perno della mappa (01 §5.2.1).
    func annuncioApertura() -> String {
        let qg = stato.mappa.quartierGeneraleGiocatore
        return testi.frase("campagna.annuncio_apertura",
                           testi.frase("mappa." + stato.mappa.identificatore).testo,
                           stato.griglia.righe, stato.griglia.colonne,
                           qg.riga, qg.colonna).testo
    }

    // MARK: - Registro (01 §5.17, 02 §6.6)

    /// La frase compiuta di una voce del registro, che dichiara il giorno.
    /// La compone il traduttore dei Segnali e non questa struttura: le frasi del
    /// registro hanno UN SOLO autore, altrimenti le due sedi che le producevano
    /// potevano dire cose diverse dello stesso fatto.
    func voceDiRegistro(_ voce: VoceRegistro) -> String {
        TraduttoreEventiCampagna(testi: testi, parte: .giocatore).voceDiRegistro(voce).testo
    }
}
