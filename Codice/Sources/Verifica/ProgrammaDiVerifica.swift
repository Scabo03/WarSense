import Foundation
import Dati
import Motore

/// Il programma di verifica del bilanciamento (00 §16.1, 05 §12): gioca molti
/// scontri sugli stessi binari del gioco e riporta numeri, mai impressioni.
/// Non contiene alcuna regola propria: ogni esito viene dal Motore.
public struct ProgrammaDiVerifica: Sendable {

    public let cartellaValori: URL
    public let cartellaScenari: URL
    /// La cartella degli scenari di campagna. Assente, la campagna non si misura:
    /// il programma resta utile anche a chi vuole i soli scontri.
    public let cartellaScenariCampagna: URL?
    /// Se vero, la corsa è breve: un solo scenario e i soli banchi essenziali.
    /// È la forma che entra nel collaudo come fumo delle simulazioni (05 §14.7).
    public let fumo: Bool

    public init(cartellaValori: URL, cartellaScenari: URL,
                cartellaScenariCampagna: URL? = nil, fumo: Bool = false) {
        self.cartellaValori = cartellaValori
        self.cartellaScenari = cartellaScenari
        self.cartellaScenariCampagna = cartellaScenariCampagna
        self.fumo = fumo
    }

    // MARK: - Corsa completa

    public func esegui() throws -> Rapporto {
        let caricati = try CartellaScenari.carica(da: cartellaScenari)
        let scenari = fumo ? Array(caricati.scenari.prefix(1)) : caricati.scenari
        let valori = try CaricatoreValori.carica(da: cartellaValori)
        let motore = MotoreBattaglia(valori: valori)
        let banchi = BanchiDiMisura(motore: motore, banchi: caricati.banchi)

        var rapporto = Rapporto()
        rapporto.aggiungi(sezioneVersione(valori))
        rapporto.aggiungi(try sezioneScontri(scenari: scenari, banchi: caricati.banchi))
        rapporto.aggiungi(try sezioneRiepilogo(scenari: scenari, banchi: caricati.banchi))
        rapporto.aggiungi(sezioneSoglieDiResa(motore: motore, banchi: caricati.banchi))
        rapporto.aggiungi(sezioneComposizioni(banchi: banchi, scenari: scenari))
        rapporto.aggiungi(sezioneBersagli(banchi: banchi, scenari: scenari))
        rapporto.aggiungi(try sezioneModificatori(banchi: banchi))
        rapporto.aggiungi(try sezioneCurvaDelTiro(banchi: banchi))
        rapporto.aggiungi(try sezioneAccerchiamento(banchi: banchi))
        if !fumo { rapporto.aggiungi(try sezioneDuelli(banchi: banchi)) }
        if !fumo {
            for sezione in try sezioniMischia(valori: valori, parametriBanchi: caricati.banchi,
                                              scenari: scenari) {
                rapporto.aggiungi(sezione)
            }
        }
        if let cartellaScenariCampagna {
            let scenariCampagna = try ScenariCampagna.carica(da: cartellaScenariCampagna)
            let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
            let banco = BancoCampagna(
                motore: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                valoriCampagna: valoriCampagna, scenari: scenariCampagna)
            for sezione in try sezioniDiCampagna(banco: banco, scenari: scenariCampagna) {
                rapporto.aggiungi(sezione)
            }
            for sezione in try sezioniDelleSessioni(valori: valori, valoriCampagna: valoriCampagna,
                                                    motore: motore, scenari: scenari) {
                rapporto.aggiungi(sezione)
            }
        }
        return rapporto
    }

    // MARK: - Sezioni della campagna

    /// Due mestieri distinti, come l'incarico chiede di tenerli: gli INVARIANTI, che
    /// non ammettono eccezioni e la cui uscita è un conteggio di violazioni che deve
    /// valere zero; e le MISURE, che sono numeri da leggere e che in questa sessione
    /// non giustificano alcuna taratura.
    func sezioniDiCampagna(banco: BancoCampagna,
                           scenari: ScenariCampagna) throws -> [Rapporto.Sezione] {
        var sezioni: [Rapporto.Sezione] = []

        // Ogni scenario si corre UNA volta sola: le sezioni che ne derivano
        // leggono le stesse corse, così non possono divergere fra loro.
        let giornate = fumo ? min(4, scenari.giornateGenerate) : scenari.giornateGenerate
        // Il fumo TRONCA la corsa a poche giornate: non è una partita intera, e l'invariante
        // dell'avvistamento (incarico 22) — che pretende almeno un avvistamento — non vi si applica,
        // perché il primo avvistamento può arrivare più tardi. Le corse intere restano il cancello.
        let corse = try scenari.scenari.map {
            try banco.corri($0, giornate: giornate, partitaCompleta: !fumo)
        }
        var righeInvarianti: [[String]] = []
        for corsa in corse {
            righeInvarianti.append([corsa.identificatore, corsa.mappa, String(corsa.gruppi),
                                    String(corsa.giornate), String(corsa.ordini),
                                    String(corsa.marce), String(corsa.marceLunghe),
                                    String(corsa.marceCompiute), String(corsa.revoche),
                                    String(corsa.presidi),
                                    String(corsa.senzaDestinazione),
                                    String(corsa.violazioni.count),
                                    corsa.violazioni.joined(separator: ";"),
                                    corsa.improntaFinale,
                                    String(corsa.volumeMinimo), String(corsa.volumeMassimo),
                                    String(corsa.divisioni), String(corsa.riunioni),
                                    String(corsa.tagli), String(corsa.sosteImposte),
                                    String(corsa.sosteVolontarie), String(corsa.riprese),
                                    String(corsa.passaggiInZona), String(corsa.struttureIsolate),
                                    // Le colonne dell'avversario si aggiungono in CODA, così
                                    // che gli indici di colonna che il riepilogo somma non si
                                    // spostino (incarico 18).
                                    String(corsa.gruppiAvversario), String(corsa.tagliDaAvversario),
                                    String(corsa.aggiramenti), String(corsa.minDistanzaAvversarioQg),
                                    // I fenomeni della ricognizione, delle imboscate e delle
                                    // azioni contro le non armate, anch'essi in CODA (incarico 19).
                                    String(corsa.esplorazioniRiuscite), String(corsa.esplorazioniAManiVuote),
                                    String(corsa.esploratoriNotati), String(corsa.esploratoriPerduti),
                                    String(corsa.sabotaggiArmati), String(corsa.sabotaggiEsploratori),
                                    String(corsa.sabotaggiFalliti), String(corsa.studi),
                                    String(corsa.imboscatePiazzate), String(corsa.imboscateScattate)])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_invarianti",
            intestazione: ["scenario", "mappa", "gruppi", "giornate", "ordini", "marce",
                           "marce_lunghe", "marce_compiute", "revoche", "presidi",
                           "senza_destinazione", "violazioni", "dettaglio",
                           "impronta_finale", "volume_minimo", "volume_massimo",
                           "divisioni", "riunioni",
                           "tagli", "soste_imposte", "soste_volontarie", "riprese",
                           "passaggi_in_zona", "strutture_isolate",
                           "gruppi_avversario", "tagli_da_avversario", "aggiramenti",
                           "min_distanza_avversario_qg",
                           "esplorazioni_riuscite", "esplorazioni_a_mani_vuote",
                           "esploratori_notati", "esploratori_perduti",
                           "sabotaggi_armati", "sabotaggi_esploratori", "sabotaggi_falliti",
                           "studi", "imboscate_piazzate", "imboscate_scattate"],
            righe: righeInvarianti))

