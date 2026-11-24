import Foundation
import Dati
import Motore

/// La traduzione dei fatti del regno in significato e annuncio (05 §10.7; incarico 30), gemella dei
/// traduttori della battaglia e della campagna: stessa struttura, stesse regole, perché il giocatore
/// impari un modo solo (00 §7.1). È anche l'UNICO autore delle frasi del regno — annunci, voci del
/// registro della patria, costi, impedimenti, forze —, sicché la schermata della patria e i segnali
/// non possano dire cose diverse dello stesso fatto. Parte neutra e collaudabile: nessun canale di
/// piattaforma.
public struct TraduttoreEventiRegno: Sendable {
    let testi: Testi

    public init(testi: Testi) {
        self.testi = testi
    }

    /// Vero se all'evento segue un'ALTRA SCHERMATA (incarico 32): aperta la campagna si entra sulla
    /// mappa; con l'inverno e con la primavera la patria cambia corpo e il fuoco torna in testa. Il
    /// punto dei segnali lo chiede prima di consegnare i fatti dell'azione, perché li accompagnino a
    /// priorità alta (RDA-183). Il passaggio da una schermata dell'inverno alla successiva non è fra
    /// questi: gli elementi si aggiornano sul posto e il fuoco resta dov'è (02 §8.7.3).
    public static func cambiaSchermata(_ evento: EventoRegno) -> Bool {
        switch evento {
        case .campagnaAperta, .campagnaConclusa, .invernoCominciato, .primaveraCominciata: return true
        case .lavoroOrdinato, .stazioneAperta, .unitaDestinata: return false
        }
    }

    /// Ciò che separa le voci di un elenco e le frasi di un'etichetta: testo anch'esso, e quindi
    /// fuori dal codice (00 §14.1).
    private var separatoreDiElenco: String { testi.frase("regno.separatore_elenco").testo }
    private var separatoreDiFrasi: String { testi.frase("regno.separatore_frasi").testo }

    // MARK: - Termini

    /// Il termine chiuso di una risorsa (01 §5.5.1). Il denaro prende il nome della moneta della
    /// fase storica (01 §5.5.1.3): nelle frasi sta nella stessa posizione di ogni altra risorsa, e
    /// a cambiare con la fase è questa sola parola (02 §4.4.1.4).
    public func termine(_ risorsa: Risorsa, fase: Fase) -> String {
        testi.termine(Self.chiave(di: risorsa, fase: fase)).testo
    }

    /// La chiave del termine di una risorsa nel vocabolario.
    public static func chiave(di risorsa: Risorsa, fase: Fase) -> String {
        switch risorsa {
        case .denaro: return "risorsa.denaro." + fase.rawValue
        default: return "risorsa." + risorsa.rawValue
        }
    }

    /// Il nome di un fronte (01 §5.6.9): per punti di riferimento, e comincia sempre con «fronte».
    public func fronte(_ identificatore: IdentificatoreDati) -> String {
        testi.frase("fronte." + identificatore).testo
    }

    /// Una voce del regno come soggetto di frase, con il suo genere (02 §4.6).
    public func voce(_ identificatore: IdentificatoreDati) -> Soggetto {
        testi.soggetto(.voceDelRegno, identificatore)
    }

    /// Il termine chiuso di un miglioramento (01 §4.13): nelle frasi sta in coda, dove non chiede
    /// né articolo né accordo.
    public func miglioramento(_ identificatore: IdentificatoreDati) -> String {
        testi.termine(Self.chiave(delMiglioramento: identificatore)).testo
    }

    public static func chiave(delMiglioramento identificatore: IdentificatoreDati) -> String {
        "miglioramento." + identificatore
    }

    /// Il titolo di una linguetta dell'inverno (01 §5.9.1.3).
    public func linguetta(_ identificatore: IdentificatoreDati) -> String {
        testi.frase(Self.chiave(dellaLinguetta: identificatore)).testo
    }

    public static func chiave(dellaLinguetta identificatore: IdentificatoreDati) -> String {
        "patria.linguetta." + identificatore
    }

