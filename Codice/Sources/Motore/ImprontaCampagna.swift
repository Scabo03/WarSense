import Foundation
import Dati

/// L'impronta canonica dello stato di campagna (05 §2.9): codifica dedicata, campi
/// nell'ordine dichiarato, interi a lunghezza fissa, opzionali con marcatore,
/// insiemi ordinati per identificatore. Mai la codifica JSON generica.
///
/// Il criterio generale vale anche qui: l'impronta deve distinguere due stati che
/// si comportano in modo diverso. Il registro vi entra per intero, perché due
/// campagne con lo stesso schieramento e cronache diverse non sono la stessa
/// partita; le qualificazioni della mappa vi entrano ordinate per casella, perché
/// il loro ordine non è un fatto di gioco.
extension Gruppo: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.intero(id.numero)
        c.testo(parte.rawValue)
        c.intero(Int64(indiceNome))
        posizione.codifica(in: &c)
        c.vero(azioneSpesa)
    }
}

extension VoceRegistro: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.intero(Int64(numero))
        c.intero(Int64(giorno))
        c.testo(fatto.rawValue)
        c.opzionale(luogo) { cc, cella in cella.codifica(in: &cc) }
    }
}

extension StatoCampagna {
    public func impronta() -> String {
        var c = CodificatoreCanonico()
        c.testo(mappa.identificatore)
        c.testo(mappa.formato)
        c.intero(mappa.griglia.righe)
        c.intero(mappa.griglia.colonne)
        c.intero(Int64(mappa.qualificazioni.count))
        for casella in mappa.qualificazioni.keys.sorted() {
            casella.codifica(in: &c)
            let q = mappa.qualificazioni[casella]!
            c.testo(q.terreno.rawValue)
            c.testo(q.strada.rawValue)
        }
        c.opzionale(mappa.strettoia) { cc, cella in cella.codifica(in: &cc) }
        mappa.quartierGeneraleGiocatore.codifica(in: &c)
        mappa.quartierGeneraleAvversario.codifica(in: &c)
        c.intero(giorno)
        c.intero(Int64(gruppi.count))
        for gruppo in gruppiOrdinati { gruppo.codifica(in: &c) }
        c.intero(prossimoIdGruppo)
        c.intero(prossimoIndiceNome)
        // Il registro è in ordine di accadimento, che è esso stesso un fatto: non
        // si riordina, come i contatti di battaglia (05 §2.9, RDA-55).
        c.intero(Int64(registro.count))
        for voce in registro { voce.codifica(in: &c) }
        c.intero(prossimoNumeroVoce)
        return SHA256.improntaEsadecimale(c.byte)
    }
}
