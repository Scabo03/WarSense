import Foundation
import Dati

/// Le regole della battaglia: validazione e applicazione dei comandi (05 §3.1).
/// Deterministico: stesso comando su stesso stato, stesso esito (00 §3.1).
/// Le formule sono struttura e vivono qui; ogni numero viene dai valori (00 §13.3, 05 §7.4).
public struct MotoreBattaglia: Sendable {
    public let valori: ValoriDiGioco

    public init(valori: ValoriDiGioco) { self.valori = valori }

    // MARK: - Accesso ai valori

    func archetipo(_ id: IdentificatoreDati) -> DefinizioneArchetipo { valori.archetipi[id]! }
    func formato(_ stato: StatoBattaglia) -> FormatoBattaglia { valori.formati[stato.formato]! }
    func caratteristica(_ stato: StatoBattaglia) -> CaratteristicaCampo { valori.caratteristiche[stato.caratteristica]! }

    func modificatore(_ gancio: CaratteristicaCampo.Gancio, _ stato: StatoBattaglia) -> Scalato {
        caratteristica(stato).modificatori[gancio] ?? .uno
    }

    // MARK: - Formule uniche condivise (00 §13.3)

    /// Volume di uno sciame: atomi per volume unitario (01 §3.4.4).
    public func volume(di sciame: Sciame) -> Int64 {
        sciame.atomiIniziali * archetipo(sciame.archetipo).volumePerAtomo
    }

    /// La formula unica del costo di piazzamento, avanzamento e ritiro (01 §8.6, §8.7):
    /// volume × (1 + penalità × profondità proporzionale), troncata, con minimo (00 §13.5, §13.6).
    public func costo(archetipo id: IdentificatoreDati, atomi: Int64, cella: Cella,
                      parte: Parte, stato: StatoBattaglia) -> Int64 {
        let a = archetipo(id)
        let volumeTotale = atomi * a.volumePerAtomo
        let g = stato.griglia
        let profonditaMillesimi = Int64(g.avanzamento(di: cella, per: parte)) * 1000 / Int64(max(1, g.righe - 1))
        let fattore = Scalato.uno + a.penalitaAvanzamento * Scalato(millesimi: profonditaMillesimi)
        let grezzo = fattore.applicato(a: volumeTotale)
        return max(valori.minimi.costoPiazzamentoMinimo, grezzo)
    }

    /// Sconto dell'imboscante sui piazzamenti dei suoi turni di vantaggio (01 §9.3.2, §9.3.6).
    func conScontoSePertinente(_ costo: Int64, parte: Parte, stato: StatoBattaglia) -> Int64 {
        guard case .vantaggio = stato.sorpresa, parte == stato.primoOccupante else { return costo }
        let f = formato(stato)
        let scontato = (Scalato.uno - f.scontoImboscante).applicato(a: costo)
        return max(valori.minimi.costoPiazzamentoMinimo, scontato)
    }

    /// La formula unica dell'efficacia offesa-protezione (01 §9.9): due poteri contro due pare,
    /// mai una tabella a doppia entrata (00 §13.3). L'offesa poco adatta non è mai inefficace.
    public func efficacia(offesa: ProfiloOffesa, protezione: ProfiloProtezione) -> Scalato {
        let resa = offesa.potereSaturazione * (Scalato.uno - protezione.paraSaturazione)
                 + offesa.poterePerforazione * (Scalato.uno - protezione.paraPerforazione)
        return resa < valori.combattimento.efficaciaMinima ? valori.combattimento.efficaciaMinima : resa
    }

    /// L'annuncio è qualitativo, il modello resta graduato (01 §9.9.1).
    public func efficaciaQualitativa(offesa: ProfiloOffesa, protezione: ProfiloProtezione) -> EfficaciaQualitativa {
        efficacia(offesa: offesa, protezione: protezione) >= valori.combattimento.sogliaPocoEfficace
            ? .efficace : .pocoEfficace
    }

