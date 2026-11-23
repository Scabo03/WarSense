import Foundation
import Dati

// Le forze militari del regno, e ciò che una voce militare fa loro: la SOLA parte del regno che
// dipende dalla modalità di battaglia (01 §1.2; documento della modalità a campioni, 1.3; incarico 30,
// RDA-166). Il resto del regno — calendario, risorse, bilancio, voci, registro — tratta le forze come
// un valore opaco e non nomina né reparti né gruppi (`StatoRegno.swift`, `MotoreRegno.swift`).
//
// Questa versione conosce la modalità a sciami. La modalità a campioni aggiungerà qui un caso a
// `ForzeDelRegno` — l'organico dei combattenti e gli eroi, con infortuni e recuperi — e i propri
// ganci a `EffettoMilitare`, senza che il resto del regno cambi.
//
// Dalla seconda tappa (incarico 31) il regno CONSERVA le formazioni con il loro nome (01 §5.6.0.4):
// una formazione è la stessa da un anno all'altro, con il nome che il giocatore ha imparato; il
// giocatore sceglie quali mandare al fronte e quali tenere in patria; le reclute formano una
// formazione nuova che dichiara in quale stagione entra; ogni reparto paga una quota annua, e chi
// porta un miglioramento lo conserva soltanto se lo si mantiene (01 §4.13–4.14.1).

/// Una formazione del regno nella modalità a sciami: ciò che un gruppo è quando non sta su un fronte.
/// Il nome (01 §5.6.0.4), la categoria (01 §5.2) e i reparti che la compongono (01 §5.6.0); la
/// casella gliela dà il fronte quando parte.
public struct FormazioneDelRegno: Hashable, Codable, Sendable {
    /// La chiave del nome, dalla lista chiusa: la formazione lo conserva per tutta la propria
    /// esistenza, sul fronte e in patria.
    public let nome: IdentificatoreDati
    public let categoria: CategoriaFormazione
    public var composizione: [Reparto]
    /// Vero se il giocatore la tiene in patria: non parte con la campagna dell'anno (incarico 31).
    public var inPatria: Bool
    /// La stagione in cui la formazione, reclutata nell'ultimo inverno, raggiunge le altre
    /// (01 §5.9.1.4): nulla per le formazioni che ci sono già.
    public var arrivo: Stagione?

    public init(nome: IdentificatoreDati, categoria: CategoriaFormazione, composizione: [Reparto],
                inPatria: Bool = false, arrivo: Stagione? = nil) {
        self.nome = nome; self.categoria = categoria; self.composizione = composizione
        self.inPatria = inPatria; self.arrivo = arrivo
    }

    public var atomiTotali: Int { composizione.reduce(0) { $0 + $1.atomi } }

    /// Vero se la formazione parte con la campagna dell'anno, dalla prima giornata o a campagna
    /// aperta: non è tenuta in patria e non arriva soltanto con l'inverno successivo.
    public var parteConLaCampagna: Bool { !inPatria && arrivo != .inverno }
}

/// Un elemento delle forze su cui una voce può agire (01 §4.13): nella modalità a sciami un reparto
/// di una formazione, indicato dal nome della formazione e dalla posizione nella sua composizione.
/// D'inverno le forze sono in patria e non cambiano forma, sicché l'indicazione è stabile per
/// tutto l'inverno in cui la si usa.
public struct BersaglioMilitare: Hashable, Codable, Sendable {
    public let unita: IdentificatoreDati
    public let elemento: Int

    public init(unita: IdentificatoreDati, elemento: Int) {
        self.unita = unita; self.elemento = elemento
    }
}

/// Ciò che è entrato nelle forze con la primavera (01 §4.12; incarico 31): la formazione che le
/// reclute di un inverno hanno formato, oppure quella a cui si sono unite quando la lista dei nomi
/// era esaurita. È ciò che l'annuncio della primavera dichiara: dove e come le reclute entrano.
public struct IngressoNelleForze: Hashable, Codable, Sendable {
    public let unita: IdentificatoreDati
    public let categoria: CategoriaFormazione
    public let composizione: [Reparto]
    /// La stagione in cui le reclute raggiungono le altre forze.
    public let arrivo: Stagione
    /// Vero se le reclute si sono unite a una formazione che c'era già, anziché formarne una nuova.
    public let confluite: Bool
}

