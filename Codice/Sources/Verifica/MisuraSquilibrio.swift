import Foundation
import Dati
import Motore

/// LO SQUILIBRIO FRA LE MAPPE (incarico 32): perché al banco il giocatore perde quasi tutte le battaglie
/// sulla mappa piccola e sulla grande e le vince quasi tutte sulla media (incarico 29: 391 perse su 398, 229
/// su 245, 178 vinte su 193).
///
/// Lo strumento gioca DUELLI: una battaglia fra due composizioni, con lo stesso ponte, lo stesso modello di
/// scontro e gli stessi due tattici del banco (`MisuraFrequenzaBattaglie.giocaBattagliaComeAlBanco`), e ne
/// registra l'esito, i giri, e quanto ciascuna parte ha potuto muovere: gli sciami scesi in campo, le mosse,
/// gli ingaggi, gli atomi rimasti. Ciascun duello si gioca nei due ordini — chi occupava la casella agisce
/// per primo — e coi due eserciti scambiati fra le parti, sicché un'asimmetria fra le parti, se c'è, si vede
/// come differenza fra un duello e il suo specchio, e ciò che dipende dalla composizione no.
public struct MisuraSquilibrio: Sendable {

    /// Una composizione col nome con cui compare nei dati.
    public struct Esercito: Sendable, Codable, Hashable {
        public let nome: String
        public let reparti: [Reparto]
        public init(_ nome: String, _ reparti: [(IdentificatoreDati, Int)]) {
            self.nome = nome
            self.reparti = reparti.map { Reparto(archetipo: $0.0, atomi: $0.1) }
        }
    }

    public struct Duello: Sendable, Codable {
        public let serie: String
        public let giocatore: String
        public let avversario: String
        /// Chi occupava la casella, e agisce per primo.
        public let primo: Parte
        public let imboscata: Bool
        public let vincitore: Parte?
        public let modo: String
        public let giri: Int
        public let atomiGiocatore: [Int]
        public let atomiAvversario: [Int]
        public let attivita: [String: Attivita]
    }

    /// Ciò che una parte ha fatto in campo.
    public struct Attivita: Sendable, Codable {
        public var sciamiInCampo = 0
        public var mosse = 0
        public var ingaggi = 0
        public var tiri = 0
        public var rese = 0
        /// Gli sciami che, scesi in campo, non si sono mai mossi né hanno mai ingaggiato.
        public var sciamiImmobili = 0
    }

    let misura: MisuraFrequenzaBattaglie
    public init(misura: MisuraFrequenzaBattaglie) { self.misura = misura }