    /// Danno inflitto da uno sciame con una data offesa a un bersaglio (01 §9.2.1).
    func danno(da attaccante: Sciame, offesa: ProfiloOffesa, a bersaglio: Sciame,
               coefficiente: Scalato, stato: StatoBattaglia) -> Int64 {
        let a = archetipo(attaccante.archetipo)
        let atomi = attaccante.atomiPresenti(puntiVitaPerAtomo: a.puntiVitaPerAtomo,
                                             minimo: valori.minimi.atomiMinimiSciameVivo)
        let base = a.capacitaOffensivaPerAtomo * atomi
        let eff = efficacia(offesa: offesa, protezione: valori.protezioni[bersaglio.protezione]!)
        let modificato = (eff * coefficiente * modificatore(.coefficienteDanno, stato)).applicato(a: base)
        return max(valori.minimi.dannoMinimo, modificato)
    }

    /// Gittata effettiva con l'eventuale gancio della caratteristica (05 §7.7).
    func gittataEffettiva(_ gittata: Int, stato: StatoBattaglia) -> Int {
        guard gittata > 0 else { return 0 }
        let coeff = modificatore(.variazioneGittate, stato)
        return max(1, Int(coeff.applicato(a: Int64(gittata))))
    }

    /// Proporzione delle perdite sulla base delle sole forze effettivamente impiegate
    /// sul campo (01 §10.2, decisione del titolare): le riserve nel deck non contano.
    /// È la base unica di ogni soglia che dipende dalle perdite subite in battaglia.
    public func proporzionePerdite(per parte: Parte, stato: StatoBattaglia) -> Scalato {
        let impiegate = stato.forzeImpegnate[parte] ?? 0
        guard impiegate > 0 else { return .zero }
        let perdite = stato.perditeSubite[parte] ?? 0
        return Scalato(millesimi: perdite * 1000 / impiegate)
    }

    /// Soglia effettiva della resa: la soglia minima si accorcia con le perdite (01 §10.2).
    public func sogliaResaEffettiva(per parte: Parte, stato: StatoBattaglia) -> Int {
        let f = formato(stato)
        let riduzione = f.accorciamentoResaPerPerdite * proporzionePerdite(per: parte, stato: stato)
        let fattore = riduzione >= .uno ? Scalato.zero : Scalato.uno - riduzione
        return max(1, Int(fattore.applicato(a: Int64(f.sogliaMinimaResaTurni))))
    }

    // MARK: - Validazione (05 §3.2: validazione e anteprima sono la stessa cosa)

