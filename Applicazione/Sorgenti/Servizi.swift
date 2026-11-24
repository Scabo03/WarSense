import UIKit
import Dati
import Motore
import Segnali
import Contenuti

// I servizi dell'applicazione: ambiente dei dati, impostazioni locali, guardiano
// del fuoco. Nessuna regola di gioco vive qui (00 §3.2); nessuna stringa nel codice.

/// Le impostazioni locali dell'apparecchio (02 §14): mai parte dello stato di partita.
@MainActor
enum Impostazioni {
    private static let archivio = UserDefaults.standard

    static var verbosita: Verbosita {
        get { Verbosita(rawValue: archivio.string(forKey: "verbosita") ?? "") ?? .normale }
        set { archivio.set(newValue.rawValue, forKey: "verbosita") }
    }
    static var suoniAttivi: Bool {
        get { archivio.object(forKey: "suoni_attivi") as? Bool ?? true }
        set { archivio.set(newValue, forKey: "suoni_attivi") }
    }
    static var apticaAttiva: Bool {
        get { archivio.object(forKey: "aptica_attiva") as? Bool ?? true }
        set { archivio.set(newValue, forKey: "aptica_attiva") }
    }
    static var passoIntensita: Int {
        get { archivio.object(forKey: "passo_intensita") as? Int ?? 3 }
        set { archivio.set(newValue, forKey: "passo_intensita") }
    }

    static var preferenzeSegnali: PuntoSegnali.Preferenze {
        PuntoSegnali.Preferenze(
            verbosita: verbosita,
            canali: PreferenzeSegnali(suoniAttivi: suoniAttivi, apticaAttiva: apticaAttiva),
            passoIntensita: passoIntensita)
    }
}

/// L'ambiente dei dati: copia di fabbrica in Documenti al primo avvio (00 §15.4),
/// caricamento da Documenti con ripiego dichiarato sulla fabbrica (05 §7.1).
/// I valori restano fissi per la sessione (05 §7.9).
@MainActor
final class Ambiente {
    let valori: ValoriDiGioco
    /// I valori del piano di campagna: formati, mappe, nomi dei gruppi (05 §7.6).
    let valoriCampagna: ValoriCampagna
    /// I valori del regno: calendario, risorse, voci, fronti (01 §5.5, §5.9; incarico 30).
    let valoriRegno: ValoriRegno
    let testi: Testi
    let segnali: PuntoSegnali
    /// Vero se il caricamento da Documenti è fallito e si è tornati alla fabbrica.
    let ripiegoSuFabbrica: Bool

    static let documenti = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static var cartellaValori: URL { documenti.appendingPathComponent("Valori") }
    static var cartellaTesti: URL { documenti.appendingPathComponent("Testi") }
    static var cartellaPartite: URL { documenti.appendingPathComponent("Partite") }

