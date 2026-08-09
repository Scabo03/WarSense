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
        // Lo stato di rifornimento entra nell'impronta: due gruppi altrimenti uguali
        // ma uno senza provviste e uno rifornito non sono lo stesso stato.
        c.intero(Int64(turniSenzaProvviste))
        c.intero(Int64(sostaDovuta))
        c.intero(Int64(turniMarciaForzata))
        // La categoria e l'ordine di imboscata (incarico 19): due gruppi altrimenti uguali
        // ma uno esploratore e uno colonna, o uno appostato e uno no, non sono lo stesso
        // stato. OMESSI quando il gruppo è un armato non appostato — la condizione ordinaria
        // — così che gli scenari armati scritti prima diano la stessa impronta al byte
        // (RDA-113). L'impronta è solo scritta e sottoposta a hash, mai decodificata, sicché
        // l'omissione condizionale non crea ambiguità di lettura: basta che stati diversi
        // diano byte diversi, e la stringa discriminante della categoria e il marcatore
        // dell'agguato lo garantiscono.
        switch categoria {
        case .armato: break
        case .ricognizione(let competenza):
            c.testo("ricognizione"); c.intero(Int64(competenza))
        case .nonArmata(let carico, let sogliaProtezione):
            c.testo("non_armata"); c.intero(Int64(carico)); c.intero(Int64(sogliaProtezione))
        }
        if ordineImboscata { c.testo("in_agguato") }
    }
}

extension FattoRegistrato: CodificabileCanonico {
    /// La chiave del testo identifica il caso; poi i suoi valori, nell'ordine
    /// dichiarato. Due voci di registro che raccontano fatti diversi devono
    /// produrre byte diversi, altrimenti l'impronta non distingue due cronache.
    public func codifica(in c: inout CodificatoreCanonico) {
        c.testo(chiaveTesto)
        switch self {
        case .marciaRevocata(let gruppo, let casella):
            c.testo(gruppo); casella.codifica(in: &c)
        case .rifornimentoInterrotto(let gruppo, let casella),
             .sostaDiRifornimento(let gruppo, let casella),
             .rifornimentoRipreso(let gruppo, let casella),
             .esploratoriPerduti(let gruppo, let casella),
             .esploratoriNotati(let gruppo, let casella):
            c.testo(gruppo); casella.codifica(in: &c)
        case .formazioneAvversariaAvvistata(let casella),
             .formazioneSabotata(let casella),
             .formazioneStudiata(let casella),
             .imboscataScattata(let casella),
             .direzioneDedotta(let casella):
            casella.codifica(in: &c)
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
        // Le forze nemiche e le strutture di rifornimento, ordinate per casella: due
        // stati con nemici o strutture in posti diversi si comportano in modo diverso
        // (il taglio e le zone ne dipendono).
        c.intero(Int64(forzeNemiche.count))
        for casella in forzeNemiche.sorted() { casella.codifica(in: &c) }
        c.intero(Int64(struttureDiRifornimento.count))
        for casella in struttureDiRifornimento.sorted() { casella.codifica(in: &c) }
        // La memoria di conoscenza, ordinata per parte e per casella: due partite con
        // ricordi diversi non sono lo stesso stato (l'età dell'informazione conta).
        for parte in Parte.allCases {
            let memoria = conoscenza[parte] ?? [:]
            c.testo(parte.rawValue)
            c.intero(Int64(memoria.count))
            for casella in memoria.keys.sorted() {
                casella.codifica(in: &c)
                c.intero(Int64(memoria[casella]!))
            }
        }
        // Le presunzioni dell'itinerario e la memoria per-formazione dell'ultima posizione
        // nota (incarico 19): due partite che deducono itinerari diversi non sono lo stesso
        // stato. OMESSE quando vuote — nessun esploratore che deduca — così che le partite
        // precedenti diano la stessa impronta al byte (come i gruppi armati sopra).
        if presunti.values.contains(where: { !$0.isEmpty }) {
            for parte in Parte.allCases {
                let insieme = presunti[parte] ?? []
                c.testo(parte.rawValue)
                c.intero(Int64(insieme.count))
                for casella in insieme.sorted() { casella.codifica(in: &c) }
            }
        }
        if ultimaPosizioneNota.values.contains(where: { !$0.isEmpty }) {
            for parte in Parte.allCases {
                let memoria = ultimaPosizioneNota[parte] ?? [:]
                c.testo(parte.rawValue)
                c.intero(Int64(memoria.count))
                for id in memoria.keys.sorted() {
                    c.intero(id.numero)
                    memoria[id]!.codifica(in: &c)
                }
            }
        }
        if studiati.values.contains(where: { !$0.isEmpty }) {
            for parte in Parte.allCases {
                let insieme = studiati[parte] ?? []
                c.testo(parte.rawValue)
                c.intero(Int64(insieme.count))
                for id in insieme.sorted() { c.intero(id.numero) }
            }
        }
        // Le imboscate scattate in attesa, nell'ordine in cui sono avvenute (un fatto di
        // gioco): due partite in cui un'imboscata è scattata o no non sono lo stesso stato.
        // Omesse quando nessuna è scattata, così che le partite precedenti restino identiche.
        if !imboscateInSospeso.isEmpty {
            c.intero(Int64(imboscateInSospeso.count))
            for i in imboscateInSospeso {
                i.casella.codifica(in: &c)
                c.testo(i.imboscante.rawValue)
                c.intero(i.intruso.numero)
                c.intero(Int64(i.giorno))
            }
        }
        return SHA256.improntaEsadecimale(c.byte)
    }
}