    /// Una battaglia fra due eserciti, dal ponte di sempre: i due gruppi su una casella della mappa, la
    /// battaglia in sospeso, lo scenario che ne nasce.
    public func duello(serie: String, giocatore: Esercito, avversario: Esercito, primo: Parte,
                       imboscata: Bool = false) throws -> Duello {
        let banco = misura.banco
        let casella = Cella(riga: 2, colonna: 2)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: "guado",
                gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: giocatore.reparti.map(ScenarioCampagna.RepartoIniziale.init))],
                gruppiAvversario: [.init(riga: 1, colonna: 2, composizione: avversario.reparti.map(ScenarioCampagna.RepartoIniziale.init))]),
            valori: banco.valoriCampagna, archetipiNoti: banco.archetipiNoti)
        let mio = stato.gruppi(di: .giocatore)[0].id, suo = stato.gruppi(di: .avversario)[0].id
        stato.gruppi[mio]!.posizione = casella
        stato.gruppi[suo]!.posizione = casella
        let battaglia = BattagliaInSospeso(identificatore: "duello", casella: casella, gruppoGiocatore: mio,
                                           gruppoAvversario: suo, primoOccupante: primo,
                                           imboscante: imboscata ? primo : nil, giorno: 1)
        stato.battaglieInSospeso = [battaglia]

        let motoreB = MotoreBattaglia(valori: misura.motore.valori)
        guard let uffId = banco.modelloScontro.ufficialeAvversario,
              let ufficiale = misura.motore.valori.ufficiali[uffId] else { throw ErroreDelDuello.senzaUfficiale }
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: banco.modelloScontro)
        var sb = try FabbricaBattaglia.crea(scenario: scenario, valori: misura.motore.valori).0
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motoreB, ufficiale: misura.ufficialeDelGiocatore(ufficiale), parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motoreB, ufficiale: ufficiale, parte: .avversario)]
        var attivita: [Parte: Attivita] = [.giocatore: Attivita(), .avversario: Attivita()]
        var inCampo: [IdSciame: Parte] = [:]
        var attivi = Set<IdSciame>()
        var passi = 0
        while sb.esito == nil, sb.giro <= MisuraFrequenzaBattaglie.tettoGiri, passi < MisuraFrequenzaBattaglie.tettoPassi {
            passi += 1
            let parte = sb.parteDiTurno
            let comando = tattici[parte]!.prossimoComando(stato: sb)
            switch comando {
            case .muovi(let id, _): attivita[parte]!.mosse += 1; attivi.insert(id)
            case .ingaggia(let id, _): attivita[parte]!.ingaggi += 1; attivi.insert(id)
            case .tira(let id, _): attivita[parte]!.tiri += 1; attivi.insert(id)
            case .dichiaraResa: attivita[parte]!.rese += 1
            default: break
            }
            sb = motoreB.applica(comando, parte: parte, stato: sb).0
            for sciame in sb.sciami.values { inCampo[sciame.id] = sciame.parte }
        }
        for parte in Parte.allCases {
            let scesi = inCampo.filter { $0.value == parte }.map(\.key)
            attivita[parte]!.sciamiInCampo = scesi.count
            attivita[parte]!.sciamiImmobili = scesi.filter { !attivi.contains($0) }.count
        }
        var vincitore: Parte?
        var modo = "non_conclusa"
        var mieiAtomi: [Int] = [], suoiAtomi: [Int] = []
        if let esito = sb.esito {
            vincitore = esito.sconfitto.avversaria
            modo = esito.modo.rawValue
            let ritorno = PonteCampagnaBattaglia.esito(da: sb, per: battaglia, stato: stato, valori: misura.motore.valori)
            mieiAtomi = ritorno.composizione(di: .giocatore).map(\.atomi)
            suoiAtomi = ritorno.composizione(di: .avversario).map(\.atomi)
        }
        return Duello(serie: serie, giocatore: giocatore.nome, avversario: avversario.nome, primo: primo,
                      imboscata: imboscata, vincitore: vincitore, modo: modo, giri: sb.giro,
                      atomiGiocatore: mieiAtomi, atomiAvversario: suoiAtomi,
                      attivita: Dictionary(uniqueKeysWithValues: attivita.map { ($0.key.rawValue, $0.value) }))
    }

    public enum ErroreDelDuello: Error { case senzaUfficiale }

    /// Le coppie ordinate di eserciti, nei due ordini d'azione.
    public func matrice(serie: String, _ eserciti: [Esercito]) throws -> [Duello] {
        var duelli: [Duello] = []
        for giocatore in eserciti {
            for avversario in eserciti {
                for primo in Parte.allCases {
                    duelli.append(try duello(serie: serie, giocatore: giocatore, avversario: avversario, primo: primo))
                }
            }
        }
        return duelli
    }
}

/// I duelli come li esegue lo strumento da riga di comando: gli eserciti degli scenari del gioco — gli stessi
/// per il giocatore e per l'avversario —, con i tattici del banco e con quello del giocatore che non si
/// arrende; e le composizioni PROPOSTE al titolare al posto di quella che non può avanzare, contro le altre.
public enum DuelliDaRigaDiComando {
    public struct Rapporto: Sendable {
        public let testo: String
        public let grezzi: String
    }

