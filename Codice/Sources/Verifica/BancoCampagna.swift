import Foundation
import Dati
import Motore

/// Gli scenari di campagna del programma di verifica, dichiarativi come quelli di
/// scontro (05 §12.2): aggiungere un caso da misurare non richiede di toccare il
/// programma. La variazione non viene da semi — la campagna di questa unità non
/// contiene alcuna estrazione del caso, esattamente come la battaglia (RDA-59) —
/// ma dagli scenari e dal numero dei gruppi.
public struct ScenariCampagna: Codable, Sendable {
    public struct Voce: Codable, Sendable {
        public let identificatore: IdentificatoreDati
        public let mappa: IdentificatoreDati
        public let gruppi: [ScenarioCampagna.GruppoIniziale]
    }
    /// Quante giornate generare per ciascuno scenario.
    public let giornateGenerate: Int
    /// I conteggi di gruppi su cui si misura il costo di chiusura della giornata.
    public let gruppiPerLaMisuraDeiPassi: [Int]
    public let scenari: [Voce]

    enum CodingKeys: String, CodingKey {
        case giornateGenerate = "giornate_generate"
        case gruppiPerLaMisuraDeiPassi = "gruppi_per_la_misura_dei_passi"
        case scenari
    }

    public static func carica(da cartella: URL) throws -> ScenariCampagna {
        let url = cartella.appendingPathComponent("campagne.json")
        guard let dati = try? Data(contentsOf: url) else {
            throw ErroreDati(chiave: "errore.dati.file_mancante", file: url.lastPathComponent)
        }
        do { return try JSONDecoder().decode(ScenariCampagna.self, from: dati) }
        catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: url.lastPathComponent) }
    }
}

/// Il banco di misura della campagna: genera giornate in modo deterministico e
/// riproducibile, sorveglia gli invarianti a ogni passo e prende le misure.
///
/// Non contiene alcuna regola propria: ogni esito viene dal Motore, come il banco
/// degli scontri (05 §12.1). Ciò che aggiunge è la CONDOTTA con cui si generano le
/// giornate, che è deterministica per costruzione: ogni gruppo in attesa riceve un
/// ordine scelto da una regola fissa, mai da un'estrazione.
public struct BancoCampagna: Sendable {
    public let motore: MotoreCampagna
    public let valoriCampagna: ValoriCampagna
    public let scenari: ScenariCampagna
    private let sonda = SondaInvariantiCampagna()

    public init(motore: MotoreCampagna, valoriCampagna: ValoriCampagna, scenari: ScenariCampagna) {
        self.motore = motore
        self.valoriCampagna = valoriCampagna
        self.scenari = scenari
    }

    // MARK: - Generazione deterministica delle giornate

    /// L'esito di una corsa: quante giornate, quanti ordini, quali violazioni.
    public struct Corsa: Sendable {
        public let identificatore: IdentificatoreDati
        public let mappa: IdentificatoreDati
        public let gruppi: Int
        public let giornate: Int
        public let ordini: Int
        public let marce: Int
        public let presidi: Int
        public let violazioni: [String]
        public let improntaFinale: String
    }