    init() throws {
        try Ambiente.copiaDiFabbricaSeServe()
        var ripiego = false
        var valoriCaricati: ValoriDiGioco
        do { valoriCaricati = try CaricatoreValori.carica(da: Ambiente.cartellaValori) }
        catch {
            valoriCaricati = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
            ripiego = true
        }
        // I valori di campagna seguono la stessa disciplina: da Documenti, con
        // ripiego dichiarato sulla fabbrica, mai dati misti (05 §7.1).
        var campagnaCaricata: ValoriCampagna
        do { campagnaCaricata = try CaricatoreCampagna.carica(da: Ambiente.cartellaValori) }
        catch {
            campagnaCaricata = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
            ripiego = true
        }
        // I valori del regno seguono la stessa disciplina, e si verificano contro gli archetipi
        // della stessa copia: mai dati misti (05 §7.1).
        var regnoCaricato: ValoriRegno
        do {
            regnoCaricato = try CaricatoreRegno.carica(da: ripiego ? Contenuti.valoriDiFabbrica
                                                                   : Ambiente.cartellaValori,
                                                       archetipiNoti: Set(valoriCaricati.archetipi.keys),
                                                       miglioramentiNoti: Set(valoriCaricati.miglioramenti.keys))
        } catch {
            valoriCaricati = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
            campagnaCaricata = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
            regnoCaricato = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                       archetipiNoti: Set(valoriCaricati.archetipi.keys),
                                                       miglioramentiNoti: Set(valoriCaricati.miglioramenti.keys))
            ripiego = true
        }
        var testiCaricati: Testi
        do { testiCaricati = try Testi.carica(albero: Ambiente.cartellaTesti, lingua: "it") }
        catch {
            testiCaricati = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
            ripiego = true
        }
        let definizioni = try DefinizioniSegnali.carica(
            da: ripiego ? Contenuti.valoriDiFabbrica : Ambiente.cartellaValori)
        self.valori = valoriCaricati
        self.valoriCampagna = campagnaCaricata
        self.valoriRegno = regnoCaricato
        self.testi = testiCaricati
        self.ripiegoSuFabbrica = ripiego
        self.segnali = PuntoSegnali(testi: testiCaricati, definizioni: definizioni,
                                    cartellaSuoni: Contenuti.suoniDiFabbrica,
                                    preferenze: { Impostazioni.preferenzeSegnali })
    }

    /// Copia Valori e Testi in Documenti al primo avvio o quando la fabbrica è più nuova.
    private static func copiaDiFabbricaSeServe() throws {
        let gestore = FileManager.default
        try gestore.createDirectory(at: cartellaPartite, withIntermediateDirectories: true)
        for (sorgente, destinazione) in [(Contenuti.valoriDiFabbrica, cartellaValori),
                                         (Contenuti.testiDiFabbrica, cartellaTesti)] {
            let manifestNuovo = try? Data(contentsOf: sorgente.appendingPathComponent("manifest.json"))
            let manifestEsistente = try? Data(contentsOf: destinazione.appendingPathComponent("manifest.json"))
            if manifestEsistente == nil || manifestEsistente != manifestNuovo {
                try? gestore.removeItem(at: destinazione)
                try gestore.copyItem(at: sorgente, to: destinazione)
            }
        }
    }
}

/// Il guardiano del fuoco (00 §11, 05 §10.3): ogni spostamento del fuoco passa da qui
/// e viene registrato. Le prove leggono il registro: nessuno spostamento non richiesto.
@MainActor
enum Fuoco {
    enum Movimento: Equatable {
        case schermataAperta
        case richiesto
        /// Chiusa una schermata, il fuoco torna sul comando che l'aveva aperta, dove il giocatore
        /// l'aveva lasciato (02 §5.1; incarico 28, osservazione 6 dell'esplorazione dell'incarico 27).
        case schermataChiusa
    }
    private(set) static var registro: [Movimento] = []

    /// Il fuoco si sposta soltanto su richiesta dell'utente o all'apertura di una
    /// schermata nuova. Nessun altro punto del programma pubblica notifiche di fuoco.
    /// L'elemento verso cui il fuoco è stato portato l'ultima volta: è il contenuto stesso della
    /// notifica, conservato come il motivo, perché le prove possano dire DOVE il fuoco è andato e non
    /// solo che si è mosso (incarico 28).
    private(set) static weak var ultimoBersaglio: AnyObject?

    static func sposta(a elemento: Any?, perche movimento: Movimento) {
        registro.append(movimento)
        ultimoBersaglio = elemento as AnyObject?
        // Gli annunci che seguono accompagnano questo spostamento (RDA-183).
        PuntoSegnali.ilFuocoSiSposta()
        UIAccessibility.post(notification: .screenChanged, argument: elemento)
    }

    /// Quanto attendere, chiusa una schermata o un pannello di sistema, prima di chiedere il fuoco o di
    /// mostrare la schermata che lo porterà: tempo d'interfaccia, non numero di gioco (05 §0.4), il
    /// minimo perché VoiceOver abbia concluso la propria rifocalizzazione, che altrimenti scavalca la
    /// richiesta del gioco (incarico 28; incarico 32 per la mappa aperta dalla scelta del fronte).
    static let attesaDelSistema: TimeInterval = 0.4

    /// Un cambio di schermata che il SISTEMA sta per compiere da sé — un pannello che si chiude, una
    /// schermata che si congeda — e a cui seguono degli annunci: si dichiara prima di consegnarli,
    /// senza alcuna notifica di fuoco, perché la lettura di ciò che compare non li tagli (RDA-183).
    static func staPerSpostarsi() { PuntoSegnali.ilFuocoSiSposta() }

    /// Un cambiamento di disposizione che NON sposta il fuoco (aggiornamenti sul posto).
    static func aggiornaDisposizione() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    static func azzeraRegistro() { registro = [] }
}