    static let corvo = MisuraSquilibrio.Esercito("6L", [("fanteria_leggera", 6)])
    static let lupo = MisuraSquilibrio.Esercito("18L+8P", [("fanteria_leggera", 18), ("fanteria_pesante", 8)])
    static let falco = MisuraSquilibrio.Esercito("24P+12C", [("fanteria_pesante", 24), ("cavalleria_manovrata", 12)])
    /// Le proposte: la metà del gruppo pesante, la stessa forza in reparti che possono avanzare, e due mezzi.
    static let proposte = [
        MisuraSquilibrio.Esercito("12P+6C", [("fanteria_pesante", 12), ("cavalleria_manovrata", 6)]),
        MisuraSquilibrio.Esercito("10P+5C", [("fanteria_pesante", 10), ("cavalleria_manovrata", 5)]),
        MisuraSquilibrio.Esercito("12P+12P+6C+6C", [("fanteria_pesante", 12), ("fanteria_pesante", 12),
                                                  ("cavalleria_manovrata", 6), ("cavalleria_manovrata", 6)]),
        MisuraSquilibrio.Esercito("16P+8C", [("fanteria_pesante", 16), ("cavalleria_manovrata", 8)]),
    ]

    public static func esegui(cartellaValori: URL) throws -> Rapporto {
        let valori = try CaricatoreValori.carica(da: cartellaValori)
        let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
        let motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        var duelli: [MisuraSquilibrio.Duello] = []
        for (suffisso, pari) in [("", false), ("_tattico_pari", true)] {
            let misura = MisuraSquilibrio(misura: MisuraFrequenzaBattaglie(motore: motore, valoriCampagna: valoriCampagna,
                                                                          tatticoPari: pari))
            duelli += try misura.matrice(serie: "scenari" + suffisso, [corvo, lupo, falco])
            for proposta in proposte {
                for altro in [corvo, lupo, falco, proposta] {
                    for primo in Parte.allCases {
                        duelli.append(try misura.duello(serie: "proposte" + suffisso, giocatore: altro, avversario: proposta, primo: primo))
                        if altro != proposta {
                            duelli.append(try misura.duello(serie: "proposte" + suffisso, giocatore: proposta, avversario: altro, primo: primo))
                        }
                    }
                }
            }
        }
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let grezzi = try duelli.map { String(decoding: try codificatore.encode($0), as: UTF8.self) }.joined(separator: "\n")
        var righe = ["serie|giocatore|avversario|primo|vincitore|modo|giri|atomi_giocatore|atomi_avversario|scesi_g|immobili_g|mosse_g|ingaggi_g|rese_g|scesi_a|immobili_a|mosse_a|ingaggi_a|rese_a"]
        duelli.sort { ($0.serie, $0.avversario, $0.giocatore, $0.primo.rawValue) < ($1.serie, $1.avversario, $1.giocatore, $1.primo.rawValue) }
        for d in duelli {
            let g = d.attivita[Parte.giocatore.rawValue]!, a = d.attivita[Parte.avversario.rawValue]!
            var colonne: [String] = [d.serie, d.giocatore, d.avversario, d.primo.rawValue, d.vincitore?.rawValue ?? "nessuno", d.modo, String(d.giri)]
            colonne.append(d.atomiGiocatore.map(String.init).joined(separator: "+"))
            colonne.append(d.atomiAvversario.map(String.init).joined(separator: "+"))
            colonne += [g.sciamiInCampo, g.sciamiImmobili, g.mosse, g.ingaggi, g.rese].map(String.init)
            colonne += [a.sciamiInCampo, a.sciamiImmobili, a.mosse, a.ingaggi, a.rese].map(String.init)
            righe.append(colonne.joined(separator: "|"))
        }
        return Rapporto(testo: righe.joined(separator: "\n"), grezzi: grezzi + "\n")
    }
}
