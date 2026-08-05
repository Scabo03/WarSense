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
        if let cartellaScenariCampagna {
            let scenariCampagna = try ScenariCampagna.carica(da: cartellaScenariCampagna)
            let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
            let banco = BancoCampagna(
                motore: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                valoriCampagna: valoriCampagna, scenari: scenariCampagna)
            for sezione in try sezioniDiCampagna(banco: banco, scenari: scenariCampagna) {
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
        let corse = try scenari.scenari.map { try banco.corri($0, giornate: giornate) }
        var righeInvarianti: [[String]] = []
        for corsa in corse {
            righeInvarianti.append([corsa.identificatore, corsa.mappa, String(corsa.gruppi),
                                    String(corsa.giornate), String(corsa.ordini),
                                    String(corsa.marce), String(corsa.presidi),
                                    String(corsa.senzaDestinazione),
                                    String(corsa.violazioni.count),
                                    corsa.violazioni.joined(separator: ";"),
                                    corsa.improntaFinale])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_invarianti",
            intestazione: ["scenario", "mappa", "gruppi", "giornate", "ordini", "marce",
                           "presidi", "senza_destinazione", "violazioni", "dettaglio",
                           "impronta_finale"],
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
        let violazioni = righeInvarianti.reduce(0) { $0 + (Int($1[8]) ?? 0) }
        voce("violazioni_trovate_in_totale", violazioni)
        voce("ordini_a_gruppi_senza_alcuna_destinazione",
             righeInvarianti.reduce(0) { $0 + (Int($1[7]) ?? 0) })
        voce("gruppi_minimo_nelle_giornate_generate", perGruppi.keys.min() ?? 0)
        voce("gruppi_massimo_nelle_giornate_generate", perGruppi.keys.max() ?? 0)
        voce("invarianti_sorvegliati", SondaInvariantiCampagna.codiciNoti.count)
        voce("formati_di_mappa", banco.valoriCampagna.formatiMappa.count)
        voce("mappe_disponibili", banco.valoriCampagna.mappe.count)
        voce("costo_in_giorni_dello_scatto", banco.valoriCampagna.marcia.costoGiorniBase)
        voce("gruppi_minimo_nella_misura_dei_passi", scenari.gruppiPerLaMisuraDeiPassi.min() ?? 0)
        voce("gruppi_massimo_nella_misura_dei_passi", scenari.gruppiPerLaMisuraDeiPassi.max() ?? 0)
        voce("disposizioni_nella_misura_dei_passi", BancoCampagna.Disposizione.allCases.count)
        return Rapporto.Sezione(nome: "campagna_riepilogo",
                                intestazione: ["voce", "valore"], righe: voci)
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
}
