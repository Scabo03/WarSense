import Foundation
import Dati
import Motore

/// Costruisce le etichette e i valori degli elementi accessibili (05 §10.7):
/// la testa fissa dell'annuncio di cella, l'ordine registrato delle informazioni
/// (02 §3.2, §3.3, §3.8.1), i livelli di verbosità che tagliano dalla coda (00 §9.5).
/// Puro e collaudabile: nessun riferimento all'interfaccia.
struct CostruttoreAnnunci {
    let testi: Testi
    let motore: MotoreBattaglia
    let stato: StatoBattaglia
    let verbosita: Verbosita

    var valori: ValoriDiGioco { motore.valori }

    /// La modalità di designazione in corso nella schermata (02 §9.2.1).
    enum Designazione: Equatable {
        case nessuna
        case movimento(sciame: IdSciame)
    }

    // MARK: - Etichetta di cella

    /// L'etichetta completa di una cella. La testa fissa non si taglia mai (02 §3.9).
    func etichettaCella(_ cella: Cella, designazione: Designazione = .nessuna) -> String {
        let testa = testi.frase("cella.testa", cella.riga, cella.colonna).testo
        var parti: [String] = []

        // Con un elemento selezionato, la disponibilità precede la testa (02 §3.3).
        if case .movimento(let id) = designazione {
            parti.append(contentsOf: disponibilitaMovimento(da: id, a: cella))
            parti.append(testa)
        } else if stato.selezione[.giocatore] != nil, stato.parteDiTurno == .giocatore {
            let esito = motore.valida(.piazza(cella: cella), parte: .giocatore, stato: stato)
            switch esito {
            case .valido(let costi):
                parti.append(testi.frase("cella.disponibile", Int(costi.volume), Int(costi.residuoDopo)).testo)
            case .nonValido(let motivo):
                parti.append(testi.termine(motivo.rawValue).testo)
            }
            parti.append(testa)
        } else {
            parti.append(testa)
        }

        parti.append(contentsOf: contenutoCella(cella))
        return parti.joined(separator: ", ")
    }

    private func disponibilitaMovimento(da id: IdSciame, a cella: Cella) -> [String] {
        guard let percorso = percorsoMovimento(da: id, a: cella) else {
            return [testi.termine(MotivoNonValido.bersaglioNonValido.rawValue).testo]
        }
        let esito = motore.valida(.muovi(sciame: id, percorso: percorso), parte: .giocatore, stato: stato)
        switch esito {
        case .valido(let costi):
            return [testi.frase("cella.disponibile", Int(costi.volume), Int(costi.residuoDopo)).testo]
        case .nonValido(let motivo):
            return [testi.termine(motivo.rawValue).testo]
        }
    }

    /// Il percorso di una o due celle verso la destinazione (01 §9.5.0.3), deterministico.
    func percorsoMovimento(da id: IdSciame, a destinazione: Cella) -> [Cella]? {
        guard let sciame = stato.sciami[id] else { return nil }
        let distanza = stato.griglia.distanza(sciame.posizione, destinazione)
        if distanza == 1 { return [destinazione] }
        guard distanza == 2 else { return nil }
        let intermedie = stato.griglia.vicini(di: sciame.posizione)
            .filter { stato.griglia.adiacenti($0, destinazione)
                && stato.occupante(di: $0) == nil && !stato.ostacoli.contains($0) }
            .sorted()
        guard let via = intermedie.first else { return nil }
        return [via, destinazione]
    }

    /// Il contenuto della cella nell'ordine registrato (02 §3.8.1), tagliato dalla coda.
    private func contenutoCella(_ cella: Cella) -> [String] {
        if stato.ostacoli.contains(cella) {
            return [testi.frase("cella.ostacolo_contenuto").testo]
        }
        let vista = VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
        guard let sciame = vista.occupanteVisibile(di: cella) else {
            return verbosita == .sintetico ? [] : [testi.frase("cella.libera").testo]
        }
        var parti: [String] = []
        let nome = testi.frase("unita." + sciame.archetipo).testo
        parti.append(sciame.parte == .giocatore
                     ? testi.frase("cella.occupante_proprio", nome).testo
                     : testi.frase("cella.occupante_avversario", nome).testo)
        guard verbosita != .sintetico else { return parti }
        // Anomalie nell'ordine fisso: controllo, munizioni (02 §3.8.1, §8.7.1).
        if stato.impegnato(sciame.id) {
            parti.append(testi.termine("controllo.impegnato").testo)
        }
        let archetipo = valori.archetipi[sciame.archetipo]!
        if archetipo.dotazioneMunizioni > 0 && sciame.parte == .giocatore {
            if sciame.munizioni == 0 {
                parti.append(testi.termine("munizioni.esaurite").testo)
            } else if sciame.munizioni * 2 <= archetipo.dotazioneMunizioni {
                parti.append(testi.termine("munizioni.scarse").testo)
            } // piene: la condizione ordinaria non si annuncia (02 §4.4.1.2)
        }
        if verbosita == .dettagliato {
            let atomi = sciame.atomiPresenti(puntiVitaPerAtomo: archetipo.puntiVitaPerAtomo,
                                             minimo: valori.minimi.atomiMinimiSciameVivo)
            parti.append(testi.frase("battaglia.atomi_presenti", Int(atomi)).testo)
        }
        return parti
    }

