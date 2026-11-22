import Foundation
import Dati

/// Le regole del regno: validazione e applicazione dei comandi (05 §3.1, §3.5; incarico 30).
/// Deterministico: stesso comando su stesso stato, stesso esito e stessi eventi (00 §3.1). Nessun
/// numero di gioco vive qui (00 §13.1): le formule sono nel codice, i coefficienti in `regno.json`.
///
/// Come `StatoRegno.swift`, questo file non nomina nulla che appartenga a una modalità di battaglia:
/// le forze sono un valore opaco e ciò che una voce dà è un gancio (`ForzeDelRegno.swift`).
public struct MotoreRegno: Sendable {
    public let valori: ValoriRegno

    public init(valori: ValoriRegno) {
        self.valori = valori
    }

    // MARK: - Nascita (05 §2.10)

    /// Lo stato con cui il regno comincia: funzione pura dei valori, senza alcuna estrazione del
    /// caso. La partita comincia nella primavera del primo anno, con la dotazione iniziale.
    public func statoIniziale() throws -> StatoRegno {
        StatoRegno(anno: 1, momento: .operativo, fase: valori.faseIniziale,
                   riserve: Riserve(valori.dotazioneIniziale),
                   forze: try ForzeDelRegno.iniziali(valori.forzeIniziali))
    }

    // MARK: - Formule (00 §13.3, 05 §7.4)

    /// Il COSTO di una voce (01 §5.9.1.5): per ciascuna risorsa che la voce consuma, la misura di
    /// ciò che dà, per la base, per il peso della voce su quella risorsa; troncato per difetto
    /// (00 §13.5) e mai sotto il minimo dichiarato (00 §13.6). Le risorse che la voce non consuma
    /// non compaiono: la voce dichiara soltanto ciò che costa davvero (02 §8.7).
    public func costo(di voce: VoceDelRegno) -> Riserve {
        var costo = Riserve()
        for risorsa in Risorsa.allCases {
            let peso = voce.peso(su: risorsa)
            let base = valori.baseLeva[risorsa.rawValue] ?? 0
            guard peso > .zero, base > 0 else { continue }
            let pieno = peso.applicato(a: Int64(voce.effetto.misura) * Int64(base))
            costo[risorsa] = max(Int(pieno), valori.costoMinimo)
        }
        return costo
    }

    /// L'ENTRATA di un anno (01 §1.3.1, §2.6; RDA-165): la rendita, che è il canale astratto che
    /// non si gestisce, più un premio per ogni battaglia vinta e un premio per la campagna vinta,
    /// entrambi coefficienti della rendita. Senza una campagna condotta, la sola rendita. Una
    /// sconfitta non toglie nulla: ha già tolto gli uomini.
    public func entrata(dopo esito: EsitoCampagna?) -> Riserve {
        var entrata = Riserve()
        for risorsa in Risorsa.allCases {
            let rendita = Int64(valori.renditaAnnua[risorsa.rawValue] ?? 0)
            var totale = rendita
            if let esito {
                totale += valori.premioBattagliaVinta.applicato(a: rendita * Int64(esito.battaglieVinte))
                if esito.vinta { totale += valori.premioCampagnaVinta.applicato(a: rendita) }
            }
            entrata[risorsa] = Int(totale)
        }
        return entrata
    }

    /// I PREMI che l'esito di una campagna aggiunge alla rendita dell'anno: l'entrata con l'esito
    /// meno l'entrata senza. È ciò che la dichiarazione di conclusione dichiara (05 §9.3).
    public func premi(per esito: EsitoCampagna) -> Riserve {
        entrata(dopo: esito) - entrata(dopo: nil)
    }

    /// Il TETTO DEL RIPORTO (01 §5.5.1.4, 03 §4.4.1; RDA-165): di ciascuna risorsa può avanzare al
    /// massimo la quota, calcolata sull'entrata dell'anno e non su ciò che era già stato riportato
    /// — come il riporto di volume, che si calcola sul budget di base e non genera a sua volta
    /// riporto (RDA-14).
    public func tettoDelRiporto(entrata: Riserve) -> Riserve {
        var tetto = Riserve()
        for risorsa in Risorsa.allCases {
            tetto[risorsa] = Int(valori.quotaRiporto.applicato(a: Int64(entrata[risorsa])))
        }
        return tetto
    }

