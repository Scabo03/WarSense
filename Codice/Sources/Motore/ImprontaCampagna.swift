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
        c.testo(nome)
        posizione.codifica(in: &c)
        // La composizione entra nell'impronta nell'ordine dichiarato dei reparti,
        // che è un fatto di gioco (l'ordine dei reparti è quello con cui il gruppo
        // si legge e si divide): due gruppi con reparti diversi — o gli stessi in
        // ordine diverso — non sono lo stesso stato. Il volume NON vi entra a sé:
        // è funzione pura della composizione e degli archetipi, e non aggiunge
        // informazione all'impronta.
        c.intero(Int64(composizione.count))
        for reparto in composizione {
            c.testo(reparto.archetipo)
            c.intero(Int64(reparto.atomi))
        }
        c.vero(azioneSpesa)
        // La marcia lunga in corso entra nell'impronta: due gruppi con la stessa
        // posizione e azione ma marce diverse — o uno in marcia e uno no — non sono
        // lo stesso stato e devono produrre byte diversi.
        c.opzionale(marcia) { cc, m in
            m.destinazione.codifica(in: &cc)
            cc.intero(Int64(m.giorniTotali))
            cc.intero(Int64(m.giorniCompiuti))
        }
    }
}

extension FattoRegistrato: CodificabileCanonico {
    /// La chiave del testo identifica il caso; poi i suoi valori, nell'ordine
    /// dichiarato. Due voci di registro che raccontano fatti diversi devono
    /// produrre byte diversi, altrimenti l'impronta non distingue due cronache.
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(chiaveTesto)
        switch self {
        case .marciaCompiuta(let gruppo, let da, let a):
            c.testo(gruppo); da.codifica(in: &c); a.codifica(in: &c)
        case .marciaRevocata(let gruppo, let casella):
            c.testo(gruppo); casella.codifica(in: &c)
        case .ordineAnnullato, .giornataAzzerata:
            break
        }
    }
}

extension VoceRegistro: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.intero(Int64(numero))
        c.intero(Int64(giorno))
        fatto.codifica(in: &c)
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
