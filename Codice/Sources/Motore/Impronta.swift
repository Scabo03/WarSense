import Foundation
import Dati

/// Codifica canonica per l'impronta di stato (05 §2.9, RDA-44): campi nell'ordine
/// dichiarato, interi a lunghezza fissa, opzionali con marcatore, insiemi ordinati.
/// Mai la codifica JSON generica, che non è canonica.
public struct CodificatoreCanonico {
    public private(set) var byte = Data()

    public mutating func intero(_ v: Int64) {
        withUnsafeBytes(of: v.bigEndian) { byte.append(contentsOf: $0) }
    }
    public mutating func intero(_ v: Int) { intero(Int64(v)) }
    public mutating func vero(_ v: Bool) { byte.append(v ? 1 : 0) }
    public mutating func testo(_ v: String) {
        let utf8 = Data(v.utf8)
        intero(Int64(utf8.count))
        byte.append(utf8)
    }
    public mutating func opzionale<T>(_ v: T?, _ scrivi: (inout CodificatoreCanonico, T) -> Void) {
        if let v { byte.append(1); scrivi(&self, v) } else { byte.append(0) }
    }
}

public protocol CodificabileCanonico {
    func codifica(in codificatore: inout CodificatoreCanonico)
}

extension Cella: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) { c.intero(riga); c.intero(colonna) }
}

extension Sciame: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.intero(id.numero); c.testo(parte.rawValue); c.testo(archetipo)
        c.testo(protezione.rawValue); c.intero(Int64(lettera))
        c.intero(atomiIniziali); c.intero(serbatoio)
        c.intero(Int64(munizioni)); posizione.codifica(in: &c)
        c.vero(azioneSpesa); c.vero(rinforzo)
    }
}

extension StatoBattaglia {
    /// L'impronta canonica dello stato: SHA-256 sulla codifica canonica (05 §2.9).
    /// Confrontabile soltanto a parità di versione dello schema.
    public func impronta() -> String {
        var c = CodificatoreCanonico()
        c.testo(formato)
        c.intero(griglia.righe); c.intero(griglia.colonne)
        c.testo(caratteristica)
        c.intero(Int64(ostacoli.count))
        for cella in ostacoli.sorted() { cella.codifica(in: &c) }
        c.testo(primoOccupante.rawValue)
        c.intero(Int64(sciami.count))
        for sciame in sciamiOrdinati { sciame.codifica(in: &c) }
        for parte in Parte.allCases {
            let elementi = deck[parte] ?? []
            c.intero(Int64(elementi.count))
            for e in elementi {
                c.testo(e.archetipo); c.testo(e.protezione.rawValue)
                c.intero(e.atomi); c.intero(Int64(e.esemplari))
            }
            c.opzionale(selezione[parte]) { cc, v in cc.intero(Int64(v)) }
            c.intero(turniGiocati[parte] ?? 0)
            let b = bilancio[parte] ?? BilancioVolume(baseTurno: 0, riportoEntrante: 0, spesa: 0)
            c.intero(b.baseTurno); c.intero(b.riportoEntrante); c.intero(b.spesa)
            c.intero(perditeSubite[parte] ?? 0)
            c.intero(forzeImpegnate[parte] ?? 0)
            let ev = evacuati[parte] ?? []
            c.intero(Int64(ev.count))
            for id in ev { c.intero(id.numero) }
            c.intero(Int64(prossimaLettera[parte] ?? 1))
        }
        c.intero(prossimoIdSciame)
        c.testo(parteDiTurno.rawValue)
        c.intero(giro)
        switch sorpresa {
        case .vantaggio(let restanti): c.intero(1); c.intero(restanti)
        case .opacita: c.intero(2); c.intero(0)
        case .trasparente: c.intero(3); c.intero(0)
        }
        // I contatti si codificano NELL'ORDINE DI ARRIVO e non riordinati: dal limite
        // dei bersagli simultanei (01 §9.11) quell'ordine decide chi riceve risposta
        // piena, chi ridotta e chi nessuna, quindi è stato di gioco a tutti gli
        // effetti. Un'impronta che lo riordinasse darebbe lo stesso valore a due
        // situazioni che si comportano in modo diverso (05 §2.9, RDA-55).
        c.intero(Int64(contatti.count))
        for contatto in contatti {
            c.intero(contatto.primo.numero); c.intero(contatto.secondo.numero)
            c.intero(contatto.consistenzaIngressoPrimo); c.intero(contatto.consistenzaIngressoSecondo)
        }
        c.intero(Int64(coppieStaccate.count))
        for coppia in coppieStaccate.sorted(by: { ($0.minore, $0.maggiore) < ($1.minore, $1.maggiore) }) {
            c.intero(coppia.minore.numero); c.intero(coppia.maggiore.numero)
        }
        c.intero(Int64(divietoIngaggio.count))
        for (coppia, giroLimite) in divietoIngaggio.sorted(by: { ($0.key.minore, $0.key.maggiore) < ($1.key.minore, $1.key.maggiore) }) {
            c.intero(coppia.minore.numero); c.intero(coppia.maggiore.numero); c.intero(giroLimite)
        }
        c.opzionale(resaDichiarataDa) { cc, v in cc.testo(v.rawValue) }
        c.opzionale(esito) { cc, v in
            cc.testo(v.sconfitto.rawValue); cc.testo(v.modo.rawValue); cc.intero(v.turni)
        }
        return SHA256.improntaEsadecimale(c.byte)
    }
}
