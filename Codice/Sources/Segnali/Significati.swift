import Foundation
import Dati
import Motore

/// I significati assegnati ai segnali (02 §11.7.1): quindici, in cinque famiglie
/// ritmiche, più gli eventi che restano a suono e voce. Le chiavi corrispondono
/// ai pattern di aptica.json e alle assegnazioni di suoni.json.
public enum SignificatoSegnale: String, Sendable, CaseIterable {
    case cambioRiga = "cambio_riga"
    case cambioRigaConNemici = "cambio_riga_con_nemici"
    case marciaCompletata = "marcia_completata"
    case conferma = "conferma"
    case annullamento = "annullamento"
    case mischiaFavorevole = "mischia_favorevole"
    case mischiaSfavorevole = "mischia_sfavorevole"
    case disingaggio = "disingaggio"
    case munizioniEsaurite = "munizioni_esaurite"
    case deckEsaurito = "deck_esaurito"
    case rifornimentoInterrotto = "rifornimento_interrotto"
    case risorsaInsufficiente = "risorsa_insufficiente"
    case imboscata = "imboscata"
    case battagliaInSospeso = "battaglia_in_sospeso"
    case sortita = "sortita"
    case vincoloCampagna = "vincolo_campagna"
    /// Fuori dal tetto tattile: solo suono e voce (02 §11.7.1).
    case rinforziNelDeck = "rinforzi_nel_deck"

    /// Vero se il significato ha un segnale tattile assegnato (02 §11.7.1).
    public var conSegnaleTattile: Bool {
        self != .rinforziNelDeck
    }
}

/// La traduzione degli eventi della battaglia in significato e annuncio (05 §10.7):
/// l'ingresso di Segnali è l'evento astratto; qui si risolvono modello, verbosità
/// e lingua. Parte neutra e collaudabile: nessun canale di piattaforma.
public struct TraduttoreEventi: Sendable {
    let testi: Testi
    /// La parte che ascolta: gli eventi si annunciano dal suo punto di vista.
    let parte: Parte

    public init(testi: Testi, parte: Parte) {
        self.testi = testi
        self.parte = parte
    }

    /// Il significato di segnale per l'evento, se l'evento ne merita uno.
    public func significato(per evento: EventoBattaglia) -> SignificatoSegnale? {
        switch evento {
        case .piazzamentoConfermato(let p, _, _, _, _, _, _):
            return p == parte ? .conferma : nil
        case .elementoDeckEsaurito(let p, _):
            return p == parte ? .deckEsaurito : nil
        case .esitoMischiaComplessivo(let esiti):
            return esiti.isEmpty ? nil : esitoFavorevole(esiti) ? .mischiaFavorevole : .mischiaSfavorevole
        case .disingaggio: return .disingaggio
        case .munizioniEsaurite: return .munizioniEsaurite
        case .contattoRisolto(let p, _, _, let esito):
            // Il contatto porta ora il proprio esito: il segnale lo accompagna
            // subito, con lo stesso segno che l'annuncio complessivo usa a inizio
            // giro (02 §11.4). Vale per l'ingaggio proprio e per quello subito.
            _ = p
            return esitoFavorevole([esito]) ? .mischiaFavorevole : .mischiaSfavorevole
        case .sorpresaConclusa: return .imboscata
        default: return nil
        }
    }

    /// L'esito complessivo delle mischie, dal punto di vista della parte che ascolta:
    /// favorevole se le perdite inflitte non sono inferiori alle subite
    /// (il segno è la sfumatura dentro la famiglia, 02 §11.4).
    func esitoFavorevole(_ esiti: [EsitoContatto]) -> Bool {
        var inflitte: Int64 = 0, subite: Int64 = 0
        for e in esiti {
            subite += e.perdite(di: parte)
            inflitte += e.perdite(di: parte.avversaria)
        }
        return inflitte >= subite
    }

    /// Il nome parlato di un archetipo e la lettera del reparto (01 §9.4.3):
    /// termini del vocabolario chiuso, in posizione fissa dopo il nome.
    private func nome(_ archetipo: IdentificatoreDati) -> String {
        testi.frase("unita." + archetipo).testo
    }
    private func lettera(_ ordinale: Int) -> String {
        testi.termine("lettera.\(ordinale)").testo
    }
    /// La frase chiusa di una fascia, declinata per direzione (02 §4.4.5, §8.9.1).
    private func fasciaFrase(_ fascia: FasciaPerdite, inflitte: Bool) -> String {
        let direzione = inflitte ? "inflitte" : "subite"
        return testi.termine("perdite." + direzione + "." + fascia.rawValue).testo
    }