    // MARK: - Le forze (01 §5.6.0, §5.6.0.4; incarico 31): la sola parte che dipende dalla modalità

    /// Un reparto in parole: «6 atomi di fanteria leggera», e se porta un miglioramento «8 atomi di
    /// fanteria pesante con addestramento mirato». L'archetipo è il soggetto della frase, con il suo
    /// genere (02 §4.6).
    public func reparto(_ reparto: Reparto, conMiglioramento: Bool = true) -> String {
        let unita = testi.soggetto(.unita, reparto.archetipo)
        if conMiglioramento, let chiave = reparto.miglioramento {
            return testi.frase("regno.reparto_migliorato", soggetto: unita, reparto.atomi,
                               miglioramento(chiave)).testo
        }
        return testi.frase("divisione.reparto", soggetto: unita, reparto.atomi).testo
    }

    /// I reparti di una composizione, in fila.
    public func composizione(_ reparti: [Reparto]) -> String {
        reparti.map { reparto($0) }.joined(separator: separatoreDiElenco)
    }

    /// Un reparto di una formazione d'INVERNO, con ciò che il giocatore deve sapere per decidere
    /// (01 §4.14): se il miglioramento che porta va ancora mantenuto, se è già stato mantenuto, o se
    /// un addestramento è in corso. `lavori` sono quelli ordinati in questo inverno.
    func repartoDInverno(_ reparto: Reparto, bersaglio: BersaglioMilitare, lavori: [LavoroOrdinato]) -> String {
        let base = self.reparto(reparto)
        guard let lavoro = lavori.first(where: { $0.bersaglio == bersaglio }) else {
            return reparto.miglioramento == nil ? base
                                                : testi.frase("regno.miglioramento_da_mantenere", base).testo
        }
        switch lavoro.effetto.specie {
        case .migliora(let chiave):
            return testi.frase("regno.miglioramento_in_corso", base, miglioramento(chiave)).testo
        case .mantiene:
            return testi.frase("regno.miglioramento_mantenuto", base).testo
        case .recluta:
            return base
        }
    }

    /// La riga di una formazione in patria (incarico 31): il nome — che è il soggetto, e che il
    /// giocatore ritrova uguale da un anno all'altro —, la categoria, i reparti, e DOVE VA: se parte
    /// per il fronte o resta in patria; per le reclute dell'inverno, dove e quando entrano.
    /// `lavori`, d'inverno, aggiungono a ciascun reparto lo stato del suo miglioramento. `fronte`, a
    /// campagna aperta, dice dov'è ADESSO la formazione partita (S29q, punto d; incarico 32): una
    /// formazione già sul fronte dichiara la casella e i reparti che ha, una distrutta che non c'è più,
    /// e soltanto quella che deve ancora arrivare parla al futuro. `condotta` è vero quando la campagna
    /// dell'anno è già conclusa: chi doveva ancora arrivarvi resta in patria.
    public func formazione(_ formazione: FormazioneDelRegno, lavori: [LavoroOrdinato]? = nil,
                           fronte: SituazioneDelFronte? = nil, condotta: Bool = false) -> String {
        let nome = testi.soggetto(.gruppo, formazione.nome)
        let categoria = testi.termine(formazione.categoria.chiaveCategoria).testo
        if let fronte, formazione.parteConLaCampagna, !fronte.inArrivo.contains(formazione.nome) {
            guard let presenza = fronte.sulFronte[formazione.nome] else {
                return testi.frase("patria.formazione_perduta", soggetto: nome, categoria).testo
            }
            return testi.frase("patria.formazione_sul_fronte", soggetto: nome, categoria,
                               composizione(presenza.composizione),
                               presenza.casella.riga, presenza.casella.colonna).testo
        }
        let reparti: String
        if let lavori {
            reparti = formazione.composizione.enumerated().map { indice, reparto in
                repartoDInverno(reparto, bersaglio: BersaglioMilitare(unita: formazione.nome, elemento: indice),
                                lavori: lavori)
            }.joined(separator: separatoreDiElenco)
        } else {
            reparti = composizione(formazione.composizione)
        }
        guard let arrivo = formazione.arrivo else {
            return formazione.inPatria
                ? testi.frase("patria.formazione_in_patria", soggetto: nome, categoria, reparti).testo
                : testi.frase("patria.formazione_al_fronte", soggetto: nome, categoria, reparti).testo
        }
        let stagione = testi.termine(arrivo.chiaveTesto).testo
        if arrivo == .inverno {
            return testi.frase("patria.reclute_con_l_inverno", soggetto: nome, categoria, reparti).testo
        }
        if formazione.inPatria || condotta {
            return testi.frase("patria.reclute_in_patria", soggetto: nome, categoria, reparti, stagione).testo
        }
        return arrivo == .primavera
            ? testi.frase("patria.reclute_in_primavera", soggetto: nome, categoria, reparti).testo
            : testi.frase("patria.reclute_a_campagna_aperta", soggetto: nome, categoria, reparti, stagione).testo
    }