    /// La condotta: per ciascun gruppo in attesa, la prima destinazione valida
    /// nell'ordine di lettura se ne esiste una, altrimenti il presidio; il gruppo
    /// da ordinare è sempre quello che il salto diretto propone. È la stessa
    /// sequenza che compirebbe un giocatore che si affida al salto, ed è la
    /// ragione per cui la misura dei passi dice qualcosa di reale.
    ///
    /// Ogni tanto si ordina il presidio anche potendo marciare, secondo una regola
    /// fissa sul numero della giornata: senza, i gruppi si accalcherebbero tutti
    /// verso nord e la misura vedrebbe una sola situazione.
    public func corri(_ voce: ScenariCampagna.Voce, giornate: Int) throws -> Corsa {
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: voce.mappa, gruppiGiocatore: voce.gruppi),
            valori: valoriCampagna)
        var violazioni = Set<String>()
        var ordini = 0, marce = 0, presidi = 0
        violazioni.formUnion(sonda.controlla(stato: stato).map(\.description))

        let giornoIniziale = stato.giorno
        var passiDiSicurezza = 0
        while stato.giorno < giornoIniziale + giornate {
            passiDiSicurezza += 1
            guard passiDiSicurezza <= giornate * (voce.gruppi.count + 2) + 10 else { break }
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)

            // L'invariante del salto si controlla percorrendolo davvero, con la
            // sequenza che la Presentazione userebbe.
            violazioni.formUnion(sonda.controllaSalto(stato: stato,
                                                      sequenza: sequenzaDelSalto(vista, stato))
                .map(\.description))

            guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { break }
            let destinazioni = vista.destinazioniValide(per: gruppo.id)
            // Regola fissa: si presidia quando la giornata è multipla di tre, o
            // quando non esiste alcuna destinazione. Deterministica, senza caso.
            let comando: ComandoCampagna
            if destinazioni.isEmpty || stato.giorno % 3 == 0 {
                comando = .presidio(gruppo: gruppo.id)
                presidi += 1
            } else {
                comando = .marcia(gruppo: gruppo.id,
                                  a: destinazioni[gruppo.id.numero % destinazioni.count])
                marce += 1
            }
            let prima = stato
            let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
            violazioni.formUnion(sonda.controlla(prima: prima, comando: comando, dopo: dopo,
                                                 eventi: eventi,
                                                 adiacenti: prima.griglia.adiacenti).map(\.description))
            violazioni.formUnion(sonda.controlla(stato: dopo).map(\.description))
            stato = dopo
            ordini += 1
        }

        violazioni.formUnion(sonda.controllaRaggiungibilita(
            griglia: stato.griglia, da: Cella(riga: 1, colonna: 1),
            vicini: stato.griglia.vicini).map(\.description))

        return Corsa(identificatore: voce.identificatore, mappa: voce.mappa,
                     gruppi: voce.gruppi.count, giornate: stato.giorno - giornoIniziale,
                     ordini: ordini, marce: marce, presidi: presidi,
                     violazioni: violazioni.sorted(), improntaFinale: stato.impronta())
    }

    /// La sequenza che il salto diretto propone percorrendolo fino a tornare al
    /// primo: è ciò che il giocatore ottiene ripetendo il gesto.
    public func sequenzaDelSalto(_ vista: VistaCampagna, _ stato: StatoCampagna) -> [IdGruppo] {
        var sequenza: [IdGruppo] = []
        var corrente: Cella? = nil
        let quanti = stato.gruppiInAttesa().count
        for _ in 0..<quanti {
            guard let prossimo = vista.prossimoGruppoInAttesa(dopo: corrente) else { break }
            sequenza.append(prossimo.id)
            corrente = prossimo.posizione
        }
        return sequenza
    }

    // MARK: - Misura: passi per chiudere una giornata

    /// Quanti passi costa chiudere una giornata al crescere del numero dei gruppi.
    /// È la misura più importante, perché è il costo che paga chi ascolta invece
    /// di guardare: chi guarda vede tutta la mappa in un colpo d'occhio.
    ///
    /// Il modello dei passi è dichiarato ed è il seguente. Con il salto diretto,
    /// ordinare un gruppo costa tre passi: il gesto di salto, l'attivazione della
    /// casella, la scelta della voce nel pannello. Senza il salto, al posto del
    /// gesto di salto occorre percorrere a scorrimenti la distanza nell'ordine di
    /// lettura fra la casella dove si è e quella del gruppo successivo. Il conteggio
    /// riguarda il presidio, che è l'azione più breve: isola così il costo della
    /// NAVIGAZIONE, che è ciò che la misura vuole vedere.
    public struct Passi: Sendable {
        public let gruppi: Int
        public let mappa: IdentificatoreDati
        public let conIlSalto: Int
        public let senzaIlSalto: Int
    }

    static let passiPerOrdine = 2 // attivazione della casella, scelta della voce
    static let passiDelSalto = 1

    public func misuraPassi(mappa identificatore: IdentificatoreDati,
                            gruppi: Int) throws -> Passi? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        // I gruppi si dispongono a distanza pari lungo l'ordine di lettura, dalla
        // prima all'ultima casella: disposizione fissa, ripetibile e rappresentativa
        // del caso reale, in cui esploratori, colonna principale e distaccamenti
        // stanno in punti diversi della mappa. Ammassarli in un angolo darebbe una
        // misura più favorevole al solo scorrimento di quanto la partita non sia.
        let griglia = GrigliaCampagna(righe: formato.righe, colonne: formato.colonne)
        let tutte = griglia.tutteLeCaselle
        guard gruppi >= 1, gruppi <= tutte.count else { return nil }
        let caselle: [Cella] = gruppi == 1
            ? [tutte[tutte.count / 2]]
            : (0..<gruppi).map { tutte[$0 * (tutte.count - 1) / (gruppi - 1)] }
        guard Set(caselle).count == gruppi else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: caselle.map { .init(riga: $0.riga, colonna: $0.colonna) }),
            valori: valoriCampagna)

        let ordine = griglia.tutteLeCaselle
        func indice(_ casella: Cella) -> Int { ordine.firstIndex(of: casella) ?? 0 }
        let posizioni = stato.gruppiInAttesa().map(\.posizione)

        let conIlSalto = gruppi * (Self.passiDelSalto + Self.passiPerOrdine)
        // Senza il salto si parte dalla prima casella della mappa e si scorre.
        var senza = 0
        var corrente = 0
        for posizione in posizioni {
            senza += abs(indice(posizione) - corrente) + Self.passiPerOrdine
            corrente = indice(posizione)
        }
        return Passi(gruppi: gruppi, mappa: identificatore,
                     conIlSalto: conIlSalto, senzaIlSalto: senza)
    }

    // MARK: - Misura: giornate per attraversare la mappa

    /// Quante giornate servono ad attraversare la mappa, dal proprio quartier
    /// generale a quello avversario, marciando ogni giorno. Si gioca davvero: il
    /// numero esce dalle regole e non da una formula scritta qui.
    public struct Attraversamento: Sendable {
        public let mappa: IdentificatoreDati
        public let formato: IdentificatoreDati
        public let lato: Int
        public let distanza: Int
        public let giornate: Int
    }

    public func misuraAttraversamento(mappa identificatore: IdentificatoreDati) throws
        -> Attraversamento? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        let partenza = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                             colonna: definizione.quartierGenerali.giocatore.colonna)
        let arrivo = Cella(riga: definizione.quartierGenerali.avversario.riga,
                           colonna: definizione.quartierGenerali.avversario.colonna)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: identificatore,
                                       gruppiGiocatore: [.init(riga: partenza.riga,
                                                               colonna: partenza.colonna)]),
            valori: valoriCampagna)
        let id = stato.gruppiOrdinati[0].id
        let giornoIniziale = stato.giorno
        var passi = 0
        let tetto = stato.griglia.righe * stato.griglia.colonne + 2
        while stato.gruppi[id]!.posizione != arrivo, passi < tetto {
            passi += 1
            let qui = stato.gruppi[id]!.posizione
            // Rotta deterministica: prima si pareggia la riga, poi la colonna.
            let prossima = qui.riga != arrivo.riga
                ? Cella(riga: qui.riga + (arrivo.riga > qui.riga ? 1 : -1), colonna: qui.colonna)
                : Cella(riga: qui.riga, colonna: qui.colonna + (arrivo.colonna > qui.colonna ? 1 : -1))
            guard motore.valida(.marcia(gruppo: id, a: prossima),
                                parte: .giocatore, stato: stato).eValido else { break }
            (stato, _) = motore.applica(.marcia(gruppo: id, a: prossima),
                                        parte: .giocatore, stato: stato)
        }
        return Attraversamento(mappa: identificatore, formato: definizione.formato,
                               lato: formato.righe,
                               distanza: stato.griglia.distanza(partenza, arrivo),
                               giornate: stato.giorno - giornoIniziale)
    }

    // MARK: - Misura: caselle raggiungibili in una giornata

    /// Quante caselle sono raggiungibili in una giornata da ciascuna casella della
    /// mappa. Con una sola azione per gruppo e lo scatto di una casella, sono i
    /// vicini ortogonali liberi: la distribuzione dice quanto la mappa si stringe
    /// ai bordi, che è ciò che chi ascolta deve poter prevedere.
    public struct Raggiungibili: Sendable {
        public let mappa: IdentificatoreDati
        public let distribuzione: Distribuzione
        public let caselleDiBordo: Int
    }

    public func misuraRaggiungibili(mappa identificatore: IdentificatoreDati) throws
        -> Raggiungibili? {
        guard let definizione = valoriCampagna.mappe[identificatore] else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: [.init(riga: definizione.quartierGenerali.giocatore.riga,
                                        colonna: definizione.quartierGenerali.giocatore.colonna)]),
            valori: valoriCampagna)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let conteggi = stato.griglia.tutteLeCaselle.map {
            vista.caselleRaggiungibiliInUnaGiornata(da: $0).count
        }
        return Raggiungibili(mappa: identificatore,
                             distribuzione: Distribuzione(conteggi),
                             caselleDiBordo: conteggi.filter { $0 < 4 }.count)
    }
}
