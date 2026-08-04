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
    public func danno(da attaccante: Sciame, offesa: ProfiloOffesa, a bersaglio: Sciame,
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
    public func gittataEffettiva(_ gittata: Int, stato: StatoBattaglia) -> Int {
        guard gittata > 0 else { return 0 }
        let coeff = modificatore(.variazioneGittate, stato)
        return max(1, Int(coeff.applicato(a: Int64(gittata))))
    }

    // MARK: - Modificatore di vicinanza per il tiro (01 §9.10.1)

    /// Prossimità del bersaglio dentro la gittata: zero al limite della gittata,
    /// uno alla minima distanza. Deterministica e calcolabile dal solo stato.
    /// Con gittata di una sola cella ogni bersaglio a portata è alla minima distanza.
    public func prossimita(distanza: Int, gittata: Int) -> Scalato {
        guard gittata > 1 else { return .uno }
        let dentro = min(max(distanza, 1), gittata)
        return Scalato(millesimi: Int64(gittata - dentro) * 1000 / Int64(gittata - 1))
    }

    /// La resa del tiro in funzione della distanza (01 §9.10.1): una formula unica
    /// che interpola fra i due estremi dichiarati nei valori (00 §13.3). Al limite
    /// della gittata il tiro rende meno dell'accoppiamento, cioè disturba; alla
    /// minima distanza rende molto di più, cioè uccide. È il solo modificatore che
    /// può ridurre la resa, e la riduzione è dichiarata in 01 §9.9.3.
    public func coefficienteVicinanza(distanza: Int, gittata: Int) -> Scalato {
        let c = valori.combattimento
        return c.resaTiroAlLimite
            + (c.resaTiroAllaMinimaDistanza - c.resaTiroAlLimite)
            * prossimita(distanza: distanza, gittata: gittata)
    }

    /// La fascia con cui la vicinanza si annuncia (01 §9.10.1), soglie dai valori (03 §5.15).
    public func fasciaVicinanza(distanza: Int, gittata: Int) -> FasciaVicinanza {
        let p = prossimita(distanza: distanza, gittata: gittata)
        if p <= valori.combattimento.fasciaVicinanzaLontanoFino { return .lontano }
        if p <= valori.combattimento.fasciaVicinanzaRavvicinatoFino { return .ravvicinato }
        return .aRidosso
    }

    // MARK: - Modificatore di accerchiamento (01 §9.10.2)

    /// I reparti che concorrono contro un bersaglio: quelli della parte avversa che,
    /// nello stato corrente e per la sola loro posizione, lo hanno sotto la propria
    /// offesa — a contatto di mischia oppure con il bersaglio dentro la gittata.
    /// L'insieme si ricava dal solo stato: non dipende da quali azioni siano già
    /// state compiute (munizioni spese, azione consumata) né dall'ordine in cui i
    /// danni si applicano, ed è quindi coerente con la risoluzione simultanea.
    /// Chi è impegnato in una mischia che non comprende il bersaglio non concorre:
    /// è trattenuto altrove.
    public func concorrenti(contro id: IdSciame, stato: StatoBattaglia) -> [IdSciame] {
        guard let bersaglio = stato.sciami[id] else { return [] }
        return stato.sciamiOrdinati.compactMap { sciame -> IdSciame? in
            guard sciame.parte == bersaglio.parte.avversaria else { return nil }
            let colBersaglio = stato.contatti.contains { $0.coinvolge(sciame.id) && $0.coinvolge(id) }
            if colBersaglio { return sciame.id }
            guard !stato.impegnato(sciame.id) else { return nil }
            let a = archetipo(sciame.archetipo)
            let distanza = stato.griglia.distanza(sciame.posizione, bersaglio.posizione)
            let portata = a.offesaTiro != nil ? gittataEffettiva(a.gittata, stato: stato) : 1
            return distanza <= portata ? sciame.id : nil
        }
    }

    /// Il coefficiente dell'accerchiamento (01 §9.10.2): formula unica più un passo
    /// dai valori (00 §13.3). Cresce col quadrato dei concorrenti eccedenti il primo,
    /// sicché due stringono moderatamente e tre o quattro assai di più; oltre il
    /// tetto dichiarato nei valori non cresce più.
    public func coefficienteAccerchiamento(concorrenti numero: Int) -> Scalato {
        let contati = Int64(concorrentiContati(numero))
        let eccedenti = contati - 1
        return .uno + valori.combattimento.passoAccerchiamento * Scalato(intero: eccedenti * eccedenti)
    }

    /// La fascia con cui l'accerchiamento si annuncia (01 §9.10.2): isolato è la
    /// condizione ordinaria e non si annuncia (02 §8.7.1).
    public func fasciaAccerchiamento(concorrenti numero: Int) -> FasciaAccerchiamento {
        switch concorrentiContati(numero) {
        case ...1: return .isolato
        case 2: return .stretto
        default: return .circondato
        }
    }

    private func concorrentiContati(_ numero: Int) -> Int {
        max(1, min(numero, valori.combattimento.concorrentiMassimi))
    }

    /// Il coefficiente di accerchiamento che si applica a chi colpisce quel bersaglio.
    func accerchiamento(su id: IdSciame, stato: StatoBattaglia) -> Scalato {
        coefficienteAccerchiamento(concorrenti: concorrenti(contro: id, stato: stato).count)
    }

    // MARK: - Limite dei bersagli simultanei (01 §9.11)

    /// Il posto che un nemico occupa nella mischia di un reparto, contato dall'ordine
    /// di arrivo dei contatti e non dalla potenza né dalla posizione (01 §9.11.1).
    /// Zero è il primo arrivato, uno il secondo, due e oltre quelli che restano fuori.
    /// L'elenco dei contatti conserva l'ordine di arrivo per costruzione: si appende
    /// all'ingaggio e si rimuove senza riordinare, quindi il posto si ricava dal solo
    /// stato ed è indipendente dall'ordine in cui i danni si applicano.
    public func postoInMischia(di id: IdSciame, contro nemico: IdSciame,
                               stato: StatoBattaglia) -> Int? {
        stato.contatti
            .filter { $0.coinvolge(id) }
            .firstIndex { $0.coinvolge(nemico) }
    }

    /// La resa con cui un reparto risponde al nemico che occupa quel posto (01 §9.11):
    /// piena al primo, ridotta dal malus dei dati al secondo, nessuna dal terzo in poi.
    /// Il caso senza risposta restituisce niente e non un coefficiente nullo, perché
    /// un danno calcolato con coefficiente nullo risalirebbe al minimo di 00 §13.6:
    /// qui il danno non è ridotto a zero, semplicemente non c'è.
    public func resaDiRisposta(posto: Int) -> Scalato? {
        switch posto {
        case 0: return .uno
        case 1: return valori.combattimento.resaControSecondoBersaglio
        default: return nil
        }
    }

    /// La condizione di risposta che il designante riceverebbe ingaggiando quel
    /// bersaglio (01 §9.11.3): dipende da quanti nemici il bersaglio già fronteggia,
    /// poiché chi sopraggiunge occupa il posto successivo.
    public func rispostaAttesa(ingaggiando bersaglio: IdSciame, stato: StatoBattaglia) -> TipoRisposta {
        let occupati = stato.contatti.filter { $0.coinvolge(bersaglio) }.count
        return TipoRisposta(posto: occupati)
    }

    /// La fascia descrittiva di un danno (01 §9.7.2): proporzione sulla consistenza
    /// del colpito immediatamente prima dell'applicazione, soglie dai valori (03 §5.14).
    public func fascia(danno: Int64, consistenzaPrima: Int64) -> FasciaPerdite {
        guard danno > 0, consistenzaPrima > 0 else { return .nessuna }
        let proporzione = Scalato(millesimi: danno * 1000 / consistenzaPrima)
        if proporzione <= valori.combattimento.fasciaPerditeLieviFino { return .lievi }
        if proporzione <= valori.combattimento.fasciaPerditeSignificativeFino { return .significative }
        return .gravi
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

        case .tira(let id, let bersaglioId):
            guard let sciame = stato.sciami[id], sciame.parte == parte,
                  let bersaglio = stato.sciami[bersaglioId], bersaglio.parte == parte.avversaria else {
                return .nonValido(.bersaglioNonValido)
            }
            guard !stato.impegnato(id) else { return .nonValido(.impegnato) }
            guard !sciame.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            let a = archetipo(sciame.archetipo)
            guard a.offesaTiro != nil else { return .nonValido(.bersaglioNonValido) }
            guard sciame.munizioni > 0 else { return .nonValido(.munizioniEsaurite) }
            // Portata binaria (01 §3.4.1 versione 3.3): dentro la gittata unica, o niente.
            let distanza = stato.griglia.distanza(sciame.posizione, bersaglio.posizione)
            guard distanza <= gittataEffettiva(a.gittata, stato: stato) else {
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
            // La lettera in ordine di piazzamento, mai riusata (01 §9.4.3).
            let lettera = stato.prossimaLettera[parte] ?? 1
            stato.prossimaLettera[parte] = lettera + 1
            let a = archetipo(elemento.archetipo)
            let sciame = Sciame(id: id, parte: parte, archetipo: elemento.archetipo,
                                protezione: elemento.protezione, lettera: lettera,
                                atomiIniziali: elemento.atomi,
                                serbatoio: elemento.atomi * a.puntiVitaPerAtomo,
                                munizioni: a.dotazioneMunizioni, posizione: cella,
                                azioneSpesa: true, // 01 §8.1.2
                                rinforzo: false)
            stato.sciami[id] = sciame
            stato.forzeImpegnate[parte, default: 0] += sciame.serbatoio // base delle perdite (01 §10.2)
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            elemento.esemplari -= 1
            stato.deck[parte]![indice] = elemento
            eventi.append(.piazzamentoConfermato(parte: parte, sciame: id,
                                                 archetipo: sciame.archetipo, lettera: lettera,
                                                 cella: cella,
                                                 costo: costiDichiarati.volume,
                                                 residuo: costiDichiarati.residuoDopo))
            if elemento.esemplari == 0 {
                stato.selezione[parte] = nil // deselezione automatica (01 §8.4)
                eventi.append(.elementoDeckEsaurito(parte: parte, indice: indice))
            }

        case .muovi(let id, let percorso):
            let costiDichiarati = valida(comando, parte: parte, stato: stato).costi!
            let sciame = stato.sciami[id]!
            stato.sciami[id]!.posizione = percorso.last!
            stato.sciami[id]!.azioneSpesa = true
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            eventi.append(.spostamentoEseguito(parte: parte, sciame: id,
                                               archetipo: sciame.archetipo, lettera: sciame.lettera,
                                               a: percorso.last!,
                                               costo: costiDichiarati.volume,
                                               residuo: costiDichiarati.residuoDopo))

        case .tira(let id, let bersaglioId):
            let sciame = stato.sciami[id]!
            let bersaglio = stato.sciami[bersaglioId]!
            let a = archetipo(sciame.archetipo)
            // Il proiettile è del reparto (01 §3.3.1); dentro la gittata unica la resa è piena (01 §3.4.1).
            // Alla resa piena si applicano i due modificatori: la vicinanza al bersaglio
            // (01 §9.10.1) e l'accerchiamento del bersaglio (01 §9.10.2).
            let offesa = a.offesaTiro!
            let vicinanza = coefficienteVicinanza(
                distanza: stato.griglia.distanza(sciame.posizione, bersaglio.posizione),
                gittata: gittataEffettiva(a.gittata, stato: stato))
            let inflitto = danno(da: sciame, offesa: offesa, a: bersaglio,
                                 coefficiente: vicinanza * accerchiamento(su: bersaglioId, stato: stato),
                                 stato: stato)
            let qualitativa = efficaciaQualitativa(offesa: offesa,
                                                   protezione: valori.protezioni[bersaglio.protezione]!)
            let fasciaInflitta = fascia(danno: inflitto, consistenzaPrima: bersaglio.serbatoio)
            stato.sciami[id]!.munizioni -= 1
            stato.sciami[id]!.azioneSpesa = true
            applicaDanno(inflitto, a: bersaglioId, stato: &stato, eventi: &eventi)
            eventi.append(.tiroEseguito(parte: parte, sciame: id, bersaglio: bersaglioId,
                                        bersaglioArchetipo: bersaglio.archetipo,
                                        bersaglioLettera: bersaglio.lettera,
                                        danno: inflitto, fascia: fasciaInflitta,
                                        efficacia: qualitativa))
            if stato.sciami[id]!.munizioni == 0 {
                eventi.append(.munizioniEsaurite(sciame: id, cella: stato.sciami[id]!.posizione))
            }

        case .ingaggia(let id, let bersaglioId):
            let sciame = stato.sciami[id]!
            let bersaglio = stato.sciami[bersaglioId]!
            let contatto = Contatto(primo: id, secondo: bersaglioId,
                                    consistenzaIngressoPrimo: sciame.serbatoio,
                                    consistenzaIngressoSecondo: bersaglio.serbatoio)
            stato.contatti.append(contatto)
            stato.sciami[id]!.azioneSpesa = true
            // Il contatto si risolve nell'istante in cui si forma (01 §9.7.1):
            // chi ingaggia scambia i colpi subito, senza attendere che entrambe le
            // parti abbiano finito di agire. Si risolve QUESTO contatto soltanto:
            // gli altri già in piedi attendono l'inizio del giro nuovo.
            let (esiti, conseguenze) = risolvi([contatto], stato: &stato, conDisingaggi: false)
            if let esito = esiti.first {
                eventi.append(.contattoRisolto(parte: parte,
                                               bersaglioArchetipo: bersaglio.archetipo,
                                               bersaglioLettera: bersaglio.lettera,
                                               esito: esito))
            }
            eventi.append(contentsOf: conseguenze)

        case .dichiaraResa:
            stato.resaDichiarataDa = parte
            eventi.append(.resaDichiarata(parte: parte))

        case .ritiraUnita(let id):
            let costiDichiarati = valida(comando, parte: parte, stato: stato).costi!
            stato.bilancio[parte]!.spesa += costiDichiarati.volume
            stato.evacuati[parte, default: []].append(id)
            stato.sciami[id] = nil
            eventi.append(.unitaEvacuata(parte: parte, sciame: id, costo: costiDichiarati.volume))

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

    /// La mischia d'inizio giro: tutti i contatti ancora in piedi si risolvono
    /// insieme (01 §9.7.1). È la seconda delle due occasioni di risoluzione; la
    /// prima è l'istante in cui il contatto si forma.
    private func risolviMischie(_ stato: inout StatoBattaglia) -> [EventoBattaglia] {
        guard !stato.contatti.isEmpty else { return [] }
        var eventi: [EventoBattaglia] = []
        let (esiti, conseguenze) = risolvi(stato.contatti, stato: &stato, conDisingaggi: true)
        guard !esiti.isEmpty else { return conseguenze }
        eventi.append(.esitoMischiaComplessivo(esiti))
        eventi.append(contentsOf: conseguenze)
        return eventi
    }

    /// Risolve i contatti indicati e restituisce gli esiti più le conseguenze
    /// (reparti disfatti, disingaggi). Dentro UNA risoluzione la simultaneità resta
    /// intera: si calcolano tutti i danni delle due direzioni di ogni contatto prima
    /// di applicarne uno solo, e i posti in mischia e gli insiemi dei concorrenti si
    /// leggono una volta sola dallo stato con cui la risoluzione si apre (01 §9.11.1,
    /// §9.10.2.3). Ciò che è caduto con la risoluzione immediata è la simultaneità
    /// FRA risoluzioni diverse dello stesso turno, che è precisamente lo scopo della
    /// modifica: chi colpisce per primo colpisce prima.
    /// `conDisingaggi` distingue le due occasioni: lo scambio immediato dell'ingaggio
    /// non fa scattare la soglia di disingaggio, che resta un fatto d'inizio giro
    /// (01 §9.8.2, dove il reparto che si sfila torna controllabile dal turno
    /// successivo). Diversamente un reparto potrebbe ritrarsi nello stesso turno in
    /// cui gli è stato ordinato di attaccare, che nessuna regola prevede.
    private func risolvi(_ daRisolvere: [Contatto], stato: inout StatoBattaglia,
                         conDisingaggi: Bool)
        -> (esiti: [EsitoContatto], eventi: [EventoBattaglia]) {
        var eventi: [EventoBattaglia] = []
        struct DannoCalcolato { let bersaglio: IdSciame; let danno: Int64 }
        var danni: [DannoCalcolato] = []
        var esiti: [EsitoContatto] = []
        let contattiOrdinati = daRisolvere.sorted {
            ($0.primo, $0.secondo) < ($1.primo, $1.secondo)
        }
        for contatto in contattiOrdinati {
            guard let a = stato.sciami[contatto.primo], let b = stato.sciami[contatto.secondo] else { continue }
            // Ciascuno rende secondo il posto che l'altro occupa nella PROPRIA mischia
            // (01 §9.11): il posto viene dallo stato con cui questa risoluzione si
            // apre, quindi è lo stesso per tutti i contatti che vi rientrano e
            // l'ordine con cui li si percorre non lo tocca.
            // Chi resta oltre il secondo posto non infligge nulla: nessun danno da
            // calcolare, non un danno ridotto a zero (01 §9.11.2).
            let dannoAB = postoInMischia(di: contatto.primo, contro: contatto.secondo, stato: stato)
                .flatMap(resaDiRisposta(posto:))
                .map { resa in
                    danno(da: a, offesa: archetipo(a.archetipo).offesaMischia, a: b,
                          coefficiente: resa * accerchiamento(su: contatto.secondo, stato: stato),
                          stato: stato)
                } ?? 0
            let dannoBA = postoInMischia(di: contatto.secondo, contro: contatto.primo, stato: stato)
                .flatMap(resaDiRisposta(posto:))
                .map { resa in
                    danno(da: b, offesa: archetipo(b.archetipo).offesaMischia, a: a,
                          coefficiente: resa * accerchiamento(su: contatto.primo, stato: stato),
                          stato: stato)
                } ?? 0
            danni.append(DannoCalcolato(bersaglio: contatto.secondo, danno: dannoAB))
            danni.append(DannoCalcolato(bersaglio: contatto.primo, danno: dannoBA))
            // Le fasce sulla consistenza prima dell'applicazione (01 §9.7.2).
            esiti.append(EsitoContatto(partePrimo: a.parte,
                                       cellaPrimo: a.posizione, cellaSecondo: b.posizione,
                                       dannoAlPrimo: dannoBA, dannoAlSecondo: dannoAB,
                                       fasciaAlPrimo: fascia(danno: dannoBA, consistenzaPrima: a.serbatoio),
                                       fasciaAlSecondo: fascia(danno: dannoAB, consistenzaPrima: b.serbatoio)))
        }
        for d in danni { applicaDanno(d.danno, a: d.bersaglio, stato: &stato, eventi: &eventi) }

        guard conDisingaggi else { return (esiti, eventi) }
        // Disingaggi, dopo l'applicazione dei danni (01 §9.8), in ordine deterministico.
        // Chi si ritrae lascia l'intera mischia: tutti i suoi contatti terminano,
        // ciascuna coppia entra nella memoria e nel divieto (precisazione P4 del
        // registro degli scostamenti: il caso dei contatti multipli non era normato).
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
                for terminato in stato.contatti.filter({ $0.coinvolge(id) }) {
                    let coppiaTerminata = Coppia(terminato.primo, terminato.secondo)
                    stato.coppieStaccate.insert(coppiaTerminata)
                    stato.divietoIngaggio[coppiaTerminata] = stato.giro // nessun ingaggio per un turno
                }
                stato.contatti.removeAll { $0.coinvolge(id) }
                eventi.append(.disingaggio(sciame: id, da: da, a: destinazione))
            }
        }
        return (esiti, eventi)
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
            eventi.append(.sciameDisfatto(sciame: id, archetipo: sciame.archetipo,
                                          lettera: sciame.lettera,
                                          cella: sciame.posizione, parte: sciame.parte))
        } else {
            stato.sciami[id] = sciame
        }
    }

    // MARK: - Condizioni di chiusura (01 §15.2.3)

    private func verificaCondizioniDiChiusura(_ stato: inout StatoBattaglia,
                                              eventi: inout [EventoBattaglia]) {
        guard stato.esito == nil else { return }
        let f = formato(stato)

        // Con la resa già dichiarata la conclusione è governata dalla ritirata
        // combattuta (01 §10.3) e lo sconfitto è chi l'ha dichiarata, qualunque cosa
        // accada sul campo (01 §15.2.2). L'annientamento non la scavalca: 01 §15.2.3
        // lo prevede «se nessuno dei due si ritira», e il ritirante che ha evacuato
        // tutto ha compiuto la ritirata, non è stato annientato.
        if let ritirante = stato.resaDichiarataDa {
            let avanzante = ritirante.avversaria
            let sogliaRaggiunta = stato.sciami.values.contains { sciame in
                guard sciame.parte == avanzante else { return false }
                return stato.griglia.avanzamento(di: sciame.posizione, per: avanzante)
                    >= stato.griglia.righe - 1 - f.righeSogliaRitirata
            }
            let ritiranteVuoto = !stato.sciami.values.contains { $0.parte == ritirante }
            // Caso non normato dai consolidati (precisazione P8): se è l'avanzante a
            // restare senza nulla, la ritirata è riuscita e lo scontro finisce; lo
            // sconfitto resta chi si è ritirato, per 01 §15.2.2.
            let avanzanteVuoto = !stato.sciami.values.contains { $0.parte == avanzante }
                && !(stato.deck[avanzante] ?? []).contains { $0.esemplari > 0 }
            if sogliaRaggiunta || ritiranteVuoto || avanzanteVuoto {
                let esito = EsitoBattaglia(sconfitto: ritirante, modo: .ritirataCompiuta,
                                           turni: stato.giro)
                stato.esito = esito
                eventi.append(.battagliaConclusa(esito))
            }
            return
        }

        // Annientamento: nessuno sciame in campo e nessun esemplare nel deck.
        let annientate = Parte.allCases.filter { parte in
            !stato.sciami.values.contains { $0.parte == parte }
                && !(stato.deck[parte] ?? []).contains { $0.esemplari > 0 }
        }
        if !annientate.isEmpty {
            // Annientamento simultaneo (01 §15.2.5): la parità non esiste (01 §15.2.2)
            // e l'esito va assegnato. Non può risolversi a sfavore del giocatore: è
            // un vantaggio nascosto dichiarato (01 §13.2), e come tale sta nei dati
            // perché il programma di verifica possa disattivarlo (05 §12.5).
            let sconfitto: Parte
            if annientate.count == Parte.allCases.count {
                sconfitto = valori.vantaggi.annientamentoSimultaneoAlGiocatore ? .avversario : .giocatore
            } else {
                sconfitto = annientate[0]
            }
            let esito = EsitoBattaglia(sconfitto: sconfitto, modo: .annientamento, turni: stato.giro)
            stato.esito = esito
            eventi.append(.battagliaConclusa(esito))
            return
        }

    }
}
