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
        /// Le forze nemiche e le strutture dello scenario: dati MINIMI per provare taglio
        /// e zona, non l'avversario e non le opere (incarico 16). Assenti negli scenari
        /// che non li esercitano, e allora vuoti.
        public let forzeNemiche: [Cella]
        public let struttureDiRifornimento: [Cella]

        enum CodingKeys: String, CodingKey {
            case identificatore, mappa, gruppi
            case forzeNemiche = "forze_nemiche"
            case struttureDiRifornimento = "strutture_di_rifornimento"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            identificatore = try c.decode(IdentificatoreDati.self, forKey: .identificatore)
            mappa = try c.decode(IdentificatoreDati.self, forKey: .mappa)
            gruppi = try c.decode([ScenarioCampagna.GruppoIniziale].self, forKey: .gruppi)
            forzeNemiche = try c.decodeIfPresent([Cella].self, forKey: .forzeNemiche) ?? []
            struttureDiRifornimento = try c.decodeIfPresent([Cella].self, forKey: .struttureDiRifornimento) ?? []
        }
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

    /// Le chiavi degli archetipi noti, per la fabbrica (rifiuto dell'archetipo ignoto).
    private var archetipiNoti: Set<IdentificatoreDati> { Set(motore.valori.archetipi.keys) }

    /// La composizione dei gruppi generati dalle misure interne (passi, distanze,
    /// uscite): una fanteria leggera, volume sotto la soglia, così che la misura del
    /// costo di chiusura non dipenda dal volume. La diversità di volume che l'unità
    /// esercita viene dagli scenari di `campagne.json`, non da queste misure.
    static let composizioneDiMisura: [ScenarioCampagna.RepartoIniziale] =
        [.init(archetipo: "fanteria_leggera", atomi: 6)]

    // MARK: - Generazione deterministica delle giornate

    /// L'esito di una corsa: quante giornate, quanti ordini, quali violazioni.
    public struct Corsa: Sendable {
        public let identificatore: IdentificatoreDati
        public let mappa: IdentificatoreDati
        public let gruppi: Int
        public let giornate: Int
        public let ordini: Int
        public let marce: Int
        /// Le marce ordinate che durano più di un giorno (01 §5.6.3.3): il caso che
        /// questa unità introduce. Se zero, la corsa non ha esercitato la marcia lunga.
        public let marceLunghe: Int
        /// Le marce compiutesi alla risoluzione di fine giornata (01 §5.6.11).
        public let marceCompiute: Int
        /// Le revoche impartite (01 §5.6.3.3, RDA-76).
        public let revoche: Int
        public let presidi: Int
        /// Le divisioni e le riunioni generate (01 §5.6.0.2, §5.6.0.3): se zero, la
        /// corsa non le ha esercitate, e gli invarianti relativi non hanno morso.
        public let divisioni: Int
        public let riunioni: Int
        /// Ordini impartiti a un gruppo che NON aveva alcuna destinazione libera:
        /// è il caso di stipamento, quello in cui l'azione di marcia non si offre
        /// affatto (02 §9.5). Se questo numero è zero, la corsa non ha esercitato
        /// lo stipamento, per quanti gruppi vi fossero.
        public let senzaDestinazione: Int
        /// Il volume più piccolo e più grande fra i gruppi dello scenario (01 §5.6.3):
        /// se differiscono, la corsa ha esercitato marce di volumi diversi, cioè il
        /// caso che questa unità introduce. Uguali, i gruppi erano tutti dello stesso
        /// ingombro e la diversità di volume non è stata esercitata.
        public let volumeMinimo: Int
        public let volumeMassimo: Int
        /// I fenomeni del rifornimento generati dalla corsa (01 §5.2.2): se restano a
        /// zero, la corsa non li ha esercitati e gli invarianti relativi non hanno morso.
        /// Il taglio (interruzioni), la sosta IMPOSTA di due turni (fatti non decisi nel
        /// registro), la sosta VOLONTARIA di un turno (ordinata dalla condotta), le
        /// riprese, i turni-gruppo passati in zona e le strutture isolate allo scenario.
        public let tagli: Int
        public let sosteImposte: Int
        public let sosteVolontarie: Int
        public let riprese: Int
        public let passaggiInZona: Int
        public let struttureIsolate: Int
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
            scenario: ScenarioCampagna(mappa: voce.mappa, gruppiGiocatore: voce.gruppi,
                                       forzeNemiche: voce.forzeNemiche,
                                       struttureDiRifornimento: voce.struttureDiRifornimento),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
        var violazioni = Set<String>()
        var ordini = 0, marce = 0, marceLunghe = 0, marceCompiute = 0, revoche = 0
        var presidi = 0, senzaDestinazione = 0, divisioni = 0, riunioni = 0
        // I fenomeni del rifornimento. Le soste VOLONTARIE le conta la condotta (è lei a
        // ordinarle); il taglio, la sosta imposta e le riprese si leggono dal registro
        // alla fine, perché sono i fatti non decisi che vi si annotano. I turni-gruppo in
        // zona si contano a ogni giornata. Le strutture isolate si contano allo scenario.
        var sosteVolontarie = 0, passaggiInZona = 0
        // La tabella dei volumi per atomo, per l'invariante del volume come somma.
        let volumePerAtomo = motore.valori.archetipi.mapValues { $0.volumePerAtomo }
        // I volumi dei gruppi (costanti in questa unità: la composizione non muta).
        let volumi = stato.gruppiOrdinati.map { motore.volume(di: $0) }
        let volumeMinimo = Int(volumi.min() ?? 0)
        let volumeMassimo = Int(volumi.max() ?? 0)
        violazioni.formUnion(sonda.controlla(stato: stato).map(\.description))

        let giornoIniziale = stato.giorno
        var passiDiSicurezza = 0
        while stato.giorno < giornoIniziale + giornate {
            passiDiSicurezza += 1
            guard passiDiSicurezza <= giornate * (voce.gruppi.count + 4) + 10 else { break }
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)

            // I turni-gruppo passati in una zona di rifornimento: si contano a ogni
            // giro, così che il fenomeno risulti esercitato quando esiste una struttura.
            passaggiInZona += stato.gruppi(di: .giocatore).lazy.filter {
                motore.inZonaDiRifornimento($0.posizione, stato: stato) }.count

            // L'invariante del salto si controlla percorrendolo davvero, con la
            // sequenza che la Presentazione userebbe.
            violazioni.formUnion(sonda.controllaSalto(stato: stato,
                                                      sequenza: sequenzaDelSalto(vista, stato))
                .map(\.description))
            // L'invariante della posizione visiva: le posizioni mostrate sono quelle
            // che la Presentazione disegnerebbe, cioè la funzione pura del Motore.
            let mostrate = Dictionary(uniqueKeysWithValues: stato.gruppiInMarcia().map {
                ($0.id, motore.avanzamentoVisivo(giorniCompiuti: $0.marcia!.giorniCompiuti,
                                                 giorniTotali: $0.marcia!.giorniTotali))
            })
            violazioni.formUnion(sonda.controllaPosizioniVisive(
                stato: stato, posizioni: valoriCampagna.marcia.posizioniVisive,
                mostrate: mostrate).map(\.description))

            // La condotta: ogni tanto si REVOCA una marcia in corso, secondo una
            // regola fissa sul giorno, per esercitare la revoca e i suoi invarianti;
            // altrimenti si ordina il prossimo gruppo in attesa, con la prima
            // destinazione valida o il presidio. Deterministica, senza caso.
            let comando: ComandoCampagna
            // La riunione (non è un'azione): ogni tanto due gruppi adiacenti si
            // fondono, purché ne restino almeno due, così da esercitare la regola
            // dell'azione già spesa senza far collassare lo scenario a un gruppo solo.
            if stato.giorno % 4 == 1, stato.gruppi.count > 2,
               let (a, b) = coppiaRiunibile(stato) {
                comando = .riunione(gruppo: a, con: b)
                riunioni += 1
            // La divisione (costa l'azione): ogni tanto un gruppo divisibile stacca il
            // primo reparto in una casella libera, se un nome è disponibile.
            } else if stato.giorno % 7 == 3,
                      let (g, staccati, dest) = divisionePossibile(vista, stato) {
                comando = .divisione(gruppo: g, repartiStaccati: staccati, a: dest)
                divisioni += 1
            } else if stato.giorno % 5 == 2, let marciante = stato.gruppiInMarcia().first {
                comando = .revocaMarcia(gruppo: marciante.id)
                revoche += 1
            } else {
                guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { break }
                // Rifornimento (01 §5.2.2). Un gruppo che DEVE rifornirsi si ferma a
                // rifornirsi: è l'unica azione possibile, e la sosta non si elude. Un
                // gruppo senza provviste, ogni tanto, si ferma di propria iniziativa: è
                // la sosta VOLONTARIA di un turno (autonomia). Un gruppo col rifornimento
                // TAGLIATO presidia, così il taglio matura invece di essere aggirato
                // marciando via — è ciò che fa emergere il taglio, la sosta imposta e la
                // ripresa in modo deterministico, qualunque cosa faccia il resto.
                if gruppo.deveRifornirsi {
                    comando = .sostaConRaccolta(gruppo: gruppo.id)
                } else if gruppo.turniSenzaProvviste == 1, stato.giorno % 3 == 0 {
                    comando = .sostaConRaccolta(gruppo: gruppo.id)
                    sosteVolontarie += 1
                } else if motore.rifornimentoTagliato(di: gruppo, stato: stato) {
                    comando = .presidio(gruppo: gruppo.id)
                    presidi += 1
                } else {
                    let destinazioni = vista.destinazioniValide(per: gruppo.id)
                    if destinazioni.isEmpty { senzaDestinazione += 1 }
                    if destinazioni.isEmpty || stato.giorno % 3 == 0 {
                        comando = .presidio(gruppo: gruppo.id)
                        presidi += 1
                    } else {
                        let destinazione = destinazioni[gruppo.id.numero % destinazioni.count]
                        // Il comando lo forma l'interrogazione, che vi mette il costo in
                        // giorni prescritto dai dati: nemmeno il banco lo inventa.
                        comando = vista.comandoDiMarcia(per: gruppo.id, a: destinazione)!
                        if case .marcia(_, _, let giorni) = comando, giorni > 1 { marceLunghe += 1 }
                        marce += 1
                    }
                }
            }
            let prima = stato
            let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
            marceCompiute += eventi.reduce(0) {
                if case .marciaCompiuta = $1 { return $0 + 1 } else { return $0 }
            }
            violazioni.formUnion(sonda.controlla(prima: prima, comando: comando, dopo: dopo,
                                                 eventi: eventi,
                                                 adiacenti: prima.griglia.adiacenti).map(\.description))
            violazioni.formUnion(sonda.controlla(stato: dopo).map(\.description))
            // L'invariante del volume come somma: il volume riportato è quello che il
            // Motore calcola, la sonda ne verifica la coincidenza con la composizione.
            let volumiRiportati = Dictionary(uniqueKeysWithValues:
                dopo.gruppiOrdinati.map { ($0.id, motore.volume(di: $0)) })
            violazioni.formUnion(sonda.controllaVolumi(
                stato: dopo, volumePerAtomo: volumePerAtomo,
                volumiRiportati: volumiRiportati).map(\.description))
            stato = dopo
            ordini += 1
        }

        violazioni.formUnion(sonda.controllaRaggiungibilita(
            griglia: stato.griglia, da: Cella(riga: 1, colonna: 1),
            vicini: stato.griglia.vicini).map(\.description))

        // Il taglio, la sosta imposta e la ripresa sono i fatti NON decisi che il
        // registro annota (01 §5.17.1): li si conta di là, non dagli eventi, così che
        // la sosta VOLONTARIA — che è un ordine e non si annota — non vi si confonda.
        var tagli = 0, sosteImposte = 0, riprese = 0
        for voce in stato.registro {
            switch voce.fatto {
            case .rifornimentoInterrotto: tagli += 1
            case .sostaDiRifornimento: sosteImposte += 1
            case .rifornimentoRipreso: riprese += 1
            default: break
            }
        }
        // Le strutture ISOLATE allo scenario: nessun proprio gruppo, all'inizio, nelle
        // nove caselle della zona (01 §5.2.2.7). Riforniscono comunque, e la prova che
        // la corsa le esercita è che esistono e che i turni-gruppo in zona sono positivi.
        let posizioniIniziali = Set(voce.gruppi.map { Cella(riga: $0.riga, colonna: $0.colonna) })
        let struttureIsolate = voce.struttureDiRifornimento.filter { struttura in
            !posizioniIniziali.contains { max(abs($0.riga - struttura.riga),
                                              abs($0.colonna - struttura.colonna)) <= 1 }
        }.count

        return Corsa(identificatore: voce.identificatore, mappa: voce.mappa,
                     gruppi: voce.gruppi.count, giornate: stato.giorno - giornoIniziale,
                     ordini: ordini, marce: marce, marceLunghe: marceLunghe,
                     marceCompiute: marceCompiute, revoche: revoche, presidi: presidi,
                     divisioni: divisioni, riunioni: riunioni,
                     senzaDestinazione: senzaDestinazione,
                     volumeMinimo: volumeMinimo, volumeMassimo: volumeMassimo,
                     tagli: tagli, sosteImposte: sosteImposte, sosteVolontarie: sosteVolontarie,
                     riprese: riprese, passaggiInZona: passaggiInZona,
                     struttureIsolate: struttureIsolate,
                     violazioni: violazioni.sorted(), improntaFinale: stato.impronta())
    }

    /// Due gruppi propri adiacenti e NON in marcia, per la riunione, il primo per id.
    /// La riunione lavora su qualunque coppia adiacente, quale che sia lo stato
    /// dell'azione: è così che si esercita la regola «già agito se uno lo era».
    private func coppiaRiunibile(_ stato: StatoCampagna) -> (IdGruppo, IdGruppo)? {
        let gruppi = stato.gruppiOrdinati.filter { !$0.inMarcia }
        for i in gruppi.indices {
            for j in gruppi.indices
            where j > i && stato.griglia.adiacenti(gruppi[i].posizione, gruppi[j].posizione) {
                return (gruppi[i].id, gruppi[j].id)
            }
        }
        return nil
    }

    /// Un gruppo in attesa con almeno due reparti, una casella libera adiacente e un
    /// nome disponibile: stacca il PRIMO reparto verso quella casella. La casella
    /// libera si prende da `destinazioniValide`, cioè le adiacenti libere e non già
    /// puntate — lo stesso vincolo del distaccamento (01 §5.6.0.2).
    private func divisionePossibile(_ vista: VistaCampagna,
                                    _ stato: StatoCampagna) -> (IdGruppo, [Int], Cella)? {
        guard stato.prossimoIndiceNome < valoriCampagna.nomiGruppi.count else { return nil }
        for gruppo in stato.gruppiInAttesa() where gruppo.composizione.count >= 2 {
            if let dest = vista.destinazioniValide(per: gruppo.id).first {
                return (gruppo.id, [0], dest)
            }
        }
        return nil
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
    /// Come i gruppi stanno sulla mappa quando la misura è presa. Le due
    /// disposizioni non sono un dettaglio: la prima giornata di una campagna ha i
    /// gruppi tutti presso il quartier generale, e dopo qualche giornata di marcia
    /// li ha sparsi. Se il costo dipendesse dalla dispersione e non dal numero, una
    /// misura sola non lo direbbe.
    public enum Disposizione: String, Sendable, CaseIterable {
        /// Ammassati intorno al proprio quartier generale, nell'ordine di lettura.
        case raccolti
        /// A distanza pari lungo l'ordine di lettura, dalla prima all'ultima casella.
        case sparpagliati
    }

    public struct Passi: Sendable {
        public let gruppi: Int
        public let mappa: IdentificatoreDati
        public let disposizione: Disposizione
        public let conIlSalto: Int
        public let senzaIlSalto: Int
    }

    static let passiPerOrdine = 2 // attivazione della casella, scelta della voce
    static let passiDelSalto = 1

    /// Le caselle su cui disporre i gruppi, per disposizione. Deterministica: la
    /// stessa richiesta dà sempre le stesse caselle.
    static func caselleDellaDisposizione(_ disposizione: Disposizione, gruppi: Int,
                                         griglia: GrigliaCampagna,
                                         quartierGenerale: Cella) -> [Cella]? {
        let tutte = griglia.tutteLeCaselle
        guard gruppi >= 1, gruppi <= tutte.count else { return nil }
        switch disposizione {
        case .sparpagliati:
            let caselle: [Cella] = gruppi == 1
                ? [tutte[tutte.count / 2]]
                : (0..<gruppi).map { tutte[$0 * (tutte.count - 1) / (gruppi - 1)] }
            return Set(caselle).count == gruppi ? caselle : nil
        case .raccolti:
            // Le più vicine al proprio quartier generale, a parità di distanza
            // nell'ordine di lettura: è la configurazione di apertura di campagna.
            let caselle = tutte.sorted {
                let da = griglia.distanza(quartierGenerale, $0)
                let db = griglia.distanza(quartierGenerale, $1)
                return da == db ? $0 < $1 : da < db
            }.prefix(gruppi)
            return Array(caselle).sorted()
        }
    }

    public func misuraPassi(mappa identificatore: IdentificatoreDati, gruppi: Int,
                            disposizione: Disposizione) throws -> Passi? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        let griglia = GrigliaCampagna(righe: formato.righe, colonne: formato.colonne)
        let quartierGenerale = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                                     colonna: definizione.quartierGenerali.giocatore.colonna)
        guard let caselle = Self.caselleDellaDisposizione(
            disposizione, gruppi: gruppi, griglia: griglia,
            quartierGenerale: quartierGenerale) else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: caselle.map {
                    .init(riga: $0.riga, colonna: $0.colonna,
                          composizione: Self.composizioneDiMisura) }),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)

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
        return Passi(gruppi: gruppi, mappa: identificatore, disposizione: disposizione,
                     conIlSalto: conIlSalto, senzaIlSalto: senza)
    }

    // MARK: - Misura: distanza fra i due quartier generali

    /// Quanto distano fra loro i due quartier generali, e quante giornate costa
    /// congiungerli marciando ogni giorno. Si gioca davvero: il numero esce dalle
    /// regole e non da una formula scritta qui.
    ///
    /// La grandezza misurata è la DISTANZA FRA I DUE QUARTIER GENERALI e non
    /// l'attraversamento della mappa, che è un'altra cosa e vale di più: sul
    /// formato quattro per quattro i due quartier generali distano tre caselle,
    /// mentre la distanza massima fra due caselle qualunque è sei. È la stessa
    /// classe di errore già corretta sulle caselle con meno di quattro uscite —
    /// una grandezza chiamata con il nome di un'altra — e per questo le due
    /// compaiono ora affiancate, così che nessuna delle due possa essere letta
    /// per l'altra.
    public struct DistanzaFraQuartierGenerali: Sendable {
        public let mappa: IdentificatoreDati
        public let formato: IdentificatoreDati
        public let lato: Int
        /// La distanza ortogonale fra il proprio quartier generale e quello avverso.
        public let distanzaFraQuartierGenerali: Int
        /// La distanza massima fra due caselle qualunque della mappa: la traversata
        /// effettiva, cioè da un angolo all'angolo opposto.
        public let distanzaMassimaFraDueCaselle: Int
        /// Le giornate spese a congiungerli marciando ogni giorno.
        public let giornatePerCongiungerli: Int
    }

    public func misuraDistanzaFraQuartierGenerali(mappa identificatore: IdentificatoreDati) throws
        -> DistanzaFraQuartierGenerali? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        let partenza = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                             colonna: definizione.quartierGenerali.giocatore.colonna)
        let arrivo = Cella(riga: definizione.quartierGenerali.avversario.riga,
                           colonna: definizione.quartierGenerali.avversario.colonna)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: identificatore,
                                       gruppiGiocatore: [.init(riga: partenza.riga,
                                                               colonna: partenza.colonna,
                                                               composizione: Self.composizioneDiMisura)]),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
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
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            guard let comando = vista.comandoDiMarcia(per: id, a: prossima),
                  motore.valida(comando, parte: .giocatore, stato: stato).eValido else { break }
            (stato, _) = motore.applica(comando, parte: .giocatore, stato: stato)
        }
        let griglia = stato.griglia
        return DistanzaFraQuartierGenerali(
            mappa: identificatore, formato: definizione.formato, lato: formato.righe,
            distanzaFraQuartierGenerali: griglia.distanza(partenza, arrivo),
            distanzaMassimaFraDueCaselle: griglia.distanza(
                Cella(riga: 1, colonna: 1), Cella(riga: griglia.righe, colonna: griglia.colonne)),
            giornatePerCongiungerli: stato.giorno - giornoIniziale)
    }

    // MARK: - Misura: caselle raggiungibili in una giornata

    /// Quante caselle sono raggiungibili in una giornata da ciascuna casella della
    /// mappa. Con una sola azione per gruppo e lo scatto di una casella, sono i
    /// vicini ortogonali LIBERI.
    ///
    /// Le uscite libere e le caselle di bordo sono due grandezze DIVERSE, e la
    /// misura le tiene separate perché il resoconto della prima unità le aveva
    /// confuse. Il bordo è geometria e non cambia mai; le uscite libere dipendono
    /// da dove stanno i gruppi, perché una casella occupata da una propria
    /// formazione non è disponibile (01 §5.6.0.2). Una casella interna adiacente a
    /// un proprio gruppo ha quattro vicine e tre uscite: è interna e ha meno di
    /// quattro uscite, e chiamarla «di bordo» è sbagliato.
    public struct UsciteLibere: Sendable {
        public let mappa: IdentificatoreDati
        public let distribuzione: Distribuzione
        /// Geometria pura: le caselle su un lato della mappa. Non dipende dai gruppi.
        public let caselleDiBordo: Int
        /// Geometria pura: il complemento del bordo.
        public let caselleInterne: Int
        /// Occupazione: le caselle da cui, nella configurazione misurata, si esce
        /// verso meno di quattro caselle libere.
        public let conMenoDiQuattroUscite: Int
        /// Di quelle, quante sono INTERNE, cioè quante devono la propria strettezza
        /// alla presenza di un gruppo e non alla forma della mappa.
        public let interneConMenoDiQuattroUscite: Int
        /// I gruppi presenti nella configurazione con cui la misura è presa.
        public let gruppiPresenti: Int
    }

    public func misuraUsciteLibere(mappa identificatore: IdentificatoreDati) throws
        -> UsciteLibere? {
        guard let definizione = valoriCampagna.mappe[identificatore] else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: [.init(riga: definizione.quartierGenerali.giocatore.riga,
                                        colonna: definizione.quartierGenerali.giocatore.colonna,
                                        composizione: Self.composizioneDiMisura)]),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let griglia = stato.griglia
        func diBordo(_ c: Cella) -> Bool {
            c.riga == 1 || c.riga == griglia.righe || c.colonna == 1 || c.colonna == griglia.colonne
        }
        let conteggi = griglia.tutteLeCaselle.map {
            vista.usciteLibere(da: $0).count
        }
        let strette = griglia.tutteLeCaselle.filter {
            vista.usciteLibere(da: $0).count < 4
        }
        return UsciteLibere(mappa: identificatore,
                             distribuzione: Distribuzione(conteggi),
                             caselleDiBordo: griglia.tutteLeCaselle.filter(diBordo).count,
                             caselleInterne: griglia.tutteLeCaselle.filter { !diBordo($0) }.count,
                             conMenoDiQuattroUscite: strette.count,
                             interneConMenoDiQuattroUscite: strette.filter { !diBordo($0) }.count,
                             gruppiPresenti: stato.gruppi.count)
    }
}