    /// Quando un lavoro ordinato adesso sarà pronto (01 §5.9.1.4: il gioco dichiara quando, non
    /// quanto dura). Nella prima tappa esiste una sola durata: ciò che si ordina d'inverno è pronto
    /// in primavera, a qualunque stazione lo si ordini.
    public func prontoIn(voce: VoceDelRegno, stato: StatoRegno) -> Stagione { .primavera }

    // MARK: - Validazione (05 §3.1, §3.2)

    /// Nessuna mutazione: dice se il comando è ammissibile, con il costo che verrebbe pagato, oppure
    /// perché non lo è. Un solo percorso produce il controllo e l'annuncio (05 §3.2).
    public func valida(_ comando: ComandoRegno, stato: StatoRegno) -> EsitoValidazioneRegno {
        switch comando {
        case .apriCampagna(let fronte):
            guard !stato.momento.eInverno else { return .nonValido(.eInverno) }
            switch stato.campagna {
            case .aperta: return .nonValido(.campagnaAperta)
            case .conclusa: return .nonValido(.campagnaGiaCondotta)
            case .nonAperta: break
            }
            guard valori.fronte(fronte) != nil else { return .nonValido(.fronteIgnoto) }
            guard stato.forze.possonoCondurreCampagna else { return .nonValido(.nessunaForza) }
            return .valido(costo: .vuote)

        case .attendiInverno:
            guard !stato.momento.eInverno else { return .nonValido(.eInverno) }
            // L'inverno non arriva finché la campagna dura: il fronte ha il proprio calendario, e
            // ci arriva da sé (01 §5.6.9.1).
            guard stato.campagna.fronteAperto == nil else { return .nonValido(.campagnaAperta) }
            return .valido(costo: .vuote)

        case .ordina(let identificatore):
            guard stato.momento.eInverno else { return .nonValido(.nonEInverno) }
            guard let voce = valori.voce(identificatore) else { return .nonValido(.voceIgnota) }
            let costo = costo(di: voce)
            let mancanti = stato.riserve.mancanti(per: costo)
            guard mancanti.isEmpty else { return .nonValido(.risorseInsufficienti(mancanti)) }
            return .valido(costo: costo)

        case .prosegui:
            guard stato.momento.eInverno else { return .nonValido(.nonEInverno) }
            return .valido(costo: .vuote)
        }
    }

    // MARK: - Applicazione (05 §3.1)

    /// Applica un comando VALIDO: la validazione è rieseguita, e un comando non valido è un errore
    /// di programmazione, non un caso d'uso (05 §3.1).
    public func applica(_ comando: ComandoRegno, stato: StatoRegno) -> (StatoRegno, [EventoRegno]) {
        let esito = valida(comando, stato: stato)
        precondition(esito.eValido, "comando.del.regno.non.valido")
        var nuovo = stato
        var eventi: [EventoRegno] = []
        switch comando {
        case .apriCampagna(let fronte):
            nuovo.campagna = .aperta(fronte: fronte)
            eventi.append(.campagnaAperta(fronte: fronte))

        case .attendiInverno:
            // Il BILANCIO nasce qui (01 §5.9, RDA-165): l'entrata dell'anno si aggiunge a ciò che
            // era stato riportato, e resta la base su cui in primavera si calcolerà il riporto.
            let entrata = entrata(dopo: stato.campagna.esito)
            nuovo.riserve = stato.riserve + entrata
            nuovo.entrataDellAnno = entrata
            nuovo.momento = .inverno(stazione: 1)
            annota(.invernoCominciato, in: &nuovo)
            eventi.append(.invernoCominciato(anno: nuovo.anno, entrata: entrata))

        case .ordina(let identificatore):
            guard let voce = valori.voce(identificatore), case .valido(let costo) = esito,
                  let stazione = stato.momento.stazione else { break }
            let pronto = prontoIn(voce: voce, stato: stato)
            nuovo.riserve = stato.riserve - costo
            nuovo.lavori.append(LavoroOrdinato(voce: identificatore, costo: costo, stazione: stazione,
                                               effetto: voce.effetto, pronto: pronto))
            eventi.append(.lavoroOrdinato(voce: identificatore, costo: costo, pronto: pronto))

        case .prosegui:
            guard let stazione = stato.momento.stazione else { break }
            if stazione < MomentoDellAnno.stazioniInvernali {
                nuovo.momento = .inverno(stazione: stazione + 1)
                eventi.append(.stazioneAperta(stazione: stazione + 1))
            } else {
                eventi.append(contentsOf: apriLaPrimavera(&nuovo))
            }
        }
        return (nuovo, eventi)
    }

