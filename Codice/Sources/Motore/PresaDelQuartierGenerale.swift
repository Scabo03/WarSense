import Foundation
import Dati

// LA PRESA DEL QUARTIER GENERALE E IL RICHIAMO DELL'ESERCITO (01 §5.18.2, §5.18.3; incarico 32): le due
// vie con cui una campagna si conclude che i documenti nominavano e che mancavano. Le regole valgono
// identiche per le due parti; il richiamo è del solo giocatore, perché la campagna è sua.

/// Una FORTEZZA, che vale come secondo quartier generale di chi la possiede (01 §5.14.3, §5.14.3.2). Le
/// opere non esistono ancora nel gioco: è un dato dello scenario, il minimo perché la regola dei due
/// quartieri generali si possa provare, come le strutture di rifornimento.
public struct Fortezza: Hashable, Codable, Sendable {
    public let riga: Int
    public let colonna: Int
    public let parte: Parte

    public init(riga: Int, colonna: Int, parte: Parte) {
        self.riga = riga; self.colonna = colonna; self.parte = parte
    }
    public var casella: Cella { Cella(riga: riga, colonna: colonna) }
}

/// L'OCCUPAZIONE in corso di un quartier generale (01 §5.18.3): dove, chi lo occupa, e quante giornate
/// di fila lo ha già tenuto. Il proprietario è l'altra parte.
public struct OccupazioneDelQuartierGenerale: Hashable, Codable, Sendable {
    public let casella: Cella
    public let occupante: Parte
    public var giornate: Int

    public init(casella: Cella, occupante: Parte, giornate: Int) {
        self.casella = casella; self.occupante = occupante; self.giornate = giornate
    }
}

/// Perché l'esercito non si può richiamare in patria (01 §5.18.2): il primo impedimento, in ordine
/// fisso, con ciò che serve a dichiararlo (02 §6.5) — quale gruppo, e dove.
public enum ImpedimentoDelRichiamo: Hashable, Sendable {
    /// La campagna non si conclude: è una campagna di prova, senza una patria a cui tornare.
    case senzaPatria
    case campagnaConclusa
    /// Una battaglia è in sospeso: il medesimo motivo di ogni comando bloccato (01 §6.4, 02 §6.5).
    case battagliaInSospeso(casella: Cella)
    case rifornimentoTagliato(gruppo: IdentificatoreDati, casella: Cella)
    case aContatto(gruppo: IdentificatoreDati, casella: Cella)
}

extension StatoCampagna {
    /// I quartieri generali di una parte, quello della mappa per primo e poi le sue fortezze (01
    /// §5.14.3: «chi la possiede ne ha due»).
    public func quartieriGenerali(di parte: Parte) -> [Cella] {
        [mappa.quartierGenerale(di: parte)]
            + (fortezze ?? []).filter { $0.parte == parte }.map(\.casella)
    }

    /// L'occupazione in corso di un quartier generale, se c'è.
    public func occupazione(di casella: Cella) -> OccupazioneDelQuartierGenerale? {
        occupazioni?.first { $0.casella == casella }
    }

    /// Le giornate che mancano perché un'occupazione prenda il quartier generale. Nullo se la campagna
    /// non dichiara la regola.
    public func giornateMancanti(_ occupazione: OccupazioneDelQuartierGenerale) -> Int? {
        regole.map { max(0, $0.giornatePerLaPresa - occupazione.giornate) }
    }

    /// Vero se nella casella c'è un quartier generale che la regola della presa rende OCCUPABILE dalla
    /// parte indicata e un suo gruppo armato vi sta: chi lo possiede lo sa sempre (01 §5.18.3.3).
    public func quartierGeneraleOccupato(su casella: Cella, da occupante: Parte) -> Bool {
        regole != nil && quartieriGenerali(di: occupante.avversaria).contains(casella)
            && self.occupante(di: casella, parte: occupante)?.categoria.eArmata == true
    }
}

extension MotoreCampagna {

    // MARK: - La presa (01 §5.18.3)

    /// Come sta un quartier generale rispetto a chi potrebbe prenderlo.
    private enum Tenuta { case libero, conteso, tenuto }

    /// Libero: nessun gruppo armato dell'altra parte vi sta. Conteso: vi sta e vi è una battaglia in
    /// sospeso, oppure vi sta col difensore senza averlo battuto. Tenuto: vi sta da solo, o vi ha battuto
    /// il difensore — che, senza una casella in cui ripiegare, può essere rimasto lì sconfitto (S25a) e
    /// non per questo lo scaccia.
    private func tenuta(di casella: Cella, da occupante: Parte, stato: StatoCampagna) -> Tenuta {
        guard stato.occupante(di: casella, parte: occupante)?.categoria.eArmata == true else { return .libero }
        if stato.battagliaInSospeso(su: casella) != nil { return .conteso }
        let difeso = stato.occupante(di: casella, parte: occupante.avversaria)?.categoria.eArmata == true
        return difeso && stato.occupazione(di: casella) == nil ? .conteso : .tenuto
    }

