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
    var vista: VistaBattaglia { VistaBattaglia(motore: motore, stato: stato, parte: .giocatore) }

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

    /// Il percorso verso la destinazione: regola di gioco, calcolata dal Motore (00 §3.2).
    func percorsoMovimento(da id: IdSciame, a destinazione: Cella) -> [Cella]? {
        VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
            .percorsoMovimento(da: id, a: destinazione)
    }

    /// La lettera parlata di un reparto (01 §9.4.3): termine chiuso del vocabolario.
    func lettera(_ sciame: Sciame) -> String {
        testi.termine("lettera.\(sciame.lettera)").testo
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
        // La lettera in posizione fissa subito dopo il nome (01 §9.4.3, 02 §3.8.1).
        parti.append(sciame.parte == .giocatore
                     ? testi.frase("cella.occupante_proprio", nome, lettera(sciame)).testo
                     : testi.frase("cella.occupante_avversario", nome, lettera(sciame)).testo)
        guard verbosita != .sintetico else { return parti }
        // Reparto élite della fase corrente (incarico 11, terza decisione): la ragione è
        // l'addestramento superiore, non la meccanica; l'annuncio rende riconoscibile la
        // condizione — resta ai propri ordini anche in mischia — prima di ingaggiare, per
        // il proprio reparto come per l'avversario.
        if valori.archetipi[sciame.archetipo]!.eliteFase == stato.fase {
            parti.append(testi.frase("battaglia.reparto_elite").testo)
        }
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

    // MARK: - Designazione del bersaglio (02 §9.2.1, §9.3)

    /// La voce di tiro su un bersaglio, con l'ordine fisso delle informazioni:
    /// bersaglio con nome e lettera, efficacia (01 §9.9.1), vicinanza (01 §9.10.1)
    /// e, se il bersaglio non è isolato, accerchiamento (01 §9.10.2). Restituisce
    /// niente quando il tiro non è ammissibile: un'azione impossibile non si offre (02 §9.5).
    func voceTiro(da sciame: IdSciame, su bersaglio: Sciame) -> String? {
        guard let anteprima = vista.anteprimaTiro(da: sciame, su: bersaglio.id),
              let vicinanza = anteprima.vicinanza else { return nil }
        let nome = testi.frase("unita." + bersaglio.archetipo).testo
        if anteprima.accerchiamento == .isolato {
            return testi.frase("pannello.tira_su", nome, lettera(bersaglio),
                               testi.termine(anteprima.efficacia.rawValue).testo,
                               testi.termine(vicinanza.rawValue).testo).testo
        }
        return testi.frase("pannello.tira_su_accerchiato", nome, lettera(bersaglio),
                           testi.termine(anteprima.efficacia.rawValue).testo,
                           testi.termine(vicinanza.rawValue).testo,
                           testi.termine(anteprima.accerchiamento.rawValue).testo).testo
    }

    /// La voce di ingaggio, con lo stesso ordine fisso della voce di tiro, senza la
    /// vicinanza, che in mischia non esiste. L'efficacia vi compare come 02 §9.2.1
    /// prescrive per ogni azione con bersaglio; in coda la risposta che il bersaglio
    /// opporrebbe (01 §9.11.3, 02 §9.3.1): prima ciò che si infligge, poi ciò che si riceve.
    func voceIngaggio(da sciame: IdSciame, su bersaglio: Sciame) -> String? {
        guard let anteprima = vista.anteprimaIngaggio(da: sciame, su: bersaglio.id),
              let risposta = anteprima.risposta else { return nil }
        let nome = testi.frase("unita." + bersaglio.archetipo).testo
        if anteprima.accerchiamento == .isolato {
            return testi.frase("pannello.ingaggia", nome, lettera(bersaglio),
                               bersaglio.posizione.riga, bersaglio.posizione.colonna,
                               testi.termine(anteprima.efficacia.rawValue).testo,
                               testi.termine(risposta.rawValue).testo).testo
        }
        return testi.frase("pannello.ingaggia_accerchiato", nome, lettera(bersaglio),
                           bersaglio.posizione.riga, bersaglio.posizione.colonna,
                           testi.termine(anteprima.efficacia.rawValue).testo,
                           testi.termine(anteprima.accerchiamento.rawValue).testo,
                           testi.termine(risposta.rawValue).testo).testo
    }

    // MARK: - Deck

    private func elementoDeck(_ indice: Int) -> ElementoDeck? {
        guard let mazzo = stato.deck[.giocatore], mazzo.indices.contains(indice) else { return nil }
        return mazzo[indice]
    }

    /// L'identità di un elemento del deck: il nome del suo archetipo (02 §8.2).
    func nomeElementoDeck(indice: Int) -> String {
        guard let elemento = elementoDeck(indice) else { return "" }
        return testi.frase("unita." + elemento.archetipo).testo
    }

    /// Il valore annunciato di un elemento del deck, in ordine fisso: atomi,
    /// volume, esemplari residui, selezione (02 §8.2). Mai tagliato: sono le
    /// informazioni con cui si decide lo schieramento.
    /// - Parameter comeSelezionato: forza la forma più lunga, quella con il termine
    ///   di selezione. Serve alla tessera per riservare l'altezza dello stato più
    ///   lungo e non muovere la disposizione quando la selezione cambia: il valore
    ///   così ottenuto non si annuncia e non si disegna.
    func valoreElementoDeck(indice: Int, comeSelezionato: Bool = false) -> String {
        guard let elemento = elementoDeck(indice) else { return "" }
        let volume = elemento.atomi * valori.archetipi[elemento.archetipo]!.volumePerAtomo
        var parti = [
            testi.frase("battaglia.atomi_presenti", Int(elemento.atomi)).testo,
            testi.frase("deck.volume", Int(volume)).testo,
            testi.frase("deck.esemplari", elemento.esemplari).testo,
        ]
        if comeSelezionato || stato.selezione[.giocatore] == indice {
            parti.append(testi.frase("deck.selezionato").testo)
        }
        return parti.joined(separator: ", ")
    }

    /// La sigla dell'archetipo, SEGNAPOSTO TESTUALE dei simboli grafici finché non
    /// esistono (valori-provvisori.md). Decorazione della tessera, mai annunciata.
    func siglaElementoDeck(indice: Int) -> String {
        guard let elemento = elementoDeck(indice) else { return "" }
        return testi.frase("deck.sigla." + elemento.archetipo).testo
    }

    /// Gli atomi del reparto, per il quadratino della tessera. Il numero è già
    /// annunciato dall'etichetta: qui è decorazione visiva, non un canale nuovo.
    func atomiElementoDeck(indice: Int) -> String {
        guard let elemento = elementoDeck(indice) else { return "" }
        return String(elemento.atomi)
    }

    /// Il volume del reparto, per il quadratino della tessera. Come gli atomi: già
    /// annunciato dall'etichetta, qui decorazione visiva.
    func volumeElementoDeck(indice: Int) -> String {
        guard let elemento = elementoDeck(indice) else { return "" }
        return String(elemento.atomi * valori.archetipi[elemento.archetipo]!.volumePerAtomo)
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