    public func valida(_ comando: ComandoBattaglia, parte: Parte, stato: StatoBattaglia) -> EsitoValidazione {
        if stato.esito != nil { return .nonValido(.battagliaConclusa) }
        if parte != stato.parteDiTurno { return .nonValido(.nonIlTurno) }
        let bilancio = stato.bilancio[parte]!

        switch comando {
        case .seleziona(let indice):
            guard let elementi = stato.deck[parte], elementi.indices.contains(indice),
                  elementi[indice].esemplari > 0 else { return .nonValido(.bersaglioNonValido) }
            return .valido(.nessuno)

        case .deseleziona:
            return .valido(.nessuno)

        case .piazza(let cella):
            guard let indice = stato.selezione[parte],
                  let elemento = stato.deck[parte]?[indice], elemento.esemplari > 0 else {
                return .nonValido(.nessunaSelezione)
            }
            guard !stato.ostacoli.contains(cella), stato.griglia.contiene(cella) else {
                return .nonValido(.ostacolo)
            }
            guard stato.occupante(di: cella) == nil else { return .nonValido(.occupata) }
            let f = formato(stato)
            let righe = stato.griglia.righeDiPiazzamento(per: parte, quante: f.righeDiPiazzamento)
            guard righe.contains(cella.riga) else { return .nonValido(.troppoAvanzata) }
            let c = conScontoSePertinente(
                costo(archetipo: elemento.archetipo, atomi: elemento.atomi, cella: cella, parte: parte, stato: stato),
                parte: parte, stato: stato)
            guard c <= bilancio.disponibile else { return .nonValido(.troppoAvanzata) }
            return .valido(CostiDichiarati(volume: c, residuoDopo: bilancio.disponibile - c))

        case .muovi(let id, let percorso):
            guard let sciame = stato.sciami[id], sciame.parte == parte else { return .nonValido(.bersaglioNonValido) }
            guard !stato.impegnato(id) else { return .nonValido(.impegnato) }
            guard !sciame.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            guard percorso.count == 1 || percorso.count == 2 else { return .nonValido(.bersaglioNonValido) }
            var da = sciame.posizione
            for passo in percorso {
                guard stato.griglia.contiene(passo), stato.griglia.adiacenti(da, passo) else {
                    return .nonValido(.bersaglioNonValido)
                }
                guard !stato.ostacoli.contains(passo) else { return .nonValido(.ostacolo) }
                guard stato.occupante(di: passo) == nil else { return .nonValido(.occupata) }
                da = passo
            }
            let destinazione = percorso.last!
            var c = costo(archetipo: sciame.archetipo, atomi: sciame.atomiIniziali,
                          cella: destinazione, parte: parte, stato: stato)
            if percorso.count == 2 {
                c = max(valori.minimi.costoPiazzamentoMinimo,
                        formato(stato).coefficienteSpostamentoDoppio.applicato(a: c))
            }
            c = max(valori.minimi.costoPiazzamentoMinimo,
                    modificatore(.coefficienteCostoMovimento, stato).applicato(a: c))
            guard c <= bilancio.disponibile else { return .nonValido(.volumeInsufficiente) }
            return .valido(CostiDichiarati(volume: c, residuoDopo: bilancio.disponibile - c))

        case .tira(let id, let bersaglioId, let proiettile):
            guard let sciame = stato.sciami[id], sciame.parte == parte,
                  let bersaglio = stato.sciami[bersaglioId], bersaglio.parte == parte.avversaria else {
                return .nonValido(.bersaglioNonValido)
            }
            guard !stato.impegnato(id) else { return .nonValido(.impegnato) }
            guard !sciame.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            let a = archetipo(sciame.archetipo)
            guard a.offeseTiro[proiettile] != nil else { return .nonValido(.bersaglioNonValido) }
            guard sciame.munizioni > 0 else { return .nonValido(.munizioniEsaurite) }
            let distanza = stato.griglia.distanza(sciame.posizione, bersaglio.posizione)
            guard distanza <= gittataEffettiva(a.gittataDisturbo, stato: stato) else {
                return .nonValido(.fuoriTiro)
            }
            return .valido(.nessuno) // il tiro non consuma volume: consuma l'azione e una scarica

        case .ingaggia(let id, let bersaglioId):
            guard let sciame = stato.sciami[id], sciame.parte == parte,
                  let bersaglio = stato.sciami[bersaglioId], bersaglio.parte == parte.avversaria else {
                return .nonValido(.bersaglioNonValido)
            }
            guard !stato.impegnato(id) else { return .nonValido(.impegnato) }
            guard !sciame.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            guard stato.griglia.distanza(sciame.posizione, bersaglio.posizione) == 1 else {
                return .nonValido(.fuoriTiro)
            }
            let coppia = Coppia(id, bersaglioId)
            if let divieto = stato.divietoIngaggio[coppia], stato.giro <= divieto {
                return .nonValido(.bersaglioNonValido) // nessun nuovo ingaggio per un turno (01 §9.8.2)
            }
            return .valido(.nessuno) // l'ingaggio è gratuito (01 §9.5.0.1)

        case .dichiaraResa:
            guard stato.resaDichiarataDa == nil else { return .nonValido(.resaNonDisponibile) }
            guard stato.giro >= sogliaResaEffettiva(per: parte, stato: stato) else {
                return .nonValido(.resaNonDisponibile)
            }
            return .valido(.nessuno)

        case .ritiraUnita(let id):
            guard stato.resaDichiarataDa == parte else { return .nonValido(.resaNonDisponibile) }
            guard let sciame = stato.sciami[id], sciame.parte == parte else { return .nonValido(.bersaglioNonValido) }
            guard !stato.impegnato(id) else { return .nonValido(.impegnato) } // 01 §10.4.1
            // Il costo del ritiro usa la formula unica sulla riga di partenza (01 §8.7, §10.4).
            let c = costo(archetipo: sciame.archetipo, atomi: sciame.atomiIniziali,
                          cella: sciame.posizione, parte: parte, stato: stato)
            guard c <= bilancio.disponibile else { return .nonValido(.volumeInsufficiente) }
            return .valido(CostiDichiarati(volume: c, residuoDopo: bilancio.disponibile - c))

        case .fineTurno:
            return .valido(.nessuno)
        }
    }