    /// Le forze in parole, una riga per unità: è ciò che la patria elenca.
    public func forze(_ forze: ForzeDelRegno, lavori: [LavoroOrdinato]? = nil,
                      fronte: SituazioneDelFronte? = nil,
                      condotta: Bool = false) -> [(unita: IdentificatoreDati, testo: String)] {
        switch forze {
        case .sciami(let formazioni, _):
            return formazioni.map { ($0.nome, formazione($0, lavori: lavori, fronte: fronte, condotta: condotta)) }
        }
    }

    /// La frase che dichiara l'ingresso delle reclute di un inverno (01 §4.12; incarico 31): quale
    /// formazione formano, con che cosa, e dove e quando entra.
    public func ingresso(_ ingresso: IngressoNelleForze) -> String {
        let nome = testi.soggetto(.gruppo, ingresso.unita)
        let reparti = composizione(ingresso.composizione)
        if ingresso.confluite {
            return testi.frase("regno.reclute_confluite", soggetto: nome, reparti).testo
        }
        switch ingresso.arrivo {
        case .primavera:
            return testi.frase("regno.reclute_in_primavera", soggetto: nome, reparti).testo
        case .estate, .autunno:
            return testi.frase("regno.reclute_a_campagna_aperta", soggetto: nome, reparti,
                               testi.termine(ingresso.arrivo.chiaveTesto).testo).testo
        case .inverno:
            return testi.frase("regno.reclute_con_l_inverno", soggetto: nome, reparti).testo
        }
    }

    /// La frase di ciò che il mantenimento ha sciolto (01 §4.14.1.1).
    public func sciolto(_ elemento: ElementoDelleForze) -> String {
        testi.frase("regno.reparto_sciolto", soggetto: testi.soggetto(.gruppo, elemento.unita),
                    reparto(elemento.reparto)).testo
    }

    /// La frase di un miglioramento compiuto (01 §4.13).
    public func migliorato(_ elemento: ElementoDelleForze) -> String {
        testi.frase("regno.miglioramento_dato", soggetto: testi.soggetto(.gruppo, elemento.unita),
                    reparto(elemento.reparto)).testo
    }

    /// La frase di un miglioramento perduto perché non mantenuto (01 §4.14): il reparto resta.
    public func miglioramentoPerduto(_ elemento: ElementoDelleForze) -> String {
        testi.frase("regno.miglioramento_perduto", soggetto: testi.soggetto(.gruppo, elemento.unita),
                    reparto(elemento.reparto, conMiglioramento: false),
                    elemento.reparto.miglioramento.map { miglioramento($0) } ?? "").testo
    }

    /// Il bersaglio di una voce in parole: «8 atomi di fanteria pesante di Lupo». Nullo se non esiste.
    public func bersaglio(_ bersaglio: BersaglioMilitare, forze: ForzeDelRegno) -> String? {
        guard let reparto = forze.reparto(bersaglio) else { return nil }
        return testi.frase("regno.bersaglio_descritto", soggetto: testi.soggetto(.gruppo, bersaglio.unita),
                           self.reparto(reparto)).testo
    }

    // MARK: - Risorse, costi, impedimenti (01 §5.9.1.5, 02 §8.7)

