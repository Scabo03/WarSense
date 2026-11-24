import XCTest
import Motore
import Dati
import Contenuti

/// La SECONDA TAPPA DEL REGNO (incarico 31), sul Motore puro: i nomi che il regno conserva (regola A),
/// le reclute che dichiarano dove e quando entrano (B), la scelta di chi parte (C), il mantenimento
/// (D), le durate dei lavori (E), l'addestramento mirato e il suo mantenimento (F). Ciò che di
/// queste regole accade sul fronte sta in `ArriviDallaPatriaTest`, ciò che accade in battaglia in
/// `MiglioramentoInBattagliaTest`.
///
/// Le formule si provano su valori scritti qui, perché una prova sui valori di fabbrica cambierebbe
/// a ogni taratura; fa eccezione la tabella delle stagioni in cui le voci di fabbrica sono pronte,
/// che è una decisione e come tale si fissa.
final class RegnoSecondaTappaTest: XCTestCase {

    static let nomi: [IdentificatoreDati] = ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila", "volpe"]

    /// Valori di prova. Quattro formazioni iniziali — Corvo e Lupo armate, Falco di ricognizione,
    /// Orso non armata —; le tre leve con le durate di fabbrica e una leva lunga dieci stazioni, che
    /// ordinata tardi matura con l'inverno successivo; l'addestramento mirato e il suo mantenimento;
    /// il mantenimento di quattro decimi di denaro per atomo, mai sotto uno.
    static func valori(nomi: [IdentificatoreDati] = RegnoSecondaTappaTest.nomi, stazioniPerStagione: Int = 4,
                       renditaDiDenaro: Int = 400) -> ValoriRegno {
        ValoriRegno(
            giornatePerStagione: 2,
            quotaRiporto: Scalato(millesimi: 100),
            dotazioneIniziale: ["denaro": 10, "uomini": 1, "metalli": 2, "materiale": 3, "animali": 0],
            renditaAnnua: ["denaro": renditaDiDenaro, "uomini": 40, "metalli": 60, "materiale": 30, "animali": 20],
            premioBattagliaVinta: Scalato(millesimi: 100),
            premioCampagnaVinta: Scalato(millesimi: 500),
            baseLeva: ["denaro": 5, "uomini": 1, "metalli": 1, "materiale": 0, "animali": 1],
            costoMinimo: 1,
            voci: [
                VoceDelRegno(identificatore: "leva_fanteria_leggera",
                             pesi: ["denaro": Scalato(intero: 1), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(millesimi: 500)],
                             durata: 2, effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)),
                VoceDelRegno(identificatore: "leva_fanteria_pesante",
                             pesi: ["denaro": Scalato(millesimi: 1600), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 2)],
                             durata: 4, effetto: .reclutaReparto(archetipo: "fanteria_pesante", atomi: 8)),
                VoceDelRegno(identificatore: "leva_cavalleria_manovrata",
                             pesi: ["denaro": Scalato(millesimi: 2400), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 1), "animali": Scalato(intero: 1)],
                             durata: 6, effetto: .reclutaReparto(archetipo: "cavalleria_manovrata", atomi: 6)),
                VoceDelRegno(identificatore: "leva_della_guardia",
                             pesi: ["denaro": Scalato(intero: 3)],
                             durata: 10, effetto: .reclutaReparto(archetipo: "guardia_elite", atomi: 4)),
                VoceDelRegno(identificatore: "addestramento_mirato",
                             pesi: ["denaro": Scalato(millesimi: 800)],
                             durata: 1, effetto: .miglioraReparto(miglioramento: "addestramento_mirato")),
                VoceDelRegno(identificatore: "mantenimento_addestramento",
                             pesi: ["denaro": Scalato(millesimi: 200)],
                             durata: 1, effetto: .mantieniMiglioramento(miglioramento: "addestramento_mirato")),
            ],
            fronti: [FronteDelRegno(identificatore: "guado", scenario: "campagna_piccola")],
            faseIniziale: .arcaica,
            forzeIniziali: [
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_leggera", atomi: 18),
                                                                        .init(archetipo: "fanteria_pesante", atomi: 8)]),
                FormazioneIniziale(categoria: "ricognizione",
                                   composizione: [.init(archetipo: "fanteria_leggera", atomi: 3)], competenza: 5),
                FormazioneIniziale(categoria: "non_armata", composizione: [.init(archetipo: "fanteria_leggera", atomi: 4)],
                                   carico: 4, sogliaProtezione: 2),
            ],
            stazioniPerStagione: stazioniPerStagione,
            linguette: [LinguettaDelRegno(identificatore: "lunghi", durataMinima: 5),
                        LinguettaDelRegno(identificatore: "medi", durataMinima: 3),
                        LinguettaDelRegno(identificatore: "brevi", durataMinima: 1)],
            mantenimento: ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 400), quotaMinima: 1),
            nomiDelleUnita: nomi)
    }

    private var motore: MotoreRegno!

    override func setUp() {
        motore = MotoreRegno(valori: Self.valori())
    }

    // MARK: - Attrezzi

    /// Applica un comando che deve essere valido.
    @discardableResult
    private func esegui(_ comando: ComandoRegno, _ stato: inout StatoRegno, con motore: MotoreRegno? = nil,
                        file: StaticString = #filePath, line: UInt = #line) -> [EventoRegno] {
        let motore = motore ?? self.motore!
        let esito = motore.valida(comando, stato: stato)
        XCTAssertTrue(esito.eValido, "\(comando) dovrebbe essere valido: \(String(describing: esito.motivo))",
                      file: file, line: line)
        guard esito.eValido else { return [] }
        let (nuovo, eventi) = motore.applica(comando, stato: stato)
        stato = nuovo
        return eventi
    }

    private func ordina(_ voce: String, su bersaglio: BersaglioMilitare? = nil, _ stato: inout StatoRegno,
                        con motore: MotoreRegno? = nil, file: StaticString = #filePath, line: UInt = #line) {
        esegui(.ordina(voce: IdentificatoreDati(voce), bersaglio: bersaglio), &stato, con: motore, file: file, line: line)
    }

    /// Prosegue dalla stazione corrente fino alla primavera e restituisce gli eventi della primavera.
    @discardableResult
    private func finoAllaPrimavera(_ stato: inout StatoRegno, con motore: MotoreRegno? = nil,
                                   file: StaticString = #filePath, line: UInt = #line) -> [EventoRegno] {
        var ultimi: [EventoRegno] = []
        while stato.momento.eInverno { ultimi = esegui(.prosegui, &stato, con: motore, file: file, line: line) }
        return ultimi
    }

    private func finoAllaStazione(_ stazione: Int, _ stato: inout StatoRegno, con motore: MotoreRegno? = nil) {
        while let corrente = stato.momento.stazione, corrente < stazione { esegui(.prosegui, &stato, con: motore) }
    }

    /// L'esito di una campagna com'è composto dal ponte: le formazioni che rientrano, col loro nome.
    private func esito(_ stato: StatoRegno, rientrano: [FormazioneDelRegno], vincitore: Parte? = .giocatore,
                       modo: ConclusioneCampagna.Modo = .annientamento, giornate: Int = 2) -> EsitoCampagna {
        EsitoCampagna(fronte: "guado", anno: stato.anno, modo: modo, vincitore: vincitore, giornate: giornate,
                      battaglieVinte: vincitore == .giocatore ? 1 : 0, battagliePerse: vincitore == .avversario ? 1 : 0,
                      superstiti: .sciami(formazioni: rientrano, prossimoNome: 0))
    }

    /// Una formazione come torna dal fronte: il nome, la categoria e i reparti; non è in patria né in arrivo.
    private func tornata(_ formazione: FormazioneDelRegno, composizione: [Reparto]? = nil,
                         ancoraInArrivo: Stagione? = nil) -> FormazioneDelRegno {
        FormazioneDelRegno(nome: formazione.nome, categoria: formazione.categoria,
                           composizione: composizione ?? formazione.composizione, arrivo: ancoraInArrivo)
    }

    private func nomi(_ stato: StatoRegno) -> [IdentificatoreDati] { stato.forze.formazioni.map(\.nome) }

    private func formazione(_ nome: String, _ stato: StatoRegno, file: StaticString = #filePath,
                            line: UInt = #line) throws -> FormazioneDelRegno {
        try XCTUnwrap(stato.forze.formazioni.first { $0.nome == nome }, "manca la formazione \(nome)",
                      file: file, line: line)
    }

    private func leggera(_ atomi: Int, leva: Int? = nil, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_leggera", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil,
                leva: leva)
    }
    private func pesante(_ atomi: Int, leva: Int? = nil, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_pesante", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil,
                leva: leva)
    }
    private func cavalleria(_ atomi: Int, leva: Int? = nil) -> Reparto {
        Reparto(archetipo: "cavalleria_manovrata", atomi: atomi, leva: leva)
    }
    private func guardia(_ atomi: Int, leva: Int? = nil) -> Reparto {
        Reparto(archetipo: "guardia_elite", atomi: atomi, leva: leva)
    }

    // MARK: - A. I nomi

    func test_incarico_31_A_le_forze_iniziali_ricevono_i_primi_nomi_della_lista_nell_ordine_dichiarato() throws {
        let stato = try motore.statoIniziale()
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso"])
        XCTAssertEqual(stato.forze.formazioni.map(\.categoria),
                       [.armato, .armato, .ricognizione(competenza: 5), .nonArmata(carico: 4, sogliaProtezione: 2)])
        XCTAssertEqual(stato.forze.formazioni.map(\.composizione),
                       [[leggera(6)], [leggera(18), pesante(8)], [leggera(3)], [leggera(4)]],
                       "i reparti con cui il regno comincia non hanno anno di leva né miglioramento")
        XCTAssertTrue(stato.forze.formazioni.allSatisfy { !$0.inPatria && $0.arrivo == nil })
        // La posizione nella lista è subito dopo l'ultimo nome dato.
        XCTAssertEqual(stato.forze, .sciami(formazioni: stato.forze.formazioni, prossimoNome: 4))
        // Un altro ordine dei nomi dà altri nomi, nello stesso ordine delle formazioni.
        let altri = try MotoreRegno(valori: Self.valori(nomi: ["volpe", "aquila", "lince", "cervo"])).statoIniziale()
        XCTAssertEqual(nomi(altri), ["volpe", "aquila", "lince", "cervo"])
        XCTAssertEqual(altri.forze, .sciami(formazioni: altri.forze.formazioni, prossimoNome: 0),
                       "data l'intera lista, la posizione torna in testa")
        // Una lista più corta delle formazioni non fa nascere il regno.
        XCTAssertThrowsError(try MotoreRegno(valori: Self.valori(nomi: ["corvo", "lupo", "falco"])).statoIniziale()) {
            XCTAssertEqual($0 as? ForzeDelRegno.ErroreForze, .nomiInsufficienti)
        }
        XCTAssertThrowsError(try MotoreRegno(valori: Self.valori(nomi: [])).statoIniziale()) {
            XCTAssertEqual($0 as? ForzeDelRegno.ErroreForze, .nomiInsufficienti)
        }
    }

    func test_incarico_31_A_una_formazione_ha_lo_stesso_nome_prima_al_rientro_e_l_anno_dopo_anche_se_un_altra_e_perduta() throws {
        var stato = try motore.statoIniziale()
        let partite = stato.forze.formazioni

        // Il primo anno: Lupo cade; Corvo torna dimezzato; Falco e Orso tornano com'erano.
        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso"], "aprire la campagna non tocca le forze")
        _ = motore.applicaEsito(esito(stato, rientrano: [tornata(partite[0], composizione: [leggera(3)]),
                                                         tornata(partite[2]), tornata(partite[3])]), in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso"], "chi rientra conserva il nome e il posto")
        XCTAssertEqual(try formazione("corvo", stato).composizione, [leggera(3)])
        XCTAssertEqual(try formazione("falco", stato), partite[2])
        XCTAssertEqual(try formazione("orso", stato), partite[3])
        XCTAssertFalse(stato.forze.conosce(unita: "lupo"), "i caduti non tornano")

        // L'inverno, una leva, la primavera: i nomi di chi c'era sono quelli di prima, e la
        // formazione nuova non prende il nome che Lupo ha lasciato.
        esegui(.attendiInverno, &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso"])
        ordina("leva_fanteria_leggera", &stato)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo"])
        XCTAssertEqual(try formazione("corvo", stato).composizione, [leggera(3)])

        // Il secondo anno: partono, tornano, e l'anno dopo sono ancora loro.
        esegui(.apriCampagna(fronte: "guado"), &stato)
        let seconde = stato.forze.formazioni
        _ = motore.applicaEsito(esito(stato, rientrano: seconde.map { tornata($0) }), in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo"])
        esegui(.attendiInverno, &stato)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.anno, 3)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo"])
        XCTAssertEqual(try formazione("cervo", stato).composizione, [leggera(6, leva: 1)],
                       "la formazione delle reclute conserva l'anno in cui è stata levata")
        XCTAssertNil(try formazione("cervo", stato).arrivo, "arrivata sul fronte, non è più in arrivo")
    }

    /// Il nome liberato dalla perdita di una formazione non torna finché la lista non è stata
    /// percorsa per intero; a lista esaurita le reclute si uniscono all'ultima formazione armata.
    func test_incarico_31_A_il_primo_nome_libero_si_cerca_in_giro_dalla_posizione_corrente() throws {
        let sei = MotoreRegno(valori: Self.valori(nomi: ["corvo", "lupo", "falco", "orso", "cervo", "lince"]))
        var stato = try sei.statoIniziale()
        let partite = stato.forze.formazioni
        esegui(.apriCampagna(fronte: "guado"), &stato, con: sei)
        _ = sei.applicaEsito(esito(stato, rientrano: [tornata(partite[0]), tornata(partite[2]), tornata(partite[3])]),
                             in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso"])

        /// Un inverno con una sola leva leggera, ordinata alla prima stazione: pronta in primavera.
        func unInvernoConUnaLeva() -> IngressoNelleForze? {
            esegui(.attendiInverno, &stato, con: sei)
            ordina("leva_fanteria_leggera", &stato, con: sei)
            guard case .primaveraCominciata(_, _, let ingressi, _, _)? = finoAllaPrimavera(&stato, con: sei).first else {
                return nil
            }
            XCTAssertEqual(ingressi.count, 1)
            return ingressi.first
        }
        // Dalla posizione corrente — la quinta —: Cervo, poi Lince; Lupo, libero, aspetta.
        XCTAssertEqual(unInvernoConUnaLeva()?.unita, "cervo")
        XCTAssertEqual(unInvernoConUnaLeva()?.unita, "lince")
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo", "lince"])
        // Percorsa la lista si ricomincia dalla testa: Corvo è in uso, Lupo no.
        let terzo = unInvernoConUnaLeva()
        XCTAssertEqual(terzo?.unita, "lupo")
        XCTAssertEqual(terzo?.confluite, false)
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo", "lince", "lupo"],
                       "la formazione nuova sta in coda, anche se porta un nome che viene prima nella lista")
        XCTAssertEqual(Set(nomi(stato)).count, 6, "nessun nome due volte")
        // I nomi sono tutti in uso: le reclute si uniscono all'ultima formazione armata, e nessuna
        // formazione nasce senza nome o con un nome ripetuto.
        let quarto = unInvernoConUnaLeva()
        XCTAssertEqual(quarto?.confluite, true)
        XCTAssertEqual(quarto?.unita, "lupo")
        XCTAssertEqual(quarto?.composizione, [leggera(6, leva: 4)])
        XCTAssertEqual(nomi(stato), ["corvo", "falco", "orso", "cervo", "lince", "lupo"])
        XCTAssertEqual(try formazione("lupo", stato).composizione, [leggera(6, leva: 3), leggera(6, leva: 4)])
    }

    func test_incarico_31_A_un_distaccamento_nato_sul_fronte_torna_in_patria_col_proprio_nome_e_lo_conserva() throws {
        var stato = try motore.statoIniziale()
        let partite = stato.forze.formazioni
        esegui(.apriCampagna(fronte: "guado"), &stato)
        // Sul fronte Lupo si è diviso: il reparto pesante è diventato il distaccamento Aquila. Il
        // ponte lo riporta col nome che ha ricevuto lì, dopo i gruppi che c'erano.
        let aquila = FormazioneDelRegno(nome: "aquila", categoria: .armato, composizione: [pesante(8)])
        _ = motore.applicaEsito(esito(stato, rientrano: [
            tornata(partite[0]), tornata(partite[1], composizione: [leggera(18)]),
            tornata(partite[2]), tornata(partite[3]), aquila]), in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "aquila"],
                       "le formazioni che c'erano conservano il posto; quella nata sul fronte segue")
        XCTAssertEqual(try formazione("aquila", stato), aquila)
        XCTAssertEqual(try formazione("lupo", stato).composizione, [leggera(18)])

        // L'inverno e due leve che maturano in primavera e in estate: i nomi nuovi sono i primi
        // liberi dalla posizione corrente, e quello del distaccamento non si dà a nessun altro.
        esegui(.attendiInverno, &stato)
        ordina("leva_fanteria_leggera", &stato)
        ordina("leva_cavalleria_manovrata", &stato)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "aquila", "cervo", "lince"])
        // Un altro inverno: la posizione arriva ad Aquila, che è in uso, e la salta.
        esegui(.attendiInverno, &stato)
        ordina("leva_fanteria_leggera", &stato)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "aquila", "cervo", "lince", "volpe"])
        XCTAssertEqual(Set(nomi(stato)).count, 8)
        XCTAssertEqual(try formazione("aquila", stato), aquila, "due anni dopo è ancora lei")
    }

    // MARK: - B. Le reclute

    /// Un inverno con leve che maturano in tutte e quattro le stagioni.
    private func dopoUnInvernoDiLeve() throws -> (stato: StatoRegno, eventi: [EventoRegno]) {
        var stato = try motore.statoIniziale()
        esegui(.attendiInverno, &stato)
        // Alla prima stazione: leggera e pesante per la primavera, cavalleria per l'estate, la
        // guardia per l'autunno.
        ordina("leva_fanteria_leggera", &stato)
        ordina("leva_fanteria_pesante", &stato)
        ordina("leva_cavalleria_manovrata", &stato)
        ordina("leva_della_guardia", &stato)
        finoAllaStazione(4, &stato)
        // Alla quarta: la leggera matura in estate, la guardia con l'inverno successivo.
        ordina("leva_fanteria_leggera", &stato)
        ordina("leva_della_guardia", &stato)
        XCTAssertEqual(stato.lavori.map(\.pronto), [.primavera, .primavera, .estate, .autunno, .estate, .inverno])
        XCTAssertEqual(stato.lavori.map(\.stazione), [1, 1, 1, 1, 4, 4])
        let eventi = finoAllaPrimavera(&stato)
        return (stato, eventi)
    }

    func test_incarico_31_B_le_reclute_formano_una_formazione_armata_per_ciascuna_stagione_in_cui_maturano() throws {
        let (stato, eventi) = try dopoUnInvernoDiLeve()
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila", "volpe"])
        XCTAssertEqual(Array(stato.forze.formazioni.prefix(4)), try motore.statoIniziale().forze.formazioni,
                       "le formazioni che c'erano restano com'erano, al loro posto")
        let attese = [
            FormazioneDelRegno(nome: "cervo", categoria: .armato,
                               composizione: [leggera(6, leva: 1), pesante(8, leva: 1)], arrivo: .primavera),
            FormazioneDelRegno(nome: "lince", categoria: .armato,
                               composizione: [cavalleria(6, leva: 1), leggera(6, leva: 1)], arrivo: .estate),
            FormazioneDelRegno(nome: "aquila", categoria: .armato, composizione: [guardia(4, leva: 1)], arrivo: .autunno),
            FormazioneDelRegno(nome: "volpe", categoria: .armato, composizione: [guardia(4, leva: 1)], arrivo: .inverno),
        ]
        XCTAssertEqual(Array(stato.forze.formazioni.suffix(4)), attese,
                       "una formazione per stagione, un reparto per leva nell'ordine in cui le leve sono state ordinate")
        XCTAssertEqual(stato.forze, .sciami(formazioni: stato.forze.formazioni, prossimoNome: 0),
                       "dati gli otto nomi, la posizione torna in testa")

        // L'evento e il registro dichiarano gli stessi ingressi, nell'ordine delle stagioni.
        guard case .primaveraCominciata(let anno, _, let ingressi, let migliorati, let perduti)? = eventi.first else {
            return XCTFail("la primavera si dichiara con un evento")
        }
        XCTAssertEqual(anno, 2)
        XCTAssertEqual(ingressi.map(\.unita), ["cervo", "lince", "aquila", "volpe"])
        XCTAssertEqual(ingressi.map(\.arrivo), [.primavera, .estate, .autunno, .inverno])
        XCTAssertEqual(ingressi.map(\.composizione), attese.map(\.composizione))
        XCTAssertTrue(ingressi.allSatisfy { $0.categoria == .armato && !$0.confluite })
        XCTAssertTrue(migliorati.isEmpty)
        XCTAssertTrue(perduti.isEmpty)
        let annotati = stato.registro.compactMap { voce -> IngressoNelleForze? in
            if case .recluteEntrate(let ingresso) = voce.fatto { return ingresso } else { return nil }
        }
        XCTAssertEqual(annotati, ingressi)
        XCTAssertTrue(stato.registro.suffix(4).allSatisfy { $0.anno == 2 && $0.stagione == .primavera })
        XCTAssertTrue(stato.lavori.isEmpty, "i lavori dell'inverno hanno dato ciò che dovevano")

        // Chi è ancora in arrivo non conta fra le unità che ci sono, e non basta a condurre campagna.
        XCTAssertEqual(stato.forze.numeroDiUnita, 4)
        XCTAssertEqual(stato.forze.formazioni.map(\.parteConLaCampagna),
                       [true, true, true, true, true, true, true, false],
                       "quella pronta con l'inverno successivo resta in patria")
    }

    func test_incarico_31_B_gli_arrivi_mai_giunti_tornano_ancora_in_arrivo_e_con_l_inverno_raggiungono_le_altre() throws {
        var (stato, _) = try dopoUnInvernoDiLeve()
        let prima = stato.forze.formazioni
        esegui(.apriCampagna(fronte: "guado"), &stato)
        // La campagna si conclude in primavera, alla seconda giornata: Cervo è entrata con la
        // prima giornata ed è un gruppo come gli altri; Lince e Aquila non sono mai arrivate, e il
        // ponte le riporta ancora in arrivo; Volpe non è mai partita e non sta nell'esito.
        let rientrano = prima.prefix(5).map { tornata($0) }
            + [tornata(prima[5], ancoraInArrivo: .estate), tornata(prima[6], ancoraInArrivo: .autunno)]
        _ = motore.applicaEsito(esito(stato, rientrano: rientrano, giornate: 2), in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila", "volpe"])
        XCTAssertEqual(stato.forze.formazioni.map(\.arrivo), [nil, nil, nil, nil, nil, .estate, .autunno, .inverno],
                       "chi è arrivato c'è; chi non ha fatto in tempo è ancora in arrivo")
        XCTAssertEqual(stato.forze.formazioni.map(\.composizione), prima.map(\.composizione))
        XCTAssertEqual(stato.forze.numeroDiUnita, 5)
        XCTAssertEqual(try formazione("volpe", stato), prima[7], "chi non è partito resta identico")

        // All'inizio dell'inverno tutti raggiungono gli altri in patria, e tutti sono mantenuti.
        let eventi = esegui(.attendiInverno, &stato)
        XCTAssertTrue(stato.forze.formazioni.allSatisfy { $0.arrivo == nil })
        XCTAssertEqual(stato.forze.numeroDiUnita, 8)
        XCTAssertEqual(stato.forze.formazioni.map(\.composizione), prima.map(\.composizione))
        guard case .invernoCominciato(_, _, let mantenimento, let sciolti)? = eventi.first else {
            return XCTFail("l'inverno si dichiara con un evento")
        }
        // 2 + (7 + 3) + 1 + 1 di chi c'era; (2 + 3) + (2 + 2) + 1 + 1 delle reclute.
        XCTAssertEqual(mantenimento[.denaro], 25)
        XCTAssertTrue(sciolti.isEmpty)
    }

    func test_incarico_31_B_senza_campagna_le_reclute_raggiungono_le_altre_con_l_inverno() throws {
        var (stato, _) = try dopoUnInvernoDiLeve()
        XCTAssertEqual(stato.forze.formazioni.filter { $0.arrivo != nil }.count, 4)
        esegui(.attendiInverno, &stato)
        XCTAssertTrue(stato.forze.formazioni.allSatisfy { $0.arrivo == nil })
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila", "volpe"])
        // E d'inverno sono reparti come gli altri: si possono addestrare.
        let voce = try XCTUnwrap(motore.valori.voce("addestramento_mirato"))
        XCTAssertTrue(motore.bersagli(di: voce, stato: stato).contains(BersaglioMilitare(unita: "volpe", elemento: 0)))
    }

    // MARK: - C. La scelta di chi parte

    func test_incarico_31_C_destina_vale_soltanto_fuori_dall_inverno_e_prima_di_aprire_la_campagna() throws {
        var stato = try motore.statoIniziale()
        XCTAssertEqual(stato.forze.destinataAlFronte("orso"), true)
        XCTAssertNil(stato.forze.destinataAlFronte("muflone"))
        XCTAssertEqual(motore.valida(.destina(unita: "muflone", alFronte: false), stato: stato).motivo, .unitaIgnota)

        // Tenere in patria: cambia la sola destinazione della sola unità indicata, e non costa nulla.
        let prima = stato
        XCTAssertEqual(motore.valida(.destina(unita: "orso", alFronte: false), stato: stato), .valido(costo: .vuote))
        XCTAssertEqual(esegui(.destina(unita: "orso", alFronte: false), &stato),
                       [.unitaDestinata(unita: "orso", alFronte: false)])
        XCTAssertEqual(stato.forze.destinataAlFronte("orso"), false)
        XCTAssertEqual(stato.forze.formazioni.map(\.inPatria), [false, false, false, true])
        var attese = prima.forze.formazioni
        attese[3].inPatria = true
        XCTAssertEqual(stato.forze.formazioni, attese)
        XCTAssertEqual(stato.riserve, prima.riserve)
        XCTAssertEqual(stato.registro, prima.registro, "una scelta del giocatore non entra nel registro (01 §5.17.1)")
        XCTAssertEqual(stato.campagna, .nonAperta)
        // Ripetere la scelta non cambia nulla; rovesciarla riporta lo stato di prima.
        var ripetuta = stato
        esegui(.destina(unita: "orso", alFronte: false), &ripetuta)
        XCTAssertEqual(ripetuta, stato)
        esegui(.destina(unita: "orso", alFronte: true), &ripetuta)
        XCTAssertEqual(ripetuta.forze, prima.forze)

        // A campagna aperta, a campagna condotta e d'inverno la scelta è respinta col suo motivo.
        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertEqual(motore.valida(.destina(unita: "orso", alFronte: true), stato: stato).motivo, .campagnaAperta)
        XCTAssertEqual(motore.valida(.destina(unita: "muflone", alFronte: true), stato: stato).motivo, .campagnaAperta)
        _ = motore.applicaEsito(esito(stato, rientrano: stato.forze.formazioni.filter(\.parteConLaCampagna)
                                        .map { tornata($0) }), in: &stato)
        XCTAssertEqual(motore.valida(.destina(unita: "orso", alFronte: true), stato: stato).motivo, .campagnaGiaCondotta)
        esegui(.attendiInverno, &stato)
        XCTAssertEqual(motore.valida(.destina(unita: "orso", alFronte: true), stato: stato).motivo, .eInverno)
        finoAllaPrimavera(&stato)
        XCTAssertTrue(motore.valida(.destina(unita: "orso", alFronte: true), stato: stato).eValido,
                      "con la primavera la scelta torna possibile")
    }

    func test_incarico_31_C_senza_una_formazione_armata_presente_e_destinata_al_fronte_la_campagna_non_si_apre() throws {
        var stato = try motore.statoIniziale()
        esegui(.destina(unita: "corvo", alFronte: false), &stato)
        XCTAssertTrue(stato.forze.possonoCondurreCampagna, "resta Lupo")
        XCTAssertTrue(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).eValido)
        esegui(.destina(unita: "lupo", alFronte: false), &stato)
        XCTAssertFalse(stato.forze.possonoCondurreCampagna)
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).motivo, .nessunaForza,
                       "la ricognizione e la formazione non armata non bastano a condurre campagna")
        XCTAssertTrue(motore.valida(.attendiInverno, stato: stato).eValido)
        esegui(.destina(unita: "lupo", alFronte: true), &stato)
        XCTAssertTrue(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).eValido)

        // Le reclute che arrivano a campagna aperta non bastano ad aprirla: l'armata deve esserci
        // dalla prima giornata. Né bastano quelle che entrano in primavera come arrivo.
        var (conReclute, _) = try dopoUnInvernoDiLeve()
        esegui(.destina(unita: "corvo", alFronte: false), &conReclute)
        esegui(.destina(unita: "lupo", alFronte: false), &conReclute)
        XCTAssertEqual(conReclute.forze.formazioni.filter { $0.categoria.eArmata && !$0.inPatria }.map(\.nome),
                       ["cervo", "lince", "aquila", "volpe"], "armate destinate al fronte ce ne sono, ma tutte in arrivo")
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "guado"), stato: conReclute).motivo, .nessunaForza)
    }

    func test_incarico_31_C_la_formazione_tenuta_in_patria_resta_identica_dopo_la_campagna_e_la_scelta_resta_l_anno_dopo() throws {
        var stato = try motore.statoIniziale()
        esegui(.destina(unita: "lupo", alFronte: false), &stato)
        esegui(.destina(unita: "orso", alFronte: false), &stato)
        let inPatria = try [formazione("lupo", stato), formazione("orso", stato)]
        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertEqual(stato.forze.formazioni.filter(\.parteConLaCampagna).map(\.nome), ["corvo", "falco"])
        // Dal fronte torna il solo Corvo, dimezzato: Falco è perduto. Lupo e Orso non erano partiti.
        _ = motore.applicaEsito(esito(stato, rientrano: [tornata(try formazione("corvo", stato),
                                                                  composizione: [leggera(3)])]), in: &stato)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "orso"])
        XCTAssertEqual(try formazione("lupo", stato), inPatria[0], "chi è rimasto in patria è identico")
        XCTAssertEqual(try formazione("orso", stato), inPatria[1])
        // L'inverno le mantiene come le altre; la primavera non tocca la scelta.
        esegui(.attendiInverno, &stato)
        XCTAssertEqual(stato.mantenimento[.denaro], 1 + 7 + 3 + 1)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(stato.forze.formazioni.map(\.inPatria), [false, true, true], "la scelta resta l'anno dopo")
        XCTAssertEqual(try formazione("lupo", stato), inPatria[0])
        // E la campagna dell'anno dopo parte ancora senza di loro.
        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertEqual(stato.forze.formazioni.filter(\.parteConLaCampagna).map(\.nome), ["corvo"])
    }

    // MARK: - D. Il mantenimento

    func test_incarico_31_D_la_quota_di_un_reparto_e_atomi_per_quota_troncata_mai_sotto_il_minimo() {
        let valori = ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 400), quotaMinima: 1)
        // atomi → quota: 0,4 per atomo, troncato; sotto tre atomi vale il minimo.
        let tabella: [(Int, Int)] = [(1, 1), (2, 1), (3, 1), (4, 1), (5, 2), (6, 2), (7, 2), (8, 3), (12, 4),
                                     (18, 7), (24, 9), (100, 40)]
        for (atomi, attesa) in tabella {
            XCTAssertEqual(ForzeDelRegno.quota(di: leggera(atomi), valori: valori), attesa, "\(atomi) atomi")
        }
        // Il miglioramento e l'anno di leva non cambiano la quota: conta la misura.
        XCTAssertEqual(ForzeDelRegno.quota(di: pesante(8, leva: 3, migliorata: true), valori: valori), 3)
        // Un altro minimo, un'altra quota.
        let caro = ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 1500), quotaMinima: 4)
        XCTAssertEqual(ForzeDelRegno.quota(di: leggera(2), valori: caro), 4, "3 troncato, sotto il minimo di 4")
        XCTAssertEqual(ForzeDelRegno.quota(di: leggera(5), valori: caro), 7, "7,5 troncato")
        let nullo = ValoriMantenimento(quotaPerMisura: .zero, quotaMinima: 1)
        XCTAssertEqual(ForzeDelRegno.quota(di: leggera(50), valori: nullo), 1)
        // La quota delle forze è la somma delle quote dei reparti, non la quota della somma degli atomi.
        let forze = ForzeDelRegno.sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(2), leggera(2), leggera(2)]),
            FormazioneDelRegno(nome: "lupo", categoria: .armato, composizione: [leggera(6)], inPatria: true),
        ], prossimoNome: 2)
        XCTAssertEqual(forze.quotaDiMantenimento(valori: valori), 1 + 1 + 1 + 2)
    }

    func test_incarico_31_D_all_inizio_dell_inverno_dopo_l_entrata_il_gioco_preleva_la_quota_e_lo_dichiara() throws {
        var stato = try motore.statoIniziale()
        // Il regno comincia con dieci monete: senza l'entrata non pagherebbe le quattordici della
        // quota. Il prelievo viene DOPO l'entrata.
        XCTAssertEqual(stato.riserve[.denaro], 10)
        let prima = stato
        let eventi = esegui(.attendiInverno, &stato)
        let entrata = motore.entrata(dopo: nil)
        XCTAssertEqual(eventi.count, 1)
        guard case .invernoCominciato(let anno, let dichiarata, let mantenimento, let sciolti)? = eventi.first else {
            return XCTFail("l'inverno si dichiara con un evento")
        }
        XCTAssertEqual(anno, 1)
        XCTAssertEqual(dichiarata, entrata)
        XCTAssertEqual(mantenimento[.denaro], 2 + 7 + 3 + 1 + 1, "Corvo 2; Lupo 7 e 3; Falco 1; Orso 1")
        XCTAssertEqual(mantenimento.risorseInGioco, [.denaro], "si preleva dal solo denaro")
        XCTAssertTrue(sciolti.isEmpty)
        // Lo stato porta ciò che la prima schermata dichiara.
        XCTAssertEqual(stato.mantenimento[.denaro], 14)
        XCTAssertEqual(stato.mantenimento.risorseInGioco, [.denaro])
        XCTAssertTrue(stato.sciolti.isEmpty)
        XCTAssertEqual(stato.riserve[.denaro], 10 + 400 - 14)
        for risorsa in Risorsa.allCases where risorsa != .denaro {
            XCTAssertEqual(stato.riserve[risorsa], prima.riserve[risorsa] + entrata[risorsa])
        }
        XCTAssertEqual(stato.entrataDellAnno, entrata, "la base del riporto è l'entrata, non l'entrata meno il mantenimento")
        XCTAssertEqual(stato.forze, prima.forze, "nessuno sciolto: le forze sono quelle di prima")
        // Il registro lo annota, dopo l'inizio dell'inverno.
        XCTAssertEqual(stato.registro.count, 2)
        XCTAssertEqual(stato.registro[0].fatto, .invernoCominciato)
        guard case .mantenimentoPrelevato(let quota) = stato.registro[1].fatto else {
            return XCTFail("la seconda voce è il mantenimento prelevato")
        }
        XCTAssertEqual(quota[.denaro], 14)
        XCTAssertEqual(stato.registro.map(\.stagione), [.inverno, .inverno])
        XCTAssertEqual(stato.registro.map(\.anno), [1, 1])
        // Il mantenimento resta dichiarato per tutto l'inverno, e con la primavera si azzera.
        esegui(.prosegui, &stato)
        XCTAssertEqual(stato.mantenimento[.denaro], 14)
        finoAllaPrimavera(&stato)
        XCTAssertTrue(stato.mantenimento.sonoVuote)
    }

    /// Le forze dell'inverno povero: sei reparti in quattro formazioni, con tre anni di leva diversi.
    /// Quote: Corvo 2 e 2; Lupo 3 e 4; Falco 1; Orso 7. In tutto diciannove.
    private func forzeDellInvernoPovero() -> ForzeDelRegno {
        .sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(6), leggera(6, leva: 2)]),
            FormazioneDelRegno(nome: "lupo", categoria: .armato, composizione: [pesante(8, leva: 1), cavalleria(12, leva: 2)]),
            FormazioneDelRegno(nome: "falco", categoria: .ricognizione(competenza: 5), composizione: [leggera(3)]),
            FormazioneDelRegno(nome: "orso", categoria: .armato, composizione: [leggera(18, leva: 2)], inPatria: true),
        ], prossimoNome: 4)
    }

    func test_incarico_31_D_se_il_denaro_non_basta_si_sciolgono_per_primi_i_reparti_reclutati_per_ultimi() throws {
        // Senza rendita di denaro, ciò che è disponibile all'inizio dell'inverno è ciò che c'è in cassa.
        let povero = MotoreRegno(valori: Self.valori(renditaDiDenaro: 0))
        let forze = forzeDellInvernoPovero()
        XCTAssertEqual(forze.quotaDiMantenimento(valori: povero.valori.mantenimento), 19)

        // In ordine di scioglimento: l'anno di leva più alto, e a parità chi sta più in fondo — la
        // formazione, poi il reparto —; i reparti senza anno sono i più anziani.
        let ordine: [(unita: IdentificatoreDati, reparto: Reparto, quota: Int)] = [
            ("orso", leggera(18, leva: 2), 7),
            ("lupo", cavalleria(12, leva: 2), 4),
            ("corvo", leggera(6, leva: 2), 2),
            ("lupo", pesante(8, leva: 1), 3),
            ("falco", leggera(3), 1),
            ("corvo", leggera(6), 2),
        ]
        // disponibile → quanti reparti si sciolgono.
        let casi: [(disponibile: Int, sciolti: Int)] = [
            (50, 0), (19, 0), (18, 1), (12, 1), (11, 2), (8, 2), (7, 3), (6, 3), (5, 4), (3, 4), (2, 5), (1, 6), (0, 6),
        ]
        for caso in casi {
            var riserve = Riserve(povero.valori.dotazioneIniziale)
            riserve[.denaro] = caso.disponibile
            var stato = StatoRegno(anno: 3, momento: .operativo, fase: .arcaica, riserve: riserve, forze: forze)
            let eventi = esegui(.attendiInverno, &stato, con: povero)
            let attesi = ordine.prefix(caso.sciolti).map { ElementoDelleForze(unita: $0.unita, reparto: $0.reparto) }
            let quotaRimasta = 19 - ordine.prefix(caso.sciolti).reduce(0) { $0 + $1.quota }
            let che = "con \(caso.disponibile) monete"
            XCTAssertEqual(stato.sciolti, attesi, che)
            XCTAssertEqual(stato.mantenimento[.denaro], quotaRimasta, che)
            XCTAssertEqual(stato.riserve[.denaro], caso.disponibile - quotaRimasta, che)
            XCTAssertGreaterThanOrEqual(stato.riserve[.denaro], 0, "il denaro non va mai sotto zero, \(che)")
            XCTAssertLessThanOrEqual(quotaRimasta, caso.disponibile, "la quota dei rimasti rientra nel disponibile, \(che)")
            if caso.sciolti > 0 {
                // Si è sciolto il meno possibile: con un reparto in meno fra gli sciolti la quota non rientrava.
                XCTAssertGreaterThan(quotaRimasta + ordine[caso.sciolti - 1].quota, caso.disponibile, che)
            }
            guard case .invernoCominciato(_, _, let mantenimento, let sciolti)? = eventi.first else {
                return XCTFail("l'inverno si dichiara con un evento")
            }
            XCTAssertEqual(sciolti, attesi, che)
            XCTAssertEqual(mantenimento[.denaro], quotaRimasta, che)
            // Gli atomi tornano: quelli di prima meno quelli sciolti.
            let atomiRimasti = stato.forze.formazioni.reduce(0) { $0 + $1.atomiTotali }
            XCTAssertEqual(atomiRimasti, 53 - attesi.reduce(0) { $0 + $1.reparto.atomi }, che)
            // Il registro: l'inverno, il prelievo se c'è, e uno scioglimento per reparto, nell'ordine.
            var fatti: [FattoDiPatria] = [.invernoCominciato]
            if quotaRimasta > 0 { fatti.append(.mantenimentoPrelevato(quota: stato.mantenimento)) }
            fatti += attesi.map { .elementoSciolto($0) }
            XCTAssertEqual(stato.registro.map(\.fatto), fatti, che)
        }
    }

    func test_incarico_31_D_una_formazione_rimasta_vuota_sparisce_e_le_altre_conservano_nome_e_posto() throws {
        let povero = MotoreRegno(valori: Self.valori(renditaDiDenaro: 0))
        func inverno(con denaro: Int) -> StatoRegno {
            var riserve = Riserve(povero.valori.dotazioneIniziale)
            riserve[.denaro] = denaro
            var stato = StatoRegno(anno: 3, momento: .operativo, fase: .arcaica, riserve: riserve,
                                   forze: forzeDellInvernoPovero())
            esegui(.attendiInverno, &stato, con: povero)
            return stato
        }
        // Sciolto l'unico reparto di Orso, la formazione non esiste più; era tenuta in patria, e non conta.
        var stato = inverno(con: 18)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco"])
        XCTAssertEqual(stato.forze.formazioni, Array(forzeDellInvernoPovero().formazioni.prefix(3)))
        // Con cinque monete: sciolti anche i due reparti di Lupo e il più recente di Corvo.
        stato = inverno(con: 5)
        XCTAssertEqual(nomi(stato), ["corvo", "falco"])
        XCTAssertEqual(try formazione("corvo", stato).composizione, [leggera(6)])
        XCTAssertEqual(try formazione("falco", stato).composizione, [leggera(3)])
        // Con una moneta non resta nessuno: il regno è senza forze, e il denaro non scende sotto zero.
        stato = inverno(con: 1)
        XCTAssertTrue(stato.forze.formazioni.isEmpty)
        XCTAssertEqual(stato.riserve[.denaro], 1)
        XCTAssertTrue(stato.mantenimento.sonoVuote)
        XCTAssertEqual(stato.sciolti.count, 6)
        XCTAssertFalse(stato.forze.possonoCondurreCampagna)
        // Il nome di una formazione sciolta torna libero: un inverno dopo, la leva lo può prendere.
        stato = inverno(con: 18)
        stato.riserve = Riserve(["denaro": 100, "uomini": 20, "metalli": 20, "materiale": 0, "animali": 0])
        ordina("leva_fanteria_leggera", &stato, con: povero)
        finoAllaPrimavera(&stato, con: povero)
        XCTAssertEqual(nomi(stato), ["corvo", "lupo", "falco", "cervo"],
                       "la posizione era alla quinta: Cervo; Orso, libero, aspetta il giro")
    }

    func test_incarico_31_D_chi_arriva_con_l_inverno_si_mantiene_e_si_scioglie_come_gli_altri() throws {
        let povero = MotoreRegno(valori: Self.valori(renditaDiDenaro: 0))
        // Corvo c'è dall'inizio; Cervo, levata quest'anno, non è mai arrivata sul fronte.
        let forze = ForzeDelRegno.sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(6)]),
            FormazioneDelRegno(nome: "cervo", categoria: .armato, composizione: [leggera(6, leva: 2)], arrivo: .autunno),
        ], prossimoNome: 5)
        var riserve = Riserve(povero.valori.dotazioneIniziale)
        riserve[.denaro] = 3
        var stato = StatoRegno(anno: 3, momento: .operativo, fase: .arcaica, riserve: riserve, forze: forze)
        esegui(.attendiInverno, &stato, con: povero)
        XCTAssertEqual(stato.sciolti, [ElementoDelleForze(unita: "cervo", reparto: leggera(6, leva: 2))],
                       "le reclute appena giunte sono le ultime reclutate")
        XCTAssertEqual(nomi(stato), ["corvo"])
        XCTAssertEqual(stato.riserve[.denaro], 1)
        riserve[.denaro] = 4
        stato = StatoRegno(anno: 3, momento: .operativo, fase: .arcaica, riserve: riserve, forze: forze)
        esegui(.attendiInverno, &stato, con: povero)
        XCTAssertTrue(stato.sciolti.isEmpty)
        XCTAssertEqual(stato.forze.formazioni.map(\.arrivo), [nil, nil])
        XCTAssertEqual(stato.riserve[.denaro], 0)
    }

    // MARK: - E. Le durate

    /// La regola, ricalcolata qui con la sola aritmetica della decisione: ordinato alla stazione s e
    /// lungo d, il lavoro è compiuto a s + d; entro 5 è pronto in primavera, entro 5 più le stazioni
    /// di una stagione in estate, entro 5 più due volte in autunno, oltre con l'inverno successivo.
    private func attesa(stazione: Int, durata: Int, stazioniPerStagione: Int) -> Stagione {
        let compiuto = stazione + durata
        if compiuto <= 5 { return .primavera }
        if compiuto <= 5 + stazioniPerStagione { return .estate }
        if compiuto <= 5 + 2 * stazioniPerStagione { return .autunno }
        return .inverno
    }

    func test_incarico_31_E_un_lavoro_ordinato_alla_stazione_s_e_lungo_d_e_compiuto_a_s_piu_d() {
        var controllati = 0
        for stazioniPerStagione in [1, 2, 3, 4, 6] {
            let motore = MotoreRegno(valori: Self.valori(stazioniPerStagione: stazioniPerStagione))
            XCTAssertEqual(motore.valori.durataMassima, 1 + 3 * stazioniPerStagione)
            for durata in 1...motore.valori.durataMassima {
                let voce = VoceDelRegno(identificatore: "voce_di_prova", pesi: ["denaro": .uno], durata: durata,
                                        effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6))
                var precedente = Stagione.primavera
                for stazione in 1...Stagione.stazioniInvernali {
                    let pronto = motore.prontoIn(voce: voce, stazione: stazione)
                    XCTAssertEqual(pronto, attesa(stazione: stazione, durata: durata,
                                                  stazioniPerStagione: stazioniPerStagione),
                                   "stazione \(stazione), durata \(durata), \(stazioniPerStagione) stazioni per stagione")
                    // Ordinare più tardi non fa mai maturare prima.
                    XCTAssertGreaterThanOrEqual(Stagione.allCases.firstIndex(of: pronto)!,
                                                Stagione.allCases.firstIndex(of: precedente)!)
                    precedente = pronto
                    controllati += 1
                }
            }
            // Gli estremi: ciò che dura una stazione è pronto in primavera a qualunque schermata lo
            // si ordini; la durata massima, ordinata all'ultima, matura con l'inverno successivo.
            let breve = VoceDelRegno(identificatore: "breve", pesi: ["denaro": .uno], durata: 1,
                                     effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6))
            let lunga = VoceDelRegno(identificatore: "lunga", pesi: ["denaro": .uno], durata: motore.valori.durataMassima,
                                     effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6))
            XCTAssertEqual((1...4).map { motore.prontoIn(voce: breve, stazione: $0) }, Array(repeating: .primavera, count: 4))
            XCTAssertEqual(motore.prontoIn(voce: lunga, stazione: 4), .inverno)
        }
        XCTAssertEqual(controllati, 4 * (4 + 7 + 10 + 13 + 19))
    }

    /// Con i valori di FABBRICA (decisione): la leva leggera è pronta in primavera dalle stazioni 1–3
    /// e in estate dalla 4; la pesante in primavera dalla 1 e in estate dalle 2–4; la cavalleria in
    /// estate dalle 1–3 e in autunno dalla 4. L'addestramento e il suo mantenimento sempre in primavera.
    func test_incarico_31_E_coi_valori_di_fabbrica_ogni_voce_e_pronta_nella_stagione_decisa() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let fabbrica = MotoreRegno(valori: try CaricatoreRegno.carica(
            da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
            miglioramentiNoti: Set(valori.miglioramenti.keys)))
        let tabella: [(voce: IdentificatoreDati, stagioni: [Stagione])] = [
            ("leva_fanteria_leggera", [.primavera, .primavera, .primavera, .estate]),
            ("leva_fanteria_pesante", [.primavera, .estate, .estate, .estate]),
            ("leva_cavalleria_manovrata", [.estate, .estate, .estate, .autunno]),
            ("addestramento_mirato", [.primavera, .primavera, .primavera, .primavera]),
            ("mantenimento_addestramento", [.primavera, .primavera, .primavera, .primavera]),
        ]
        XCTAssertEqual(Set(tabella.map(\.voce)), Set(fabbrica.valori.voci.map(\.identificatore)),
                       "la tabella copre ogni voce di fabbrica")
        for riga in tabella {
            let voce = try XCTUnwrap(fabbrica.valori.voce(riga.voce))
            XCTAssertEqual((1...Stagione.stazioniInvernali).map { fabbrica.prontoIn(voce: voce, stazione: $0) },
                           riga.stagioni, riga.voce)
        }
        // Coi valori di fabbrica nulla matura con l'inverno successivo: la voce più lunga, ordinata
        // all'ultima stazione, arriva in autunno.
        for voce in fabbrica.valori.voci {
            XCTAssertNotEqual(fabbrica.prontoIn(voce: voce, stazione: Stagione.stazioniInvernali), .inverno, voce.identificatore)
        }
    }

    func test_incarico_31_E_il_lavoro_ordinato_porta_la_stazione_e_la_stagione_in_cui_sara_pronto() throws {
        var stato = try motore.statoIniziale()
        let cavalleria = try XCTUnwrap(motore.valori.voce("leva_cavalleria_manovrata"))
        // Fuori dall'inverno si dichiara ciò che varrebbe alla prima stazione.
        XCTAssertEqual(motore.prontoIn(voce: cavalleria, stato: stato), .estate)
        esegui(.attendiInverno, &stato)
        // Abbastanza risorse perché le quattro leve si paghino tutte.
        stato.riserve = Riserve(["denaro": 1000, "uomini": 100, "metalli": 100, "materiale": 0, "animali": 100])
        var dichiarate: [Stagione] = []
        for stazione in 1...Stagione.stazioniInvernali {
            finoAllaStazione(stazione, &stato)
            XCTAssertEqual(motore.prontoIn(voce: cavalleria, stato: stato),
                           motore.prontoIn(voce: cavalleria, stazione: stazione))
            let eventi = esegui(.ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil), &stato)
            guard case .lavoroOrdinato(let voce, let costo, let pronto, let bersaglio)? = eventi.first else {
                return XCTFail("l'ordine si dichiara con un evento")
            }
            XCTAssertEqual(voce, "leva_cavalleria_manovrata")
            XCTAssertEqual(costo, motore.costo(di: cavalleria, misura: 6))
            XCTAssertNil(bersaglio)
            XCTAssertEqual(stato.lavori.last?.stazione, stazione)
            XCTAssertEqual(stato.lavori.last?.pronto, pronto, "lo stato e l'evento dichiarano la stessa stagione")
            dichiarate.append(pronto)
        }
        XCTAssertEqual(dichiarate, [.estate, .estate, .estate, .autunno])
        // E in primavera le reclute stanno nella formazione della stagione dichiarata.
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.forze.formazioni.suffix(2).map(\.arrivo), [.estate, .autunno])
        XCTAssertEqual(stato.forze.formazioni.suffix(2).map(\.composizione.count), [3, 1])
    }

    // MARK: - F. I miglioramenti

    private static let pesanteDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)
    private static let leggeraDiLupo = BersaglioMilitare(unita: "lupo", elemento: 0)
    private static let leggeraDiCorvo = BersaglioMilitare(unita: "corvo", elemento: 0)

    func test_incarico_31_F_l_addestramento_mirato_costa_atomi_per_base_per_peso_ed_e_pronto_in_primavera() throws {
        var stato = try motore.statoIniziale()
        let addestramento = try XCTUnwrap(motore.valori.voce("addestramento_mirato"))
        // Il costo dipende dal reparto: gli atomi, per la base di cinque monete, per il peso di otto decimi.
        XCTAssertEqual(motore.costo(di: addestramento, bersaglio: Self.pesanteDiLupo, stato: stato)?[.denaro], 32)
        XCTAssertEqual(motore.costo(di: addestramento, bersaglio: Self.leggeraDiLupo, stato: stato)?[.denaro], 72)
        XCTAssertEqual(motore.costo(di: addestramento, bersaglio: Self.leggeraDiCorvo, stato: stato)?[.denaro], 24)
        XCTAssertEqual(motore.costo(di: addestramento, bersaglio: Self.pesanteDiLupo, stato: stato)?.risorseInGioco, [.denaro])
        XCTAssertEqual(motore.costo(di: addestramento, bersaglio: Self.pesanteDiLupo, stato: stato),
                       motore.costo(di: addestramento, misura: 8))
        // Senza bersaglio, o con uno che non esiste, il costo non c'è.
        XCTAssertNil(motore.costo(di: addestramento, bersaglio: nil, stato: stato))
        XCTAssertNil(motore.costo(di: addestramento, bersaglio: BersaglioMilitare(unita: "muflone", elemento: 0), stato: stato))
        XCTAssertNil(motore.costo(di: addestramento, bersaglio: BersaglioMilitare(unita: "lupo", elemento: 2), stato: stato))

        esegui(.attendiInverno, &stato)
        let denaro = stato.riserve[.denaro]
        // Pronto in primavera a qualunque stazione lo si ordini.
        XCTAssertEqual((1...4).map { motore.prontoIn(voce: addestramento, stazione: $0) },
                       [.primavera, .primavera, .primavera, .primavera])
        finoAllaStazione(3, &stato)
        let eventi = esegui(.ordina(voce: "addestramento_mirato", bersaglio: Self.pesanteDiLupo), &stato)
        XCTAssertEqual(eventi, [.lavoroOrdinato(voce: "addestramento_mirato", costo: motore.costo(di: addestramento, misura: 8),
                                                pronto: .primavera, bersaglio: Self.pesanteDiLupo)])
        XCTAssertEqual(stato.riserve[.denaro], denaro - 32)
        XCTAssertEqual(stato.lavori.last, LavoroOrdinato(
            voce: "addestramento_mirato", costo: motore.costo(di: addestramento, misura: 8), stazione: 3,
            effetto: .miglioraReparto(miglioramento: "addestramento_mirato"), pronto: .primavera,
            bersaglio: Self.pesanteDiLupo))
        XCTAssertEqual(stato.forze.reparto(Self.pesanteDiLupo), pesante(8), "d'inverno il reparto non è ancora migliorato")

        // In primavera il reparto porta il miglioramento, e nient'altro è cambiato.
        let prima = stato.forze.formazioni
        let primavera = finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.forze.reparto(Self.pesanteDiLupo), pesante(8, migliorata: true))
        var attese = prima
        attese[1].composizione[1] = pesante(8, migliorata: true)
        XCTAssertEqual(stato.forze.formazioni, attese)
        guard case .primaveraCominciata(_, _, let ingressi, let migliorati, let perduti)? = primavera.first else {
            return XCTFail("la primavera si dichiara con un evento")
        }
        XCTAssertTrue(ingressi.isEmpty)
        XCTAssertEqual(migliorati, [ElementoDelleForze(unita: "lupo", reparto: pesante(8, migliorata: true))])
        XCTAssertTrue(perduti.isEmpty)
        XCTAssertEqual(stato.registro.last?.fatto,
                       .miglioramentoDato(ElementoDelleForze(unita: "lupo", reparto: pesante(8, migliorata: true))))
        XCTAssertEqual(stato.registro.last?.stagione, .primavera)
    }

    func test_incarico_31_F_ogni_ordine_fuori_regola_su_un_reparto_e_respinto_col_suo_motivo() throws {
        var stato = try motore.statoIniziale()
        func motivo(_ voce: String, _ bersaglio: BersaglioMilitare?) -> MotivoNonValidoRegno? {
            motore.valida(.ordina(voce: IdentificatoreDati(voce), bersaglio: bersaglio), stato: stato).motivo
        }
        // Fuori dall'inverno non si ordina, col bersaglio o senza.
        XCTAssertEqual(motivo("addestramento_mirato", Self.pesanteDiLupo), .nonEInverno)
        esegui(.attendiInverno, &stato)

        // La voce che agisce su un reparto lo vuole indicato, ed esistente.
        XCTAssertEqual(motivo("addestramento_mirato", nil), .bersaglioMancante)
        XCTAssertEqual(motivo("mantenimento_addestramento", nil), .bersaglioMancante)
        XCTAssertEqual(motivo("addestramento_mirato", BersaglioMilitare(unita: "muflone", elemento: 0)), .bersaglioMancante)
        XCTAssertEqual(motivo("addestramento_mirato", BersaglioMilitare(unita: "lupo", elemento: 2)), .bersaglioMancante)
        XCTAssertEqual(motivo("addestramento_mirato", BersaglioMilitare(unita: "lupo", elemento: -1)), .bersaglioMancante)
        // La leva non ne vuole.
        XCTAssertEqual(motivo("leva_fanteria_leggera", Self.pesanteDiLupo), .bersaglioMancante)
        XCTAssertEqual(motivo("voce_che_non_esiste", Self.pesanteDiLupo), .voceIgnota)
        // Non si mantiene ciò che il reparto non porta.
        XCTAssertEqual(motivo("mantenimento_addestramento", Self.pesanteDiLupo), .bersaglioNonAmmesso)

        // Lo stesso reparto non riceve due lavori nello stesso inverno.
        XCTAssertNil(motivo("addestramento_mirato", Self.pesanteDiLupo))
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        XCTAssertEqual(motivo("addestramento_mirato", Self.pesanteDiLupo), .giaOrdinato)
        XCTAssertEqual(motivo("mantenimento_addestramento", Self.pesanteDiLupo), .giaOrdinato,
                       "un lavoro in corso sul reparto precede ogni altro giudizio")
        esegui(.prosegui, &stato)
        XCTAssertEqual(motivo("addestramento_mirato", Self.pesanteDiLupo), .giaOrdinato, "anche a un'altra schermata")
        // Un altro reparto della stessa formazione si può ancora addestrare.
        XCTAssertNil(motivo("addestramento_mirato", Self.leggeraDiLupo))
        // Le risorse: l'addestramento dei diciotto atomi costa settantadue monete.
        stato.riserve[.denaro] = 71
        XCTAssertEqual(motivo("addestramento_mirato", Self.leggeraDiLupo), .risorseInsufficienti([.denaro]))
        stato.riserve[.denaro] = 72
        XCTAssertNil(motivo("addestramento_mirato", Self.leggeraDiLupo))

        // L'anno dopo il reparto migliorato non si addestra una seconda volta: si mantiene.
        finoAllaPrimavera(&stato)
        esegui(.attendiInverno, &stato)
        XCTAssertEqual(motivo("addestramento_mirato", Self.pesanteDiLupo), .bersaglioNonAmmesso)
        XCTAssertNil(motivo("mantenimento_addestramento", Self.pesanteDiLupo))
        ordina("mantenimento_addestramento", su: Self.pesanteDiLupo, &stato)
        XCTAssertEqual(motivo("mantenimento_addestramento", Self.pesanteDiLupo), .giaOrdinato)
        XCTAssertEqual(stato.lavori.count, 1, "nessun ordine respinto è entrato fra i lavori")
    }

    func test_incarico_31_F_i_bersagli_di_una_voce_sono_i_reparti_che_la_ammettono_meno_quelli_gia_al_lavoro() throws {
        var stato = try motore.statoIniziale()
        let addestramento = try XCTUnwrap(motore.valori.voce("addestramento_mirato"))
        let mantenimento = try XCTUnwrap(motore.valori.voce("mantenimento_addestramento"))
        let leva = try XCTUnwrap(motore.valori.voce("leva_fanteria_leggera"))
        esegui(.attendiInverno, &stato)
        let tutti = [Self.leggeraDiCorvo, Self.leggeraDiLupo, Self.pesanteDiLupo,
                     BersaglioMilitare(unita: "falco", elemento: 0), BersaglioMilitare(unita: "orso", elemento: 0)]
        XCTAssertEqual(motore.bersagli(di: addestramento, stato: stato), tutti,
                       "ogni reparto senza miglioramento, nell'ordine in cui le forze si leggono")
        XCTAssertTrue(motore.bersagli(di: mantenimento, stato: stato).isEmpty, "nessuno porta ancora il miglioramento")
        XCTAssertTrue(motore.bersagli(di: leva, stato: stato).isEmpty, "la leva non agisce su un reparto")
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        XCTAssertEqual(motore.bersagli(di: addestramento, stato: stato), tutti.filter { $0 != Self.pesanteDiLupo })
        finoAllaPrimavera(&stato)
        esegui(.attendiInverno, &stato)
        XCTAssertEqual(motore.bersagli(di: addestramento, stato: stato), tutti.filter { $0 != Self.pesanteDiLupo })
        XCTAssertEqual(motore.bersagli(di: mantenimento, stato: stato), [Self.pesanteDiLupo])
        ordina("mantenimento_addestramento", su: Self.pesanteDiLupo, &stato)
        XCTAssertTrue(motore.bersagli(di: mantenimento, stato: stato).isEmpty)
        // Ogni bersaglio offerto è un ordine che il Motore accetta, se le risorse bastano.
        stato.riserve[.denaro] = 1000
        for bersaglio in motore.bersagli(di: addestramento, stato: stato) {
            XCTAssertTrue(motore.valida(.ordina(voce: "addestramento_mirato", bersaglio: bersaglio), stato: stato).eValido)
        }
        // Chi è ancora in arrivo non è un bersaglio: non si addestra chi non c'è.
        let conUnArrivo = ForzeDelRegno.sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(6)]),
            FormazioneDelRegno(nome: "cervo", categoria: .armato, composizione: [leggera(6, leva: 1)], arrivo: .estate),
        ], prossimoNome: 5)
        XCTAssertEqual(conUnArrivo.bersagli(di: addestramento.effetto), [Self.leggeraDiCorvo])
    }

    func test_incarico_31_F_il_miglioramento_si_conserva_soltanto_se_mantenuto_altrimenti_si_perde_e_il_reparto_resta() throws {
        var stato = try motore.statoIniziale()
        // Il primo inverno: due addestramenti.
        esegui(.attendiInverno, &stato)
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        ordina("addestramento_mirato", su: Self.leggeraDiCorvo, &stato)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.forze.reparto(Self.pesanteDiLupo), pesante(8, migliorata: true))
        XCTAssertEqual(stato.forze.reparto(Self.leggeraDiCorvo), leggera(6, migliorata: true))

        // Il secondo inverno: si mantiene il solo reparto di Lupo, per otto monete.
        esegui(.attendiInverno, &stato)
        let mantenimento = try XCTUnwrap(motore.valori.voce("mantenimento_addestramento"))
        XCTAssertEqual(motore.costo(di: mantenimento, bersaglio: Self.pesanteDiLupo, stato: stato)?[.denaro], 8,
                       "otto atomi per cinque monete per due decimi")
        XCTAssertEqual(motore.costo(di: mantenimento, bersaglio: Self.leggeraDiCorvo, stato: stato)?[.denaro], 6)
        ordina("mantenimento_addestramento", su: Self.pesanteDiLupo, &stato)
        XCTAssertEqual(stato.forze.reparto(Self.leggeraDiCorvo), leggera(6, migliorata: true),
                       "per tutto l'inverno il reparto non mantenuto porta ancora il miglioramento")
        let prima = stato.forze.formazioni
        let primavera = finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.forze.reparto(Self.pesanteDiLupo), pesante(8, migliorata: true), "mantenuto: lo conserva")
        XCTAssertEqual(stato.forze.reparto(Self.leggeraDiCorvo), leggera(6), "non mantenuto: lo perde, e resta")
        var attese = prima
        attese[0].composizione[0] = leggera(6)
        XCTAssertEqual(stato.forze.formazioni, attese, "nient'altro è cambiato")
        guard case .primaveraCominciata(_, _, let ingressi, let migliorati, let perduti)? = primavera.first else {
            return XCTFail("la primavera si dichiara con un evento")
        }
        XCTAssertTrue(ingressi.isEmpty)
        XCTAssertTrue(migliorati.isEmpty, "mantenere non è dare: il mantenuto non si annuncia come nuovo")
        XCTAssertEqual(perduti, [ElementoDelleForze(unita: "corvo", reparto: leggera(6, migliorata: true))],
                       "il fatto porta il reparto com'era, col miglioramento che ha perduto")
        XCTAssertEqual(stato.registro.last?.fatto,
                       .miglioramentoPerduto(ElementoDelleForze(unita: "corvo", reparto: leggera(6, migliorata: true))))

        // Il terzo inverno: nessuno mantiene, e anche Lupo lo perde; Corvo si può riaddestrare.
        esegui(.attendiInverno, &stato)
        XCTAssertTrue(motore.valida(.ordina(voce: "addestramento_mirato", bersaglio: Self.leggeraDiCorvo), stato: stato).eValido)
        finoAllaPrimavera(&stato)
        XCTAssertEqual(stato.forze.reparto(Self.pesanteDiLupo), pesante(8))
        XCTAssertEqual(stato.forze.formazioni.flatMap(\.composizione).filter { $0.miglioramento != nil }.count, 0)
    }

    func test_incarico_31_F_il_miglioramento_segue_il_reparto_al_fronte_e_al_rientro() throws {
        var stato = try motore.statoIniziale()
        esegui(.attendiInverno, &stato)
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        finoAllaPrimavera(&stato)
        // La campagna: Lupo torna coi superstiti raggruppati come li raggruppa il ritorno dalla
        // battaglia — per archetipo, miglioramento e anno di leva —, e il pesante è ancora migliorato.
        esegui(.apriCampagna(fronte: "guado"), &stato)
        let lupo = try formazione("lupo", stato)
        let rientrano = stato.forze.formazioni.map { formazione in
            formazione.nome == "lupo" ? tornata(lupo, composizione: [leggera(11), pesante(5, migliorata: true)])
                                      : tornata(formazione)
        }
        _ = motore.applicaEsito(esito(stato, rientrano: rientrano), in: &stato)
        XCTAssertEqual(try formazione("lupo", stato).composizione, [leggera(11), pesante(5, migliorata: true)])
        // E d'inverno è lui il reparto da mantenere, col costo dei superstiti.
        esegui(.attendiInverno, &stato)
        let mantenimento = try XCTUnwrap(motore.valori.voce("mantenimento_addestramento"))
        XCTAssertEqual(motore.bersagli(di: mantenimento, stato: stato), [Self.pesanteDiLupo])
        XCTAssertEqual(motore.costo(di: mantenimento, bersaglio: Self.pesanteDiLupo, stato: stato)?[.denaro], 5,
                       "cinque atomi per cinque monete per due decimi")
    }

    // MARK: - L'impronta e la codifica (05 §2.9, 00 §15)

    func test_incarico_31_l_impronta_distingue_cio_che_la_seconda_tappa_ha_aggiunto() throws {
        var stato = try motore.statoIniziale()
        esegui(.attendiInverno, &stato)
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        let base = stato.impronta()
        func diversa(_ che: String, _ cambia: (inout StatoRegno) -> Void, riga: UInt = #line) {
            var altro = stato
            cambia(&altro)
            XCTAssertNotEqual(altro.impronta(), base, "l'impronta non distingue \(che)", line: riga)
        }
        func conFormazioni(_ cambia: @escaping (inout [FormazioneDelRegno]) -> Void) -> (inout StatoRegno) -> Void {
            { stato in
                guard case .sciami(var formazioni, let prossimoNome) = stato.forze else { return }
                cambia(&formazioni)
                stato.forze = .sciami(formazioni: formazioni, prossimoNome: prossimoNome)
            }
        }
        diversa("il nome di una formazione", conFormazioni {
            $0[0] = FormazioneDelRegno(nome: "muflone", categoria: $0[0].categoria, composizione: $0[0].composizione)
        })
        diversa("la formazione tenuta in patria", conFormazioni { $0[0].inPatria = true })
        diversa("la stagione d'arrivo", conFormazioni { $0[0].arrivo = .estate })
        diversa("il miglioramento di un reparto", conFormazioni { $0[0].composizione[0] = self.leggera(6, migliorata: true) })
        diversa("l'anno di leva di un reparto", conFormazioni { $0[0].composizione[0] = self.leggera(6, leva: 1) })
        diversa("la posizione nella lista dei nomi") {
            $0.forze = .sciami(formazioni: $0.forze.formazioni, prossimoNome: 7)
        }
        diversa("il mantenimento prelevato") { $0.mantenimento[.denaro] += 1 }
        diversa("ciò che il mantenimento ha sciolto") {
            $0.sciolti = [ElementoDelleForze(unita: "orso", reparto: self.leggera(4))]
        }
        diversa("il bersaglio di un lavoro") {
            let lavoro = $0.lavori[0]
            $0.lavori[0] = LavoroOrdinato(voce: lavoro.voce, costo: lavoro.costo, stazione: lavoro.stazione,
                                          effetto: lavoro.effetto, pronto: lavoro.pronto, bersaglio: Self.leggeraDiLupo)
        }
        diversa("la stagione in cui un lavoro è pronto") {
            let lavoro = $0.lavori[0]
            $0.lavori[0] = LavoroOrdinato(voce: lavoro.voce, costo: lavoro.costo, stazione: lavoro.stazione,
                                          effetto: lavoro.effetto, pronto: .estate, bersaglio: lavoro.bersaglio)
        }
        diversa("l'effetto di un lavoro") {
            let lavoro = $0.lavori[0]
            $0.lavori[0] = LavoroOrdinato(voce: lavoro.voce, costo: lavoro.costo, stazione: lavoro.stazione,
                                          effetto: .mantieniMiglioramento(miglioramento: "addestramento_mirato"),
                                          pronto: lavoro.pronto, bersaglio: lavoro.bersaglio)
        }
        // E gli stessi comandi danno lo stesso stato e la stessa impronta (00 §3.1).
        var gemello = try motore.statoIniziale()
        esegui(.attendiInverno, &gemello)
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &gemello)
        XCTAssertEqual(gemello, stato)
        XCTAssertEqual(gemello.impronta(), base)
    }

    func test_incarico_31_lo_stato_del_regno_si_codifica_e_si_rilegge_sullo_stesso_stato() throws {
        var (stato, _) = try dopoUnInvernoDiLeve()
        esegui(.destina(unita: "orso", alFronte: false), &stato)
        esegui(.attendiInverno, &stato)
        ordina("addestramento_mirato", su: Self.pesanteDiLupo, &stato)
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let dati = try codificatore.encode(stato)
        let riletto = try JSONDecoder().decode(StatoRegno.self, from: dati)
        XCTAssertEqual(riletto.impronta(), stato.impronta(), "l'impronta copre le forze, i lavori, il registro e il mantenimento")
        XCTAssertEqual(riletto.forze, stato.forze)
        XCTAssertEqual(riletto.lavori.map(\.bersaglio), stato.lavori.map(\.bersaglio))
        XCTAssertEqual(riletto.lavori.map(\.effetto), stato.lavori.map(\.effetto))
        XCTAssertEqual(riletto.registro.count, stato.registro.count)
        XCTAssertEqual(riletto.mantenimento[.denaro], stato.mantenimento[.denaro])
        XCTAssertEqual(try codificatore.encode(riletto), dati, "la ricodifica dà gli stessi byte")
        // I campi facoltativi dei reparti e delle formazioni si omettono quando mancano.
        let testo = String(data: try codificatore.encode(try motore.statoIniziale()), encoding: .utf8)!
        for chiave in ["\"miglioramento\"", "\"leva\"", "\"arrivo\"", "\"bersaglio\""] {
            XCTAssertFalse(testo.contains(chiave), "lo stato iniziale non ha \(chiave) da scrivere")
        }
    }

    func test_incarico_31_ogni_motivo_del_regno_ha_la_propria_chiave_distinta() {
        let chiavi = MotivoNonValidoRegno.casiDiRiferimento.map(\.chiaveTesto)
        XCTAssertEqual(chiavi.count, 12, "gli otto motivi della prima tappa e i quattro della seconda")
        XCTAssertEqual(Set(chiavi).count, chiavi.count)
        for nuova in ["regno.non_valido.unita_ignota", "regno.non_valido.bersaglio_mancante",
                      "regno.non_valido.bersaglio_non_ammesso", "regno.non_valido.gia_ordinato"] {
            XCTAssertTrue(chiavi.contains(nuova), nuova)
        }
    }
}