    // MARK: - Deck

    /// L'etichetta di un elemento del deck (02 §8.2).
    func etichettaElementoDeck(indice: Int) -> String {
        guard let elemento = stato.deck[.giocatore]?[indice] else { return "" }
        let nome = testi.frase("unita." + elemento.archetipo).testo
        let atomi = testi.frase("battaglia.atomi_presenti", Int(elemento.atomi)).testo
        let volume = elemento.atomi * valori.archetipi[elemento.archetipo]!.volumePerAtomo
        let esemplari = testi.frase("deck.esemplari", elemento.esemplari).testo
        var etichetta = testi.frase("deck.elemento", nome, atomi, Int(volume), esemplari).testo
        if stato.selezione[.giocatore] == indice {
            etichetta += ", " + testi.frase("deck.selezionato").testo
        }
        return etichetta
    }

    // MARK: - Informazione di stato (02 §6.4)

    func informazioneDiStato() -> String {
        let vista = VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
        let info = vista.informazioneDiStato
        var testo = testi.frase("battaglia.stato", Int(info.volumeResiduo), info.numeroGiro).testo
        if let riga = info.rigaAvversariaPiuAvanzata {
            testo += testi.frase("battaglia.stato_riga_avanzata", riga).testo
        }
        if let righe = info.righeAllaSogliaDiRitirata {
            testo += testi.frase("battaglia.stato_ritirata", righe).testo
        }
        return testo
    }

    /// L'annuncio di apertura: la caratteristica del campo, una sola volta (02 §4.4.2),
    /// e la presenza di ostacoli (01 §7.6).
    func annuncioApertura() -> String {
        let caratteristica = testi.termine("caratteristica." + stato.caratteristica).testo
        var testo = testi.frase("battaglia.annuncio_apertura",
                                testi.frase("avvio.titolo").testo,
                                stato.griglia.righe, stato.griglia.colonne, caratteristica).testo
        if !stato.ostacoli.isEmpty {
            testo += ", " + testi.frase("cella.ostacolo_contenuto").testo
        }
        return testo
    }

    // MARK: - Resoconto (01 §15.3.1)

    func vociResoconto() -> [String] {
        guard let esito = stato.esito else { return [] }
        var voci: [String] = []
        let modo = testi.frase(esito.modo == .annientamento
                               ? "resoconto.modo_annientamento" : "resoconto.modo_ritirata_compiuta").testo
        voci.append(esito.sconfitto == .giocatore
                    ? testi.frase("resoconto.esito_sconfitta", modo).testo
                    : testi.frase("resoconto.esito_vittoria", modo).testo)
        voci.append(testi.frase("resoconto.durata", esito.turni).testo)
        voci.append(testi.frase("resoconto.perdite_proprie",
                                Int(stato.perditeSubite[.giocatore] ?? 0),
                                Int(stato.forzeImpegnate[.giocatore] ?? 0)).testo)
        voci.append(testi.frase("resoconto.perdite_inflitte",
                                Int(stato.perditeSubite[.avversario] ?? 0)).testo)
        voci.append(testi.frase("resoconto.evacuati", stato.evacuati[.giocatore]?.count ?? 0).testo)
        let scariche = stato.sciami.values
            .filter { $0.parte == .giocatore }
            .reduce(0) { $0 + $1.munizioni }
        voci.append(testi.frase("resoconto.munizioni", scariche).testo)
        let riserve = stato.deck[.giocatore]?.reduce(0) { $0 + $1.esemplari } ?? 0
        voci.append(testi.frase("resoconto.riserve", riserve).testo)
        return voci
    }
}