    /// L'elenco delle quantità non nulle, nell'ordine fisso delle risorse: «monete di bronzo 220,
    /// uomini 26». Vuoto se non c'è nulla da elencare.
    public func elenco(_ quantita: Riserve, fase: Fase) -> String {
        quantita.risorseInGioco
            .map { testi.frase("regno.entrata_voce", termine($0, fase: fase), quantita[$0]).testo }
            .joined(separator: separatoreDiElenco)
    }

    /// Il costo di una voce nella forma che dice quanto costa su quanto se ne possiede, per le sole
    /// risorse che la voce consuma (02 §8.7): «Costa: monete di bronzo 30 su 220, uomini 6 su 26.»
    public func costo(_ costo: Riserve, su riserve: Riserve, fase: Fase) -> String {
        let voci = costo.risorseInGioco
            .map { testi.frase("regno.costo_voce", termine($0, fase: fase), costo[$0], riserve[$0]).testo }
        return testi.frase("regno.costo", voci.joined(separator: separatoreDiElenco)).testo
    }

    /// L'impossibilità di ordinare, con le risorse che mancano (01 §5.9.1.5): «Non si può ordinare:
    /// mancano uomini, mancano metalli.» Una frase intera per ciascuna risorsa (00 §14.2).
    public func impedimento(_ mancanti: [Risorsa], fase: Fase) -> String {
        let frasi = mancanti.map { risorsa -> String in
            switch risorsa {
            case .denaro: return testi.frase("regno.manca.denaro." + fase.rawValue).testo
            default: return testi.frase("regno.manca." + risorsa.rawValue).testo
            }
        }
        return testi.frase("regno.non_ordinabile", frasi.joined(separator: separatoreDiElenco)).testo
    }

    /// Il motivo per cui un comando del regno è respinto (05 §3.2): il termine chiuso, oppure, per
    /// le risorse insufficienti, l'impedimento che le nomina.
    public func motivo(_ motivo: MotivoNonValidoRegno, fase: Fase) -> TestoLocalizzato {
        if case .risorseInsufficienti(let mancanti) = motivo {
            return TestoLocalizzato(testo: impedimento(mancanti, fase: fase), lingua: testi.lingua)
        }
        return testi.termine(motivo.chiaveTesto)
    }

    /// Ciò che una voce militare dà, in parole (05 §7.7): è la sola frase delle voci che dipende
    /// dalla modalità di battaglia.
    public func effetto(_ effetto: EffettoMilitare) -> String {
        switch effetto {
        case .reclutaReparto(_, let atomi):
            return testi.frase("regno.effetto.recluta_reparto", atomi).testo
        case .miglioraReparto:
            return testi.frase("regno.effetto.migliora_reparto").testo
        case .mantieniMiglioramento:
            return testi.frase("regno.effetto.mantieni_miglioramento").testo
        }
    }

    /// L'etichetta di una voce da ordinare (01 §5.9.1.5, 02 §8.7, §8.7.1), in ordine fisso: il nome;
    /// l'impossibilità, prontamente e con le risorse che mancano, soltanto quando c'è — una voce
    /// acquistabile non dichiara di esserlo —; il costo sulla riserva; ciò che dà e quando sarà
    /// pronta. I livelli di verbosità tagliano dalla coda (00 §9.5): il sintetico omette l'ultima.
    public func etichetta(dellaVoce voce: VoceDelRegno, costo: Riserve, riserve: Riserve,
                          pronta: Stagione, fase: Fase, verbosita: Verbosita) -> String {
        let soggetto = self.voce(voce.identificatore)
        var parti = [testi.frase("regno.voce_nome", soggetto: soggetto).testo]
        let mancanti = riserve.mancanti(per: costo)
        if !mancanti.isEmpty { parti.append(impedimento(mancanti, fase: fase)) }
        parti.append(self.costo(costo, su: riserve, fase: fase))
        if verbosita != .sintetico {
            parti.append(testi.frase("regno.voce_effetto", soggetto: soggetto, effetto(voce.effetto),
                                     testi.termine(pronta.chiaveTesto).testo).testo)
        }
        return parti.joined(separator: separatoreDiFrasi)
    }