/// Un elemento delle forze nominato in un fatto del regno — ciò che il mantenimento ha sciolto, ciò
/// che ha ricevuto un miglioramento, ciò che lo ha perduto (01 §4.13–4.14.1): nella modalità a sciami
/// un reparto, con la formazione cui appartiene. Il fatto lo porta per intero, perché il registro
/// racconta il momento in cui è avvenuto e non rilegge lo stato.
public struct ElementoDelleForze: Hashable, Codable, Sendable {
    public let unita: IdentificatoreDati
    public let reparto: Reparto

    public init(unita: IdentificatoreDati, reparto: Reparto) {
        self.unita = unita; self.reparto = reparto
    }
}

/// Le forze militari del regno, nella forma della modalità di battaglia scelta all'inizio della
/// partita (01 §1.2).
public enum ForzeDelRegno: Hashable, Codable, Sendable {
    /// Modalità a sciami: le formazioni, nell'ordine in cui il regno le conserva — che è quello in
    /// cui partono per il fronte e si leggono in patria —, e la posizione, nella lista chiusa dei
    /// nomi, da cui si cerca il nome della prossima formazione.
    case sciami(formazioni: [FormazioneDelRegno], prossimoNome: Int)

    /// Le formazioni della modalità a sciami.
    public var formazioni: [FormazioneDelRegno] {
        switch self {
        case .sciami(let formazioni, _): return formazioni
        }
    }

    private var prossimoNome: Int {
        switch self {
        case .sciami(_, let prossimoNome): return prossimoNome
        }
    }

    private func con(_ formazioni: [FormazioneDelRegno]) -> ForzeDelRegno {
        .sciami(formazioni: formazioni, prossimoNome: prossimoNome)
    }

    /// Quante unità contano le forze, nella misura della modalità: nella modalità a sciami le
    /// formazioni che ci sono, senza quelle ancora in arrivo. È il numero che la dichiarazione di
    /// conclusione dice di ciò che rientra.
    public var numeroDiUnita: Int { formazioni.filter { $0.arrivo == nil }.count }

    /// Vero se il regno ha di che condurre una campagna: nella modalità a sciami, almeno una
    /// formazione armata che parta dalla prima giornata, perché senza la campagna si concluderebbe
    /// all'istante (RDA-164). Le formazioni tenute in patria e quelle che arrivano più tardi non
    /// contano.
    public var possonoCondurreCampagna: Bool {
        formazioni.contains { $0.categoria.eArmata && !$0.inPatria && $0.arrivo == nil }
    }

    // MARK: - La scelta di chi parte (incarico 31)

    /// Vero se le forze hanno un'unità con questo nome.
    public func conosce(unita: IdentificatoreDati) -> Bool {
        formazioni.contains { $0.nome == unita }
    }

    /// Vero se l'unità è destinata al fronte; nulla se non esiste.
    public func destinataAlFronte(_ unita: IdentificatoreDati) -> Bool? {
        formazioni.first { $0.nome == unita }.map { !$0.inPatria }
    }

    /// Le forze con un'unità destinata al fronte oppure tenuta in patria.
    public func destinando(_ unita: IdentificatoreDati, alFronte: Bool) -> ForzeDelRegno {
        con(formazioni.map { formazione in
            var nuova = formazione
            if formazione.nome == unita { nuova.inPatria = !alFronte }
            return nuova
        })
    }

    // MARK: - I nomi (01 §5.6.0.4)

    /// Il primo nome della lista che nessuna formazione porta, cercato dalla posizione corrente e
    /// in giro: così un nome liberato dalla perdita di una formazione non torna finché la lista
    /// non è stata percorsa per intero. Nulla se tutti i nomi sono in uso.
    private static func nomeLibero(fra nomi: [IdentificatoreDati], da posizione: Int,
                                   inUso: Set<IdentificatoreDati>) -> (nome: IdentificatoreDati, dopo: Int)? {
        guard !nomi.isEmpty else { return nil }
        for passo in 0..<nomi.count {
            let indice = (posizione + passo) % nomi.count
            if !inUso.contains(nomi[indice]) { return (nomi[indice], (indice + 1) % nomi.count) }
        }
        return nil
    }

    // MARK: - Nascita