    // MARK: - Applicazione

    /// Applica un comando valido. Un comando non valido è un errore di programmazione (05 §3.1).
    public func applica(_ comando: ComandoBattaglia, parte: Parte,
                        stato iniziale: StatoBattaglia) -> (StatoBattaglia, [EventoBattaglia]) {
        precondition(valida(comando, parte: parte, stato: iniziale).eValido, "comando.non.valido")
        var stato = iniziale
        var eventi: [EventoBattaglia] = []

        switch comando {
        case .seleziona(let indice):
            stato.selezione[parte] = indice

        case .deseleziona:
            stato.selezione[parte] = nil

        case .piazza(let cella):
            let indice = stato.selezione[parte]!
            var elemento = stato.deck[parte]![indice]
            let costiDichiarati = valida(comando, parte: parte, stato: stato).costi!
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let a = archetipo(elemento.archetipo)
            let sciame = Sciame(id: id, parte: parte, archetipo: elemento.archetipo,
                                protezione: elemento.protezione, atomiIniziali: elemento.atomi,
                                serbatoio: elemento.atomi * a.puntiVitaPerAtomo,
                                munizioni: a.dotazioneMunizioni, posizione: cella,
                                azioneSpesa: true, // 01 §8.1.2
                                rinforzo: false)
            stato.sciami[id] = sciame
            stato.forzeImpegnate[parte, default: 0] += sciame.serbatoio // base delle perdite (01 §10.2)
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            elemento.esemplari -= 1
            stato.deck[parte]![indice] = elemento
            eventi.append(.piazzamentoConfermato(parte: parte, sciame: id, cella: cella,
                                                 costo: costiDichiarati.volume,
                                                 residuo: costiDichiarati.residuoDopo))
            if elemento.esemplari == 0 {
                stato.selezione[parte] = nil // deselezione automatica (01 §8.4)
                eventi.append(.elementoDeckEsaurito(parte: parte, indice: indice))
            }

        case .muovi(let id, let percorso):
            let costiDichiarati = valida(comando, parte: parte, stato: stato).costi!
            stato.sciami[id]!.posizione = percorso.last!
            stato.sciami[id]!.azioneSpesa = true
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            eventi.append(.spostamentoEseguito(sciame: id, a: percorso.last!,
                                               costo: costiDichiarati.volume,
                                               residuo: costiDichiarati.residuoDopo))

        case .tira(let id, let bersaglioId, let proiettile):
            let sciame = stato.sciami[id]!
            let bersaglio = stato.sciami[bersaglioId]!
            let a = archetipo(sciame.archetipo)
            let offesa = a.offeseTiro[proiettile]!
            let distanza = stato.griglia.distanza(sciame.posizione, bersaglio.posizione)
            let entroPericolosita = distanza <= gittataEffettiva(a.gittataPericolosita, stato: stato)
            // La fascia che uccide è la pericolosità; entro il solo disturbo il tiro rende una frazione (01 §3.4.1).
            let coefficiente = entroPericolosita ? Scalato.uno : valori.combattimento.coefficienteTiroDisturbo
            let inflitto = danno(da: sciame, offesa: offesa, a: bersaglio, coefficiente: coefficiente, stato: stato)
            let qualitativa = efficaciaQualitativa(offesa: offesa,
                                                   protezione: valori.protezioni[bersaglio.protezione]!)
            stato.sciami[id]!.munizioni -= 1
            stato.sciami[id]!.azioneSpesa = true
            applicaDanno(inflitto, a: bersaglioId, stato: &stato, eventi: &eventi)
            eventi.append(.tiroEseguito(sciame: id, bersaglio: bersaglioId, danno: inflitto, efficacia: qualitativa))
            if stato.sciami[id]!.munizioni == 0 {
                eventi.append(.munizioniEsaurite(sciame: id, cella: stato.sciami[id]!.posizione))
            }

        case .ingaggia(let id, let bersaglioId):
            let sciame = stato.sciami[id]!
            let bersaglio = stato.sciami[bersaglioId]!
            stato.contatti.append(Contatto(primo: id, secondo: bersaglioId,
                                           consistenzaIngressoPrimo: sciame.serbatoio,
                                           consistenzaIngressoSecondo: bersaglio.serbatoio))
            stato.sciami[id]!.azioneSpesa = true
            eventi.append(.contattoAvviato(cella: bersaglio.posizione))

        case .dichiaraResa:
            stato.resaDichiarataDa = parte
            eventi.append(.resaDichiarata(parte: parte))

        case .ritiraUnita(let id):
            let costiDichiarati = valida(comando, parte: parte, stato: stato).costi!
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            stato.evacuati[parte, default: []].append(id)
            stato.sciami[id] = nil
            eventi.append(.unitaEvacuata(sciame: id, costo: costiDichiarati.volume))

        case .fineTurno:
            eventi.append(contentsOf: concludiTurno(&stato))
        }

        verificaCondizioniDiChiusura(&stato, eventi: &eventi)
        return (stato, eventi)
    }

