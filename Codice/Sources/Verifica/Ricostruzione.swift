import Foundation
import Dati
import Motore

/// La ricostruzione di uno scontro colpo per colpo. Non è un aggregato: registra
/// ogni singolo danno con chi lo ha inflitto, a chi, in quale giro, da quale
/// distanza e con quale efficacia. Serve a rispondere alle domande che le medie
/// non possono raggiungere, come «dove si forma il divario fra due reparti».
public struct Ricostruzione: Sendable {

    public struct Colpo: Sendable {
        public let giro: Int
        /// Tiro oppure mischia.
        public let genere: String
        public let parteChiColpisce: Parte
        public let chiColpisce: String
        public let parteColpito: Parte
        public let colpito: String
        public let distanza: Int
        public let efficacia: EfficaciaQualitativa
        public let danno: Int64
        /// Consistenza del colpito dopo il colpo, in punti.
        public let residuo: Int64
    }

    public let colpi: [Colpo]
    public let esito: EsitoBattaglia?
    public let giri: Int

    /// Il nome parlante di uno sciame dentro la ricostruzione: archetipo e lettera.
    static func nome(_ sciame: Sciame) -> String {
        sciame.archetipo + "-" + String(sciame.lettera)
    }

    /// Gioca uno scontro registrando ogni colpo. Le due parti sono guidate dalle
    /// condotte fornite: così si può mettere una condotta contro un'altra.
    public static func gioca(motore: MotoreBattaglia, scenario: ScenarioBattaglia,
                             condotte: [Parte: Condotta], giriMassimi: Int) throws -> Ricostruzione {
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0
        var colpi: [Colpo] = []
        var passi = 0
        while stato.esito == nil && stato.giro <= giriMassimi && passi < giriMassimi * 200 {
            let parte = stato.parteDiTurno
            let prima = stato
            let comando = condotte[parte]!.prossimoComando(stato: stato, parte: parte)
            let (dopo, eventi) = motore.applica(comando, parte: parte, stato: stato)
            colpi.append(contentsOf: estrai(eventi: eventi, prima: prima, dopo: dopo, motore: motore))
            stato = dopo
            passi += 1
        }
        return Ricostruzione(colpi: colpi, esito: stato.esito, giri: stato.giro)
    }

    /// Ricava i colpi dagli eventi del Motore, appoggiandosi allo stato precedente
    /// per sapere chi occupava quale cella e a quale distanza.
    static func estrai(eventi: [EventoBattaglia], prima: StatoBattaglia, dopo: StatoBattaglia,
                       motore: MotoreBattaglia) -> [Colpo] {
        var esito: [Colpo] = []
        for evento in eventi {
            switch evento {
            case .tiroEseguito(let parte, let sciame, let bersaglio, _, _, let danno, _, let efficacia):
                guard let chi = prima.sciami[sciame], let colpito = prima.sciami[bersaglio] else { break }
                esito.append(Colpo(
                    giro: prima.giro, genere: "tiro",
                    parteChiColpisce: parte, chiColpisce: nome(chi),
                    parteColpito: colpito.parte, colpito: nome(colpito),
                    distanza: prima.griglia.distanza(chi.posizione, colpito.posizione),
                    efficacia: efficacia, danno: danno,
                    residuo: dopo.sciami[bersaglio]?.serbatoio ?? 0))

            case .contattoRisolto(_, _, _, let c):
                guard let primo = prima.occupante(di: c.cellaPrimo),
                      let secondo = prima.occupante(di: c.cellaSecondo) else { break }
                for (chi, colpito, danno) in [(secondo, primo, c.dannoAlPrimo),
                                              (primo, secondo, c.dannoAlSecondo)] {
                    let offesa = motore.valori.archetipi[chi.archetipo]!.offesaMischia
                    esito.append(Colpo(
                        giro: prima.giro, genere: "mischia_immediata",
                        parteChiColpisce: chi.parte, chiColpisce: nome(chi),
                        parteColpito: colpito.parte, colpito: nome(colpito),
                        distanza: 1,
                        efficacia: motore.efficaciaQualitativa(
                            offesa: offesa,
                            protezione: motore.valori.protezioni[colpito.protezione]!),
                        danno: danno,
                        residuo: dopo.sciami[colpito.id]?.serbatoio ?? 0))
                }

            case .esitoMischiaComplessivo(let contatti):
                for contatto in contatti {
                    guard let primo = prima.occupante(di: contatto.cellaPrimo),
                          let secondo = prima.occupante(di: contatto.cellaSecondo) else { continue }
                    // Ogni contatto produce due direzioni: il danno al primo viene
                    // dal secondo e viceversa. Il danno nullo è esso stesso un fatto
                    // (il limite dei bersagli: chi arriva terzo non riceve risposta).
                    for (chi, colpito, danno) in [(secondo, primo, contatto.dannoAlPrimo),
                                                  (primo, secondo, contatto.dannoAlSecondo)] {
                        let offesa = motore.valori.archetipi[chi.archetipo]!.offesaMischia
                        esito.append(Colpo(
                            giro: prima.giro, genere: "mischia",
                            parteChiColpisce: chi.parte, chiColpisce: nome(chi),
                            parteColpito: colpito.parte, colpito: nome(colpito),
                            distanza: 1,
                            efficacia: motore.efficaciaQualitativa(
                                offesa: offesa,
                                protezione: motore.valori.protezioni[colpito.protezione]!),
                            danno: danno,
                            residuo: dopo.sciami[colpito.id]?.serbatoio ?? 0))
                    }
                }
            default:
                break
            }
        }
        return esito
    }
}

/// Una condotta: chi decide i comandi di una parte. Il tattico del Motore è una
/// condotta; se ne possono mettere altre a confronto, che è il solo modo di
/// misurare se un MODO di giocare batta un altro.
public protocol Condotta: Sendable {
    func prossimoComando(stato: StatoBattaglia, parte: Parte) -> ComandoBattaglia
}

/// Il tattico del Motore, cioè la condotta che concentra: ordina i bersagli per
/// efficacia, ingaggia appena può, avanza verso il più vicino.
public struct CondottaDelTattico: Condotta {
    let tattico: TatticoBattaglia
    public init(tattico: TatticoBattaglia) { self.tattico = tattico }
    public func prossimoComando(stato: StatoBattaglia, parte: Parte) -> ComandoBattaglia {
        tattico.prossimoComando(stato: stato)
    }
}