    /// L'annuncio per l'evento, già risolto nel livello di verbosità e nella lingua.
    /// Restituisce nulla per gli eventi che non producono annuncio proattivo.
    /// Gli eventi avversari si annunciano senza alcun numero di volume (01 §9.3.7);
    /// gli esiti dei combattimenti si annunciano in fasce, mai in numeri (01 §9.7.2).
    public func annuncio(per evento: EventoBattaglia, verbosita: Verbosita) -> TestoLocalizzato? {
        switch evento {
        case .turnoIniziato(let p, let giro):
            let chiave = p == parte ? "battaglia.turno_proprio" : "battaglia.turno_avversario"
            return testi.frase(chiave, verbosita: verbosita, giro)
        case .piazzamentoConfermato(let p, _, let archetipo, let letteraOrdinale, let cella, let costo, let residuo):
            guard p == parte else {
                // L'ingresso di forze avversarie si annuncia (02 §8.2.1), senza volume.
                return testi.frase("battaglia.ingresso_avversario", verbosita: verbosita,
                                   nome(archetipo), lettera(letteraOrdinale), cella.riga, cella.colonna)
            }
            return testi.frase("battaglia.piazzamento_confermato", verbosita: verbosita,
                               Int(costo), Int(residuo))
        case .elementoDeckEsaurito(let p, _):
            return p == parte ? testi.frase("battaglia.elemento_esaurito", verbosita: verbosita) : nil
        case .spostamentoEseguito(let p, _, let archetipo, let letteraOrdinale, let a, let costo, let residuo):
            guard p == parte else {
                return testi.frase("battaglia.spostamento_avversario", verbosita: verbosita,
                                   nome(archetipo), lettera(letteraOrdinale), a.riga, a.colonna)
            }
            return testi.frase("battaglia.spostamento", verbosita: verbosita,
                               a.riga, a.colonna, Int(costo), Int(residuo))
        case .tiroEseguito(let p, _, _, let archetipo, let letteraOrdinale, _, let fascia, _):
            if p == parte {
                return testi.frase("battaglia.tiro_eseguito", verbosita: verbosita,
                                   nome(archetipo), lettera(letteraOrdinale),
                                   fasciaFrase(fascia, inflitte: true))
            }
            return testi.frase("battaglia.tiro_subito", verbosita: verbosita,
                               nome(archetipo), lettera(letteraOrdinale),
                               fasciaFrase(fascia, inflitte: false))
        case .contattoRisolto(let p, let archetipo, let letteraOrdinale, let esito):
            // L'esito segue immediatamente l'azione che lo ha causato, nella stessa
            // forma del tiro: una frase sola, in fasce, mai cifre (02 §8.9.2).
            if p == parte {
                return testi.frase("battaglia.contatto_eseguito", verbosita: verbosita,
                                   nome(archetipo), lettera(letteraOrdinale),
                                   fasciaFrase(esito.fascia(di: parte.avversaria), inflitte: true),
                                   fasciaFrase(esito.fascia(di: parte), inflitte: false))
            }
            return testi.frase("battaglia.contatto_subito", verbosita: verbosita,
                               nome(archetipo), lettera(letteraOrdinale),
                               fasciaFrase(esito.fascia(di: parte.avversaria), inflitte: true),
                               fasciaFrase(esito.fascia(di: parte), inflitte: false))
        case .esitoMischiaComplessivo(let esiti):
            guard !esiti.isEmpty else { return nil }
            // Una sola comunicazione ordinata per tutti i contatti (01 §9.7.1),
            // in fasce dal punto di vista di chi ascolta (02 §8.9.1).
            let voci = esiti.map { e in
                e.stallo
                    ? testi.frase("battaglia.mischia_voce_stallo", verbosita: verbosita,
                                  e.cellaPrimo.riga, e.cellaPrimo.colonna,
                                  testi.termine("esito.stallo").testo).testo
                    : testi.frase("battaglia.mischia_voce", verbosita: verbosita,
                                  e.cellaPrimo.riga, e.cellaPrimo.colonna,
                                  fasciaFrase(e.fascia(di: parte.avversaria), inflitte: true),
                                  fasciaFrase(e.fascia(di: parte), inflitte: false)).testo
            }
            let separatore = testi.frase("battaglia.mischia_separatore").testo
            return TestoLocalizzato(
                testo: testi.frase("battaglia.mischia_complessiva", verbosita: verbosita,
                                   esiti.count).testo + voci.joined(separator: separatore),
                lingua: testi.lingua)
        case .disingaggio(_, _, let a):
            return testi.frase("battaglia.disingaggio", verbosita: verbosita, a.riga, a.colonna)
        case .sciameDisfatto(_, let archetipo, let letteraOrdinale, let cella, let p):
            let chiave = p == parte ? "battaglia.disfatto_proprio" : "battaglia.disfatto_avversario"
            return testi.frase(chiave, verbosita: verbosita,
                               nome(archetipo), lettera(letteraOrdinale), cella.riga, cella.colonna)
        case .munizioniEsaurite(_, let cella):
            return testi.frase("battaglia.munizioni_esaurite", verbosita: verbosita, cella.riga, cella.colonna)
        case .resaDichiarata(let p):
            let chiave = p == parte ? "battaglia.resa_propria" : "battaglia.resa_avversaria"
            return testi.frase(chiave, verbosita: verbosita)
        case .unitaEvacuata(let p, _, let costo):
            guard p == parte else {
                return testi.frase("battaglia.evacuata_avversaria", verbosita: verbosita)
            }
            return testi.frase("battaglia.evacuata", verbosita: verbosita, Int(costo))
        case .sorpresaConclusa:
            return testi.frase("battaglia.sorpresa_conclusa", verbosita: verbosita)
        case .battagliaConclusa(let esito):
            let chiave = esito.modo == .annientamento
                ? "battaglia.conclusa_annientamento" : "battaglia.conclusa_ritirata"
            return testi.frase(chiave, verbosita: verbosita)
        }
    }
}