    // MARK: - Turni e giri (05 §3.9)

    /// Prepara il primo turno di una battaglia appena creata.
    func apriPrimoTurno(_ stato: inout StatoBattaglia) -> [EventoBattaglia] {
        iniziaTurno(di: stato.primoOccupante, stato: &stato)
        return [.turnoIniziato(parte: stato.parteDiTurno, numeroGiro: stato.giro)]
    }

    private func concludiTurno(_ stato: inout StatoBattaglia) -> [EventoBattaglia] {
        var eventi: [EventoBattaglia] = []
        let f = formato(stato)
        let chiFinisce = stato.parteDiTurno

        // Riporto: sul budget di base, e il riportato non genera riporto (01 §9.3.3, §9.3.4).
        let b = stato.bilancio[chiFinisce]!
        let nonSpesoDellaBase = max(0, b.baseTurno - b.spesa)
        let tetto = f.quotaRiporto.applicato(a: f.budgetVolumeBase)
        let riporto = min(nonSpesoDellaBase, tetto)
        stato.bilancio[chiFinisce] = BilancioVolume(baseTurno: 0, riportoEntrante: riporto, spesa: 0)

        // Chi agisce ora, secondo la fase della sorpresa (01 §9.3.2.1).
        var prossima: Parte
        switch stato.sorpresa {
        case .vantaggio(let restanti):
            if chiFinisce == stato.primoOccupante && restanti > 1 {
                stato.sorpresa = .vantaggio(restanti: restanti - 1)
                prossima = stato.primoOccupante
            } else {
                stato.sorpresa = .opacita
                prossima = stato.primoOccupante.avversaria
            }
        case .opacita:
            // Il turno opaco di chi subisce è finito: dal turno dell'imboscante tutto è scoperto.
            stato.sorpresa = .trasparente
            eventi.append(.sorpresaConclusa)
            prossima = stato.primoOccupante
        case .trasparente:
            prossima = chiFinisce.avversaria
        }

        // Nuovo giro quando il turno torna al primo occupante: prima le mischie (01 §9.7.1).
        if prossima == stato.primoOccupante {
            stato.giro += 1
            eventi.append(contentsOf: risolviMischie(&stato))
        }

        iniziaTurno(di: prossima, stato: &stato)
        eventi.append(.turnoIniziato(parte: prossima, numeroGiro: stato.giro))
        return eventi
    }

