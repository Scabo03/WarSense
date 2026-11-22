import Foundation
import Dati
import Motore

/// La traduzione dei fatti del regno in significato e annuncio (05 §10.7; incarico 30), gemella dei
/// traduttori della battaglia e della campagna: stessa struttura, stesse regole, perché il giocatore
/// impari un modo solo (00 §7.1). È anche l'UNICO autore delle frasi del regno — annunci, voci del
/// registro della patria, costi, impedimenti —, sicché la schermata della patria e i segnali non
/// possano dire cose diverse dello stesso fatto. Parte neutra e collaudabile: nessun canale di
/// piattaforma.
public struct TraduttoreEventiRegno: Sendable {
    let testi: Testi

    public init(testi: Testi) {
        self.testi = testi
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

    /// Ciò che una voce militare dà, in parole (05 §7.7): è la sola frase del regno che dipende
    /// dalla modalità di battaglia.
    public func effetto(_ effetto: EffettoMilitare) -> String {
        switch effetto {
        case .reclutaReparto(_, let atomi):
            return testi.frase("regno.effetto.recluta_reparto", atomi).testo
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

    /// La riga di un lavoro già ordinato: «Leva di fanteria leggera, pronta in primavera».
    public func lavoroElencato(_ lavoro: LavoroOrdinato) -> String {
        testi.frase("regno.lavoro_elencato", soggetto: voce(lavoro.voce),
                    testi.termine(lavoro.pronto.chiaveTesto).testo).testo
    }

    /// La conferma dell'annullamento di una spesa.
    public func spesaAnnullata(_ lavoro: LavoroOrdinato) -> TestoLocalizzato {
        testi.frase("regno.spesa_annullata", soggetto: voce(lavoro.voce))
    }

    // MARK: - Eventi (05 §3.7)

    /// Il significato di segnale per l'evento, se ne merita uno. Il tetto dei significati è chiuso
    /// (02 §11.5): gli ordini del giocatore portano la conferma, come sulla mappa; i fatti del
    /// calendario si annunciano a parole e non ne aggiungono.
    public func significato(per evento: EventoRegno) -> SignificatoSegnale? {
        switch evento {
        case .campagnaAperta, .lavoroOrdinato: return .conferma
        case .campagnaConclusa, .invernoCominciato, .stazioneAperta, .primaveraCominciata: return nil
        }
    }

    /// L'annuncio per l'evento, già nella lingua dichiarata. Nulla per la conclusione della
    /// campagna, che ha la propria schermata (05 §9.3).
    public func annuncio(per evento: EventoRegno, fase: Fase) -> TestoLocalizzato? {
        switch evento {
        case .campagnaAperta(let fronte):
            return testi.frase("regno.campagna_aperta", self.fronte(fronte))
        case .campagnaConclusa:
            return nil
        case .invernoCominciato(let anno, let entrata):
            return testi.frase("regno.inverno_cominciato", anno, elenco(entrata, fase: fase))
        case .lavoroOrdinato(let voce, _, let pronto):
            return testi.frase("regno.lavoro_ordinato", soggetto: self.voce(voce),
                               testi.termine(pronto.chiaveTesto).testo)
        case .stazioneAperta(let stazione):
            return testi.frase("regno.stazione_aperta", stazione, MomentoDellAnno.stazioniInvernali)
        case .primaveraCominciata(let anno, let perduto, let lavoriPronti):
            // Una frase per fatto, in fila: la primavera, ciò che il riporto ha tolto se ha tolto
            // qualcosa (la condizione assente non si nomina, 02 §8.7.1), i lavori pronti.
            var testo = testi.frase("regno.primavera_cominciata", anno).testo
            if !perduto.sonoVuote {
                testo += testi.frase("regno.riporto_perduto", elenco(perduto, fase: fase)).testo
            }
            for voce in lavoriPronti {
                testo += testi.frase("regno.lavoro_pronto", soggetto: self.voce(voce)).testo
            }
            return TestoLocalizzato(testo: testo, lingua: testi.lingua)
        }
    }

    // MARK: - Registro della patria (01 §5.17, 02 §6.6)

    /// La frase di una voce del registro della patria: compiuta, con l'anno e la stagione cui si
    /// riferisce, una frase intera per ciascun fatto (00 §14.2).
    public func voceDiRegistro(_ voce: VoceRegistroPatria) -> TestoLocalizzato {
        let stagione = testi.termine(voce.stagione.chiaveTesto).testo
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
        case .lavoroPronto(let identificatore):
            return testi.frase("registro_patria.lavoro_pronto", soggetto: self.voce(identificatore),
                               voce.anno, stagione)
        case .primaveraCominciata(let eccedenzaPerduta):
            return testi.frase(eccedenzaPerduta ? "registro_patria.primavera_con_riporto"
                                                : "registro_patria.primavera",
                               voce.anno, stagione)
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