    /// L'etichetta di una voce che si ordina SU un reparto esistente (01 §4.13, §4.14), nell'elenco
    /// dell'inverno: il nome; che il reparto si sceglie, oppure che non ce n'è alcuno; ciò che dà e
    /// quando sarà pronta. Il costo dipende dal reparto e lo dichiara ciascuna scelta.
    public func etichetta(dellaVoceConBersaglio voce: VoceDelRegno, bersagli: Int, pronta: Stagione,
                          verbosita: Verbosita) -> String {
        // Le due frasi che hanno la voce per soggetto si compongono per prime, ciascuna con la
        // propria chiave scritta per esteso: il cancello dell'accordo di genere legge le chiamate
        // con un'espressione regolare, e una frase senza soggetto seguita da una con soggetto,
        // senza una virgola in mezzo, gli parrebbe una chiave non letterale.
        let soggetto = self.voce(voce.identificatore)
        let nome = testi.frase("regno.voce_nome", soggetto: soggetto).testo
        let cheCosaDa = testi.frase("regno.voce_effetto", soggetto: soggetto, effetto(voce.effetto),
                                    testi.termine(pronta.chiaveTesto).testo).testo
        let scelta = bersagli == 0 ? testi.frase("regno.voce_senza_bersagli").testo
                                   : testi.frase("regno.voce_con_bersaglio").testo
        var parti = [nome, scelta]
        if verbosita != .sintetico { parti.append(cheCosaDa) }
        return parti.joined(separator: separatoreDiFrasi)
    }

    /// L'etichetta di una scelta nell'elenco dei reparti su cui ordinare una voce: la formazione e
    /// il reparto; l'impossibilità, se c'è; il costo sulla riserva (02 §8.7).
    public func etichetta(delBersaglio bersaglio: BersaglioMilitare, forze: ForzeDelRegno, costo: Riserve,
                          riserve: Riserve, fase: Fase) -> String {
        var parti: [String] = []
        if let reparto = forze.reparto(bersaglio) {
            parti.append(testi.frase("regno.bersaglio", soggetto: testi.soggetto(.gruppo, bersaglio.unita),
                                     self.reparto(reparto)).testo)
        }
        let mancanti = riserve.mancanti(per: costo)
        if !mancanti.isEmpty { parti.append(impedimento(mancanti, fase: fase)) }
        parti.append(self.costo(costo, su: riserve, fase: fase))
        return parti.joined(separator: separatoreDiFrasi)
    }

    /// La riga di un lavoro già ordinato: «Leva di fanteria leggera, pronta in primavera»; per le
    /// voci con un bersaglio, anche su che cosa.
    public func lavoroElencato(_ lavoro: LavoroOrdinato, forze: ForzeDelRegno) -> String {
        let stagione = testi.termine(lavoro.pronto.chiaveTesto).testo
        if let bersaglio = lavoro.bersaglio, let descritto = self.bersaglio(bersaglio, forze: forze) {
            return testi.frase("regno.lavoro_elencato_su", soggetto: voce(lavoro.voce), stagione, descritto).testo
        }
        return testi.frase("regno.lavoro_elencato", soggetto: voce(lavoro.voce), stagione).testo
    }

    /// La conferma dell'annullamento di una spesa.
    public func spesaAnnullata(_ lavoro: LavoroOrdinato) -> TestoLocalizzato {
        testi.frase("regno.spesa_annullata", soggetto: voce(lavoro.voce))
    }

    /// Ciò che la PRIMA schermata dell'inverno dichiara del mantenimento (01 §4.14.1.1): quanto il
    /// gioco ha prelevato da sé e, se il denaro non è bastato, che cosa ha sciolto. Vuoto se non
    /// c'era nulla da mantenere.
    public func dichiarazioneDelMantenimento(prelevato: Riserve, sciolti: [ElementoDelleForze],
                                             fase: Fase) -> [String] {
        var righe: [String] = []
        if !prelevato.sonoVuote {
            righe.append(testi.frase("patria.mantenimento", elenco(prelevato, fase: fase)).testo)
        }
        if !sciolti.isEmpty {
            righe.append(testi.frase("patria.mantenimento_insufficiente").testo)
            righe += sciolti.map { testi.frase("regno.frase_in_elenco", sciolto($0)).testo }
        }
        return righe
    }