    /// Le forze iniziali dichiarate dai valori, tradotte e verificate come i gruppi di uno scenario.
    /// Ricevono i primi nomi della lista, nell'ordine in cui sono dichiarate.
    public static func iniziali(_ dichiarate: [FormazioneIniziale],
                                nomi: [IdentificatoreDati]) throws -> ForzeDelRegno {
        guard dichiarate.count <= nomi.count else { throw ErroreForze.nomiInsufficienti }
        var formazioni: [FormazioneDelRegno] = []
        for (indice, dichiarata) in dichiarate.enumerated() {
            let categoria: CategoriaFormazione
            switch dichiarata.categoria {
            case "armato":
                guard dichiarata.competenza == nil, dichiarata.carico == nil,
                      dichiarata.sogliaProtezione == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .armato
            case "ricognizione":
                guard let competenza = dichiarata.competenza, competenza >= 0, dichiarata.carico == nil,
                      dichiarata.sogliaProtezione == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .ricognizione(competenza: competenza)
            case "non_armata":
                guard let carico = dichiarata.carico, carico >= 0,
                      let soglia = dichiarata.sogliaProtezione, soglia >= 0,
                      dichiarata.competenza == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .nonArmata(carico: carico, sogliaProtezione: soglia)
            default:
                throw ErroreForze.formazioneIncoerente
            }
            guard !dichiarata.composizione.isEmpty,
                  dichiarata.composizione.allSatisfy({ $0.atomi >= 1 }) else {
                throw ErroreForze.formazioneIncoerente
            }
            formazioni.append(FormazioneDelRegno(
                nome: nomi[indice], categoria: categoria,
                composizione: dichiarata.composizione.map { Reparto(archetipo: $0.archetipo, atomi: $0.atomi) }))
        }
        return .sciami(formazioni: formazioni, prossimoNome: nomi.isEmpty ? 0 : dichiarate.count % nomi.count)
    }

    public enum ErroreForze: Error, Equatable {
        /// Una formazione iniziale con una categoria ignota, dati di un'altra categoria, o vuota.
        case formazioneIncoerente
        /// La lista chiusa dei nomi non basta alle formazioni iniziali.
        case nomiInsufficienti
    }

    // MARK: - La primavera: reclute, miglioramenti (01 §4.12–4.14)

    /// Vero se il bersaglio indica un elemento che esiste.
    public func esiste(_ bersaglio: BersaglioMilitare) -> Bool { reparto(bersaglio) != nil }

    /// Il reparto che un bersaglio indica.
    public func reparto(_ bersaglio: BersaglioMilitare) -> Reparto? {
        guard let formazione = formazioni.first(where: { $0.nome == bersaglio.unita }),
              formazione.composizione.indices.contains(bersaglio.elemento) else { return nil }
        return formazione.composizione[bersaglio.elemento]
    }

    /// La misura di un bersaglio, cui si applica il costo di base: nella modalità a sciami gli atomi
    /// del reparto.
    public func misura(di bersaglio: BersaglioMilitare) -> Int? { reparto(bersaglio)?.atomi }

    /// Gli elementi su cui una voce può agire, nell'ordine in cui le forze si leggono: per il
    /// miglioramento i reparti che non ne portano uno, per il mantenimento quelli che portano
    /// quel miglioramento. Soltanto le formazioni che ci sono: chi è ancora in arrivo non si
    /// addestra una seconda volta nello stesso inverno. Vuoto per le voci senza bersaglio.
    public func bersagli(di effetto: EffettoMilitare) -> [BersaglioMilitare] {
        var esito: [BersaglioMilitare] = []
        for formazione in formazioni where formazione.arrivo == nil {
            for (indice, reparto) in formazione.composizione.enumerated() {
                let ammesso: Bool
                switch effetto {
                case .reclutaReparto: ammesso = false
                case .miglioraReparto: ammesso = reparto.miglioramento == nil
                case .mantieniMiglioramento(let miglioramento): ammesso = reparto.miglioramento == miglioramento
                }
                if ammesso { esito.append(BersaglioMilitare(unita: formazione.nome, elemento: indice)) }
            }
        }
        return esito
    }