    private func iniziaTurno(di parte: Parte, stato: inout StatoBattaglia) {
        let f = formato(stato)
        stato.parteDiTurno = parte
        stato.turniGiocati[parte, default: 0] += 1
        let primoTurno = stato.turniGiocati[parte] == 1
        let base = primoTurno ? f.coefficientePrimoTurno.applicato(a: f.budgetVolumeBase) : f.budgetVolumeBase
        let riporto = stato.bilancio[parte]?.riportoEntrante ?? 0
        stato.bilancio[parte] = BilancioVolume(baseTurno: base, riportoEntrante: riporto, spesa: 0)
        for id in stato.sciami.keys where stato.sciami[id]!.parte == parte {
            stato.sciami[id]!.azioneSpesa = false
        }
    }

    // MARK: - Risoluzione delle mischie (01 §9.7)

    private func risolviMischie(_ stato: inout StatoBattaglia) -> [EventoBattaglia] {
        guard !stato.contatti.isEmpty else { return [] }
        var eventi: [EventoBattaglia] = []

        // Danni simultanei: prima si calcolano tutti, poi si applicano (05 §3.9).
        struct DannoCalcolato { let bersaglio: IdSciame; let danno: Int64 }
        var danni: [DannoCalcolato] = []
        var esiti: [EsitoContatto] = []
        let contattiOrdinati = stato.contatti.sorted {
            ($0.primo, $0.secondo) < ($1.primo, $1.secondo)
        }
        for contatto in contattiOrdinati {
            guard let a = stato.sciami[contatto.primo], let b = stato.sciami[contatto.secondo] else { continue }
            let dannoAB = danno(da: a, offesa: archetipo(a.archetipo).offesaMischia, a: b,
                               coefficiente: .uno, stato: stato)
            let dannoBA = danno(da: b, offesa: archetipo(b.archetipo).offesaMischia, a: a,
                               coefficiente: .uno, stato: stato)
            danni.append(DannoCalcolato(bersaglio: contatto.secondo, danno: dannoAB))
            danni.append(DannoCalcolato(bersaglio: contatto.primo, danno: dannoBA))
            esiti.append(EsitoContatto(cellaPrimo: a.posizione, cellaSecondo: b.posizione,
                                       dannoAlPrimo: dannoBA, dannoAlSecondo: dannoAB))
        }
        eventi.append(.esitoMischiaComplessivo(esiti))
        for d in danni { applicaDanno(d.danno, a: d.bersaglio, stato: &stato, eventi: &eventi) }

        // Disingaggi, dopo l'applicazione dei danni (01 §9.8), in ordine deterministico.
        for contatto in contattiOrdinati {
            guard stato.contatti.contains(contatto),
                  stato.sciami[contatto.primo] != nil, stato.sciami[contatto.secondo] != nil else { continue }
            let coppia = Coppia(contatto.primo, contatto.secondo)
            guard !stato.coppieStaccate.contains(coppia) else { continue } // 01 §9.8.3
            for (id, ingresso) in [(contatto.primo, contatto.consistenzaIngressoPrimo),
                                   (contatto.secondo, contatto.consistenzaIngressoSecondo)] {
                guard let sciame = stato.sciami[id], stato.contatti.contains(contatto) else { continue }
                let perdite = ingresso - sciame.serbatoio
                let soglia = archetipo(sciame.archetipo).sogliaDisingaggio
                // Proporzione delle perdite sulla consistenza d'ingresso (01 §9.8).
                guard ingresso > 0, Scalato(millesimi: perdite * 1000 / ingresso) >= soglia else { continue }
                // Ritrazione di una cella verso le proprie retrovie, se una cella è libera (01 §9.8.2).
                let candidate = stato.griglia.celleArretrate(di: sciame.posizione, per: sciame.parte)
                    .filter { !stato.ostacoli.contains($0) && stato.occupante(di: $0) == nil }
                guard let destinazione = candidate.first else { continue } // senza spazio la mischia continua
                let da = sciame.posizione
                stato.sciami[id]!.posizione = destinazione
                stato.sciami[id]!.azioneSpesa = true // torna controllabile dal turno successivo (01 §9.8.2)
                stato.contatti.removeAll { $0 == contatto }
                stato.coppieStaccate.insert(coppia)
                stato.divietoIngaggio[coppia] = stato.giro // nessun ingaggio per un turno
                eventi.append(.disingaggio(sciame: id, da: da, a: destinazione))
            }
        }
        return eventi
    }