    // MARK: - Eventi (05 §3.7)

    /// Il significato di segnale per l'evento, se ne merita uno. Il tetto dei significati è chiuso
    /// (02 §11.5): gli ordini del giocatore portano la conferma, come sulla mappa; i fatti del
    /// calendario si annunciano a parole e non ne aggiungono.
    public func significato(per evento: EventoRegno) -> SignificatoSegnale? {
        switch evento {
        case .campagnaAperta, .lavoroOrdinato, .unitaDestinata: return .conferma
        case .campagnaConclusa, .invernoCominciato, .stazioneAperta, .primaveraCominciata: return nil
        }
    }

    /// L'annuncio per l'evento, già nella lingua dichiarata. Nulla per la conclusione della
    /// campagna, che ha la propria schermata (05 §9.3). `forze` sono quelle del regno dopo
    /// l'evento: servono a nominare il bersaglio di una voce.
    public func annuncio(per evento: EventoRegno, fase: Fase, forze: ForzeDelRegno? = nil) -> TestoLocalizzato? {
        switch evento {
        case .campagnaAperta(let fronte):
            return testi.frase("regno.campagna_aperta", self.fronte(fronte))
        case .campagnaConclusa:
            return nil
        case .invernoCominciato(let anno, let entrata, let mantenimento, let sciolti):
            // Una frase per fatto, in fila: l'inverno con l'entrata; il mantenimento che il gioco
            // ha prelevato da sé; e, se il denaro non è bastato, ciò che è stato sciolto.
            var testo = testi.frase("regno.inverno_cominciato", anno, elenco(entrata, fase: fase)).testo
            if !mantenimento.sonoVuote {
                testo += testi.frase("regno.mantenimento_prelevato", elenco(mantenimento, fase: fase)).testo
            }
            if !sciolti.isEmpty { testo += testi.frase("regno.mantenimento_insufficiente").testo }
            for elemento in sciolti { testo += testi.frase("regno.frase_in_fila", sciolto(elemento)).testo }
            return TestoLocalizzato(testo: testo, lingua: testi.lingua)
        case .lavoroOrdinato(let voce, _, let pronto, let bersaglio):
            let stagione = testi.termine(pronto.chiaveTesto).testo
            if let bersaglio, let forze, let descritto = self.bersaglio(bersaglio, forze: forze) {
                return testi.frase("regno.lavoro_ordinato_su", soggetto: self.voce(voce), stagione, descritto)
            }
            return testi.frase("regno.lavoro_ordinato", soggetto: self.voce(voce), stagione)
        case .stazioneAperta(let stazione):
            return testi.frase("regno.stazione_aperta", stazione, MomentoDellAnno.stazioniInvernali)
        case .primaveraCominciata(let anno, let perduto, let ingressi, let migliorati, let perduti):
            // Una frase per fatto, in fila: la primavera, ciò che il riporto ha tolto se ha tolto
            // qualcosa (la condizione assente non si nomina, 02 §8.7.1), le reclute con il luogo e
            // il momento in cui entrano, i miglioramenti compiuti, quelli perduti.
            var testo = testi.frase("regno.primavera_cominciata", anno).testo
            if !perduto.sonoVuote {
                testo += testi.frase("regno.riporto_perduto", elenco(perduto, fase: fase)).testo
            }
            for ingresso in ingressi { testo += testi.frase("regno.frase_in_fila", self.ingresso(ingresso)).testo }
            for elemento in migliorati { testo += testi.frase("regno.frase_in_fila", migliorato(elemento)).testo }
            for elemento in perduti { testo += testi.frase("regno.frase_in_fila", miglioramentoPerduto(elemento)).testo }
            return TestoLocalizzato(testo: testo, lingua: testi.lingua)
        case .unitaDestinata(let unita, let alFronte):
            // Due chiamate con la chiave scritta per esteso, non una con la chiave scelta: il
            // cancello dell'accordo di genere vuole leggere quale frase riceve il soggetto.
            let nome = testi.soggetto(.gruppo, unita)
            return alFronte ? testi.frase("regno.unita_al_fronte", soggetto: nome)
                            : testi.frase("regno.unita_in_patria", soggetto: nome)
        }
    }