    /// Le forze dopo la PRIMAVERA (01 §4.12–4.14; incarico 31). Tre cose, in quest'ordine.
    ///
    /// I miglioramenti non mantenuti si perdono, e il reparto resta (01 §4.14): `mantenuti` sono i
    /// bersagli delle voci di mantenimento ordinate nell'inverno.
    ///
    /// I miglioramenti ordinati nell'inverno si applicano ai loro bersagli.
    ///
    /// Le reclute formano una formazione armata nuova PER CIASCUNA STAGIONE in cui maturano, con un
    /// reparto per leva (RDA-166): quella pronta in primavera parte con le altre; quelle pronte in
    /// estate e in autunno raggiungono il quartier generale a campagna aperta (01 §5.2.1, §5.17.1);
    /// quella pronta con l'inverno successivo resta in patria. Ciascuna riceve il prossimo nome
    /// libero della lista e lo conserva; se i nomi sono tutti in uso le reclute si uniscono
    /// all'ultima formazione armata. Riunire le reclute a un altro gruppo o tenerle distinte è una
    /// scelta che il giocatore compie sulla mappa (01 §5.6.0.2, §5.6.0.3).
    public func dopoLaPrimavera(reclute: [(effetto: EffettoMilitare, pronto: Stagione)],
                                miglioramenti: [(bersaglio: BersaglioMilitare, miglioramento: IdentificatoreDati)],
                                mantenuti: Set<BersaglioMilitare>,
                                anno: Int, nomi: [IdentificatoreDati])
        -> (forze: ForzeDelRegno, ingressi: [IngressoNelleForze], migliorati: [ElementoDelleForze],
            perduti: [ElementoDelleForze]) {
        var formazioni = self.formazioni
        var prossimo = prossimoNome
        var perduti: [ElementoDelleForze] = []

        for f in formazioni.indices where formazioni[f].arrivo == nil {
            for r in formazioni[f].composizione.indices {
                let reparto = formazioni[f].composizione[r]
                guard reparto.miglioramento != nil,
                      !mantenuti.contains(BersaglioMilitare(unita: formazioni[f].nome, elemento: r)) else { continue }
                perduti.append(ElementoDelleForze(unita: formazioni[f].nome, reparto: reparto))
                formazioni[f].composizione[r] = reparto.con(miglioramento: nil)
            }
        }

        var migliorati: [ElementoDelleForze] = []
        for ordine in miglioramenti {
            guard let f = formazioni.firstIndex(where: { $0.nome == ordine.bersaglio.unita }),
                  formazioni[f].composizione.indices.contains(ordine.bersaglio.elemento) else { continue }
            let r = ordine.bersaglio.elemento
            formazioni[f].composizione[r] = formazioni[f].composizione[r].con(miglioramento: ordine.miglioramento)
            migliorati.append(ElementoDelleForze(unita: formazioni[f].nome, reparto: formazioni[f].composizione[r]))
        }

        var ingressi: [IngressoNelleForze] = []
        for stagione in Stagione.allCases {
            let reparti = reclute.filter { $0.pronto == stagione }.compactMap { leva -> Reparto? in
                guard case .reclutaReparto(let archetipo, let atomi) = leva.effetto else { return nil }
                return Reparto(archetipo: archetipo, atomi: atomi, leva: anno)
            }
            guard !reparti.isEmpty else { continue }
            let inUso = Set(formazioni.map(\.nome))
            if let libero = Self.nomeLibero(fra: nomi, da: prossimo, inUso: inUso) {
                prossimo = libero.dopo
                formazioni.append(FormazioneDelRegno(nome: libero.nome, categoria: .armato,
                                                     composizione: reparti, arrivo: stagione))
                ingressi.append(IngressoNelleForze(unita: libero.nome, categoria: .armato,
                                                   composizione: reparti, arrivo: stagione, confluite: false))
            } else if let ultima = formazioni.lastIndex(where: { $0.categoria.eArmata }) {
                formazioni[ultima].composizione += reparti
                ingressi.append(IngressoNelleForze(unita: formazioni[ultima].nome, categoria: .armato,
                                                   composizione: reparti,
                                                   arrivo: formazioni[ultima].arrivo ?? .primavera, confluite: true))
            }
        }
        return (.sciami(formazioni: formazioni, prossimoNome: prossimo), ingressi, migliorati, perduti)
    }

    // MARK: - La campagna dell'anno

    /// Le forze dopo che la campagna dell'anno si è conclusa (01 §2.6, §4.12): chi non era partito
    /// resta com'era; di chi era partito resta ciò che il fronte restituisce — le formazioni
    /// rientrate, col loro nome, e gli arrivi che la campagna non ha fatto in tempo a ricevere. Le
    /// formazioni che c'erano conservano il posto che avevano; quelle nate sul fronte, per
    /// divisione, seguono. I caduti non tornano.
    public func dopoLaCampagna(rientrano: ForzeDelRegno) -> ForzeDelRegno {
        let rientrate = rientrano.formazioni
        var esito: [FormazioneDelRegno] = []
        for formazione in formazioni {
            if !formazione.parteConLaCampagna {
                esito.append(formazione)
            } else if let tornata = rientrate.first(where: { $0.nome == formazione.nome }) {
                esito.append(tornata)
            }
        }
        let note = Set(formazioni.map(\.nome))
        esito += rientrate.filter { !note.contains($0.nome) }
        return con(esito)
    }