    /// Le occupazioni che una parte può avere: i quartieri generali dell'altra che non sono già presi.
    private func occupabili(da occupante: Parte, stato: StatoCampagna) -> [Cella] {
        let presi = Set(stato.quartieriGeneraliPresi ?? [])
        return stato.quartieriGenerali(di: occupante.avversaria).filter { !presi.contains($0) }
    }

    /// Il passo di fine giornata (01 §5.6.11, §5.18.3): dopo i movimenti e gli scontri, ogni quartier
    /// generale tenuto da un gruppo armato dell'altra parte conta la giornata. La chiusura in cui il
    /// gruppo vi entra COMINCIA l'occupazione e non conta; ogni chiusura successiva in cui la tiene conta
    /// una giornata; quella in cui è contesa non conta e non azzera; quella in cui non c'è più azzera.
    /// Raggiunte le giornate della regola il quartier generale è preso; preso l'ultimo, la campagna è
    /// conclusa. Il giocatore per primo: se nella stessa chiusura cadessero gli ultimi quartieri generali
    /// di entrambi, vince lui, come nell'annientamento simultaneo (01 §15.2.5).
    func contaLeOccupazioni(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        guard let regole = stato.regole, stato.conclusione == nil else { return [] }
        var eventi: [EventoCampagna] = []
        for occupante in [Parte.giocatore, .avversario] {
            for casella in occupabili(da: occupante, stato: stato) {
                let posto = stato.occupazioni?.firstIndex { $0.casella == casella }
                switch (tenuta(di: casella, da: occupante, stato: stato), posto) {
                case (.tenuto, nil):
                    eventi.append(cominciaLOccupazione(di: casella, da: occupante, regole: regole, in: &stato))
                case (.tenuto, .some(let indice)):
                    stato.occupazioni![indice].giornate += 1
                    let mancano = regole.giornatePerLaPresa - stato.occupazioni![indice].giornate
                    if mancano > 0 {
                        eventi.append(.occupazioneProsegue(casella: casella, occupante: occupante, mancano: mancano))
                    } else {
                        eventi.append(contentsOf: prendi(casella, occupante: occupante, in: &stato))
                        if stato.conclusione != nil { return eventi }
                    }
                case (.libero, .some):
                    eventi.append(interrompiLOccupazione(di: casella, da: occupante, in: &stato))
                case (.conteso, _), (.libero, nil):
                    break
                }
            }
        }
        return eventi
    }

    /// Il ritorno da una battaglia (01 §5.18.3.2): se è nata su un quartier generale, chi lo occupava e
    /// l'ha perduta vede azzerarsi il conteggio, anche se non ha potuto ripiegare; chi l'ha vinta contro
    /// il difensore comincia l'occupazione. Non conta giornate: le conta la chiusura.
    func rivediLeOccupazioni(dopo esito: EsitoInCampagna, _ stato: inout StatoCampagna) -> [EventoCampagna] {
        guard let regole = stato.regole, stato.conclusione == nil else { return [] }
        var eventi = interrompiLeOccupazioniLasciate(&stato)
        for occupante in [Parte.giocatore, .avversario]
        where occupabili(da: occupante, stato: stato).contains(esito.casella) {
            let inCorso = stato.occupazione(di: esito.casella) != nil
            if esito.sconfitto == occupante {
                if inCorso { eventi.append(interrompiLOccupazione(di: esito.casella, da: occupante, in: &stato)) }
            } else if !inCorso, stato.occupante(di: esito.casella, parte: occupante)?.categoria.eArmata == true {
                eventi.append(cominciaLOccupazione(di: esito.casella, da: occupante, regole: regole, in: &stato))
            }
        }
        return eventi
    }

    /// Dopo una riunione (01 §5.6.0.3): se il gruppo che occupava è confluito in un altro che sta altrove,
    /// la casella è lasciata adesso, e il conteggio si azzera subito. Non comincia nulla: chi è posto o
    /// resta su un quartier generale durante la giornata comincia a occuparlo alla chiusura.
    func interrompiLeOccupazioniLasciate(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        (stato.occupazioni ?? [])
            .filter { tenuta(di: $0.casella, da: $0.occupante, stato: stato) == .libero }
            .map { interrompiLOccupazione(di: $0.casella, da: $0.occupante, in: &stato) }
    }

    private func cominciaLOccupazione(di casella: Cella, da occupante: Parte, regole: RegoleDiCampagna,
                                      in stato: inout StatoCampagna) -> EventoCampagna {
        stato.occupazioni = (stato.occupazioni ?? [])
            + [OccupazioneDelQuartierGenerale(casella: casella, occupante: occupante, giornate: 0)]
        // Nel registro entra ciò che il giocatore non ha deciso (01 §5.17.1): l'avversario che occupa il
        // suo quartier generale. La propria occupazione, che è la sua marcia compiuta, si annuncia.
        if occupante == .avversario { annota(.quartierGeneraleOccupato(casella: casella), in: &stato) }
        return .quartierGeneraleOccupato(casella: casella, occupante: occupante, mancano: regole.giornatePerLaPresa)
    }