    /// LA PRIMAVERA (01 §5.9.1.1: dopo la quarta schermata comincia la primavera, senza alcun
    /// riepilogo conclusivo). Tre cose, in quest'ordine: il riporto toglie ciò che eccede la quota
    /// (01 §5.5.1.4); i lavori pronti producono il proprio effetto (01 §4.12); l'anno avanza e la
    /// campagna dell'anno nuovo è da aprire.
    private func apriLaPrimavera(_ stato: inout StatoRegno) -> [EventoRegno] {
        let tetto = tettoDelRiporto(entrata: stato.entrataDellAnno)
        var perduto = Riserve()
        for risorsa in Risorsa.allCases where stato.riserve[risorsa] > tetto[risorsa] {
            perduto[risorsa] = stato.riserve[risorsa] - tetto[risorsa]
            stato.riserve[risorsa] = tetto[risorsa]
        }
        let pronti = stato.lavori.filter { $0.pronto == .primavera }
        stato.forze = stato.forze.ricevendo(pronti.map(\.effetto))
        stato.lavori.removeAll { $0.pronto == .primavera }
        stato.entrataDellAnno = .vuote
        stato.anno += 1
        stato.momento = .operativo
        stato.campagna = .nonAperta
        // Nel registro entrano i fatti che il giocatore non ha deciso (01 §5.17.1): il cambio di
        // stagione, col riporto, e il completamento dei lavori.
        annota(.primaveraCominciata(eccedenzaPerduta: !perduto.sonoVuote), in: &stato)
        for lavoro in pronti { annota(.lavoroPronto(voce: lavoro.voce), in: &stato) }
        return [.primaveraCominciata(anno: stato.anno, perduto: perduto, lavoriPronti: pronti.map(\.voce))]
    }

    // MARK: - L'esito della campagna (RDA-162)

    /// Vero se l'esito è quello della campagna che il regno ha aperta: stesso fronte, stesso anno.
    public func accetta(_ esito: EsitoCampagna, stato: StatoRegno) -> Bool {
        stato.campagna.fronteAperto == esito.fronte && esito.anno == stato.anno
    }

    /// Piega sul regno l'esito della campagna conclusa (01 §2.6). È puro — funzione dei soli esito
    /// e stato — sicché rigiocare il giornale del regno, dove l'esito è iscritto come riga a sé,
    /// riproduce il regno senza rileggere i file della campagna. Le forze diventano quelle che
    /// rientrano: i caduti non tornano (01 §4.12: il reintegro avviene soltanto in patria).
    public func applicaEsito(_ esito: EsitoCampagna, in stato: inout StatoRegno) -> [EventoRegno] {
        precondition(accetta(esito, stato: stato), "esito.di.una.campagna.non.aperta")
        stato.campagna = .conclusa(esito)
        stato.forze = esito.superstiti
        annota(.campagnaConclusa(fronte: esito.fronte, modo: esito.modo, vincitore: esito.vincitore),
               in: &stato)
        return [.campagnaConclusa(esito: esito)]
    }

    /// Annota un fatto nel registro della patria, con l'anno e la stagione in cui cade (01 §5.17).
    func annota(_ fatto: FattoDiPatria, in stato: inout StatoRegno) {
        stato.registro.append(VoceRegistroPatria(
            numero: stato.prossimoNumeroVoce, anno: stato.anno,
            stagione: stato.stagione(giornatePerStagione: valori.giornatePerStagione), fatto: fatto))
        stato.prossimoNumeroVoce += 1
    }
}