    /// Le forze all'inizio dell'inverno: chi era ancora in arrivo — perché la campagna si è chiusa
    /// prima, o non c'è stata, o perché maturava con l'inverno — raggiunge le altre in patria.
    public func conGliArriviGiunti() -> ForzeDelRegno {
        con(formazioni.map { formazione in
            var nuova = formazione
            nuova.arrivo = nil
            return nuova
        })
    }

    // MARK: - Il mantenimento (01 §4.14.1; decisione del titolare del 2026-11-23)

    /// La quota annua di un reparto: gli atomi per la quota di un atomo, troncata (00 §13.5) e mai
    /// sotto il minimo (00 §13.6).
    public static func quota(di reparto: Reparto, valori: ValoriMantenimento) -> Int {
        max(valori.quotaMinima, Int(valori.quotaPerMisura.applicato(a: Int64(reparto.atomi))))
    }

    /// La quota annua di mantenimento di tutte le forze.
    public func quotaDiMantenimento(valori: ValoriMantenimento) -> Int {
        formazioni.reduce(0) { somma, formazione in
            somma + formazione.composizione.reduce(0) { $0 + Self.quota(di: $1, valori: valori) }
        }
    }

    /// Il MANTENIMENTO all'inizio dell'inverno (01 §4.14.1): ogni reparto ha una quota annua. Se
    /// ciò che è disponibile non basta, si sciolgono per primi i reparti reclutati per ultimi —
    /// l'anno di leva più recente; a parità, quelli che stanno più in fondo fra le formazioni e,
    /// dentro una formazione, nella sua composizione — finché la quota dei reparti che restano non
    /// rientra nel disponibile. Una formazione rimasta senza reparti non esiste più, e il suo nome
    /// torna libero. Restituisce le forze che restano, la quota da prelevare e ciò che è stato sciolto.
    public func mantenute(con disponibile: Int, valori: ValoriMantenimento)
        -> (forze: ForzeDelRegno, quota: Int, sciolti: [ElementoDelleForze]) {
        var formazioni = self.formazioni
        var quota = quotaDiMantenimento(valori: valori)
        var sciolti: [ElementoDelleForze] = []
        while quota > disponibile {
            // L'ultimo reclutato: anno di leva più alto (i reparti senza anno sono i più anziani);
            // a parità, la formazione e poi il reparto che stanno più in fondo.
            var scelto: (formazione: Int, reparto: Int, leva: Int)?
            for f in formazioni.indices {
                for r in formazioni[f].composizione.indices {
                    let leva = formazioni[f].composizione[r].leva ?? 0
                    if scelto == nil || leva >= scelto!.leva { scelto = (f, r, leva) }
                }
            }
            guard let ultimo = scelto else { break }
            let reparto = formazioni[ultimo.formazione].composizione.remove(at: ultimo.reparto)
            sciolti.append(ElementoDelleForze(unita: formazioni[ultimo.formazione].nome, reparto: reparto))
            quota -= Self.quota(di: reparto, valori: valori)
        }
        formazioni.removeAll { $0.composizione.isEmpty }
        return (con(formazioni), quota, sciolti)
    }
}

/// Esemplari degli elementi delle forze, per gli elenchi di riferimento del regno comune: il
/// collaudo pretende una frase per ogni fatto, e il regno comune non può nominare i reparti.
public enum Esemplari {
    public static let bersaglio = BersaglioMilitare(unita: "lupo", elemento: 0)
    public static let sciolto = ElementoDelleForze(unita: "lince",
                                                  reparto: Reparto(archetipo: "fanteria_leggera", atomi: 6, leva: 1))
    public static let migliorato = ElementoDelleForze(
        unita: "lupo", reparto: Reparto(archetipo: "fanteria_pesante", atomi: 8,
                                        miglioramento: "addestramento_mirato"))
    public static func ingresso(_ arrivo: Stagione, confluite: Bool) -> IngressoNelleForze {
        IngressoNelleForze(unita: "lince", categoria: .armato,
                           composizione: [Reparto(archetipo: "fanteria_leggera", atomi: 6, leva: 1)],
                           arrivo: arrivo, confluite: confluite)
    }
}
