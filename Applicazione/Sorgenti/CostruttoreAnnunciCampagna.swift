import Foundation
import Dati
import Motore

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
            case .valido: parti.append(testi.frase("casella.disponibile").testo)
            case .nonValido(let motivo): parti.append(testi.termine(motivo.rawValue).testo)
            }
        }
        parti.append(testi.frase("casella.testa", casella.riga, casella.colonna).testo)
        parti.append(contentsOf: contenutoCasella(casella))
        return parti.joined(separator: ", ")
    }

    /// Il contenuto nell'ordine registrato da 02 §3.8.1, ridotto a ciò che esiste:
    /// occupante con il proprio stato, poi il quartier generale (che occupa il posto
    /// delle opere presenti nella casella), poi terreno e tipo di strada, infine le
    /// note di zona, cioè la strettoia. Lo stato di conoscenza, le anomalie
    /// dell'occupante e la zona di rifornimento appartengono a unità successive e si
    /// saltano senza lasciare traccia.
    ///
    /// I tagli di verbosità partono dalla coda: il livello sintetico tiene la sola
    /// identità di ciò che occupa la casella, come fa quello di battaglia. Fra
    /// normale e dettagliato non c'è differenza finché la coda ha tre sole voci.
    private func contenutoCasella(_ casella: Cella) -> [String] {
        var parti: [String] = []
        if let gruppo = vista.occupante(di: casella) {
            parti.append(testi.frase("casella.occupante_proprio",
                                     nomeGruppo(gruppo),
                                     testi.termine(gruppo.statoDichiarato.rawValue).testo).testo)
        } else if verbosita != .sintetico, !haSegni(casella) {
            parti.append(testi.frase("casella.libera").testo)
        }
        guard verbosita != .sintetico else { return parti }

        if let parte = vista.quartierGeneraleSu(casella) {
            parti.append(testi.termine(parte == .giocatore
                                       ? "casella.quartier_generale"
                                       : "casella.quartier_generale_avversario").testo)
        }
        let terreno = vista.terreno(di: casella)
        if terreno != .aperto { parti.append(testi.termine("terreno." + terreno.rawValue).testo) }
        let strada = vista.strada(di: casella)
        if strada != .nessuna { parti.append(testi.termine("strada." + strada.rawValue).testo) }
        if vista.eStrettoia(casella) { parti.append(testi.termine("casella.strettoia").testo) }
        return parti
    }

    /// Vero se la casella dichiara qualcosa oltre alla propria posizione: allora
    /// «libera» non si dice, perché la casella non è vuota di informazione.
    private func haSegni(_ casella: Cella) -> Bool {
        vista.quartierGeneraleSu(casella) != nil
            || vista.terreno(di: casella) != .aperto
            || vista.strada(di: casella) != .nessuna
            || vista.eStrettoia(casella)
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
    /// si annunciano: quartier generale, terreno, strada, strettoia.
    func segniCasella(_ casella: Cella) -> String? {
        var segni: [String] = []
        if vista.quartierGeneraleSu(casella) != nil { segni.append("Q") }
        switch vista.terreno(di: casella) {
        case .bosco: segni.append("B")
        case .acqua: segni.append("A")
        case .aperto: break
        }
        if vista.strada(di: casella) != .nessuna { segni.append("=") }
        if vista.eStrettoia(casella) { segni.append("><") }
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
    /// gruppi che hanno agito sul totale. Le condizioni assenti non si nominano.
    func informazioneDiStato() -> String {
        let info = vista.informazioneDiStato
        if info.gruppiCheHannoAgito == 0 {
            return testi.frase("campagna.stato_tutti_fermi", info.giorno, info.gruppiTotali).testo
        }
        return testi.frase("campagna.stato", info.giorno,
                           info.gruppiCheHannoAgito, info.gruppiTotali).testo
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
    func voceDiRegistro(_ voce: VoceRegistro) -> String {
        switch voce.fatto {
        case .giornataAperta: return testi.frase("registro.giornata_aperta", voce.giorno).testo
        }
    }
}
