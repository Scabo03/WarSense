import Foundation
import Dati

/// Le regole della campagna: validazione e applicazione dei comandi (05 §3.1).
/// Deterministico: stesso comando su stesso stato, stesso esito e stessi eventi
/// (00 §3.1). Nessun numero di gioco vive qui (00 §13.1).
public struct MotoreCampagna: Sendable {
    public let valori: ValoriDiGioco
    public let valoriCampagna: ValoriCampagna

    public init(valori: ValoriDiGioco, valoriCampagna: ValoriCampagna) {
        self.valori = valori
        self.valoriCampagna = valoriCampagna
    }

    // MARK: - Validazione (05 §3.1, §3.2)

    /// Nessuna mutazione: dice se il comando è ammissibile e, se non lo è, perché,
    /// con un motivo del vocabolario chiuso. Un solo percorso di codice produce sia
    /// il controllo sia l'annuncio, e i due non possono divergere (05 §3.2).
    public func valida(_ comando: ComandoCampagna, parte: Parte,
                       stato: StatoCampagna) -> EsitoValidazioneCampagna {
        // Il BLOCCO della campagna in sospeso (01 §6.3, §6.4, incarico 24): finché una battaglia
        // non è conclusa, in questa campagna nulla avanza — nessun movimento, nessuna azione, per
        // nessuna delle due parti. Ogni comando è respinto col MEDESIMO motivo, così che il
        // giocatore non debba ricostruirlo per tentativi (02 §6.5). È il primo controllo, prima di
        // ogni altro: nessun comando di campagna scavalca una battaglia in sospeso. L'apertura
        // della battaglia non passa di qui — non è un comando di campagna ma il passaggio di
        // schermata (01 §6.2). Il dirottamento dei superstiti (01 §6.9) non è costruito (S24c).
        if !stato.battaglieInSospeso.isEmpty {
            return .nonValido(.battagliaInSospeso)
        }
        switch comando {
        case .marcia(let idGruppo, let destinazione, let giorni):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Un gruppo che ha concluso la giornata non riceve ordini, e un gruppo
            // in marcia lunga ha concluso la giornata anche quando l'azione non è
            // spesa dal giocatore (01 §5.16.1): a distinguerlo serve
            // `haConclusoLaGiornata`. È l'invariante «un gruppo in marcia non riceve
            // mai un ordine» reso impossibile qui, non soltanto sorvegliato.
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            // Il taglio non paralizza ma toglie la marcia finché la sosta è dovuta
            // (01 §5.2.2.4): la sosta non si elude marciando (invariante).
            guard !gruppo.deveRifornirsi else { return .nonValido(.deveRifornirsi) }
            guard stato.griglia.contiene(destinazione) else { return .nonValido(.fuoriMappa) }
            guard stato.griglia.adiacenti(gruppo.posizione, destinazione) else {
                return .nonValido(.nonAdiacente)
            }
            // Ogni casella ospita al massimo una formazione della stessa parte
            // (01 §5.6.0.2). La casella di arrivo dev'essere libera ADESSO e non
            // già puntata da un'altra marcia in corso: due marce verso la stessa
            // casella si scontrerebbero alla risoluzione, e il gruppo in marcia
            // resta nella casella di partenza fino a compimento, sicché la sua
            // destinazione è prenotata quanto una casella occupata.
            guard stato.occupante(di: destinazione, parte: parte) == nil else {
                return .nonValido(.occupata)
            }
            guard !stato.gruppi.values.contains(where: {
                $0.parte == parte && $0.marcia?.destinazione == destinazione
            }) else {
                return .nonValido(.occupata)
            }
            // Il costo dichiarato dal comando dev'essere quello che i dati
            // prescrivono per quello scatto: un comando che ne porti un altro non
            // è un comando del gioco (01 §5.6.3.1, RDA-75).
            guard giorni == costoInGiorni(da: gruppo.posizione, a: destinazione,
                                          parte: parte, stato: stato) else {
                return .nonValido(.costoNonCoerente)
            }
            return .valido

        case .presidio(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            // Il PRIMO turno di sosta è dedicato al rifornimento (01 §5.2.2.4): con
            // due soste dovute solo la sosta con raccolta è ammessa; dal secondo turno
            // (una sosta dovuta) un'altra azione non di marcia, come il presidio, va bene.
            guard gruppo.sostaDovuta < 2 else { return .nonValido(.deveRifornirsi) }
            return .valido

        case .revocaMarcia(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // La revoca si compie solo su una marcia in corso (01 §5.6.3.3). Non
            // controlla `azioneSpesa`: la revoca non è un'azione e si può compiere
            // in qualunque momento, anche nel giorno stesso dell'ordine.
            guard gruppo.inMarcia else { return .nonValido(.gruppoNonInMarcia) }
            return .valido

        case .divisione(let idGruppo, let repartiStaccati, let destinazione):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // L'inchiodamento si controlla PRIMA dell'azione spesa, così che il
            // giocatore senta «inchiodato» e non «azione già spesa» (01 §5.6.3.5).
            guard !gruppo.inMarcia else { return .nonValido(.gruppoInchiodato) }
            guard !gruppo.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            // La divisione colloca il distaccamento con uno spostamento: come la marcia,
            // non si compie finché la sosta di rifornimento è dovuta (01 §5.2.2.4).
            guard !gruppo.deveRifornirsi else { return .nonValido(.deveRifornirsi) }
            guard stato.griglia.contiene(destinazione) else { return .nonValido(.fuoriMappa) }
            // Il distaccamento nasce in una casella ADIACENTE, mai in quella di origine
            // (01 §5.6.0.2): l'origine non è adiacente a sé, sicché il controllo di
            // adiacenza la esclude già.
            guard stato.griglia.adiacenti(gruppo.posizione, destinazione) else {
                return .nonValido(.nonAdiacente)
            }
            guard stato.occupante(di: destinazione, parte: parte) == nil,
                  !stato.gruppi.values.contains(where: {
                      $0.parte == parte && $0.marcia?.destinazione == destinazione }) else {
                return .nonValido(.occupata)
            }
            // Reparti interi, nessuna parte vuota (01 §5.6.0.2): indici distinti, tutti
            // esistenti, almeno uno staccato e almeno uno tenuto.
            let indici = Set(repartiStaccati)
            guard indici.count == repartiStaccati.count,
                  !indici.isEmpty, indici.count < gruppo.composizione.count,
                  indici.allSatisfy({ $0 >= 0 && $0 < gruppo.composizione.count }) else {
                return .nonValido(.divisioneImpropria)
            }
            // Il distaccamento ha bisogno di un nome dalla lista chiusa (01 §5.6.0.4).
            // Esaurita la lista, la divisione è rifiutata (S16).
            guard stato.prossimoIndiceNome < valoriCampagna.nomiGruppi.count else {
                return .nonValido(.nomiEsauriti)
            }
            return .valido

        case .riunione(let idGruppo, let idAltro):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte,
                  let altro = stato.gruppi[idAltro], altro.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            guard idGruppo != idAltro else { return .nonValido(.riunioneImpropria) }
            // La riunione non costa l'azione, ma un gruppo in marcia è inchiodato e non
            // può confluire (01 §5.6.3.5): l'inchiodamento vince sull'adiacenza.
            guard !gruppo.inMarcia, !altro.inMarcia else { return .nonValido(.gruppoInchiodato) }
            guard stato.griglia.adiacenti(gruppo.posizione, altro.posizione) else {
                return .nonValido(.nonAdiacente)
            }
            return .valido

        case .sostaConRaccolta(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // La sosta con raccolta è un'azione (01 §5.6.8.1): la può ordinare un gruppo
            // che non ha concluso la giornata — un gruppo in marcia è inchiodato. Vale
            // sia per l'autonomia sia per la sosta imposta dal taglio (01 §5.6.5).
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            return .valido

        case .esplorazione(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Riservata alle formazioni di ricognizione (01 §5.6.8.1). Gli esploratori NON
            // sono soggetti al taglio (01 §5.15): nessun controllo di sosta li riguarda.
            guard gruppo.categoria.eRicognizione else { return .nonValido(.categoriaNonAmmessa) }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            return .valido

        case .imboscata(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Riservata ai gruppi armati (01 §5.11, §5.6.8.1).
            guard gruppo.categoria.eArmata else { return .nonValido(.categoriaNonAmmessa) }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            // Come il presidio: un gruppo tenuto fermo dal taglio (due soste) non si appòsta,
            // solo si rifornisce; dal secondo turno (una sosta) l'agguato va bene.
            guard gruppo.sostaDovuta < 2 else { return .nonValido(.deveRifornirsi) }
            return .valido

        case .sabotaggio(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Gruppi armati o esploratori, mai una formazione non armata (01 §5.10.2).
            guard !gruppo.categoria.eNonArmata else { return .nonValido(.categoriaNonAmmessa) }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            guard gruppo.sostaDovuta < 2 else { return .nonValido(.deveRifornirsi) }
            // Serve una formazione non armata avversaria co-locata (01 §5.10, §6.1).
            guard bersaglioNonArmato(su: gruppo.posizione, parte: parte, stato: stato) != nil else {
                return .nonValido(.nessunBersaglio)
            }
            return .valido

        case .studioApprofondito(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Riservato alle formazioni di ricognizione (01 §5.10.2), esenti dal taglio.
            guard gruppo.categoria.eRicognizione else { return .nonValido(.categoriaNonAmmessa) }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            guard bersaglioNonArmato(su: gruppo.posizione, parte: parte, stato: stato) != nil else {
                return .nonValido(.nessunBersaglio)
            }
            return .valido
        }
    }

    /// La formazione non armata AVVERSARIA co-locata con una casella, se c'è (01 §5.10, §6.1):
    /// il bersaglio del sabotaggio e dello studio approfondito, che agiscono sulla formazione
    /// non armata della parte OPPOSTA presente nella stessa casella per compresenza. Nil se la
    /// casella non ospita una formazione non armata avversaria.
    public func bersaglioNonArmato(su casella: Cella, parte: Parte,
                                   stato: StatoCampagna) -> Gruppo? {
        let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
        guard let bersaglio = stato.occupante(di: casella, parte: avversa),
              bersaglio.categoria.eNonArmata else { return nil }
        return bersaglio
    }

    // MARK: - Volume della colonna (01 §5.6.0, §5.6.3, §3.4.4)

    /// Il volume complessivo di un gruppo: la somma, sui reparti, di atomi per
    /// `volume_per_atomo` dell'archetipo. È la STESSA grandezza del volume di
    /// battaglia (`MotoreBattaglia.volume(di sciame:)`, `atomi × volume_per_atomo`):
    /// 01 §3.4.4 la dichiara «unica e stabile per archetipo», e qui si legge lo
    /// stesso campo dell'archetipo. Non è mai un campo dello stato: derivarla dalla
    /// composizione rende impossibile che diverga da ciò che compone il gruppo
    /// (invariante «il volume è la somma di ciò che lo compone»). Gli archetipi sono
    /// noti per costruzione, perché la fabbrica respinge lo scenario che ne nomini
    /// uno ignoto; l'accesso forzato rispecchia `MotoreBattaglia`.
    public func volume(di gruppo: Gruppo) -> Int64 {
        gruppo.composizione.reduce(0) { somma, reparto in
            somma + Int64(reparto.atomi) * valori.archetipi[reparto.archetipo]!.volumePerAtomo
        }
    }

    // MARK: - Rifornimento: catena, taglio, zone (01 §5.2.2)

    /// Le caselle DIETRO la colonna (01 §5.2.2.2): le tre colonne centrate su quella
    /// occupata, prese sulla riga della colonna stessa e su quella immediatamente
    /// retrostante — retrostante DALLA PARTE DEL PROPRIO QUARTIER GENERALE. La
    /// direzione è ricavata dalla posizione REALE del quartier generale del gruppo, mai
    /// da un'assunzione sulla geometria della mappa né dall'allineamento dei due
    /// quartier generali (RDA-107). Le due condizioni di bordo cadono da sé filtrando
    /// le caselle inesistenti: sull'ultima riga verso il proprio quartier generale la
    /// riga retrostante non esiste e restano le sole caselle esistenti; su una colonna
    /// di bordo la fascia si restringe a due caselle anziché tre.
    public func caselleAlleSpalle(di gruppo: Gruppo, mappa: MappaCampagna) -> [Cella] {
        Self.caselleAlleSpalle(di: gruppo.posizione,
                               qg: mappa.quartierGenerale(di: gruppo.parte),
                               griglia: mappa.griglia)
    }

    /// La geometria PURA delle caselle alle spalle di una posizione, dato il proprio
    /// quartier generale (01 §5.2.2.2): dipende solo dalla griglia e da due caselle,
    /// mai dalle posizioni delle parti. Estratta perché la condotta dell'avversario
    /// possa ragionare sulle spalle di una formazione del giocatore che OSSERVA — la
    /// casella nota e il quartier generale del giocatore, entrambi geografia nota —
    /// senza accedere allo stato reale (incarico 18, RDA-114).
    public static func caselleAlleSpalle(di pos: Cella, qg: Cella,
                                         griglia: GrigliaCampagna) -> [Cella] {
        let passo = qg.riga == pos.riga ? 0 : (qg.riga > pos.riga ? 1 : -1)
        let righe = passo == 0 ? [pos.riga] : [pos.riga, pos.riga + passo]
        var caselle: [Cella] = []
        for r in righe {
            for c in [pos.colonna - 1, pos.colonna, pos.colonna + 1] {
                let cella = Cella(riga: r, colonna: c)
                if griglia.contiene(cella) { caselle.append(cella) }
            }
        }
        return caselle
    }

    /// Vero se la casella è in una ZONA di rifornimento (01 §5.2.2.6): la casella di
    /// una struttura o una delle otto che la circondano — le nove caselle del blocco
    /// tre per tre (distanza di Čebyšëv al più uno), diagonali comprese. La fortezza
    /// isolata rifornisce comunque, perché conta la prossimità e non il collegamento
    /// con la patria (01 §5.2.2.7): la regola non guarda chi possiede l'intorno.
    public func inZonaDiRifornimento(_ cella: Cella, stato: StatoCampagna) -> Bool {
        stato.struttureDiRifornimento.contains {
            max(abs($0.riga - cella.riga), abs($0.colonna - cella.colonna)) <= 1
        }
    }

    /// Le caselle occupate da forze OSTILI a una parte (01 §5.2.2.2): i gruppi della
    /// parte OPPOSTA, più — per il solo giocatore — le forze nemiche FERME dichiarate
    /// dallo scenario (dati minimi di verifica, incarico 16). È relativa alla parte e
    /// mai fissa su una sola (incarico 18, RDA-112): ciò che taglia il giocatore sono i
    /// gruppi avversari e le forze ferme, ciò che taglia l'avversario sono i gruppi del
    /// giocatore. La simmetria è voluta (01 §5.2.3, §5.9.1.8) e sostituisce l'uso
    /// diretto di `stato.forzeNemiche`, che presupponeva il giocatore come unica vittima.
    public func caselleOstili(a parte: Parte, stato: StatoCampagna) -> Set<Cella> {
        var celle = Set(stato.gruppi.values.lazy.filter { $0.parte != parte }.map(\.posizione))
        if parte == .giocatore { celle.formUnion(stato.forzeNemiche) }
        return celle
    }

    /// Vero se il rifornimento del gruppo è tagliato (01 §5.2.2.2): forze OSTILI alla
    /// sua parte in una delle caselle alle spalle. In una zona di rifornimento il taglio
    /// non produce effetto (01 §5.2.2.6): la zona vince sul taglio, e un gruppo in zona
    /// non risulta mai tagliato (invariante).
    public func rifornimentoTagliato(di gruppo: Gruppo, stato: StatoCampagna) -> Bool {
        guard !inZonaDiRifornimento(gruppo.posizione, stato: stato) else { return false }
        let ostili = caselleOstili(a: gruppo.parte, stato: stato)
        return caselleAlleSpalle(di: gruppo, mappa: stato.mappa).contains(where: ostili.contains)
    }

    /// Lo stato di rifornimento del gruppo per il vocabolario chiuso (02 §4.4.5), con
    /// la precedenza fissa: sosta, poi zona, poi senza provviste. Il gruppo RIFORNITO
    /// è la condizione ordinaria e restituisce nil, perché non si annuncia (02 §8.7).
    public func statoDiRifornimento(di gruppo: Gruppo, stato: StatoCampagna) -> StatoRifornimento? {
        if gruppo.sostaDovuta > 0 { return .inSosta(giorniDovuti: gruppo.sostaDovuta) }
        if inZonaDiRifornimento(gruppo.posizione, stato: stato) { return .inZona }
        if gruppo.turniSenzaProvviste > 0 { return .senzaProvviste(giorno: gruppo.turniSenzaProvviste) }
        return nil
    }

    // MARK: - Conoscenza incompleta (01 §5.3)

    /// Vero se la casella è OSSERVATA ORA da una parte: entro il raggio di osservazione
    /// (distanza ortogonale, 03 §4.8.2) da una delle sue formazioni. È la conoscenza
    /// corrente, derivata dalle posizioni; il ricordo che invecchia sta nello stato.
    public func osservata(_ cella: Cella, da parte: Parte, stato: StatoCampagna) -> Bool {
        let raggio = valoriCampagna.conoscenza.raggioOsservazione
        return stato.gruppi.values.contains {
            $0.parte == parte && stato.griglia.distanza($0.posizione, cella) <= raggio
        }
    }

    /// Le caselle che una parte osserva ora: l'insieme, per chi deve percorrerlo tutto
    /// (l'invecchiamento di fine giornata e i rotori). Deriva dalle posizioni.
    public func caselleOsservate(da parte: Parte, stato: StatoCampagna) -> Set<Cella> {
        let raggio = valoriCampagna.conoscenza.raggioOsservazione
        var viste = Set<Cella>()
        for gruppo in stato.gruppi.values where gruppo.parte == parte {
            let p = gruppo.posizione
            for dr in -raggio...raggio {
                for dc in -raggio...raggio where abs(dr) + abs(dc) <= raggio {
                    let cella = Cella(riga: p.riga + dr, colonna: p.colonna + dc)
                    if stato.griglia.contiene(cella) { viste.insert(cella) }
                }
            }
        }
        return viste
    }

    /// Lo stato di conoscenza di una casella per una parte (01 §5.3): confermato se
    /// osservato ora, altrimenti derivato dal ricordo che invecchia. Il gioco non
    /// dichiara mai il falso — la mancanza di conoscenza è inesplorato, non menzogna
    /// (01 §12). Il presunto nasce solo dalla deduzione dell'itinerario (01 §5.10.1,
    /// blocco successivo) e non da qui.
    public func conoscenza(di cella: Cella, per parte: Parte, stato: StatoCampagna) -> StatoConoscenza {
        let soglia = valoriCampagna.conoscenza.sogliaConfermatoInAvvistato
        // L'OCCULTAMENTO dell'imboscata (01 §5.11.1, incarico 21): se nella casella c'è un gruppo
        // AVVERSARIO APPOSTATO che questa parte non ha ancora SCOPERTO con la ricognizione, la
        // parte NON può confermarla — un gruppo nascosto non si individua osservando (§5.11.1) — e
        // la sua conoscenza RETROCEDE al solo ricordo, mai a confermato. Non è un'eccezione alla
        // visibilità: è la conoscenza che retrocede. Il gioco non dichiara il falso: non annuncia
        // mai «vuoto» né «confermato», ma «avvistato» (notizia non più certa) o meno. Vale
        // simmetricamente per le due parti. La scoperta (imboscateScoperte) leva l'occultamento.
        let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
        let appostatoNascosto = stato.occupante(di: cella, parte: avversa)?.ordineImboscata == true
            && stato.imboscateScoperte[parte]?.contains(cella) != true
        if appostatoNascosto {
            let base = statoDalRicordo(di: cella, per: parte, stato: stato, soglia: soglia)
            // Un ricordo ancora fresco (confermato per età) retrocede al limite dell'avvistato: il
            // gruppo si è nascosto, sicché la certezza recente non vale più. Mai «vuoto», mai il falso.
            if case .confermato = base { return .avvistato(turni: soglia) }
            return base
        }
        if osservata(cella, da: parte, stato: stato) { return .confermato }
        return statoDalRicordo(di: cella, per: parte, stato: stato, soglia: soglia)
    }

    /// Lo stato di conoscenza dal solo RICORDO, senza l'osservazione corrente (01 §5.3): un ricordo
    /// reale — anche invecchiato in avvistato — prevale sulla deduzione, chi ha visto sa più di chi
    /// presume; il PRESUNTO (01 §5.10.1, RDA-110) interviene solo dove non c'è alcun ricordo.
    private func statoDalRicordo(di cella: Cella, per parte: Parte, stato: StatoCampagna,
                                 soglia: Int) -> StatoConoscenza {
        if let eta = stato.conoscenza[parte]?[cella] {
            return StatoConoscenza.da(eta: eta, sogliaConfermato: soglia)
        }
        if stato.presunti[parte]?.contains(cella) == true { return .presunto }
        return .inesplorato
    }

    /// L'invecchiamento e il decadimento della conoscenza (01 §5.6.11, §5.3): passo di
    /// fine giornata. Per ciascuna parte, ogni ricordo invecchia di un turno; poi le
    /// caselle osservate a fine giornata si riportano a zero, appena viste. Non produce
    /// eventi: ciò che il giocatore apprende passa dagli stati di conoscenza e dal
    /// registro, mai da un annuncio dell'invecchiamento (01 §5.6.11). Un ricordo non
    /// retrocede mai da confermato senza il passare del tempo (invariante).
    func invecchiaLaConoscenza(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        for parte in [Parte.giocatore, .avversario] {
            var memoria = stato.conoscenza[parte] ?? [:]
            for cella in memoria.keys { memoria[cella]! += 1 }
            for cella in caselleOsservate(da: parte, stato: stato) { memoria[cella] = 0 }
            stato.conoscenza[parte] = memoria
        }
        return []
    }

    // MARK: - La vista ristretta dell'avversario (01 §5.6.11, §5.11.1, RDA-114)

    /// Costruisce la vista su cui decide l'avversario, proiettando lo stato reale
    /// attraverso la SUA conoscenza. È l'UNICO punto del programma in cui la condotta
    /// dell'avversario dipende dallo stato: qui si leggono le posizioni del giocatore, ma
    /// SOLTANTO per stabilire quali sono osservate ORA dall'avversario (entro il raggio
    /// di una sua formazione, cioè confermate per lui — 01 §5.3), e nella vista entra solo
    /// quell'insieme di caselle. Le posizioni che l'avversario non osserva non escono di
    /// qui: la condotta riceve la `VistaAvversario` e mai lo `StatoCampagna`, sicché non
    /// può decidere su ciò che non possiede (incarico 18, RDA-114). L'avversario decide
    /// sulla propria memoria e non sullo stato reale della mappa (01 §5.11.1).
    public func vistaAvversario(stato: StatoCampagna) -> VistaAvversario {
        let propri = stato.gruppi(di: .avversario)
        var volumi: [IdGruppo: Int64] = [:]
        for g in propri { volumi[g.id] = volume(di: g) }
        var note = Set<Cella>()
        for g in stato.gruppi.values where g.parte == .giocatore {
            // Un gruppo del giocatore APPOSTATO resta occulto per l'avversario (01 §5.11.1,
            // incarico 21): non entra fra le note — l'avversario decide sulla propria conoscenza e
            // vi può cadere — finché i propri esploratori non lo SCOPRONO. Scoperto, l'avversario lo
            // tratta come ostacolo e ne sta alla larga (aggiramento). Un gruppo non appostato entra
            // fra le note appena l'avversario lo osserva, come sempre (incarico 18).
            let confermata = g.ordineImboscata
                ? stato.imboscateScoperte[.avversario]?.contains(g.posizione) == true
                : osservata(g.posizione, da: .avversario, stato: stato)
            if confermata { note.insert(g.posizione) }
        }
        return VistaAvversario(mappa: stato.mappa, marcia: valoriCampagna.marcia,
                               condotta: valoriCampagna.condotta,
                               gruppiPropri: propri, volumi: volumi,
                               formazioniGiocatoreNote: note)
    }

    /// Proietta una sequenza di eventi PER IL GIOCATORE (01 §5.6.11): passano gli eventi
    /// dei suoi gruppi, i confini di giornata e gli avvistamenti (già filtrati a monte
    /// dall'osservazione); gli eventi dei gruppi AVVERSARI — ordini, conferme, il loro
    /// rifornimento — non passano, o il giocatore apprenderebbe le mosse avversarie per
    /// una via diversa dalla conoscenza e dal registro. È l'ultima difesa, oltre alla
    /// soppressione già operata nelle risoluzioni: la Sessione vi passa tutti gli eventi
    /// del turno prima di consegnarli alla Presentazione.
    public func proiettaPerIlGiocatore(_ eventi: [EventoCampagna],
                                       stato: StatoCampagna) -> [EventoCampagna] {
        func diGiocatore(_ id: IdGruppo) -> Bool { stato.gruppi[id]?.parte == .giocatore }
        return eventi.filter { evento in
            switch evento {
            case .giornataChiusa, .giornataAperta, .formazioneAvversariaAvvistata,
                 .imboscataScattata, .direzioneDedotta,
                 .battagliaInnescata, .battagliaConclusa:
                // Confini di giornata, avvistamenti, scatti d'imboscata (sempre fra parti
                // opposte, il giocatore è parte) e deduzioni (prodotte solo per lui). Le
                // battaglie innescate e concluse coinvolgono sempre il giocatore: si consegnano.
                return true
            case .marciaOrdinata(let g, _, _, _, _), .presidioOrdinato(let g, _, _),
                 .marciaRevocata(let g, _, _, _), .marciaCompiuta(let g, _, _, _),
                 .gruppoDiviso(let g, _, _, _, _), .gruppiRiuniti(let g, _, _, _),
                 .rifornimentoInterrotto(let g, _, _), .sostaDiRifornimento(let g, _, _),
                 .rifornimentoRipreso(let g, _, _),
                 .imboscataOrdinata(let g, _, _), .sabotaggioCompiuto(let g, _, _, _),
                 .studioCompiuto(let g, _, _):
                return diGiocatore(g)
            case .esplorazioneCompiuta(let p, _, _, _, _), .imboscataScoperta(let p, _):
                // L'esplorazione (il gruppo può essere stato rimosso, esito perduti) e la scoperta
                // di un'imboscata si consegnano guardando la PARTE: solo le proprie scoperte
                // raggiungono il giocatore, mai quelle dell'avversario (01 §5.11.1).
                return p == .giocatore
            }
        }
    }

    // MARK: - Costo in giorni dello scatto (01 §5.6.3.1, §5.6.3.2)

    /// I giorni necessari a entrare nella casella di arrivo venendo da quella di
    /// partenza. È UNA SOLA grandezza, come 01 §5.6.3.2 impone: vi confluiscono, per
    /// somma e senza regole separate che si sommino in modo opaco, il costo base, la
    /// natura della casella di partenza e quella di arrivo con pesi distinti, il tipo
    /// di strada della casella di arrivo, il costo fisso della strettoia e il VOLUME
    /// della colonna (quinto fattore di 01 §5.6.3.2). Il volume è quello del gruppo
    /// che occupa la casella di partenza — la colonna che marcia — letto dallo stato,
    /// senza spostare il punto di calcolo (RDA-75, `impatto-marcia-lunga.md` §1 ora
    /// superato): una colonna più voluminosa è più lunga e percorre meno strada in
    /// una giornata (01 §5.6.3), sicché il suo contributo è POSITIVO e cresce col
    /// volume. Se la casella di partenza non ha occupante il contributo è nullo: il
    /// costo esiste anche per una casella libera (anteprime, banco). Il costo non
    /// scende mai sotto uno, che 00 §13.6 fissa per impedire lo scatto gratuito.
    ///
    /// Il volume è quello del gruppo che marcia, cioè l'occupante di `partenza` DELLA
    /// PARTE indicata: con la compresenza (01 §6.1) una casella può ospitare un gruppo
    /// per parte, e la colonna che marcia è la propria. `parte` ha per difetto il
    /// giocatore, il caso ordinario e l'unico esercitato dalle prove; la validazione,
    /// l'applicazione e la vista passano la parte reale, sicché l'avversario paga il
    /// proprio volume e non quello del giocatore (incarico 18, RDA-112: rimosso il
    /// fisso `.giocatore` che era l'unica asimmetria del costo).
    public func costoInGiorni(da partenza: Cella, a arrivo: Cella,
                              parte: Parte = .giocatore, stato: StatoCampagna) -> Int {
        let volumeColonna = stato.occupante(di: partenza, parte: parte).map(volume(di:)) ?? 0
        return Self.costoInGiorni(da: partenza, a: arrivo, volumeColonna: volumeColonna,
                                  mappa: stato.mappa, marcia: valoriCampagna.marcia)
    }

    /// Il nucleo PURO del costo in giorni (01 §5.6.3.2): funzione soltanto della
    /// geometria della mappa (terreno, strada, strettoia, tutti PUBBLICI) e del VOLUME
    /// della colonna che marcia. Non tocca le posizioni di alcuna parte, sicché la vista
    /// dell'avversario può calcolare i propri costi senza accedere allo stato reale
    /// (incarico 18, RDA-114): è il punto in cui il costo cessa di dipendere dallo stato.
    public static func costoInGiorni(da partenza: Cella, a arrivo: Cella,
                                     volumeColonna: Int64, mappa: MappaCampagna,
                                     marcia m: ValoriMarcia) -> Int {
        var costo = m.costoGiorniBase
        costo += m.pesoTerrenoPartenza[mappa.terreno(di: partenza).rawValue] ?? 0
        costo += m.pesoTerrenoArrivo[mappa.terreno(di: arrivo).rawValue] ?? 0
        costo += m.pesoStradaArrivo[mappa.strada(di: arrivo).rawValue] ?? 0
        if mappa.strettoia == arrivo { costo += m.costoStrettoia }
        // Il volume entra sulla MEDESIMA grandezza, per somma: giorni aggiuntivi pari
        // al volume diviso la soglia (troncamento). Formula nel codice, coefficiente
        // nei dati (00 §13.1): la soglia è provvisoria. Il contributo è monotòno nel
        // volume e nullo per una colonna leggera sotto la soglia.
        costo += Int(volumeColonna / Int64(m.sogliaVolumePerGiornoAggiuntivo))
        return max(1, costo)
    }

    /// La posizione dell'avanzamento visivo, fra le `posizioni_visive` disposte a
    /// quadrato dentro la casella (01 §5.6.3.4): DERIVATA per troncamento dalla
    /// proporzione fra giorni compiuti e giorni totali, mai una grandezza autonoma.
    /// Chi ascolta riceve i giorni; questa è la sola grandezza che chi vede riceve,
    /// e non può divergere dai giorni perché è una funzione pura di essi. Restituisce
    /// un indice in `0 ..< posizioni_visive` per una marcia in corso.
    public func avanzamentoVisivo(giorniCompiuti: Int, giorniTotali: Int) -> Int {
        guard giorniTotali > 0 else { return 0 }
        return (giorniCompiuti * valoriCampagna.marcia.posizioniVisive) / giorniTotali
    }

    // MARK: - Applicazione (05 §3.1)

    /// Applica soltanto comandi validi: la validazione è rieseguita internamente e
    /// un comando non valido è un errore di programmazione, non un caso d'uso.
    public func applica(_ comando: ComandoCampagna, parte: Parte,
                        stato: StatoCampagna) -> (StatoCampagna, [EventoCampagna]) {
        precondition(valida(comando, parte: parte, stato: stato).eValido,
                     "comando.di.campagna.non.valido.applicato")
        var nuovo = stato
        var eventi: [EventoCampagna] = []

        switch comando {
        case .marcia(let idGruppo, let destinazione, let giorni):
            let partenza = nuovo.gruppi[idGruppo]!.posizione
            let nome = nuovo.gruppi[idGruppo]!.nome
            // La marcia REGISTRA un ordine e spende l'azione, ma NON muove il gruppo:
            // con il costo maggiore di uno il movimento matura alla risoluzione di
            // fine giornata (01 §5.6.3.3). Con costo uno matura alla chiusura della
            // stessa giornata, ma passa comunque per la marcia in corso, sicché un
            // solo percorso vale per ogni durata.
            nuovo.gruppi[idGruppo]!.marcia = MarciaInCorso(destinazione: destinazione,
                                                           giorniTotali: giorni, giorniCompiuti: 0)
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            // L'evento fa l'annuncio immediato della conferma dell'ordine, che il
            // giocatore ascolta; NON entra nel registro. L'ordine di marcia è deciso
            // dal giocatore, e il registro annota i fatti che il giocatore NON ha
            // deciso (01 §5.17.1, ripristinato dalla correzione del titolare, RDA-104):
            // la deroga di RDA-72/RDA-101 (S8) è superata, perché il fatto non deciso
            // — l'arrivo — ora esiste.
            eventi.append(.marciaOrdinata(gruppo: idGruppo, nome: nome,
                                          da: partenza, a: destinazione, giorni: giorni))

        case .presidio(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            // Come la marcia: l'evento annuncia, il registro non annota un ordine.
            eventi.append(.presidioOrdinato(gruppo: idGruppo, nome: gruppo.nome,
                                            casella: gruppo.posizione))

        case .revocaMarcia(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            let giorniPersi = gruppo.marcia!.giorniCompiuti
            let casella = gruppo.posizione
            // La revoca cancella la marcia e con essa i giorni spesi; il gruppo resta
            // nella casella di partenza (01 §5.6.3.3). Non restituisce la giornata:
            // il gruppo l'ha già spesa con l'ordine di marcia e non compie altro
            // (decisione del titolare, RDA-100). `azioneSpesa` a vero lo dichiara.
            nuovo.gruppi[idGruppo]!.marcia = nil
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.marciaRevocata(gruppo: idGruppo, nome: gruppo.nome,
                                          casella: casella, giorniPersi: giorniPersi))
            // La revoca del GIOCATORE resta nel registro per volontà del titolare
            // (RDA-104); quella dell'avversario — che la condotta non compie, ma la
            // validazione ammette per simmetria — non vi entra, o il registro darebbe al
            // giocatore un ordine avversario che la sua conoscenza non gli ha dato.
            if parte == .giocatore {
                annota(.marciaRevocata(gruppo: gruppo.nome, casella: casella), in: &nuovo)
            }

        case .divisione(let idGruppo, let repartiStaccati, let destinazione):
            let origine = nuovo.gruppi[idGruppo]!
            let staccati = Set(repartiStaccati)
            // Reparti tenuti e staccati per indice: la divisione lavora su reparti
            // INTERI, e la somma delle due parti eguaglia il gruppo di prima (invariante
            // `divisione_non_conserva`). L'ordine dei reparti tenuti si conserva.
            var tenuti: [Reparto] = []
            var distacco: [Reparto] = []
            for (indice, reparto) in origine.composizione.enumerated() {
                if staccati.contains(indice) { distacco.append(reparto) } else { tenuti.append(reparto) }
            }
            // Il gruppo di origine conserva id, nome e casella; spende l'azione (la
            // divisione COSTA la giornata, 01 §5.6.0.2) e perde i reparti staccati.
            nuovo.gruppi[idGruppo]!.composizione = tenuti
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            // Il distaccamento: id e nome nuovi dalla lista chiusa (i nomi non si
            // riusano). Nasce nella casella adiacente AVENDO GIÀ AGITO, perché il
            // collocamento è uno spostamento (01 §5.6.0.2); mai in marcia.
            let idNuovo = IdGruppo(nuovo.prossimoIdGruppo)
            let nomeNuovo = valoriCampagna.nomiGruppi[nuovo.prossimoIndiceNome]
            nuovo.gruppi[idNuovo] = Gruppo(id: idNuovo, parte: parte, nome: nomeNuovo,
                                           posizione: destinazione, composizione: distacco,
                                           azioneSpesa: true, marcia: nil)
            nuovo.prossimoIdGruppo += 1
            nuovo.prossimoIndiceNome += 1
            // Fatto DECISO dal giocatore: l'evento annuncia, il registro non annota.
            eventi.append(.gruppoDiviso(gruppo: idGruppo, nome: origine.nome,
                                        distaccamento: idNuovo, nomeDistaccamento: nomeNuovo,
                                        a: destinazione))

        case .riunione(let idGruppo, let idAltro):
            let a = nuovo.gruppi[idGruppo]!, b = nuovo.gruppi[idAltro]!
            // Il MAGGIORE dei due conserva nome, id e casella; a parità di volume vince
            // l'id minore, cioè il più antico (01 §5.6.0.4). L'altro è assorbito e
            // sparisce, e il suo nome non si riusa.
            let aMaggiore: Bool = {
                let va = volume(di: a), vb = volume(di: b)
                return va != vb ? va > vb : a.id < b.id
            }()
            let maggiore = aMaggiore ? a : b
            let assorbito = aMaggiore ? b : a
            // Il risultante si considera avere già agito se ALMENO UNO dei due lo era
            // (01 §5.6.0.3): la riunione non è un'azione, ma non deve regalare una
            // giornata a chi l'aveva spesa. La composizione è l'unione, il maggiore
            // per primo. Nessuno dei due è in marcia (la validazione lo esclude).
            nuovo.gruppi.removeValue(forKey: assorbito.id)
            nuovo.gruppi[maggiore.id]!.composizione = maggiore.composizione + assorbito.composizione
            nuovo.gruppi[maggiore.id]!.azioneSpesa = a.azioneSpesa || b.azioneSpesa
            eventi.append(.gruppiRiuniti(risultante: maggiore.id, nome: maggiore.nome,
                                         assorbito: assorbito.id, casella: maggiore.posizione))

        case .sostaConRaccolta(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            // La sosta con raccolta è l'azione con cui un gruppo si ferma a rifornirsi
            // (01 §5.6.8.1): spende la giornata come le altre azioni. Ordinata di propria
            // iniziativa da un gruppo che ha già patito il taglio (turni senza provviste)
            // ma non è ancora costretto (nessuna sosta già dovuta), fissa i giorni di
            // sosta pari ai turni digiunati — il gruppo si ferma «con i giorni di sosta
            // dovuti» (02 §4.4.5) — e ne dà annuncio (fatto deciso: non si annota). La
            // sosta già imposta dal taglio non si tocca qui: la fine giornata la scala.
            // Ordinata da un gruppo rifornito è una semplice raccolta: spende la giornata
            // e nient'altro.
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            if gruppo.turniSenzaProvviste > 0 && gruppo.sostaDovuta == 0 {
                nuovo.gruppi[idGruppo]!.sostaDovuta = gruppo.turniSenzaProvviste
                eventi.append(.sostaDiRifornimento(gruppo: idGruppo, nome: gruppo.nome,
                                                   casella: gruppo.posizione))
            }

        case .esplorazione(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            let casella = gruppo.posizione
            // L'esito è DETERMINISTICO (01 §5.4, §12): si calcola sullo stato PRIMA di spendere
            // l'azione, dal confronto fra competenza e insidiosità della zona. Nessuna estrazione.
            let esito = esitoEsplorazione(di: gruppo, stato: stato)
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            switch esito {
            case .riuscita:
                // L'area attorno all'esploratore diventa conoscenza fresca (01 §5.3): memoria a
                // zero sulle caselle entro il raggio di esplorazione, più ampio dell'ordinario.
                rivelaArea(attorno: casella, per: parte,
                           raggio: valoriCampagna.ricognizione.raggioEsplorazione, in: &nuovo)
                // SCOPERTA DELLE IMBOSCATE (01 §5.11.1, incarico 21): l'esplorazione riuscita è il
                // SOLO modo di scoprire un'imboscata pendente. Ogni gruppo avversario appostato
                // nell'area scoperta viene rivelato — la sua casella entra fra le scoperte, che
                // levano l'occultamento, e il fatto entra nel registro col luogo.
                eventi.append(contentsOf: scopriLeImboscate(
                    attorno: casella, per: parte,
                    raggio: valoriCampagna.ricognizione.raggioEsplorazione, in: &nuovo))
            case .aManiVuote:
                break
            case .notati:
                // La casella dell'esploratore diventa avvistata PER L'AVVERSARIO (01 §5.4): la
                // sua memoria di quella casella si azzera, come se vi avesse una formazione.
                let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
                nuovo.conoscenza[avversa, default: [:]][casella] = 0
                if parte == .giocatore {
                    annota(.esploratoriNotati(gruppo: gruppo.nome, casella: casella), in: &nuovo)
                }
            case .perduti:
                // La formazione va perduta: sparisce dalla mappa (01 §5.4.2). L'evento porta la
                // parte perché il gruppo non è più rintracciabile per la proiezione.
                nuovo.gruppi.removeValue(forKey: idGruppo)
                if parte == .giocatore {
                    annota(.esploratoriPerduti(gruppo: gruppo.nome, casella: casella), in: &nuovo)
                }
            }
            eventi.append(.esplorazioneCompiuta(parte: parte, gruppo: idGruppo, nome: gruppo.nome,
                                                casella: casella, esito: esito))

        case .imboscata(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            // Colloca il gruppo in agguato OGGI (01 §5.11) e CONSUMA l'azione (incarico 21):
            // `ordineImboscata` e `azioneSpesa` valgono per questa giornata e si azzerano insieme
            // all'apertura della prossima — l'ordine va rinnovato. L'occultamento è realizzato dalla
            // conoscenza che retrocede (§5.11.1, `conoscenza`): il gioco non dichiara il falso —
            // l'avversario non individua l'appostato perché la casella non è per lui confermata, non
            // perché il gioco menta. Fatto deciso dal giocatore: annuncio di conferma, non registro.
            nuovo.gruppi[idGruppo]!.ordineImboscata = true
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.imboscataOrdinata(gruppo: idGruppo, nome: gruppo.nome, casella: gruppo.posizione))

        case .sabotaggio(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            let casella = gruppo.posizione
            let bersaglio = bersaglioNonArmato(su: casella, parte: parte, stato: stato)!
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            // Compiuto da un gruppo armato riesce SEMPRE; da esploratori solo se la competenza
            // raggiunge la soglia di protezione del bersaglio, altrimenti fallisce e gli
            // esploratori si fanno notare (01 §5.10.2). Deterministico, mai un'estrazione.
            let riuscito: Bool
            if gruppo.categoria.eArmata {
                riuscito = true
            } else if let competenza = gruppo.categoria.competenza,
                      let soglia = bersaglio.categoria.sogliaProtezione {
                riuscito = competenza >= soglia
            } else {
                riuscito = false
            }
            if riuscito {
                // Disperde la formazione bersaglio, il suo carico perduto (01 §5.10.2): sparisce
                // dalla mappa. Il sabotaggio è sempre fra parti opposte e tocca sempre il
                // giocatore — attore o vittima — sicché il fatto entra nel registro.
                nuovo.gruppi.removeValue(forKey: bersaglio.id)
                nuovo.studiati[parte]?.remove(bersaglio.id)
                nuovo.studiati[bersaglio.parte]?.remove(bersaglio.id)
                annota(.formazioneSabotata(casella: casella), in: &nuovo)
            } else {
                // Esploratori sotto soglia: si fanno notare, la loro casella avvistata per
                // l'avversario (01 §5.10.2). Il bersaglio resta.
                let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
                nuovo.conoscenza[avversa, default: [:]][casella] = 0
                if parte == .giocatore {
                    annota(.esploratoriNotati(gruppo: gruppo.nome, casella: casella), in: &nuovo)
                }
            }
            eventi.append(.sabotaggioCompiuto(gruppo: idGruppo, nome: gruppo.nome,
                                              casella: casella, riuscito: riuscito))

        case .studioApprofondito(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            let casella = gruppo.posizione
            let bersaglio = bersaglioNonArmato(su: casella, parte: parte, stato: stato)!
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            // Porta a confermato la conoscenza della formazione studiata (01 §5.10.2): la sua
            // casella diventa conoscenza fresca (età zero), e la formazione entra fra le
            // `studiati`, sicché composizione, carico e direzione restano note anche quando
            // esce dall'osservazione — si è appreso ciò che quella colonna trasporta.
            nuovo.conoscenza[parte, default: [:]][casella] = 0
            nuovo.studiati[parte, default: []].insert(bersaglio.id)
            if parte == .giocatore {
                annota(.formazioneStudiata(casella: casella), in: &nuovo)
            }
            eventi.append(.studioCompiuto(gruppo: idGruppo, nome: gruppo.nome, casella: casella))
        }

        eventi.append(contentsOf: chiudiLaGiornataSeServe(&nuovo))
        return (nuovo, eventi)
    }

    // MARK: - Il rischio deterministico della ricognizione (01 §5.4, §12)

    /// L'esito DETERMINISTICO di un'esplorazione (01 §5.4): la riuscita discende dalla
    /// COMPETENZA degli esploratori e dalle CONDIZIONI, mai da un'estrazione (01 §12). Le
    /// condizioni compongono l'INSIDIOSITÀ della zona: una base, la PROFONDITÀ dell'esploratore
    /// nel campo avversario (distanza ortogonale dal proprio quartier generale) e il numero di
    /// gruppi armati avversari VICINI. Il margine `competenza − insidiosità`, confrontato con lo
    /// zero e con due soglie, dà l'esito in ordine di gravità decrescente. I pesi e le soglie
    /// vengono dai dati (`ricognizione-campagna.json`), provvisori.
    ///
    /// La competenza si legge dalla categoria; se il gruppo non è un esploratore la funzione non
    /// dovrebbe essere chiamata (la validazione lo esclude) e l'insidiosità vince, ma non si
    /// forza: si tratta come competenza nulla.
    public func esitoEsplorazione(di gruppo: Gruppo, stato: StatoCampagna) -> EsitoEsplorazione {
        let r = valoriCampagna.ricognizione
        let competenza = gruppo.categoria.competenza ?? 0
        let qgProprio = stato.mappa.quartierGenerale(di: gruppo.parte)
        let profondita = stato.griglia.distanza(gruppo.posizione, qgProprio)
        let avversa: Parte = gruppo.parte == .giocatore ? .avversario : .giocatore
        let nemiciVicini = stato.gruppi.values.filter {
            $0.parte == avversa && $0.categoria.eArmata
                && stato.griglia.distanza($0.posizione, gruppo.posizione) <= r.raggioNemiciVicini
        }.count
        let insidiosita = r.insidiositaBase + r.pesoProfondita * profondita + r.pesoNemiciVicini * nemiciVicini
        let margine = competenza - insidiosita
        if margine >= 0 { return .riuscita }
        if margine >= -r.sogliaManiVuote { return .aManiVuote }
        if margine >= -r.sogliaNotati { return .notati }
        return .perduti
    }

    /// Rivela un'area come conoscenza FRESCA di una parte (01 §5.3, §5.4): la memoria di ogni
    /// casella entro il raggio (ortogonale) si azzera, come se la parte vi osservasse ora. È
    /// l'effetto dell'esplorazione riuscita, che vede più lontano del raggio ordinario.
    func rivelaArea(attorno centro: Cella, per parte: Parte, raggio: Int, in stato: inout StatoCampagna) {
        for dr in -raggio...raggio {
            for dc in -raggio...raggio where abs(dr) + abs(dc) <= raggio {
                let cella = Cella(riga: centro.riga + dr, colonna: centro.colonna + dc)
                if stato.griglia.contiene(cella) { stato.conoscenza[parte, default: [:]][cella] = 0 }
            }
        }
    }

    /// La chiusura del turno (01 §5.6.0.6): il turno si chiude automaticamente quando
    /// tutti i gruppi hanno CONCLUSO la giornata — spendendola o essendo in marcia
    /// lunga, che la consuma senza comando — e NON esiste alcun comando di fine
    /// giornata. La chiusura resta la conseguenza dell'ultimo ordine del giocatore e
    /// non un'iniziativa del programma.
    ///
    /// È un CICLO e non un solo passo: se tutti i gruppi restano in marcia lunga dopo
    /// l'apertura della giornata nuova, non c'è nulla da ordinare e le giornate
    /// scorrono da sé finché una marcia non si compie e libera un gruppo. Il ciclo
    /// termina perché ogni giro avanza tutte le marce di un giorno, e una marcia si
    /// compie entro i propri giorni totali.
    func chiudiLaGiornataSeServe(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        while !stato.gruppi.isEmpty,
              stato.battaglieInSospeso.isEmpty, // una battaglia in sospeso ferma il corso della campagna (01 §6.4)
              stato.gruppi.values.allSatisfy({ $0.haConclusoLaGiornata }) {
            let chiuso = stato.giorno
            eventi.append(.giornataChiusa(giorno: chiuso))
            eventi.append(contentsOf: risolviFineGiornata(&stato))
            stato.giorno += 1
            // Le azioni si azzerano; le marce in corso restano e continuano a consumare la
            // giornata (01 §5.16.1). L'ORDINE DI IMBOSCATA si azzera con l'azione (incarico 21):
            // l'imboscata è un'azione che si RINNOVA, non uno stato che dura, sicché un gruppo
            // appostato torna in ATTESA il mattino dopo. È ciò che scioglie alla radice la
            // cascata infinita di uno stato di soli agguati (il difetto del banco, incarico 20):
            // un gruppo tornato in attesa non è più «concluso», e il ciclo si ferma. Nessun freno
            // che nasconda: la terminazione discende dalla natura dell'ordine. Le imboscate
            // SCOPERTE si azzerano con esse — ogni giornata è una nuova imboscata da scoprire (§5.4).
            for id in stato.gruppi.keys.sorted() {
                stato.gruppi[id]!.azioneSpesa = false
                stato.gruppi[id]!.ordineImboscata = false
            }
            stato.imboscateScoperte = [:]
            // L'apertura della giornata NON produce una voce di registro: il giorno è
            // una proprietà di ciascuna voce (02 §6.6) e non un fatto a sé. Resta
            // l'annuncio, che il cambiamento di stato rilevante richiede (00 §11.4).
            eventi.append(.giornataAperta(giorno: stato.giorno))
        }
        return eventi
    }

    /// La CHIUSURA ESPLICITA della giornata (incarico 26, decisione del titolare): chiude la
    /// giornata corrente quale che sia lo stato dei gruppi, marcando come SPESA la giornata di ogni
    /// gruppo che non l'ha ancora conclusa — la chiusura del titolare vale, per essi, come un ordine
    /// di restare —, poi lascia proseguire la cascata automatica (`chiudiLaGiornataSeServe`). È una
    /// via d'uscita per il giocatore, NON una correzione: la chiusura automatica (01 §5.6.0.6) resta
    /// e vale come prima. Una battaglia in sospeso non si scavalca (01 §6.4): quel blocco si scioglie
    /// aprendo la battaglia dalla casella, non chiudendo la giornata.
    public func chiudiLaGiornataForzata(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        guard !stato.gruppi.isEmpty, stato.battaglieInSospeso.isEmpty else { return [] }
        for id in stato.gruppi.keys.sorted() where !stato.gruppi[id]!.haConclusoLaGiornata {
            stato.gruppi[id]!.azioneSpesa = true
        }
        return chiudiLaGiornataSeServe(&stato)
    }

    /// Le risoluzioni di fine giornata (01 §5.6.11): un MOMENTO DICHIARATO E ORDINATO,
    /// non una funzione che fa una cosa sola. L'ordine è quello di 01 §5.6.11:
    /// avanzamento delle marce lunghe, SCATTO DELLE IMBOSCATE, valutazione dei tagli
    /// di rifornimento, completamenti di costruzione, invecchiamento e decadimento
    /// della conoscenza — di cui la DEDUZIONE DELL'ITINERARIO (01 §5.10.1) fa parte,
    /// perché produce il `presunto` dalle osservazioni fresche. Questa unità aggiunge lo
    /// scatto delle imboscate e la deduzione senza toccare gli altri passi (RDA-98, il
    /// passo già preparato). Restano da costruire i completamenti di costruzione.
    func risolviFineGiornata(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        // Le posizioni PRIMA dell'avanzamento: distinguono chi ENTRA in una casella, perché
        // l'imboscata scatta solo all'ingresso di un gruppo armato (01 §5.11), non su chi vi
        // stava già. Si legge sullo stato prima che le marce settino le nuove posizioni.
        let posizioniPrima = stato.gruppi.mapValues { $0.posizione }
        eventi.append(contentsOf: avanzaLeMarce(&stato))
        let arrivati = Set(stato.gruppi.compactMap { (id, g) -> IdGruppo? in
            posizioniPrima[id] != nil && posizioniPrima[id] != g.posizione ? id : nil
        })
        eventi.append(contentsOf: scattaLeImboscate(&stato, arrivati: arrivati))
        eventi.append(contentsOf: innescaLeBattaglie(&stato, arrivati: arrivati))
        eventi.append(contentsOf: valutaITagliDiRifornimento(&stato))
        // Passo successivo (unità futura): completaLeCostruzioni(&stato)
        eventi.append(contentsOf: deduciGliItinerari(&stato))
        eventi.append(contentsOf: invecchiaLaConoscenza(&stato))
        return eventi
    }

    /// Lo SCATTO DELLE IMBOSCATE (01 §5.11, §5.6.11): passo di fine giornata. Un gruppo armato
    /// appostato la cui casella riceve, in questa risoluzione, l'INGRESSO di un gruppo armato
    /// avversario vede scattare la propria imboscata. «All'ingresso» è la chiave: `arrivati`
    /// sono i gruppi che si sono mossi in questa risoluzione, e l'imboscata scatta solo se
    /// l'intruso armato è fra loro — non su chi occupava già la casella per compresenza. Vale
    /// SIMMETRICAMENTE per entrambe le parti (l'avversario può tendere imboscate, e il giocatore
    /// vi può cadere). Il vantaggio dell'imboscante è materia della battaglia (01 §9.3.2, non
    /// costruita): qui si registra lo scatto in `imboscateInSospeso` e si annota il fatto, sempre
    /// consegnato al giocatore (lo scatto è fra parti opposte, il giocatore ne è parte). L'ordine
    /// è deterministico (per id). L'agguato scattato si spegne — è sorto e ha còlto il suo bersaglio.
    func scattaLeImboscate(_ stato: inout StatoCampagna, arrivati: Set<IdGruppo>) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        for id in stato.gruppi.keys.sorted() {
            guard let appostato = stato.gruppi[id], appostato.ordineImboscata else { continue }
            let casella = appostato.posizione
            let avversa: Parte = appostato.parte == .giocatore ? .avversario : .giocatore
            guard let intruso = stato.occupante(di: casella, parte: avversa),
                  intruso.categoria.eArmata, arrivati.contains(intruso.id) else { continue }
            stato.gruppi[id]!.ordineImboscata = false
            stato.imboscateInSospeso.append(ImboscataInSospeso(
                casella: casella, imboscante: appostato.parte, intruso: intruso.id, giorno: stato.giorno))
            annota(.imboscataScattata(casella: casella), in: &stato)
            eventi.append(.imboscataScattata(casella: casella))
            // Lo scatto RACCOLTO e REALIZZATO (incarico 24, RDA-98): l'imboscata diventa una
            // battaglia in sospeso col vantaggio della sorpresa (imboscante = l'appostato, che
            // occupava per primo e agirà per primo, 01 §9.3.2, §9.4.1). L'`imboscataScattata` sopra
            // resta il fatto di registro; la battaglia in sospeso è il record che il passaggio
            // consuma. L'evento dedicato dà l'allarme «nuova battaglia in sospeso» (02 §11.7.1).
            registraBattagliaInSospeso(casella: casella, primoOccupante: appostato.parte,
                                       imboscante: appostato.parte, in: &stato)
            eventi.append(.battagliaInnescata(casella: casella, daImboscata: true))
        }
        return eventi
    }

    /// L'INNESCO DELLE BATTAGLIE ORDINARIE (01 §6.1, §6.11, incarico 24): passo di fine giornata,
    /// gemello dello scatto delle imboscate. Un gruppo armato che ENTRA in una casella dove sta
    /// già un gruppo armato contrapposto impone lo scontro (01 §6.1.1: «chi arriva sceglie tempo e
    /// luogo»; chi voleva rifiutare doveva essersene andato prima, S24a). Vale SIMMETRICAMENTE per
    /// le due parti. Diversamente dall'imboscata non concede alcun vantaggio (01 §5.6.3.5). L'ordine
    /// dei turni: agisce per primo chi occupava per primo, cioè chi NON è fra gli arrivati (01
    /// §9.4.1); se entrambi sono arrivati nella stessa risoluzione, il vantaggio nascosto va al
    /// giocatore (S24d, coerente con 01 §13, §15.2.5). L'agguato ha la precedenza sul contatto
    /// ordinario nella stessa casella, col suo vantaggio. Ordine deterministico (per id, per casella).
    func innescaLeBattaglie(_ stato: inout StatoCampagna, arrivati: Set<IdGruppo>) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        var caselleViste = Set<Cella>()
        for id in stato.gruppi.keys.sorted() {
            guard let g = stato.gruppi[id], g.categoria.eArmata else { continue }
            let casella = g.posizione
            guard !caselleViste.contains(casella) else { continue }
            guard let nemico = stato.occupante(di: casella, parte: g.parte.avversaria),
                  nemico.categoria.eArmata else { continue }
            // La compresenza preesistente non innesca da sé: almeno uno dei due deve essere
            // entrato in QUESTA risoluzione (S24a, 01 §6.1 «due eserciti possono restare fronte
            // a fronte»). Chi era già lì e resta non impone nulla marcia dopo marcia.
            guard arrivati.contains(id) || arrivati.contains(nemico.id) else { continue }
            caselleViste.insert(casella)
            // L'agguato precede: se un'imboscata ha già registrato la battaglia qui, col suo
            // vantaggio, il contatto ordinario non la sostituisce né la duplica.
            guard stato.battagliaInSospeso(su: casella) == nil else { continue }
            let primoOccupante: Parte
            if !arrivati.contains(id) { primoOccupante = g.parte }
            else if !arrivati.contains(nemico.id) { primoOccupante = nemico.parte }
            else { primoOccupante = .giocatore }
            registraBattagliaInSospeso(casella: casella, primoOccupante: primoOccupante,
                                       imboscante: nil, in: &stato)
            annota(.battagliaInnescata(casella: casella), in: &stato)
            eventi.append(.battagliaInnescata(casella: casella, daImboscata: false))
        }
        return eventi
    }

    /// Registra una battaglia in sospeso nella casella, risolvendo i due gruppi contrapposti
    /// (incarico 24). Idempotente sulla casella: non ne registra due nella stessa. L'identificatore
    /// è deterministico dalla casella e dal giorno, così che nomini lo stesso slot su disco a ogni
    /// ripresa (05 §2.8). Non fa nulla se la casella non ospita entrambe le parti armate.
    private func registraBattagliaInSospeso(casella: Cella, primoOccupante: Parte,
                                            imboscante: Parte?, in stato: inout StatoCampagna) {
        guard stato.battagliaInSospeso(su: casella) == nil,
              let g = stato.occupante(di: casella, parte: .giocatore),
              let a = stato.occupante(di: casella, parte: .avversario) else { return }
        stato.battaglieInSospeso.append(BattagliaInSospeso(
            identificatore: BattagliaInSospeso.identificatore(casella: casella, giorno: stato.giorno),
            casella: casella, gruppoGiocatore: g.id, gruppoAvversario: a.id,
            primoOccupante: primoOccupante, imboscante: imboscante, giorno: stato.giorno))
    }

    /// IL RITORNO IN CAMPAGNA (01 §15, incarico 24): piega sulla mappa l'esito di una battaglia
    /// conclusa. È PURO — funzione dei soli `esito` e `stato` — sicché rigiocare il giornale di
    /// campagna, dove l'esito è iscritto come una riga a sé, riproduce il ripiegamento identico
    /// senza rileggere i file della battaglia (05 §6.1, invariante «rigiocatura identica»). Per
    /// ciascuno dei due gruppi: se i superstiti sono vuoti il gruppo è annientato e SPARISCE dalla
    /// mappa (01 §15.2.3); altrimenti la sua composizione diventa quella dei superstiti già
    /// raggruppati (01 §4.11, §15.7) e la sua casella quella del ritorno — il vincitore nella
    /// casella contesa (01 §15.5), lo sconfitto arretrato (01 §10.6). La battaglia in sospeso si
    /// consuma, e la campagna si sblocca (01 §15.8). Il fatto entra nel registro col luogo e
    /// l'esito, sicché chi torna sulla mappa sa com'è andata anche riaprendo la campagna.
    public func applicaEsitoInCampagna(_ esito: EsitoInCampagna,
                                       in stato: inout StatoCampagna) -> [EventoCampagna] {
        for parte in [Parte.giocatore, .avversario] {
            let id = esito.gruppo(di: parte)
            let composizione = esito.composizione(di: parte)
            if composizione.isEmpty {
                stato.gruppi.removeValue(forKey: id) // annientato: sparisce dalla mappa (01 §15.2.3)
            } else if stato.gruppi[id] != nil {
                stato.gruppi[id]!.composizione = composizione
                if let posizione = esito.posizione(di: parte) {
                    stato.gruppi[id]!.posizione = posizione
                }
                // IL GRUPPO CHE HA COMBATTUTO SPENDE LA GIORNATA COMBATTENDO (regola del titolare,
                // 01 §5.6.0.5: «ogni azione consuma l'intera giornata del gruppo che la compie»): il
                // superstite risulta AGITO — `azioneSpesa` a vero —, non in attesa, e la giornata si
                // chiude di conseguenza (01 §5.6.0.6). È la causa vera del blocco della build 26, dove
                // il vincitore tornava non-agito e non-ordinabile: reso impossibile per costruzione.
                // La battaglia interrompe la marcia e ogni agguato.
                stato.gruppi[id]!.marcia = nil
                stato.gruppi[id]!.ordineImboscata = false
                stato.gruppi[id]!.azioneSpesa = true
            }
        }
        stato.battaglieInSospeso.removeAll { $0.identificatore == esito.identificatore }
        annota(.battagliaConclusa(casella: esito.casella,
                                  giocatoreSconfitto: esito.sconfitto == .giocatore), in: &stato)
        var eventi: [EventoCampagna] = [.battagliaConclusa(casella: esito.casella,
                                                           giocatoreSconfitto: esito.sconfitto == .giocatore)]
        // Sbloccata la campagna e speso il combattente, la giornata si chiude da sé se non resta
        // altro da fare (01 §5.6.0.6): i combattenti hanno agito, e se erano gli ultimi in attesa la
        // giornata avanza subito, senza che il giocatore debba dare un ordine di troppo al reduce.
        eventi.append(contentsOf: chiudiLaGiornataSeServe(&stato))
        return eventi
    }

    /// La SCOPERTA delle imboscate (01 §5.11.1, incarico 21): dentro il raggio di un'esplorazione
    /// RIUSCITA, ogni gruppo avversario APPOSTATO non ancora scoperto viene rivelato. La sua casella
    /// entra in `imboscateScoperte[parte]`, che leva l'occultamento (`conoscenza` la torna
    /// confermata e la parte vi vede l'appostato), e il fatto è annotato nel registro col luogo —
    /// del solo giocatore, come gli altri fatti (l'avversario decide sulla propria conoscenza e il
    /// giocatore non apprende le sue scoperte). Deterministica: nessuna estrazione, discende dalla
    /// stessa riuscita dell'esplorazione (§5.4); l'ordine delle caselle è fisso (per id del gruppo).
    func scopriLeImboscate(attorno centro: Cella, per parte: Parte, raggio: Int,
                           in stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
        var scoperte = stato.imboscateScoperte[parte] ?? []
        for g in stato.gruppi(di: avversa)
        where g.ordineImboscata
            && stato.griglia.distanza(g.posizione, centro) <= raggio
            && !scoperte.contains(g.posizione) {
            scoperte.insert(g.posizione)
            if parte == .giocatore {
                annota(.imboscataScoperta(casella: g.posizione), in: &stato)
            }
            eventi.append(.imboscataScoperta(parte: parte, casella: g.posizione))
        }
        stato.imboscateScoperte[parte] = scoperte
        return eventi
    }

    /// La DEDUZIONE DELL'ITINERARIO (01 §5.10.1): passo di fine giornata dentro la conoscenza.
    /// Il compito è degli ESPLORATORI (01 §5.10.1): per ciascuna parte, si guardano le colonne
    /// avversarie che una sua formazione di RICOGNIZIONE osserva ora. Se una colonna si è mossa
    /// lungo una strada per due caselle consecutive — la sua ultima posizione nota, adiacente e
    /// su strada, e quella attuale, anch'essa su strada, allineate — se ne deduce che segua
    /// quella strada «fino alla destinazione o a una ramificazione»: le caselle a valle diventano
    /// `presunto` per quella parte, e si annota la deduzione (del solo giocatore). Le presunzioni
    /// si RICALCOLANO ogni giornata dalle osservazioni fresche: una presunzione non più sostenuta
    /// svanisce. Deterministico: nessuna estrazione, ordine dei gruppi e delle caselle fisso.
    /// Simmetrico fra le parti; solo i fatti del giocatore raggiungono il suo registro.
    func deduciGliItinerari(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        for parte in [Parte.giocatore, .avversario] {
            let avversa: Parte = parte == .giocatore ? .avversario : .giocatore
            var nuoviPresunti = Set<Cella>()
            var memoria = stato.ultimaPosizioneNota[parte] ?? [:]
            for colonna in stato.gruppi(di: avversa) {
                let pos = colonna.posizione
                // Solo ciò che un ESPLORATORE della parte osserva ora abilita la deduzione.
                guard osservataDaEsploratore(pos, di: parte, stato: stato) else { continue }
                let precedente = memoria[colonna.id]
                memoria[colonna.id] = pos
                guard let prev = precedente, prev != pos,
                      stato.griglia.adiacenti(prev, pos),
                      stato.mappa.strada(di: prev) != .nessuna,
                      stato.mappa.strada(di: pos) != .nessuna else { continue }
                let proiettate = proiettaItinerario(da: pos, verso: (pos.riga - prev.riga, pos.colonna - prev.colonna),
                                                    stato: stato)
                guard !proiettate.isEmpty else { continue }
                nuoviPresunti.formUnion(proiettate)
                if parte == .giocatore {
                    annota(.direzioneDedotta(casella: pos), in: &stato)
                    eventi.append(.direzioneDedotta(casella: pos))
                }
            }
            stato.presunti[parte] = nuoviPresunti
            stato.ultimaPosizioneNota[parte] = memoria
        }
        return eventi
    }

    /// Vero se una formazione di RICOGNIZIONE della parte osserva ora la casella (01 §5.10.1):
    /// entro il raggio di osservazione ordinario da un proprio esploratore. È ciò che distingue
    /// la deduzione dell'itinerario, compito degli esploratori, dalla semplice osservazione.
    func osservataDaEsploratore(_ cella: Cella, di parte: Parte, stato: StatoCampagna) -> Bool {
        let raggio = valoriCampagna.conoscenza.raggioOsservazione
        return stato.gruppi.values.contains {
            $0.parte == parte && $0.categoria.eRicognizione
                && stato.griglia.distanza($0.posizione, cella) <= raggio
        }
    }

    /// Proietta l'itinerario dedotto lungo una strada, da una casella in una direzione ortogonale,
    /// «fino alla destinazione o a una ramificazione» (01 §5.10.1): le caselle successive finché
    /// sono su strada e dentro la mappa, includendo la ramificazione e fermandosi lì. Una
    /// ramificazione è una casella su strada con un'uscita su strada PERPENDICOLARE alla direzione
    /// di marcia: la colonna potrebbe svoltare, sicché il seguito oltre non è più presumibile. Il
    /// limite del numero di caselle della griglia impedisce ogni ciclo.
    func proiettaItinerario(da origine: Cella, verso direzione: (Int, Int),
                            stato: StatoCampagna) -> Set<Cella> {
        var proiettate = Set<Cella>()
        let (dr, dc) = direzione
        var corrente = Cella(riga: origine.riga + dr, colonna: origine.colonna + dc)
        let massimo = stato.griglia.righe * stato.griglia.colonne
        while proiettate.count < massimo,
              stato.griglia.contiene(corrente),
              stato.mappa.strada(di: corrente) != .nessuna {
            proiettate.insert(corrente)
            // Ramificazione: un'uscita su strada perpendicolare alla direzione. Vi ci si ferma.
            let perpendicolari = [Cella(riga: corrente.riga + dc, colonna: corrente.colonna + dr),
                                  Cella(riga: corrente.riga - dc, colonna: corrente.colonna - dr)]
            let ramifica = perpendicolari.contains {
                stato.griglia.contiene($0) && stato.mappa.strada(di: $0) != .nessuna
            }
            if ramifica { break }
            corrente = Cella(riga: corrente.riga + dr, colonna: corrente.colonna + dc)
        }
        return proiettate
    }

    /// Primo e unico passo realizzato della risoluzione: ogni marcia in corso avanza
    /// di un giorno; quella che raggiunge i giorni totali si compie e il gruppo entra
    /// nella casella di arrivo (01 §5.6.3.3). L'ordine è deterministico (per id). La
    /// casella di arrivo è libera per costruzione, perché la validazione impedisce
    /// che due marce puntino la stessa casella o che una punti una casella occupata.
    func avanzaLeMarce(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        // Le caselle in cui una formazione AVVERSARIA si è compiuta questa giornata: gli
        // avvistamenti si valutano DOPO, sulle posizioni settlate (vedi sotto).
        var arriviAvversari: [Cella] = []
        for id in stato.gruppi.keys.sorted() {
            guard var marcia = stato.gruppi[id]!.marcia else { continue }
            marcia.giorniCompiuti += 1
            if marcia.giorniCompiuti >= marcia.giorniTotali {
                let gruppo = stato.gruppi[id]!
                let partenza = gruppo.posizione
                let nome = gruppo.nome
                let arrivo = marcia.destinazione
                stato.gruppi[id]!.posizione = arrivo
                stato.gruppi[id]!.marcia = nil
                if gruppo.parte == .giocatore {
                    // L'ARRIVO si annuncia — l'evento e il richiamo tattile del completamento
                    // di marcia (02 §11.7.1) — ma NON entra più nel registro (seconda correzione
                    // del titolare, incarico 19): è un fatto che il giocatore ha deciso e già
                    // conosce, e il registro serve a recuperare ciò che è accaduto mentre
                    // guardava altrove. La voce di registro se ne va; l'annuncio resta.
                    eventi.append(.marciaCompiuta(gruppo: id, nome: nome, da: partenza, a: arrivo))
                } else {
                    arriviAvversari.append(arrivo)
                }
            } else {
                stato.gruppi[id]!.marcia = marcia
            }
        }
        // Gli avvistamenti si valutano quando TUTTE le marce si sono compiute, sulle
        // posizioni settlate: l'osservazione a metà del giro dipenderebbe dall'ordine
        // degli identificatori (un gruppo del giocatore nato da una divisione ha id
        // maggiore dell'avversario e si muoverebbe dopo di lui), e darebbe avvistamenti
        // incoerenti con lo stato finale. Una formazione avversaria compiutasi è
        // avvistata se il giocatore la OSSERVA ora (conoscenza confermato, 01 §5.6.11):
        // il fatto e il luogo, senza nome né volume (02 §6.4.1), annunciato e nel registro
        // (02 §8.2.1). Su una casella non osservata non esce nulla, e nessuna informazione
        // raggiunge il giocatore se non dalla sua conoscenza e dal registro.
        for arrivo in arriviAvversari where osservata(arrivo, da: .giocatore, stato: stato) {
            eventi.append(.formazioneAvversariaAvvistata(casella: arrivo))
            annota(.formazioneAvversariaAvvistata(casella: arrivo), in: &stato)
        }
        return eventi
    }

    /// La valutazione dei tagli di rifornimento (01 §5.6.11, §5.2.2): il passo di fine
    /// giornata che, sulla posizione RAGGIUNTA da ciascun gruppo, aggiorna lo stato di
    /// rifornimento. Gira DOPO l'avanzamento delle marce, così una marcia compiuta si
    /// valuta già nella casella d'arrivo. Non decide nulla per il giocatore: registra
    /// fatti non decisi — il taglio, la sosta imposta, la ripresa — con il giorno e il
    /// salto al luogo (02 §6.6). L'ordine è deterministico (per id).
    ///
    /// La precedenza è fissa. Un gruppo IN SOSTA scala un giorno dovuto e, esaurita la
    /// sosta, torna rifornito. Un gruppo IN ZONA è rifornito comunque, perché in zona
    /// il taglio non ha effetto (01 §5.2.2.6). Un gruppo TAGLIATO accumula i turni
    /// senza provviste, mai oltre due: al primo il rifornimento si interrompe, al
    /// secondo scatta la sosta imposta di due turni (01 §5.2.2.4). Un gruppo di nuovo
    /// rifornito lungo la catena, che aveva patito il taglio senza arrivare alla sosta,
    /// riprende. Il malus dei turni senza provviste agisce altrove, sui parametri del
    /// reparto, e mai sul volume (01 §5.2.2.3): qui si tiene solo il conto.
    func valutaITagliDiRifornimento(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        for id in stato.gruppi.keys.sorted() {
            let gruppo = stato.gruppi[id]!
            // Le formazioni di RICOGNIZIONE non sono soggette al taglio (01 §5.15): vivono di
            // autonomia, il loro costo è il rischio (01 §5.4). Si saltano, e i loro contatori
            // di rifornimento restano a zero (invariante `rifornimento_fuori_intervallo`).
            guard !gruppo.esenteDalTaglio else { continue }
            let casella = gruppo.posizione
            // Il rifornimento dell'AVVERSARIO segue le stesse regole (nessuna asimmetria,
            // 01 §5.2.2), ma i suoi fatti NON raggiungono il giocatore: non entrano nel
            // suo registro né nei suoi annunci, o gli darebbero informazione che la sua
            // conoscenza non gli ha dato (01 §5.6.11). Lo stato si aggiorna per entrambe
            // le parti; annuncio e registro sono del solo giocatore. `riporta` è il punto
            // unico che lo rende impossibile per costruzione, non per disciplina.
            func riporta(_ evento: EventoCampagna, _ fatto: FattoRegistrato) {
                guard gruppo.parte == .giocatore else { return }
                eventi.append(evento)
                annota(fatto, in: &stato)
            }

            // In sosta: si scala un giorno dovuto. All'ultimo, il gruppo è di nuovo
            // rifornito e i turni senza provviste si azzerano; la ripresa si annota.
            if gruppo.sostaDovuta > 0 {
                stato.gruppi[id]!.sostaDovuta -= 1
                if stato.gruppi[id]!.sostaDovuta == 0 {
                    stato.gruppi[id]!.turniSenzaProvviste = 0
                    riporta(.rifornimentoRipreso(gruppo: id, nome: gruppo.nome, casella: casella),
                            .rifornimentoRipreso(gruppo: gruppo.nome, casella: casella))
                }
                continue
            }

            // In zona: rifornito comunque. Se veniva da un digiuno, la zona lo chiude e
            // il rifornimento riprende.
            if inZonaDiRifornimento(casella, stato: stato) {
                if gruppo.turniSenzaProvviste > 0 {
                    stato.gruppi[id]!.turniSenzaProvviste = 0
                    riporta(.rifornimentoRipreso(gruppo: id, nome: gruppo.nome, casella: casella),
                            .rifornimentoRipreso(gruppo: gruppo.nome, casella: casella))
                }
                continue
            }

            // Tagliato: si accumula un turno senza provviste, mai oltre due. Al primo il
            // rifornimento si interrompe; al secondo scatta la sosta imposta di due turni.
            if rifornimentoTagliato(di: gruppo, stato: stato) {
                switch gruppo.turniSenzaProvviste {
                case 0:
                    stato.gruppi[id]!.turniSenzaProvviste = 1
                    riporta(.rifornimentoInterrotto(gruppo: id, nome: gruppo.nome, casella: casella),
                            .rifornimentoInterrotto(gruppo: gruppo.nome, casella: casella))
                case 1:
                    stato.gruppi[id]!.turniSenzaProvviste = 2
                    stato.gruppi[id]!.sostaDovuta = 2
                    riporta(.sostaDiRifornimento(gruppo: id, nome: gruppo.nome, casella: casella),
                            .sostaDiRifornimento(gruppo: gruppo.nome, casella: casella))
                default:
                    // A due turni senza provviste senza sosta già dovuta non si arriva:
                    // il secondo taglio impone sempre la sosta, gestita dal ramo di sopra.
                    break
                }
                continue
            }

            // Rifornito lungo la catena: se veniva da un digiuno mai sfociato in sosta —
            // l'ha spezzato muovendosi al riparo — il rifornimento riprende.
            if gruppo.turniSenzaProvviste > 0 {
                stato.gruppi[id]!.turniSenzaProvviste = 0
                riporta(.rifornimentoRipreso(gruppo: id, nome: gruppo.nome, casella: casella),
                        .rifornimentoRipreso(gruppo: gruppo.nome, casella: casella))
            }
        }
        return eventi
    }

    /// Annota un fatto nel registro della campagna (01 §5.17, 02 §6.6). Il giorno
    /// è quello corrente al momento del fatto e resta scritto nella voce.
    public func annota(_ fatto: FattoRegistrato, in stato: inout StatoCampagna) {
        stato.registro.append(VoceRegistro(numero: stato.prossimoNumeroVoce,
                                           giorno: stato.giorno, fatto: fatto))
        stato.prossimoNumeroVoce += 1
    }
}