    private func applicaDanno(_ danno: Int64, a id: IdSciame,
                              stato: inout StatoBattaglia, eventi: inout [EventoBattaglia]) {
        guard var sciame = stato.sciami[id] else { return }
        let effettivo = min(danno, sciame.serbatoio)
        sciame.serbatoio -= effettivo
        stato.perditeSubite[sciame.parte, default: 0] += effettivo
        if sciame.serbatoio <= 0 {
            // Sciame disfatto: lascia il campo (01 §4.3) e i suoi contatti finiscono.
            stato.sciami[id] = nil
            stato.contatti.removeAll { $0.coinvolge(id) }
            eventi.append(.sciameDisfatto(sciame: id, cella: sciame.posizione, parte: sciame.parte))
        } else {
            stato.sciami[id] = sciame
        }
    }

    // MARK: - Condizioni di chiusura (01 §15.2.3)

    private func verificaCondizioniDiChiusura(_ stato: inout StatoBattaglia,
                                              eventi: inout [EventoBattaglia]) {
        guard stato.esito == nil else { return }
        let f = formato(stato)

        // Annientamento: nessuno sciame in campo e nessun esemplare nel deck.
        for parte in Parte.allCases {
            let inCampo = stato.sciami.values.contains { $0.parte == parte }
            let nelDeck = (stato.deck[parte] ?? []).contains { $0.esemplari > 0 }
            if !inCampo && !nelDeck {
                let esito = EsitoBattaglia(sconfitto: parte, modo: .annientamento, turni: stato.giro)
                stato.esito = esito
                eventi.append(.battagliaConclusa(esito))
                return
            }
        }

        // Fine della ritirata combattuta: l'avanzante raggiunge la riga di soglia (01 §10.3),
        // oppure il ritirante non ha più nulla in campo.
        if let ritirante = stato.resaDichiarataDa {
            let avanzante = ritirante.avversaria
            let sogliaRaggiunta = stato.sciami.values.contains { sciame in
                guard sciame.parte == avanzante else { return false }
                return stato.griglia.avanzamento(di: sciame.posizione, per: avanzante)
                    >= stato.griglia.righe - 1 - f.righeSogliaRitirata
            }
            let ritiranteVuoto = !stato.sciami.values.contains { $0.parte == ritirante }
            if sogliaRaggiunta || ritiranteVuoto {
                let esito = EsitoBattaglia(sconfitto: ritirante, modo: .ritirataCompiuta, turni: stato.giro)
                stato.esito = esito
                eventi.append(.battagliaConclusa(esito))
            }
        }
    }
}
