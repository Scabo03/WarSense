import Foundation
import Dati

// L'impronta canonica dello stato del regno (05 §2.9): codifica dedicata, campi nell'ordine
// dichiarato, interi a lunghezza fissa, opzionali con marcatore. Due stati che si comportano in
// modo diverso devono dare byte diversi; mai la codifica JSON generica.

extension Riserve: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        for risorsa in Risorsa.allCases { c.intero(Int64(self[risorsa])) }
    }
}

extension CategoriaFormazione: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        switch self {
        case .armato: c.testo("armato")
        case .ricognizione(let competenza):
            c.testo("ricognizione"); c.intero(Int64(competenza))
        case .nonArmata(let carico, let sogliaProtezione):
            c.testo("non_armata"); c.intero(Int64(carico)); c.intero(Int64(sogliaProtezione))
        }
    }
}

extension ForzeDelRegno: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        switch self {
        case .sciami(let formazioni, let prossimoNome):
            c.testo("sciami")
            // L'ordine delle formazioni è un fatto di gioco: è quello in cui partono per il fronte.
            c.intero(Int64(formazioni.count))
            for formazione in formazioni {
                c.testo(formazione.nome)
                formazione.categoria.codifica(in: &c)
                c.intero(Int64(formazione.composizione.count))
                for reparto in formazione.composizione { reparto.codifica(in: &c) }
                c.vero(formazione.inPatria)
                c.testo(formazione.arrivo?.rawValue ?? "")
            }
            c.intero(Int64(prossimoNome))
        }
    }
}

extension BersaglioMilitare: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(unita); c.intero(Int64(elemento))
    }
}

extension ElementoDelleForze: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(unita); reparto.codifica(in: &c)
    }
}

extension IngressoNelleForze: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(unita); categoria.codifica(in: &c)
        c.intero(Int64(composizione.count))
        for reparto in composizione { reparto.codifica(in: &c) }
        c.testo(arrivo.rawValue); c.vero(confluite)
    }
}

extension EffettoMilitare: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(gancio)
        switch self {
        case .reclutaReparto(let archetipo, let atomi):
            c.testo(archetipo); c.intero(Int64(atomi))
        case .miglioraReparto(let miglioramento), .mantieniMiglioramento(let miglioramento):
            c.testo(miglioramento)
        }
    }
}

extension EsitoCampagna: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(fronte); c.intero(Int64(anno)); c.testo(modo.rawValue)
        c.testo(vincitore?.rawValue ?? "")
        c.intero(Int64(giornate)); c.intero(Int64(battaglieVinte)); c.intero(Int64(battagliePerse))
        superstiti.codifica(in: &c)
    }
}

extension FattoDiPatria: CodificabileCanonico {
    public func codifica(in c: inout CodificatoreCanonico) {
        switch self {
        case .campagnaConclusa(let fronte, let modo, let vincitore):
            c.testo("campagna_conclusa"); c.testo(fronte); c.testo(modo.rawValue)
            c.testo(vincitore?.rawValue ?? "")
        case .invernoCominciato:
            c.testo("inverno_cominciato")
        case .miglioramentoDato(let migliorato):
            c.testo("miglioramento_dato"); migliorato.codifica(in: &c)
        case .primaveraCominciata(let eccedenzaPerduta):
            c.testo("primavera_cominciata"); c.vero(eccedenzaPerduta)
        case .mantenimentoPrelevato(let quota):
            c.testo("mantenimento_prelevato"); quota.codifica(in: &c)
        case .elementoSciolto(let sciolto):
            c.testo("elemento_sciolto"); sciolto.codifica(in: &c)
        case .recluteEntrate(let ingresso):
            c.testo("reclute_entrate"); ingresso.codifica(in: &c)
        case .miglioramentoPerduto(let perduto):
            c.testo("miglioramento_perduto"); perduto.codifica(in: &c)
        }
    }
}

extension StatoRegno {
    /// L'impronta canonica dello stato: SHA-256 sulla codifica canonica (05 §2.9).
    public func impronta() -> String {
        var c = CodificatoreCanonico()
        c.intero(Int64(anno))
        switch momento {
        case .operativo: c.testo("operativo")
        case .inverno(let stazione): c.testo("inverno"); c.intero(Int64(stazione))
        }
        c.testo(fase.rawValue)
        riserve.codifica(in: &c)
        entrataDellAnno.codifica(in: &c)
        forze.codifica(in: &c)
        switch campagna {
        case .nonAperta: c.testo("non_aperta")
        case .aperta(let fronte): c.testo("aperta"); c.testo(fronte)
        case .conclusa(let esito): c.testo("conclusa"); esito.codifica(in: &c)
        }
        // I lavori, nell'ordine in cui sono stati ordinati: è l'ordine in cui si annullano.
        c.intero(Int64(lavori.count))
        for lavoro in lavori {
            c.testo(lavoro.voce); lavoro.costo.codifica(in: &c)
            c.intero(Int64(lavoro.stazione)); lavoro.effetto.codifica(in: &c)
            c.testo(lavoro.pronto.rawValue)
            c.opzionale(lavoro.bersaglio) { cc, b in b.codifica(in: &cc) }
        }
        // Il registro è in ordine di accadimento, che è esso stesso un fatto (RDA-55).
        c.intero(Int64(registro.count))
        for voce in registro {
            c.intero(Int64(voce.numero)); c.intero(Int64(voce.anno)); c.testo(voce.stagione.rawValue)
            voce.fatto.codifica(in: &c)
        }
        c.intero(Int64(prossimoNumeroVoce))
        // Il mantenimento prelevato e ciò che ha sciolto in questo inverno: è ciò che la prima
        // schermata dichiara, e due inverni che dichiarano cose diverse non sono lo stesso stato.
        mantenimento.codifica(in: &c)
        c.intero(Int64(sciolti.count))
        for sciolto in sciolti { sciolto.codifica(in: &c) }
        return SHA256.improntaEsadecimale(c.byte)
    }
}
