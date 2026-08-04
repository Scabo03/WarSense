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

        var righeInvarianti: [[String]] = []
        let giornate = fumo ? min(4, scenari.giornateGenerate) : scenari.giornateGenerate
        for voce in scenari.scenari {
            let corsa = try banco.corri(voce, giornate: giornate)
            righeInvarianti.append([corsa.identificatore, corsa.mappa, String(corsa.gruppi),
                                    String(corsa.giornate), String(corsa.ordini),
                                    String(corsa.marce), String(corsa.presidi),
                                    String(corsa.violazioni.count),
                                    corsa.violazioni.joined(separator: ";"),
                                    corsa.improntaFinale])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_invarianti",
            intestazione: ["scenario", "mappa", "gruppi", "giornate", "ordini", "marce",
                           "presidi", "violazioni", "dettaglio", "impronta_finale"],
            righe: righeInvarianti))

        var righePassi: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            for gruppi in scenari.gruppiPerLaMisuraDeiPassi {
                guard let passi = try banco.misuraPassi(mappa: mappa, gruppi: gruppi) else { continue }
                righePassi.append([mappa, String(passi.gruppi), String(passi.conIlSalto),
                                   String(passi.senzaIlSalto),
                                   String(passi.senzaIlSalto - passi.conIlSalto)])
            }
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_passi_per_giornata",
            intestazione: ["mappa", "gruppi", "con_il_salto", "senza_il_salto", "scarto"],
            righe: righePassi))

        var righeAttraversamento: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            guard let misura = try banco.misuraAttraversamento(mappa: mappa) else { continue }
            righeAttraversamento.append([misura.mappa, misura.formato, String(misura.lato),
                                         String(misura.distanza), String(misura.giornate)])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_attraversamento",
            intestazione: ["mappa", "formato", "lato", "distanza_in_caselle", "giornate"],
            righe: righeAttraversamento))

        var righeRaggiungibili: [[String]] = []
        for mappa in banco.valoriCampagna.mappe.keys.sorted() {
            guard let misura = try banco.misuraRaggiungibili(mappa: mappa) else { continue }
            let d = misura.distribuzione
            righeRaggiungibili.append([misura.mappa, String(d.quanti), String(d.minimo),
                                       String(d.mediana), String(d.massimo), String(d.media),
                                       String(misura.caselleDiBordo)])
        }
        sezioni.append(Rapporto.Sezione(
            nome: "campagna_caselle_raggiungibili",
            intestazione: ["mappa", "caselle", "minimo", "mediana", "massimo", "media",
                           "caselle_sotto_quattro"],
            righe: righeRaggiungibili))

        return sezioni
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