    // MARK: - Registro della patria (01 §5.17, 02 §6.6)

    /// La frase di una voce del registro della patria: compiuta, con l'anno e la stagione cui si
    /// riferisce, una frase intera per ciascun fatto (00 §14.2).
    public func voceDiRegistro(_ voce: VoceRegistroPatria, fase: Fase) -> TestoLocalizzato {
        let stagione = testi.termine(voce.stagione.chiaveTesto).testo
        /// I fatti delle forze hanno già la propria frase, la stessa dell'annuncio: il registro vi
        /// premette l'anno e la stagione.
        func datato(_ frase: String) -> TestoLocalizzato {
            testi.frase("registro_patria.fatto", voce.anno, stagione, frase)
        }
        switch voce.fatto {
        case .campagnaConclusa(let fronte, let modo, let vincitore):
            let chiave: String
            switch modo {
            case .inverno: chiave = "registro_patria.campagna_interrotta"
            case .annientamento:
                chiave = vincitore == .giocatore ? "registro_patria.campagna_vinta"
                                                 : "registro_patria.campagna_perduta"
            }
            return testi.frase(chiave, voce.anno, stagione, self.fronte(fronte))
        case .invernoCominciato:
            return testi.frase("registro_patria.inverno_cominciato", voce.anno, stagione)
        case .primaveraCominciata(let eccedenzaPerduta):
            return testi.frase(eccedenzaPerduta ? "registro_patria.primavera_con_riporto"
                                                : "registro_patria.primavera",
                               voce.anno, stagione)
        case .mantenimentoPrelevato(let quota):
            return testi.frase("registro_patria.mantenimento_prelevato", voce.anno, stagione,
                               elenco(quota, fase: fase))
        case .elementoSciolto(let elemento):
            return datato(sciolto(elemento))
        case .recluteEntrate(let ingresso):
            return datato(self.ingresso(ingresso))
        case .miglioramentoDato(let elemento):
            return datato(migliorato(elemento))
        case .miglioramentoPerduto(let elemento):
            return datato(miglioramentoPerduto(elemento))
        }
    }

    // MARK: - La dichiarazione di conclusione della campagna (05 §9.3)

    /// Le voci della dichiarazione di conclusione, in ordine fisso, ciascuna una frase (02 §10.3):
    /// l'esito e il modo; la durata; le battaglie; ciò che rientra; i premi che l'esito aggiunge
    /// alla rendita, o che non ce ne sono. I premi li calcola il Motore, non questa struttura.
    public func dichiarazioneDiConclusione(_ esito: EsitoCampagna, premi: Riserve, fase: Fase) -> [String] {
        let nome = fronte(esito.fronte)
        var voci: [String] = []
        switch esito.modo {
        case .inverno:
            voci.append(testi.frase("conclusione.inverno", nome).testo)
        case .annientamento:
            voci.append(testi.frase(esito.vinta ? "conclusione.vittoria" : "conclusione.sconfitta", nome).testo)
        }
        voci.append(testi.frase("conclusione.giornate", esito.giornate).testo)
        voci.append(testi.frase("conclusione.battaglie", esito.battaglieVinte, esito.battagliePerse).testo)
        let rientrano = esito.superstiti.numeroDiUnita
        voci.append(rientrano == 0 ? testi.frase("conclusione.nessun_rientro").testo
                                   : testi.frase("conclusione.rientro", rientrano).testo)
        voci.append(premi.sonoVuote ? testi.frase("conclusione.nessun_premio").testo
                                    : testi.frase("conclusione.premio", elenco(premi, fase: fase)).testo)
        return voci
    }
}
