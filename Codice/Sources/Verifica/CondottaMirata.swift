import Foundation
import Dati
import Motore

// La terza condotta del giocatore al banco (incarico 32): quella di chi conosce la regola della presa (01
// §5.18.3). Le altre due sono quelle degli incarichi 29 e 31, e restano com'erano perché le misure si
// confrontino: nessuna delle due guarda i quartieri generali.

extension MisuraFrequenzaBattaglie {

    /// Il prossimo gruppo in attesa e il suo ordine. Chi occupa il quartier generale avversario lo tiene;
    /// se il proprio è occupato ogni gruppo armato torna a riprenderlo per la via più breve in giornate;
    /// una delle armate — scelta dal seme, la stessa per tutta la partita — fa la guardia al proprio; le
    /// altre vanno verso quello avversario, aggirando ciò che si sa dell'avversario, e vi entrano. Un
    /// giorno su quattro, a sorte, un gruppo che avanzerebbe resta: senza, le partite di una stessa forza
    /// iniziale sarebbero tutte uguali. La ricognizione esplora, le formazioni non armate presidiano.
    func condottaMirata(stato: StatoCampagna, vista: VistaCampagna, seme: UInt64,
                        generatore: inout Generatore) -> ComandoCampagna? {
        guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { return nil }
        func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: stato).eValido }
        let mio = stato.mappa.quartierGenerale(di: .giocatore), suo = stato.mappa.quartierGenerale(di: .avversario)
        let noti = Set(vista.caselleFormazioniAvversarieNote)

        func marcia(verso meta: Cella) -> ComandoCampagna? {
            let giornate = MotoreCampagna.giornate(
                verso: meta, volumeColonna: motore.volume(di: gruppo), mappa: stato.mappa,
                marcia: motore.valoriCampagna.marcia, evitando: noti.subtracting([meta, gruppo.posizione]))
            var migliore: (comando: ComandoCampagna, giornate: Int)?
            for casella in stato.griglia.vicini(di: gruppo.posizione).sorted() {
                guard let resto = giornate[casella], let comando = vista.comandoDiMarcia(per: gruppo.id, a: casella),
                      valido(comando) else { continue }
                let totale = vista.costoInGiorni(da: gruppo.posizione, a: casella) + resto
                if migliore.map({ totale < $0.giornate }) ?? true { migliore = (comando, totale) }
            }
            return migliore?.comando
        }

        var candidati: [ComandoCampagna?] = []
        if gruppo.categoria.eRicognizione {
            candidati.append(.esplorazione(gruppo: gruppo.id))
        } else if gruppo.categoria.eArmata {
            if gruppo.deveRifornirsi { candidati.append(.sostaConRaccolta(gruppo: gruppo.id)) }
            let armate = stato.gruppi(di: .giocatore).filter { $0.categoria.eArmata }.sorted { $0.id < $1.id }
            let guardia = armate.count > 1 ? armate[Int(seme % UInt64(armate.count))].id : nil
            if stato.quartierGeneraleOccupato(su: mio, da: .avversario), gruppo.posizione != mio {
                candidati.append(marcia(verso: mio))
            } else if gruppo.posizione == suo {
                candidati.append(.presidio(gruppo: gruppo.id))
            } else if gruppo.id == guardia {
                candidati.append(gruppo.posizione == mio ? .presidio(gruppo: gruppo.id) : marcia(verso: mio))
            } else if generatore.prossimo() % 4 != 0 {
                candidati.append(marcia(verso: suo))
            }
        }
        candidati += [.presidio(gruppo: gruppo.id), .sostaConRaccolta(gruppo: gruppo.id)]
        return candidati.compactMap { $0 }.first(where: valido)
    }
}