    private func interrompiLOccupazione(di casella: Cella, da occupante: Parte,
                                        in stato: inout StatoCampagna) -> EventoCampagna {
        stato.occupazioni?.removeAll { $0.casella == casella }
        if occupante == .avversario { annota(.quartierGeneraleLiberato(casella: casella), in: &stato) }
        return .occupazioneInterrotta(casella: casella, occupante: occupante)
    }

    /// Un quartier generale CADE. Se era l'ultimo di chi lo possedeva la campagna è conclusa e vinta da
    /// chi l'ha preso (01 §5.14.3.2, §5.18.3.4), e la dichiarazione di conclusione dice la caduta;
    /// altrimenti la caduta è un fatto a sé. Un quartier generale preso resta preso fino al termine
    /// della campagna. Le battaglie rimaste in sospeso altrove non si combattono più.
    private func prendi(_ casella: Cella, occupante: Parte, in stato: inout StatoCampagna) -> [EventoCampagna] {
        stato.occupazioni?.removeAll { $0.casella == casella }
        stato.quartieriGeneraliPresi = (stato.quartieriGeneraliPresi ?? []) + [casella]
        guard occupabili(da: occupante, stato: stato).isEmpty else {
            annota(.quartierGeneralePreso(casella: casella, dalGiocatore: occupante == .giocatore), in: &stato)
            return [.quartierGeneralePreso(casella: casella, occupante: occupante)]
        }
        stato.battaglieInSospeso = []
        return [Self.concludi(&stato, modo: .presa, vincitore: occupante, giorno: stato.giorno)]
    }

    // MARK: - Il richiamo (01 §5.18.2)

    /// Il primo motivo per cui l'esercito non si può richiamare adesso, oppure nulla se si può. Nessun
    /// gruppo del giocatore dev'essere a rifornimento tagliato (5.2.2.2) né a contatto col nemico: nella
    /// stessa casella di un gruppo avversario, di qualunque categoria, oppure in una battaglia in sospeso
    /// (decisione del titolare del 24 novembre 2026). Le formazioni di ricognizione non sono soggette al
    /// taglio (5.15). L'ordine è fisso: i gruppi si guardano in ordine di lettura.
    public func impedimentoDelRichiamo(_ stato: StatoCampagna) -> ImpedimentoDelRichiamo? {
        guard stato.calendario != nil else { return .senzaPatria }
        guard stato.conclusione == nil else { return .campagnaConclusa }
        if let battaglia = stato.battaglieInSospeso.first { return .battagliaInSospeso(casella: battaglia.casella) }
        let miei = stato.gruppi(di: .giocatore)
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
        for gruppo in miei where !gruppo.esenteDalTaglio && rifornimentoTagliato(di: gruppo, stato: stato) {
            return .rifornimentoTagliato(gruppo: gruppo.nome, casella: gruppo.posizione)
        }
        for gruppo in miei where stato.occupante(di: gruppo.posizione, parte: .avversario) != nil {
            return .aContatto(gruppo: gruppo.nome, casella: gruppo.posizione)
        }
        return nil
    }

    /// Il RICHIAMO dell'esercito in patria: la campagna si conclude e conta come perduta, e i superstiti
    /// tornano tutti. Precondizione: nessun impedimento.
    public func richiama(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        precondition(impedimentoDelRichiamo(stato) == nil, "richiamo.impedito")
        return [Self.concludi(&stato, modo: .richiamo, vincitore: .avversario, giorno: stato.giorno)]
    }

    // MARK: - Le strade in giornate

    /// Le GIORNATE che servono a una colonna del volume dato per raggiungere una meta da ciascuna casella,
    /// per la via più breve in giornate (01 §5.6.3.1), senza attraversare le caselle da evitare: la meta
    /// stessa è sempre ammessa. È ciò che serve a chi deve sapere se arriva in tempo, l'avversario e le
    /// condotte di verifica; nessuna estrazione, e a parità di costo l'ordine di lettura.
    public static func giornate(verso meta: Cella, volumeColonna: Int64, mappa: MappaCampagna,
                                marcia: ValoriMarcia, evitando: Set<Cella> = []) -> [Cella: Int] {
        var distanze: [Cella: Int] = [meta: 0]
        var daVisitare: Set<Cella> = [meta]
        while let corrente = daVisitare.min(by: { distanze[$0]! == distanze[$1]! ? $0 < $1 : distanze[$0]! < distanze[$1]! }) {
            daVisitare.remove(corrente)
            for vicino in mappa.griglia.vicini(di: corrente) where !evitando.contains(vicino) {
                let costo = distanze[corrente]! + costoInGiorni(da: vicino, a: corrente, volumeColonna: volumeColonna,
                                                                mappa: mappa, marcia: marcia)
                if costo < distanze[vicino] ?? Int.max {
                    distanze[vicino] = costo
                    daVisitare.insert(vicino)
                }
            }
        }
        return distanze
    }
}