        // La curva, non il punto: il costo di chiusura di una giornata si misura su
        // tutto l'intervallo di copertura e nelle due disposizioni, perché il
        // numero dei gruppi e la loro dispersione sono due cause distinte e una
        // misura sola non le distingue.
        var righePassi: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            for disposizione in BancoCampagna.Disposizione.allCases {
                for gruppi in scenari.gruppiPerLaMisuraDeiPassi {
                    guard let passi = try banco.misuraPassi(mappa: mappa, gruppi: gruppi,
                                                            disposizione: disposizione)
                    else { continue }
                    righePassi.append([mappa, disposizione.rawValue, String(passi.gruppi),
                                       String(passi.conIlSalto), String(passi.senzaIlSalto),
                                       String(passi.senzaIlSalto - passi.conIlSalto),
                                       String(passi.conIlSalto / passi.gruppi),
                                       String(passi.senzaIlSalto / passi.gruppi)])
                }
            }
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_passi_per_giornata",
            intestazione: ["mappa", "disposizione", "gruppi", "con_il_salto", "senza_il_salto",
                           "scarto", "con_il_salto_per_gruppo", "senza_il_salto_per_gruppo"],
            righe: righePassi))

        // La distanza fra i due quartier generali, affiancata alla distanza massima
        // fra due caselle: due grandezze diverse, due colonne che non si scambiano.
        var righeDistanze: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            guard let misura = try banco.misuraDistanzaFraQuartierGenerali(mappa: mappa)
            else { continue }
            righeDistanze.append([misura.mappa, misura.formato, String(misura.lato),
                                  String(misura.distanzaFraQuartierGenerali),
                                  String(misura.distanzaMassimaFraDueCaselle),
                                  String(misura.giornatePerCongiungerli)])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_distanze",
            intestazione: ["mappa", "formato", "lato", "distanza_fra_quartier_generali",
                           "distanza_massima_fra_due_caselle", "giornate_per_congiungerli"],
            righe: righeDistanze))

        // Bordo e interno sono GEOMETRIA e non dipendono dai gruppi; le uscite
        // libere dipendono da dove i gruppi stanno, perché una casella occupata da
        // una propria formazione non è disponibile (01 §5.6.0.2). Le due grandezze
        // hanno colonne distinte perché il resoconto della prima unità le aveva
        // confuse, chiamando «caselle di bordo» quelle con meno di quattro uscite.
        var righeRaggiungibili: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            guard let misura = try banco.misuraUsciteLibere(mappa: mappa) else { continue }
            let d = misura.distribuzione
            righeRaggiungibili.append([misura.mappa, String(d.quanti),
                                       String(misura.caselleDiBordo), String(misura.caselleInterne),
                                       String(misura.gruppiPresenti),
                                       String(d.minimo), String(d.mediana), String(d.massimo),
                                       String(d.media), String(misura.conMenoDiQuattroUscite),
                                       String(misura.interneConMenoDiQuattroUscite)])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_uscite_libere",
            intestazione: ["mappa", "caselle", "caselle_di_bordo", "caselle_interne",
                           "gruppi_nella_misura", "uscite_minimo", "uscite_mediana",
                           "uscite_massimo", "uscite_media", "con_meno_di_quattro_uscite",
                           "di_cui_interne"],
            righe: righeRaggiungibili))

        // La distribuzione dei gruppi nelle giornate generate: gli invarianti che si
        // rompono con molti gruppi sparpagliati non sono provati da giornate con due
        // gruppi vicini, e senza questa sezione non si vede quale parte della
        // distribuzione la generazione copra davvero.
        var perGruppi: [Int: (giornate: Int, ordini: Int, scenari: Int)] = [:]
        for corsa in corse {
            let vecchio = perGruppi[corsa.gruppi] ?? (0, 0, 0)
            perGruppi[corsa.gruppi] = (vecchio.giornate + corsa.giornate,
                                       vecchio.ordini + corsa.ordini, vecchio.scenari + 1)
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_distribuzione_gruppi",
            intestazione: ["gruppi", "scenari", "giornate", "ordini"],
            righe: perGruppi.keys.sorted().map { g in
                [String(g), String(perGruppi[g]!.scenari), String(perGruppi[g]!.giornate),
                 String(perGruppi[g]!.ordini)]
            }))

        sezioni.append(riepilogo(banco: banco, scenari: scenari,
                                 righeInvarianti: righeInvarianti, perGruppi: perGruppi))
        return sezioni
    }

    /// IL BLOCCO UNICO dei numeri destinati al resoconto (incarico: «fa' in modo che
    /// i numeri destinati al resoconto siano prodotti dal programma in un blocco
    /// unico»). Ogni cifra che il resoconto cita deve comparire qui; una cifra che
    /// non compaia qui va dichiarata come calcolata a mano nel punto stesso in cui
    /// è scritta. I totali sono sommati dal programma proprio perché non li sommi
    /// più io: nella prima unità le somme le avevo fatte a mente, e una era sbagliata.
    func riepilogo(banco: BancoCampagna, scenari: ScenariCampagna,
                   righeInvarianti: [[String]],
                   perGruppi: [Int: (giornate: Int, ordini: Int, scenari: Int)]) -> Rapporto.Sezione {
        var voci: [[String]] = []
        func voce(_ nome: String, _ valore: Int) { voci.append([nome, String(valore)]) }

        voce("scenari_di_campagna_generati", scenari.scenari.count)
        voce("giornate_generate_in_totale", perGruppi.values.reduce(0) { $0 + $1.giornate })
        voce("ordini_impartiti_in_totale", perGruppi.values.reduce(0) { $0 + $1.ordini })
        // I totali delle marce lunghe, dei compimenti e delle revoche si sommano
        // dalle stesse righe di dettaglio (RDA-71): la marcia lunga a colonna 6, il
        // compimento a 7, la revoca a 8.
        voce("marce_totali", righeInvarianti.reduce(0) { $0 + (Int($1[5]) ?? 0) })
        voce("marce_lunghe_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[6]) ?? 0) })
        voce("marce_compiute_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[7]) ?? 0) })
        voce("revoche_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[8]) ?? 0) })
        // Divisioni e riunioni si sommano dalle colonne 16 e 17: se zero, il banco non
        // le ha esercitate e i loro invarianti non hanno morso (01 §5.6.0.2, §5.6.0.3).
        voce("divisioni_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[16]) ?? 0) })
        voce("riunioni_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[17]) ?? 0) })
        // I fenomeni del rifornimento si sommano dalle colonne 18–23: il taglio, la
        // sosta imposta di due turni, la sosta volontaria di uno, la ripresa, i
        // turni-gruppo in zona e le strutture isolate (01 §5.2.2). Se un totale è zero,
        // il banco non ha esercitato quel fenomeno e l'invariante relativo non ha morso.
        voce("tagli_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[18]) ?? 0) })
        voce("soste_imposte_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[19]) ?? 0) })
        voce("soste_volontarie_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[20]) ?? 0) })
        voce("riprese_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[21]) ?? 0) })
        voce("passaggi_in_zona_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[22]) ?? 0) })
        voce("strutture_isolate_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[23]) ?? 0) })
        // I fenomeni dell'AVVERSARIO (incarico 18), dalle colonne 24–27: gli scenari con
        // avversario, i tagli del giocatore da lui causati, gli aggiramenti, e quanto si
        // è avvicinato al quartier generale del giocatore. È il primo dato che dice se si
        // gioca davvero contro qualcuno: se i tagli-da-avversario e gli aggiramenti sono
        // zero, il banco non ha ancora esercitato l'avversario in modo significativo.
        voce("scenari_con_avversario", righeInvarianti.filter { (Int($0[24]) ?? 0) > 0 }.count)
        voce("gruppi_avversari_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[24]) ?? 0) })
        voce("tagli_da_avversario_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[25]) ?? 0) })
        voce("aggiramenti_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[26]) ?? 0) })
        // La distanza minima raggiunta da un avversario dal quartier generale del
        // giocatore, fra i soli scenari con avversario (dove la colonna è significativa).
        voce("distanza_minima_avversario_dal_qg_giocatore",
             righeInvarianti.filter { (Int($0[24]) ?? 0) > 0 }.compactMap { Int($0[27]) }.min() ?? -1)
        // I fenomeni della ricognizione, delle imboscate e delle azioni contro le formazioni
        // non armate (incarico 19), dalle colonne 28–37. Il banco deve GENERARLI: se un totale
        // è zero, il fenomeno non è stato esercitato e l'invariante relativo non ha morso.
        voce("esplorazioni_riuscite_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[28]) ?? 0) })
        voce("esplorazioni_a_mani_vuote_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[29]) ?? 0) })
        voce("esploratori_notati_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[30]) ?? 0) })
        voce("esploratori_perduti_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[31]) ?? 0) })
        voce("sabotaggi_armati_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[32]) ?? 0) })
        voce("sabotaggi_esploratori_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[33]) ?? 0) })
        voce("sabotaggi_falliti_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[34]) ?? 0) })
        voce("studi_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[35]) ?? 0) })
        voce("imboscate_piazzate_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[36]) ?? 0) })
        voce("imboscate_scattate_in_totale", righeInvarianti.reduce(0) { $0 + (Int($1[37]) ?? 0) })
        let violazioni = righeInvarianti.reduce(0) { $0 + (Int($1[11]) ?? 0) }
        voce("violazioni_trovate_in_totale", violazioni)
        voce("ordini_a_gruppi_senza_alcuna_destinazione",
             righeInvarianti.reduce(0) { $0 + (Int($1[10]) ?? 0) })
        voce("gruppi_minimo_nelle_giornate_generate", perGruppi.keys.min() ?? 0)
        voce("gruppi_massimo_nelle_giornate_generate", perGruppi.keys.max() ?? 0)
        voce("invarianti_sorvegliati", SondaInvariantiCampagna.codiciNoti.count)
        voce("formati_di_mappa", banco.valoriCampagna.formatiMappa.count)
        voce("mappe_disponibili", banco.valoriCampagna.mappe.count)
        voce("costo_in_giorni_dello_scatto_base", banco.valoriCampagna.marcia.costoGiorniBase)
        voce("posizioni_visive_della_marcia", banco.valoriCampagna.marcia.posizioniVisive)
        // Il volume e il suo coefficiente (01 §5.6.3): il minimo e il massimo si
        // leggono dalle colonne 14 e 15 del dettaglio; se differiscono, il banco ha
        // esercitato marce di volumi diversi. La soglia è provvisoria.
        voce("volume_minimo_fra_gli_scenari", righeInvarianti.compactMap { Int($0[14]) }.min() ?? 0)
        voce("volume_massimo_fra_gli_scenari", righeInvarianti.compactMap { Int($0[15]) }.max() ?? 0)
        voce("soglia_volume_per_giorno_aggiuntivo",
             banco.valoriCampagna.marcia.sogliaVolumePerGiornoAggiuntivo)
        voce("gruppi_minimo_nella_misura_dei_passi", scenari.gruppiPerLaMisuraDeiPassi.min() ?? 0)
        voce("gruppi_massimo_nella_misura_dei_passi", scenari.gruppiPerLaMisuraDeiPassi.max() ?? 0)
        voce("disposizioni_nella_misura_dei_passi", BancoCampagna.Disposizione.allCases.count)
        return Rapporto.Sezione(nome: "campagna_riepilogo",
                                intestazione: ["voce", "valore"], righe: voci)
    }

    // MARK: - Sessioni complete (campagna e battaglia)

    /// Le sessioni INTERE, che è cosa diversa dalle giornate isolate e dagli scontri
    /// del banco: qui si sorvegliano anche gli invarianti che soltanto l'accumularsi
    /// dello stato può violare (`SondaSessioneCampagna`, `SondaSessioneBattaglia`).
    /// Nel fumo si riduce il numero di sessioni, mai la qualità degli invarianti.
    func sezioniDelleSessioni(valori: ValoriDiGioco, valoriCampagna: ValoriCampagna,
                              motore: MotoreBattaglia,
                              scenari: [ScenarioDiVerifica]) throws -> [Rapporto.Sezione] {
        let motoreCampagna = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        let bancoC = BancoSessioniCampagna(motore: motoreCampagna, valoriCampagna: valoriCampagna)
        let sessioniC = try bancoC.tutteLeSessioni(
            mappe: valoriCampagna.mappe, formati: valoriCampagna.formatiMappa,
            gruppiMassimi: fumo ? 2 : 12, giornate: fumo ? 3 : 12)

        var righeC: [[String]] = []
        for s in sessioniC {
            righeC.append([s.mappa, String(s.gruppi), s.disposizione.rawValue, s.condotta.rawValue,
                           String(s.giornate), String(s.ordini),
                           String(s.violazioniDiPasso.count + s.violazioniDiSessione.count),
                           (s.violazioniDiPasso + s.violazioniDiSessione).joined(separator: ";"),
                           s.improntaFinale])
        }
        let sezioneC = Rapporto.Sezione(
            nome: "sessioni_campagna",
            intestazione: ["mappa", "gruppi", "disposizione", "condotta", "giornate", "ordini",
                           "violazioni", "dettaglio", "impronta_finale"],
            righe: righeC)

        let bancoB = BancoSessioniBattaglia(motore: motore)
        let composizioni = composizioniDiMazzo(scenari: scenari)
        var righeB: [[String]] = []
        var sessioniB: [BancoSessioniBattaglia.Sessione] = []
        let ufficiali = valori.ufficiali.keys.sorted()
        for composizione in composizioni {
            for primo in [Parte.giocatore, .avversario] {
                for ufficiale in (fumo ? Array(ufficiali.prefix(1)) : ufficiali) {
                    for imboscata in (fumo ? [false] : [false, true]) {
                        let s = try bancoB.gioca(composizione, formato: scenari[0].formato,
                                                 caratteristica: scenari[0].caratteristica,
                                                 primoOccupante: primo, ufficiale: ufficiale,
                                                 imboscata: imboscata,
                                                 giriMassimi: scenari[0].giriMassimi)
                        sessioniB.append(s)
                        righeB.append([s.composizione, String(describing: s.primoOccupante),
                                       s.ufficiale, String(s.imboscata),
                                       String(s.concluso), String(s.giri), String(s.comandi),
                                       String(s.riserveRimaste), String(s.violazioni.count),
                                       s.violazioni.joined(separator: ";")])
                    }
                }
            }
        }
        let sezioneB = Rapporto.Sezione(
            nome: "sessioni_battaglia",
            intestazione: ["composizione", "primo_occupante", "ufficiale", "imboscata",
                           "conclusa", "giri", "comandi",
                           "riserve_rimaste", "violazioni", "dettaglio"],
            righe: righeB)

        return [sezioneC, sezioneB, riepilogoDelleSessioni(sessioniC, sessioniB)]
    }

    /// Il blocco unico dei numeri delle sessioni: i totali li somma il programma,
    /// e una prova li pareggia con le righe di dettaglio (RDA-71).
    func riepilogoDelleSessioni(_ campagna: [BancoSessioniCampagna.Sessione],
                                _ battaglia: [BancoSessioniBattaglia.Sessione]) -> Rapporto.Sezione {
        var voci: [[String]] = []
        func voce(_ nome: String, _ valore: Int) { voci.append([nome, String(valore)]) }
        voce("sessioni_di_campagna_giocate", campagna.count)
        voce("giornate_giocate_nelle_sessioni", campagna.reduce(0) { $0 + $1.giornate })
        voce("ordini_impartiti_nelle_sessioni", campagna.reduce(0) { $0 + $1.ordini })
        voce("violazioni_nelle_sessioni_di_campagna",
             campagna.reduce(0) { $0 + $1.violazioniDiPasso.count + $1.violazioniDiSessione.count })
        voce("gruppi_minimo_nelle_sessioni", campagna.map(\.gruppi).min() ?? 0)
        voce("gruppi_massimo_nelle_sessioni", campagna.map(\.gruppi).max() ?? 0)
        voce("mappe_percorse_dalle_sessioni", Set(campagna.map(\.mappa)).count)
        voce("disposizioni_percorse", Set(campagna.map(\.disposizione.rawValue)).count)
        voce("condotte_percorse", Set(campagna.map(\.condotta.rawValue)).count)
        voce("sessioni_di_battaglia_giocate", battaglia.count)
        voce("sessioni_di_battaglia_concluse", battaglia.filter(\.concluso).count)
        voce("comandi_nelle_sessioni_di_battaglia", battaglia.reduce(0) { $0 + $1.comandi })
        voce("sessioni_di_battaglia_con_riserve_rimaste",
             battaglia.filter { $0.riserveRimaste > 0 }.count)
        voce("violazioni_nelle_sessioni_di_battaglia", battaglia.reduce(0) { $0 + $1.violazioni.count })
        voce("invarianti_di_sessione_campagna", SondaSessioneCampagna.codiciNoti.count)
        voce("invarianti_di_sessione_battaglia", SondaSessioneBattaglia.codiciNoti.count)
        return Rapporto.Sezione(nome: "sessioni_riepilogo",
                                intestazione: ["voce", "valore"], righe: voci)
    }

    /// Le composizioni di mazzo che i copioni esistenti NON producono. Gli scenari
    /// dichiarativi danno i due mazzi tarati; qui si aggiungono i casi limite, e in
    /// particolare quello che lascia forze in riserva a fine battaglia, perché il
    /// deck è riserva vera per tutta la durata (01 §9.3.5).
    func composizioniDiMazzo(scenari: [ScenarioDiVerifica]) -> [BancoSessioniBattaglia.Composizione] {
        let base = scenari[0]
        let pieno = base.deckGiocatore
        let minimo = Array(pieno.prefix(1))
        // Il mazzo abbondante: gli stessi elementi con esemplari moltiplicati, così
        // che il volume non basti a schierarli tutti e qualcosa resti in riserva.
        let abbondante = pieno.map {
            ScenarioBattaglia.ElementoScenario(archetipo: $0.archetipo, protezione: $0.protezione,
                                               atomi: $0.atomi, esemplari: $0.esemplari * 3)
        }
        let unSoloArchetipo = pieno.prefix(1).map {
            ScenarioBattaglia.ElementoScenario(archetipo: $0.archetipo, protezione: $0.protezione,
                                               atomi: $0.atomi, esemplari: 4)
        }
        return [
            .init(nome: "pari", giocatore: pieno, avversario: base.deckAvversario),
            .init(nome: "abbondante_contro_pieno", giocatore: abbondante, avversario: pieno),
            .init(nome: "minimo_contro_pieno", giocatore: minimo, avversario: pieno),
            .init(nome: "un_solo_archetipo", giocatore: unSoloArchetipo, avversario: unSoloArchetipo),
        ]
    }

    // MARK: - Sezioni

    func sezioneVersione(_ valori: ValoriDiGioco) -> Rapporto.Sezione {
        Rapporto.Sezione(nome: "versione",
                         intestazione: ["versione_valori", "modificati_localmente", "archetipi", "formati"],
                         righe: [[valori.versioneEffettiva, String(valori.modificatiLocalmente),
                                  String(valori.archetipi.count), String(valori.formati.count)]])
    }

    /// Una riga per configurazione: è la forma richiesta da 05 §12.6, dove la
    /// configurazione prende il posto del seme perché la battaglia non ha caso
    /// alcuno (01 §12.1) e la variazione viene dagli estremi degli intervalli.
    func sezioneScontri(scenari: [ScenarioDiVerifica],
                        banchi: ParametriBanchi) throws -> Rapporto.Sezione {
        var righe: [[String]] = []
        for corsa in try corse(scenari: scenari) {
            let c = corsa.configurazione
            righe.append([
                corsa.scenario,
                c.primoOccupante.rawValue, c.ufficialeGiocatore, c.ufficialeAvversario,
                String(c.vantaggiAccesi), String(c.imboscata),
                corsa.concluso ? (corsa.modo?.rawValue ?? "") : "non_concluso",
                corsa.sconfitto?.rawValue ?? "",
                String(corsa.giri), String(corsa.comandi),
                String(corsa.perdite[.giocatore] ?? 0), String(corsa.perdite[.avversario] ?? 0),
                String(corsa.impegnate[.giocatore] ?? 0), String(corsa.impegnate[.avversario] ?? 0),
            ])
        }
        return Rapporto.Sezione(
            nome: "scontri",
            intestazione: ["scenario", "primo_occupante", "ufficiale_giocatore", "ufficiale_avversario",
                           "vantaggi_accesi", "imboscata", "modo", "sconfitto", "giri", "comandi",
                           "perdite_giocatore", "perdite_avversario",
                           "impegnate_giocatore", "impegnate_avversario"],
            righe: righe)
    }

    /// Il riepilogo per scenario e per stato dei vantaggi: frequenza degli esiti,
    /// distribuzione della durata, frequenza di vittoria delle due parti.
    func sezioneRiepilogo(scenari: [ScenarioDiVerifica],
                          banchi: ParametriBanchi) throws -> Rapporto.Sezione {
        let tutte = try corse(scenari: scenari)
        var righe: [[String]] = []
        for scenario in scenari {
            for vantaggi in [true, false] {
                let gruppo = tutte.filter {
                    $0.scenario == scenario.identificatore && $0.configurazione.vantaggiAccesi == vantaggi
                }
                guard !gruppo.isEmpty else { continue }
                let concluse = gruppo.filter { $0.concluso }
                let durata = Distribuzione(concluse.map(\.giri))
                let vittorieGiocatore = concluse.filter { $0.sconfitto == .avversario }.count
                let vittorieAvversario = concluse.filter { $0.sconfitto == .giocatore }.count
                let perAnnientamento = concluse.filter { $0.modo == .annientamento }.count
                let perRitirata = concluse.filter { $0.modo == .ritirataCompiuta }.count
                let scarto = abs(vittorieGiocatore - vittorieAvversario) * 1000 / max(1, concluse.count)
                // La soglia si giudica sulle sole corse a vantaggi SPENTI: con i
                // vantaggi accesi lo scarto misura quanto valgono i vantaggi, che è
                // un'asimmetria voluta e non uno sbilanciamento (03 §7.1, 05 §12.5).
                let soglia = vantaggi ? nil : scenario.soglie["scarto_vittorie_permille_senza_vantaggi"]
                righe.append([
                    scenario.identificatore, String(vantaggi),
                    String(gruppo.count), String(concluse.count),
                    String(gruppo.count - concluse.count),
                    String(perAnnientamento), String(perRitirata),
                    String(vittorieGiocatore), String(vittorieAvversario),
                    String(scarto),
                    soglia.map { String(scarto <= $0) } ?? "",
                    String(durata.minimo), String(durata.mediana), String(durata.massimo),
                    String(durata.media),
                ])
            }
        }
        return Rapporto.Sezione(
            nome: "riepilogo_scontri",
            intestazione: ["scenario", "vantaggi_accesi", "corse", "concluse", "non_concluse",
                           "per_annientamento", "per_ritirata",
                           "vittorie_giocatore", "vittorie_avversario", "scarto_permille",
                           "entro_soglia", "giri_minimo", "giri_mediana", "giri_massimo", "giri_media"],
            righe: righe)
    }

    /// Le corse di tutti gli scenari, con i vantaggi nascosti accesi e spenti.
    func corse(scenari: [ScenarioDiVerifica]) throws -> [BancoScontri.Corsa] {
        var esito: [BancoScontri.Corsa] = []
        for accesi in [true, false] {
            let sostituzioni = accesi ? [] : ValoriVariati.vantaggiSpenti
            try ValoriVariati.con(base: cartellaValori, sostituendo: sostituzioni) { valori in
                let motore = MotoreBattaglia(valori: valori)
                let ufficiali = valori.ufficiali.keys.sorted()
                for scenario in scenari {
                    let banco = BancoScontri(motore: motore, scenario: scenario)
                    for configurazione in BancoScontri.configurazioni(di: scenario, ufficiali: ufficiali)
                    where configurazione.vantaggiAccesi == accesi {
                        esito.append(try banco.gioca(configurazione))
                    }
                }
            }
        }
        return esito.sorted { a, b in
            if a.scenario != b.scenario { return a.scenario < b.scenario }
            let ca = a.configurazione, cb = b.configurazione
            if ca.vantaggiAccesi != cb.vantaggiAccesi { return ca.vantaggiAccesi && !cb.vantaggiAccesi }
            if ca.primoOccupante != cb.primoOccupante { return ca.primoOccupante == .giocatore }
            if ca.ufficialeGiocatore != cb.ufficialeGiocatore {
                return ca.ufficialeGiocatore < cb.ufficialeGiocatore
            }
            if ca.ufficialeAvversario != cb.ufficialeAvversario {
                return ca.ufficialeAvversario < cb.ufficialeAvversario
            }
            return !ca.imboscata && cb.imboscata
        }
    }

    func sezioneSoglieDiResa(motore: MotoreBattaglia, banchi: ParametriBanchi) -> Rapporto.Sezione {
        var righe: [[String]] = []
        for accesi in [true, false] {
            let sostituzioni = accesi ? [] : ValoriVariati.vantaggiSpenti
            let misure = (try? ValoriVariati.con(base: cartellaValori, sostituendo: sostituzioni) { valori in
                BanchiDiMisura(motore: MotoreBattaglia(valori: valori),
                               banchi: banchi).soglieDiResa(vantaggiAccesi: accesi)
            }) ?? []
            for m in misure {
                righe.append([m.ufficiale, m.parte.rawValue, String(m.vantaggiAccesi),
                              String(m.sogliaPermille), String(m.raggiungibile)])
            }
        }
        return Rapporto.Sezione(
            nome: "soglie_di_resa",
            intestazione: ["ufficiale", "parte", "vantaggi_accesi", "soglia_permille", "raggiungibile"],
            righe: righe)
    }

    func sezioneComposizioni(banchi: BanchiDiMisura,
                             scenari: [ScenarioDiVerifica]) -> Rapporto.Sezione {
        var righe: [[String]] = []
        for scenario in scenari {
            for m in banchi.redditivita(di: scenario) {
                righe.append([m.scenario, m.parte.rawValue,
                              String(m.efficaciaMassimaPermille), String(m.efficaciaMediaPermille),
                              String(m.elementiEfficaci), String(m.elementiTotali)])
            }
        }
        return Rapporto.Sezione(
            nome: "composizioni",
            intestazione: ["scenario", "parte", "efficacia_massima_permille",
                           "efficacia_media_permille", "elementi_efficaci", "elementi_totali"],
            righe: righe)
    }

    func sezioneBersagli(banchi: BanchiDiMisura,
                         scenari: [ScenarioDiVerifica]) -> Rapporto.Sezione {
        var righe: [[String]] = []
        for scenario in scenari {
            for b in banchi.bersagliDiSchieramento(di: scenario) {
                righe.append([b.scenario, b.parte.rawValue, b.archetipo, b.protezione.rawValue,
                              String(b.efficaciaDelTiroAvversoPermille), String(b.efficace),
                              String(b.puntiVita)])
            }
        }
        return Rapporto.Sezione(
            nome: "bersagli_di_schieramento",
            intestazione: ["scenario", "parte", "archetipo", "protezione",
                           "efficacia_tiro_avverso_permille", "efficace", "punti_vita"],
            righe: righe)
    }

    func sezioneModificatori(banchi: BanchiDiMisura) throws -> Rapporto.Sezione {
        Rapporto.Sezione(
            nome: "modificatori",
            intestazione: ["modificatore", "condizione", "coefficiente_permille", "danno_di_riferimento"],
            righe: try banchi.pesiDeiModificatori().map {
                [$0.modificatore, $0.condizione, String($0.coefficientePermille),
                 String($0.dannoDiRiferimento)]
            })
    }

    func sezioneCurvaDelTiro(banchi: BanchiDiMisura) throws -> Rapporto.Sezione {
        var righe: [[String]] = []
        for protezione in TipoProtezione.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            for punto in try banchi.curvaDelTiro(protezioneBersaglio: protezione) {
                righe.append([punto.archetipo, protezione.rawValue, String(punto.distanza),
                              String(punto.coefficientePermille), punto.fasciaVicinanza.rawValue,
                              String(punto.danno), String(punto.dannoPermilleDelBersaglio),
                              punto.fasciaPerdite.rawValue])
            }
        }
        return Rapporto.Sezione(
            nome: "curva_del_tiro",
            intestazione: ["archetipo", "protezione_bersaglio", "distanza", "coefficiente_permille",
                           "fascia_vicinanza", "danno", "danno_permille_del_bersaglio", "fascia_perdite"],
            righe: righe)
    }

    func sezioneAccerchiamento(banchi: BanchiDiMisura) throws -> Rapporto.Sezione {
        Rapporto.Sezione(
            nome: "accerchiamento",
            intestazione: ["assalitori", "coefficiente_permille", "inflitto", "subito",
                           "rapporto_permille", "bersaglio_caduto_in_un_giro", "subito_dall_ultimo"],
            righe: try banchi.progressioneAccerchiamento().map {
                [String($0.assalitori), String($0.coefficientePermille), String($0.inflitto),
                 String($0.subito), String($0.rapportoPermille),
                 String($0.bersaglioCadutoInUnGiro), String($0.subitoDallUltimoAggiunto)]
            })
    }

    func sezioneDuelli(banchi: BanchiDiMisura) throws -> Rapporto.Sezione {
        Rapporto.Sezione(
            nome: "duelli",
            intestazione: ["attaccante", "bersaglio", "protezione", "inflitto_primo_giro",
                           "subito_primo_giro", "giri", "prevale", "residuo_permille", "modo_di_fine"],
            righe: try banchi.duelli().map {
                [$0.attaccante, $0.bersaglio, $0.protezione.rawValue,
                 String($0.dannoInflittoPrimoGiro), String($0.dannoSubitoPrimoGiro),
                 String($0.giri), String($0.prevale), String($0.consistenzaResiduaPermille),
                 $0.modoDiFine]
            })
    }

    // MARK: - Misura del corpo a corpo (incarico 09)

    /// Le sezioni della mischia. La fotografia si prende a soglia ATTIVA (il regime del
    /// gioco distribuito); il quadro per la distruzione e i modificatori congiunti si
    /// prendono a soglia DISATTIVATA, che è l'artificio di misura di
    /// `ValoriVariati.disingaggioDisattivato` (soglia portata a 1,0 su ogni archetipo,
    /// dal caricatore vero). La provenienza delle perdite si legge su tutte le battaglie
    /// che il programma genera. Chiude il blocco unico di riepilogo, da cui il resoconto
    /// copia i numeri e che una prova pareggia con le righe di dettaglio (RDA-71).
    func sezioniMischia(valori: ValoriDiGioco, parametriBanchi: ParametriBanchi,
                        scenari: [ScenarioDiVerifica]) throws -> [Rapporto.Sezione] {
        // Le soglie osservate dalla misura sono quelle della fase del banco (antica, la
        // fase che la fabbrica assume): l'élite di quella fase non ha soglia (incarico 11).
        let faseDelBanco: Fase = .antica
        let soglieReali = valori.archetipi.mapValues { $0.eliteFase == faseDelBanco ? nil : $0.sogliaDisingaggio }

        // Fotografia: soglia attiva.
        let banchiAttivi = BanchiDiMisura(motore: MotoreBattaglia(valori: valori), banchi: parametriBanchi)
        let fotografia = try banchiAttivi.corseMischia(soglieReali: soglieReali)

        // Crux, distruzione e accerchiamento congiunto: soglia disattivata.
        let (accoppiamenti, accerchiata) = try ValoriVariati.con(
            base: cartellaValori, inElenco: ValoriVariati.disingaggioDisattivato) { valoriDisattivati in
            let b = BanchiDiMisura(motore: MotoreBattaglia(valori: valoriDisattivati), banchi: parametriBanchi)
            return (try b.corseMischia(soglieReali: soglieReali), try b.mischiaAccerchiata())
        }

        // Provenienza delle perdite su tutte le battaglie generate.
        let provenienze = try provenienzaDiTutteLeBattaglie(valori: valori, scenari: scenari)

        func vincitore(_ c: BanchiDiMisura.CorsaMischia) -> String {
            switch c.esito {
            case "disfatta_bersaglio": return "attaccante"
            case "disfatta_attaccante": return "bersaglio"
            case "disfatta_reciproca": return "nessuno"
            default: return "nessuno_al_tetto"
            }
        }

        // Sezione crux: turni per distruggere il bersaglio accanto ai turni per scattare
        // la sua soglia, per ciascun accoppiamento. È il dato su cui il titolare decide.
        var righeCrux: [[String]] = []
        for c in accoppiamenti {
            let inflittoPermille = c.inflittoPrimoScambio * 1000 / max(1, c.ingressoBersaglio)
            let scattaPrima = c.turnoSogliaBersaglio > 0
                && (c.turnoDistruzioneBersaglio == 0 || c.turnoSogliaBersaglio < c.turnoDistruzioneBersaglio)
            let divario = (c.turnoDistruzioneBersaglio > 0 && c.turnoSogliaBersaglio > 0)
                ? String(c.turnoDistruzioneBersaglio - c.turnoSogliaBersaglio) : ""
            let sogliaBersaglio = (soglieReali[c.bersaglio] ?? nil).map { String($0.grezzo) } ?? "assente"
            righeCrux.append([
                c.attaccante, c.bersaglio, c.protezione.rawValue,
                String(c.ingressoBersaglio), String(c.inflittoPrimoScambio),
                String(inflittoPermille), sogliaBersaglio,
                String(c.turnoSogliaBersaglio), String(c.turnoDistruzioneBersaglio),
                String(scattaPrima), divario, vincitore(c),
                String(c.turnoDistruzioneAttaccante),
            ])
        }
        let sezioneCrux = Rapporto.Sezione(
            nome: "mischia_accoppiamenti",
            intestazione: ["attaccante", "bersaglio", "protezione", "ingresso_bersaglio",
                           "inflitto_primo_scambio", "inflitto_primo_scambio_permille_bersaglio",
                           "soglia_bersaglio_permille", "turni_soglia_bersaglio",
                           "turni_distruzione_bersaglio", "soglia_scatta_prima", "divario",
                           "vincitore", "turni_distruzione_attaccante"],
            righe: righeCrux)

        // Sezione fotografia: che cosa accade oggi (soglia attiva).
        let sezioneFotografia = Rapporto.Sezione(
            nome: "mischia_fotografia",
            intestazione: ["attaccante", "bersaglio", "protezione", "esito", "scambi",
                           "chi_si_sfila", "perdite_permille_chi_si_sfila", "turni_soglia_bersaglio",
                           "residuo_bersaglio_permille", "residuo_attaccante_permille"],
            righe: fotografia.map {
                [$0.attaccante, $0.bersaglio, $0.protezione.rawValue, $0.esito, String($0.scambi),
                 $0.chiSiSfila, String($0.perditeChiSiSfilaPermille), String($0.turnoSogliaBersaglio),
                 String($0.residuoBersaglioPermille), String($0.residuoAttaccantePermille)]
            })

        // Sezione modificatori congiunti: accerchiamento e limite dei bersagli insieme.
        let sezioneAccerchiata = Rapporto.Sezione(
            nome: "mischia_modificatori_congiunti",
            intestazione: ["assalitori", "coefficiente_accerchiamento_permille", "inflitto_primo_giro",
                           "subito_primo_giro", "rapporto_permille", "scambi_per_distruggere",
                           "bersaglio_giu_a_primo_giro"],
            righe: accerchiata.map {
                [String($0.assalitori), String($0.coefficienteAccerchiamentoPermille),
                 String($0.inflittoPrimoGiro), String($0.subitoPrimoGiro), String($0.rapportoPermille),
                 String($0.scambiPerDistruggere), String($0.bersaglioGiuAPrimoGiro)]
            })

        // Sezione provenienza: per singola battaglia.
        let sezioneProvenienza = Rapporto.Sezione(
            nome: "provenienza_perdite",
            intestazione: ["famiglia", "etichetta", "perdite_tiro_giocatore", "perdite_tiro_avversario",
                           "perdite_mischia_giocatore", "perdite_mischia_avversario",
                           "distruzioni_in_mischia", "distruzioni_in_tiro",
                           "reingaggi", "disingaggi", "conclusa", "modo"],
            righe: provenienze.map {
                [$0.famiglia, $0.etichetta,
                 String($0.tiroG), String($0.tiroA), String($0.mischiaG), String($0.mischiaA),
                 String($0.distMischia), String($0.distTiro),
                 String($0.reingaggi), String($0.disingaggi), String($0.concluso), $0.modo]
            })

        // Fasce di disingaggio: per ciascun valore di soglia (cioè per ciascuna fascia,
        // più l'assenza dell'elitario) dopo quanti scambi la soglia scatta negli
        // accoppiamenti tipici, e la verifica che le fasce restino separate (incarico 10).
        let sezioneFasce = sezioneFasceDiDisingaggio(accoppiamenti: accoppiamenti,
                                                     soglieReali: soglieReali)

        let riepilogo = riepilogoMischia(fotografia: fotografia, accoppiamenti: accoppiamenti,
                                         accerchiata: accerchiata, provenienze: provenienze,
                                         soglieReali: soglieReali)

        return [sezioneCrux, sezioneFotografia, sezioneFasce, sezioneAccerchiata,
                sezioneProvenienza, riepilogo]
    }

    /// Per ciascun valore di soglia presente nei dati — ciascuna FASCIA — dopo quanti
    /// scambi la soglia scatta, misurato sugli accoppiamenti in cui il bersaglio di quella
    /// fascia la raggiunge (turni_soglia > 0). L'assenza di soglia (reparto elitario) è una
    /// riga a sé, con la soglia dichiarata «assente» e nessuno scambio, perché non scatta
    /// mai. Le righe sono ordinate per soglia crescente: il divario fra le mediane è la
    /// grandezza su cui il cancello `MisuraMischiaTest` verifica che le fasce siano separate.
    func sezioneFasceDiDisingaggio(accoppiamenti: [BanchiDiMisura.CorsaMischia],
                                   soglieReali: [IdentificatoreDati: Scalato?]) -> Rapporto.Sezione {
        // Gruppi di archetipi per valore di soglia; nil (elitario) come gruppo a parte.
        var archetipiPerSoglia: [Int: [String]] = [:]  // -1 = assente
        for (id, soglia) in soglieReali {
            let chiave = soglia.map { Int($0.grezzo) } ?? -1
            archetipiPerSoglia[chiave, default: []].append(id)
        }
        var righe: [[String]] = []
        for chiave in archetipiPerSoglia.keys.sorted() {
            let archetipi = archetipiPerSoglia[chiave]!.sorted()
            let scatti = accoppiamenti
                .filter { archetipi.contains($0.bersaglio) && $0.turnoSogliaBersaglio > 0 }
                .map(\.turnoSogliaBersaglio)
            let d = Distribuzione(scatti)
            righe.append([chiave < 0 ? "assente" : String(chiave),
                          archetipi.joined(separator: ";"),
                          String(d.quanti), String(d.minimo), String(d.mediana), String(d.massimo)])
        }
        return Rapporto.Sezione(
            nome: "mischia_fasce",
            intestazione: ["soglia_permille", "archetipi", "accoppiamenti_che_scattano",
                           "scatta_minimo", "scatta_mediana", "scatta_massimo"],
            righe: righe)
    }

    /// Una riga di provenienza per singola battaglia, con la famiglia da cui viene.
    struct RigaProvenienza {
        let famiglia: String
        let etichetta: String
        let tiroG: Int64
        let tiroA: Int64
        let mischiaG: Int64
        let mischiaA: Int64
        let distMischia: Int
        let distTiro: Int
        let reingaggi: Int
        let disingaggi: Int
        let concluso: Bool
        let modo: String
    }

    /// La provenienza delle perdite su TUTTE le battaglie che il programma genera: gli
    /// scontri del banco, sotto i due regimi dei vantaggi nascosti come nel resto del
    /// rapporto, e le trentadue sessioni complete di battaglia. Ogni battaglia è
    /// rigiocata identica dal medesimo tattico del Motore e la provenienza si legge dallo
    /// stato che il gioco produce (incarico 09, quarto).
    func provenienzaDiTutteLeBattaglie(valori: ValoriDiGioco,
                                       scenari: [ScenarioDiVerifica]) throws -> [RigaProvenienza] {
        var righe: [RigaProvenienza] = []

        // Famiglia "scontri": ogni scenario, ogni configurazione, sotto i due regimi.
        for accesi in [true, false] {
            let sostituzioni = accesi ? [] : ValoriVariati.vantaggiSpenti
            try ValoriVariati.con(base: cartellaValori, sostituendo: sostituzioni) { valoriV in
                let motore = MotoreBattaglia(valori: valoriV)
                let prov = ProvenienzaBattaglia(motore: motore)
                let ufficiali = valoriV.ufficiali.keys.sorted()
                for scenario in scenari {
                    for config in BancoScontri.configurazioni(di: scenario, ufficiali: ufficiali)
                    where config.vantaggiAccesi == accesi {
                        let sb = ScenarioBattaglia(
                            formato: scenario.formato, caratteristica: scenario.caratteristica,
                            ostacoli: scenario.ostacoli, primoOccupante: config.primoOccupante,
                            imboscata: config.imboscata,
                            deckGiocatore: scenario.deckGiocatore, deckAvversario: scenario.deckAvversario,
                            ufficialeAvversario: config.ufficialeAvversario)
                        let stato = try FabbricaBattaglia.crea(scenario: sb, valori: valoriV).0
                        let uG = valoriV.ufficiali[config.ufficialeGiocatore]!
                        let uA = valoriV.ufficiali[config.ufficialeAvversario]!
                        let tattici: [Parte: TatticoBattaglia] = [
                            .giocatore: TatticoBattaglia(motore: motore, ufficiale: uG, parte: .giocatore),
                            .avversario: TatticoBattaglia(motore: motore, ufficiale: uA, parte: .avversario),
                        ]
                        let e = prov.replica(stato: stato, tattici: tattici,
                                             giriMassimi: scenario.giriMassimi)
                        let etichetta = [scenario.identificatore, config.primoOccupante.rawValue,
                                         config.ufficialeGiocatore, config.ufficialeAvversario,
                                         accesi ? "vantaggi" : "spenti",
                                         config.imboscata ? "imboscata" : "aperto"].joined(separator: "|")
                        righe.append(rigaProvenienza(famiglia: "scontri", etichetta: etichetta, esito: e))
                    }
                }
            }
        }

        // Famiglia "sessioni": le trentadue sessioni complete di battaglia.
        let motoreBase = MotoreBattaglia(valori: valori)
        let provBase = ProvenienzaBattaglia(motore: motoreBase)
        let ufficiali = valori.ufficiali.keys.sorted()
        for composizione in composizioniDiMazzo(scenari: scenari) {
            for primo in [Parte.giocatore, .avversario] {
                for ufficiale in ufficiali {
                    for imboscata in [false, true] {
                        let sb = ScenarioBattaglia(
                            formato: scenari[0].formato, caratteristica: scenari[0].caratteristica,
                            primoOccupante: primo, imboscata: imboscata,
                            deckGiocatore: composizione.giocatore, deckAvversario: composizione.avversario,
                            ufficialeAvversario: ufficiale)
                        let stato = try FabbricaBattaglia.crea(scenario: sb, valori: valori).0
                        let u = valori.ufficiali[ufficiale]!
                        let tattici: [Parte: TatticoBattaglia] = [
                            .giocatore: TatticoBattaglia(motore: motoreBase, ufficiale: u, parte: .giocatore),
                            .avversario: TatticoBattaglia(motore: motoreBase, ufficiale: u, parte: .avversario),
                        ]
                        let e = provBase.replica(stato: stato, tattici: tattici,
                                                 giriMassimi: scenari[0].giriMassimi)
                        let etichetta = [composizione.nome, primo.rawValue, ufficiale,
                                         imboscata ? "imboscata" : "aperto"].joined(separator: "|")
                        righe.append(rigaProvenienza(famiglia: "sessioni", etichetta: etichetta, esito: e))
                    }
                }
            }
        }
        return righe
    }

    private func rigaProvenienza(famiglia: String, etichetta: String,
                                 esito e: ProvenienzaBattaglia.Esito) -> RigaProvenienza {
        RigaProvenienza(
            famiglia: famiglia, etichetta: etichetta,
            tiroG: e.perditeTiro[.giocatore] ?? 0, tiroA: e.perditeTiro[.avversario] ?? 0,
            mischiaG: e.perditeMischia[.giocatore] ?? 0, mischiaA: e.perditeMischia[.avversario] ?? 0,
            distMischia: e.distruzioniInMischia, distTiro: e.distruzioniInTiro,
            reingaggi: e.reingaggi, disingaggi: e.disingaggi,
            concluso: e.concluso, modo: e.modo)
    }

    /// Il blocco unico dei numeri della mischia. I totali li somma il programma, e la
    /// prova `MisuraMischiaTest` li pareggia con le righe di dettaglio (RDA-71).
    func riepilogoMischia(fotografia: [BanchiDiMisura.CorsaMischia],
                          accoppiamenti: [BanchiDiMisura.CorsaMischia],
                          accerchiata: [BanchiDiMisura.MischiaAccerchiata],
                          provenienze: [RigaProvenienza],
                          soglieReali: [IdentificatoreDati: Scalato?]) -> Rapporto.Sezione {
        var voci: [[String]] = []
        func voce(_ nome: String, _ valore: Int) { voci.append([nome, String(valore)]) }

        // Primo: la fotografia (soglia attiva).
        voce("accoppiamenti_totali", fotografia.count)
        func conta(_ righe: [BanchiDiMisura.CorsaMischia], _ esito: String) -> Int {
            righe.filter { $0.esito == esito }.count
        }
        let disingaggi = fotografia.filter { $0.chiSiSfila != "" }
        voce("fotografia_disingaggio", disingaggi.count)
        voce("fotografia_disfatta_bersaglio", conta(fotografia, "disfatta_bersaglio"))
        voce("fotografia_disfatta_attaccante", conta(fotografia, "disfatta_attaccante"))
        voce("fotografia_disfatta_reciproca", conta(fotografia, "disfatta_reciproca"))
        voce("fotografia_tetto", conta(fotografia, "tetto"))
        let durata = Distribuzione(fotografia.map(\.scambi))
        voce("contatto_scambi_minimo", durata.minimo)
        voce("contatto_scambi_mediana", durata.mediana)
        voce("contatto_scambi_massimo", durata.massimo)
        voce("contatto_scambi_media", durata.media)
        let perditeSfila = Distribuzione(disingaggi.map { Int($0.perditeChiSiSfilaPermille) })
        voce("disingaggio_perdite_permille_minimo", perditeSfila.minimo)
        voce("disingaggio_perdite_permille_mediana", perditeSfila.mediana)
        voce("disingaggio_perdite_permille_massimo", perditeSfila.massimo)
        voce("disingaggio_perdite_permille_media", perditeSfila.media)

        // Secondo e terzo: distruzione a soglia disattivata.
        voce("distruzione_bersaglio_conteggio", conta(accoppiamenti, "disfatta_bersaglio"))
        voce("distruzione_attaccante_conteggio", conta(accoppiamenti, "disfatta_attaccante"))
        voce("distruzione_reciproca_conteggio", conta(accoppiamenti, "disfatta_reciproca"))
        voce("distruzione_tetto_conteggio", conta(accoppiamenti, "tetto"))
        let scattaPrima = accoppiamenti.filter {
            $0.turnoSogliaBersaglio > 0
                && ($0.turnoDistruzioneBersaglio == 0 || $0.turnoSogliaBersaglio < $0.turnoDistruzioneBersaglio)
        }.count
        voce("accoppiamenti_soglia_scatta_prima_della_distruzione", scattaPrima)
        let divari = accoppiamenti.compactMap { c -> Int? in
            (c.turnoDistruzioneBersaglio > 0 && c.turnoSogliaBersaglio > 0)
                ? c.turnoDistruzioneBersaglio - c.turnoSogliaBersaglio : nil
        }
        let distribuzioneDivari = Distribuzione(divari)
        voce("divario_soglia_distruzione_minimo", distribuzioneDivari.minimo)
        voce("divario_soglia_distruzione_mediana", distribuzioneDivari.mediana)
        voce("divario_soglia_distruzione_massimo", distribuzioneDivari.massimo)

        // Quinto: modificatori congiunti.
        voce("accerchiamento_scambi_distruzione_uno_assalitore",
             accerchiata.first { $0.assalitori == 1 }?.scambiPerDistruggere ?? 0)
        voce("accerchiamento_scambi_distruzione_massimo_assalitori",
             accerchiata.last?.scambiPerDistruggere ?? 0)

        // Quarto: provenienza delle perdite su tutte le battaglie generate.
        voce("battaglie_generate_totali", provenienze.count)
        let tiro = provenienze.reduce(Int64(0)) { $0 + $1.tiroG + $1.tiroA }
        let mischia = provenienze.reduce(Int64(0)) { $0 + $1.mischiaG + $1.mischiaA }
        let totale = tiro + mischia
        voce("perdite_da_tiro_totali", Int(tiro))
        voce("perdite_da_mischia_totali", Int(mischia))
        voce("perdite_totali", Int(totale))
        voce("perdite_da_tiro_permille", Int(totale > 0 ? tiro * 1000 / totale : 0))
        voce("perdite_da_mischia_permille", Int(totale > 0 ? mischia * 1000 / totale : 0))
        voce("battaglie_senza_distruzione_in_mischia",
             provenienze.filter { $0.distMischia == 0 }.count)
        voce("battaglie_con_distruzione_in_mischia",
             provenienze.filter { $0.distMischia > 0 }.count)
        // Regola del secondo contatto (01 §9.8.3): quanto è esercitata e quanti disingaggi
        // automatici avvengono in tutte le battaglie generate (incarico 10).
        voce("reingaggi_totali", provenienze.reduce(0) { $0 + $1.reingaggi })
        voce("disingaggi_automatici_totali", provenienze.reduce(0) { $0 + $1.disingaggi })
        voce("battaglie_con_almeno_un_reingaggio", provenienze.filter { $0.reingaggi > 0 }.count)

        return Rapporto.Sezione(nome: "mischia_riepilogo",
                                intestazione: ["voce", "valore"], righe: voci)
    }
}
