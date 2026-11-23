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
                   forze: try ForzeDelRegno.iniziali(valori.forzeIniziali, nomi: valori.nomiDelleUnita))
    }

    // MARK: - Formule (00 §13.3, 05 §7.4)

    /// Il COSTO di una voce per una data misura (01 §5.9.1.5): per ciascuna risorsa che la voce
    /// consuma, la misura di ciò su cui agisce, per la base, per il peso della voce su quella
    /// risorsa; troncato per difetto (00 §13.5) e mai sotto il minimo dichiarato (00 §13.6). Le
    /// risorse che la voce non consuma non compaiono: la voce dichiara soltanto ciò che costa
    /// davvero (02 §8.7).
    public func costo(di voce: VoceDelRegno, misura: Int) -> Riserve {
        var costo = Riserve()
        for risorsa in Risorsa.allCases {
            let peso = voce.peso(su: risorsa)
            let base = valori.baseLeva[risorsa.rawValue] ?? 0
            guard peso > .zero, base > 0 else { continue }
            let pieno = peso.applicato(a: Int64(misura) * Int64(base))
            costo[risorsa] = max(Int(pieno), valori.costoMinimo)
        }
        return costo
    }

    /// Il costo di una voce com'è adesso: con la misura che la voce porta con sé, oppure — per le
    /// voci che agiscono su qualcosa che esiste già (01 §4.13) — con quella del bersaglio. Nullo se
    /// la voce chiede un bersaglio e quello indicato non esiste.
    public func costo(di voce: VoceDelRegno, bersaglio: BersaglioMilitare?, stato: StatoRegno) -> Riserve? {
        if let misura = voce.effetto.misuraPropria { return costo(di: voce, misura: misura) }
        guard let bersaglio, let misura = stato.forze.misura(di: bersaglio) else { return nil }
        return costo(di: voce, misura: misura)
    }

    /// L'ENTRATA di un anno (01 §5.5.1.6; RDA-165): la rendita, che è il canale astratto che
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

    /// QUANDO un lavoro ordinato a una data stazione sarà pronto (01 §5.9.1.3, §5.9.1.4: il gioco
    /// dichiara quando, non quanto dura). L'inverno è esso stesso tempo: le quattro stazioni sono le
    /// sue quattro parti, e la primavera comincia dopo la quarta. Un lavoro ordinato alla stazione
    /// `s` e lungo `d` stazioni è compiuto alla stazione `s + d`, contata dall'inizio dell'inverno:
    /// se cade entro l'inizio della primavera è pronto in primavera; altrimenti nella prima
    /// stagione il cui inizio lo contiene, ogni stagione operativa valendo il numero di stazioni
    /// che i valori dichiarano; oltre l'autunno, con l'inverno successivo. Chi ordina tardi una
    /// cosa lunga la riceve a campagna aperta: nulla sparisce dalle schermate (01 §5.9.1.3).
    public func prontoIn(voce: VoceDelRegno, stazione: Int) -> Stagione {
        let compiuto = stazione + voce.durata
        var inizio = MomentoDellAnno.stazioniInvernali + 1
        for stagione in Stagione.operative {
            if compiuto <= inizio { return stagione }
            inizio += valori.stazioniPerStagione
        }
        return .inverno
    }

    /// Quando un lavoro ordinato adesso sarà pronto. Fuori dall'inverno si dichiara ciò che
    /// varrebbe alla prima stazione.
    public func prontoIn(voce: VoceDelRegno, stato: StatoRegno) -> Stagione {
        prontoIn(voce: voce, stazione: stato.momento.stazione ?? 1)
    }

    /// Gli elementi delle forze su cui una voce si può ancora ordinare in questo inverno (01 §4.13,
    /// §4.14): quelli che le forze ammettono per il suo effetto, meno quelli su cui un lavoro di
    /// questo inverno agisce già — un elemento in addestramento non si addestra due volte, un
    /// miglioramento mantenuto non si mantiene due volte.
    public func bersagli(di voce: VoceDelRegno, stato: StatoRegno) -> [BersaglioMilitare] {
        stato.forze.bersagli(di: voce.effetto).filter { bersaglio in
            !stato.lavori.contains { $0.bersaglio == bersaglio }
        }
    }

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

        case .ordina(let identificatore, let bersaglio):
            guard stato.momento.eInverno else { return .nonValido(.nonEInverno) }
            guard let voce = valori.voce(identificatore) else { return .nonValido(.voceIgnota) }
            if voce.effetto.richiedeBersaglio {
                // La voce agisce su un elemento che esiste: lo si indica, deve esistere, non deve
                // già ricevere un lavoro in questo inverno, e deve poter ricevere questo.
                guard let bersaglio, stato.forze.esiste(bersaglio) else { return .nonValido(.bersaglioMancante) }
                guard !stato.lavori.contains(where: { $0.bersaglio == bersaglio }) else {
                    return .nonValido(.giaOrdinato)
                }
                guard stato.forze.bersagli(di: voce.effetto).contains(bersaglio) else {
                    return .nonValido(.bersaglioNonAmmesso)
                }
            } else {
                guard bersaglio == nil else { return .nonValido(.bersaglioMancante) }
            }
            guard let costo = costo(di: voce, bersaglio: bersaglio, stato: stato) else {
                return .nonValido(.bersaglioMancante)
            }
            let mancanti = stato.riserve.mancanti(per: costo)
            guard mancanti.isEmpty else { return .nonValido(.risorseInsufficienti(mancanti)) }
            return .valido(costo: costo)

        case .destina(let unita, _):
            // Chi parte si sceglie prima di aprire la campagna dell'anno: d'inverno le forze sono
            // in patria, a campagna aperta sono sul fronte, e a campagna condotta la scelta non
            // avrebbe più oggetto fino alla primavera.
            guard !stato.momento.eInverno else { return .nonValido(.eInverno) }
            switch stato.campagna {
            case .aperta: return .nonValido(.campagnaAperta)
            case .conclusa: return .nonValido(.campagnaGiaCondotta)
            case .nonAperta: break
            }
            guard stato.forze.conosce(unita: unita) else { return .nonValido(.unitaIgnota) }
            return .valido(costo: .vuote)

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
            eventi.append(contentsOf: apriLInverno(&nuovo))

        case .ordina(let identificatore, let bersaglio):
            guard let voce = valori.voce(identificatore), case .valido(let costo) = esito,
                  let stazione = stato.momento.stazione else { break }
            let pronto = prontoIn(voce: voce, stazione: stazione)
            nuovo.riserve = stato.riserve - costo
            nuovo.lavori.append(LavoroOrdinato(voce: identificatore, costo: costo, stazione: stazione,
                                               effetto: voce.effetto, pronto: pronto, bersaglio: bersaglio))
            eventi.append(.lavoroOrdinato(voce: identificatore, costo: costo, pronto: pronto,
                                          bersaglio: bersaglio))

        case .destina(let unita, let alFronte):
            nuovo.forze = stato.forze.destinando(unita, alFronte: alFronte)
            eventi.append(.unitaDestinata(unita: unita, alFronte: alFronte))

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

    /// L'INVERNO (01 §5.9). Tre cose, in quest'ordine.
    ///
    /// Il BILANCIO nasce qui (RDA-165): l'entrata dell'anno si aggiunge a ciò che era stato
    /// riportato, e resta la base su cui in primavera si calcolerà il riporto.
    ///
    /// Chi era ancora in arrivo raggiunge le altre forze in patria.
    ///
    /// Il MANTENIMENTO (01 §4.14.1.1; decisione del titolare del 2026-11-23): il gioco preleva da
    /// sé, dal denaro, la quota annua di ciò che il regno tiene in armi, e lo dichiara nella prima
    /// schermata. Se il denaro non basta lo dichiara e scioglie per primo ciò che è stato reclutato
    /// per ultimo, finché la quota non rientra in ciò che c'è.
    private func apriLInverno(_ stato: inout StatoRegno) -> [EventoRegno] {
        let entrata = entrata(dopo: stato.campagna.esito)
        stato.riserve = stato.riserve + entrata
        stato.entrataDellAnno = entrata
        stato.momento = .inverno(stazione: 1)
        annota(.invernoCominciato, in: &stato)

        let mantenute = stato.forze.conGliArriviGiunti()
            .mantenute(con: stato.riserve[.denaro], valori: valori.mantenimento)
        stato.forze = mantenute.forze
        var prelievo = Riserve()
        prelievo[.denaro] = mantenute.quota
        stato.riserve = stato.riserve - prelievo
        stato.mantenimento = prelievo
        stato.sciolti = mantenute.sciolti
        if !prelievo.sonoVuote { annota(.mantenimentoPrelevato(quota: prelievo), in: &stato) }
        for sciolto in mantenute.sciolti { annota(.elementoSciolto(sciolto), in: &stato) }
        return [.invernoCominciato(anno: stato.anno, entrata: entrata, mantenimento: prelievo,
                                   sciolti: mantenute.sciolti)]
    }

    /// LA PRIMAVERA (01 §5.9.1.1: dopo la quarta schermata comincia la primavera, senza alcun
    /// riepilogo conclusivo). Tre cose, in quest'ordine: il riporto toglie ciò che eccede la quota
    /// (01 §5.5.1.4); i lavori dell'inverno producono il proprio effetto sulle forze (01 §4.12–4.14)
    /// — le reclute vi entrano, ciascuna nella stagione in cui è pronta, ciò che si è migliorato lo
    /// è, e il miglioramento che nessuno ha mantenuto si perde —; l'anno avanza e la campagna
    /// dell'anno nuovo è da aprire.
    private func apriLaPrimavera(_ stato: inout StatoRegno) -> [EventoRegno] {
        let tetto = tettoDelRiporto(entrata: stato.entrataDellAnno)
        var perduto = Riserve()
        for risorsa in Risorsa.allCases where stato.riserve[risorsa] > tetto[risorsa] {
            perduto[risorsa] = stato.riserve[risorsa] - tetto[risorsa]
            stato.riserve[risorsa] = tetto[risorsa]
        }

        var reclute: [(effetto: EffettoMilitare, pronto: Stagione)] = []
        var migliorie: [(bersaglio: BersaglioMilitare, miglioramento: IdentificatoreDati)] = []
        var mantenuti = Set<BersaglioMilitare>()
        for lavoro in stato.lavori {
            switch lavoro.effetto.specie {
            case .recluta:
                reclute.append((lavoro.effetto, lavoro.pronto))
            case .migliora(let miglioramento):
                guard let bersaglio = lavoro.bersaglio else { continue }
                migliorie.append((bersaglio, miglioramento))
            case .mantiene:
                if let bersaglio = lavoro.bersaglio { mantenuti.insert(bersaglio) }
            }
        }
        let primavera = stato.forze.dopoLaPrimavera(reclute: reclute, miglioramenti: migliorie,
                                                    mantenuti: mantenuti, anno: stato.anno,
                                                    nomi: valori.nomiDelleUnita)
        stato.forze = primavera.forze
        stato.lavori = []
        stato.entrataDellAnno = .vuote
        stato.mantenimento = .vuote
        stato.sciolti = []
        stato.anno += 1
        stato.momento = .operativo
        stato.campagna = .nonAperta
        // Nel registro entrano i fatti che il giocatore non ha deciso (01 §5.17.1): il cambio di
        // stagione, col riporto; l'ingresso delle reclute; il completamento dei lavori; la perdita
        // di ciò che non è stato mantenuto.
        annota(.primaveraCominciata(eccedenzaPerduta: !perduto.sonoVuote), in: &stato)
        for ingresso in primavera.ingressi { annota(.recluteEntrate(ingresso), in: &stato) }
        for migliorato in primavera.migliorati { annota(.miglioramentoDato(migliorato), in: &stato) }
        for perdita in primavera.perduti { annota(.miglioramentoPerduto(perdita), in: &stato) }
        return [.primaveraCominciata(anno: stato.anno, perduto: perduto, ingressi: primavera.ingressi,
                                     migliorati: primavera.migliorati, miglioramentiPerduti: primavera.perduti)]
    }

    // MARK: - L'esito della campagna (RDA-162)

    /// Vero se l'esito è quello della campagna che il regno ha aperta: stesso fronte, stesso anno.
    public func accetta(_ esito: EsitoCampagna, stato: StatoRegno) -> Bool {
        stato.campagna.fronteAperto == esito.fronte && esito.anno == stato.anno
    }

    /// Piega sul regno l'esito della campagna conclusa (01 §2.6). È puro — funzione dei soli esito
    /// e stato — sicché rigiocare il giornale del regno, dove l'esito è iscritto come riga a sé,
    /// riproduce il regno senza rileggere i file della campagna. Di ciò che era partito resta ciò
    /// che rientra: i caduti non tornano (01 §4.12: il reintegro avviene soltanto in patria). Ciò
    /// che il giocatore aveva tenuto in patria resta com'era.
    public func applicaEsito(_ esito: EsitoCampagna, in stato: inout StatoRegno) -> [EventoRegno] {
        precondition(accetta(esito, stato: stato), "esito.di.una.campagna.non.aperta")
        stato.campagna = .conclusa(esito)
        stato.forze = stato.forze.dopoLaCampagna(rientrano: esito.superstiti)
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
