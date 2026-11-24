import UIKit
import Dati
import Motore
import Segnali
import Sessione

/// La patria (01 §5.6.10, 05 §9.3; incarico 30): la schermata del regno. È il livello più alto
/// dell'architettura dei luoghi — patria, campagne, fronte (02 §6.5.4) —: da qui si apre la campagna
/// dell'anno e qui, d'inverno, si spende il bilancio nelle quattro schermate (01 §5.9.1.1).
///
/// Il linguaggio è quello delle altre schermate (00 §7): una colonna che scorre, letta nell'ordine
/// in cui è disposta; il tocco magico per l'informazione di stato; il gesto di fuga per risalire.
/// Gli elementi si aggiornano sul posto e il fuoco non si sposta dopo una spesa (00 §11.3); cambia
/// soltanto quando cambia il momento dell'anno, che è una schermata nuova. L'interfaccia non
/// calcola mai un dato di gioco: costi, riserve e validità li chiede al Motore (00 §3.2), e le
/// frasi le compone il traduttore dei Segnali, che ne è l'unico autore.
@MainActor
final class SchermataPatria: UIViewController {

    private let partita: PartitaRegno
    private var stato: StatoRegno?
    /// La campagna dell'anno, quando il regno ne ha una aperta.
    private var campagna: PartitaCampagna?
    private var dataDelFronte: DataDiCampagna?
    /// Dove sono le formazioni sul fronte della campagna aperta (incarico 32).
    private var situazione: SituazioneDelFronte?
    var alTermine: (() -> Void)?

    private let colonna = UIStackView()
    private var scorrimento: UIScrollView?
    private let titolo = UILabel()
    private let etichettaData = UILabel()
    private let etichettaCampagna = UILabel()
    /// La parte della colonna che dipende dal momento dell'anno: si ricostruisce quando il momento
    /// cambia, e fra un cambio e l'altro i suoi elementi si aggiornano sul posto.
    private let corpo = UIStackView()
    private var etichetteRiserve: [Risorsa: UILabel] = [:]
    private var pulsantiVoci: [(voce: VoceDelRegno, pulsante: PulsanteMultiriga)] = []
    /// Le righe delle forze, una per formazione, nell'ordine in cui il regno le conserva: comandi
    /// in primavera, quando si sceglie chi parte, testo negli altri momenti (incarico 31).
    private var righeForze: [(unita: IdentificatoreDati, vista: UIView)] = []
    /// Ciò che la prima schermata dell'inverno dichiara del mantenimento (01 §4.14.1.1).
    private let pilaMantenimento = UIStackView()
    private let pilaLavori = UIStackView()
    private var pulsanteProsegui: PulsanteMultiriga?
    /// Ciò che il corpo mostra: quando cambia, il corpo si ricostruisce e il fuoco torna in testa.
    private var corpoMostrato: Corpo?

    private enum Corpo: Equatable {
        case daAprire, aperta, condotta, inverno
    }

    init(partita: PartitaRegno) {
        self.partita = partita
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    private var testi: Testi { partita.ambiente.testi }
    private var traduttore: TraduttoreEventiRegno { TraduttoreEventiRegno(testi: testi) }
    private var segnali: PuntoSegnali { partita.ambiente.segnali }

    // MARK: - Impianto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        colonna.axis = .vertical
        colonna.spacing = 12
        scorrimento = ColonnaScorrevole.monta(colonna, in: view, centrata: false)
        titolo.text = testi.frase("patria.titolo").testo
        TestoDinamico.applica(titolo, stile: .largeTitle)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
        colonna.addArrangedSubview(TestoDinamico.applica(etichettaData, stile: .title3))
        colonna.addArrangedSubview(TestoDinamico.applica(etichettaCampagna, stile: .body))
        corpo.axis = .vertical
        corpo.spacing = 12
        colonna.addArrangedSubview(corpo)
        pilaLavori.axis = .vertical
        pilaLavori.spacing = 6
        pilaMantenimento.axis = .vertical
        pilaMantenimento.spacing = 6
        Task { await carica() }
    }

    /// Il fuoco d'apertura parte alla comparsa, sul titolo, che esiste da subito: non attende il
    /// caricamento dello stato (05 §10.3, lettera f).
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard presentedViewController == nil, !fuocoDApertura else { return }
        fuocoDApertura = true
        Fuoco.sposta(a: titolo, perche: .schermataAperta)
    }
    private var fuocoDApertura = false

    /// Legge lo stato del regno e, se il regno ha una campagna aperta, la riprende dal suo slot. Una
    /// campagna conclusa il cui esito non era ancora arrivato in patria lo porta adesso, con la sua
    /// dichiarazione di conclusione.
    private func carica() async {
        stato = await partita.stato
        if stato?.campagna.fronteAperto != nil, campagna == nil {
            campagna = try? await partita.campagnaAperta()
        }
        if let campagna, let esito = try? await partita.riportaEsitoSeConclusa(campagna) {
            self.campagna = nil
            stato = await partita.stato
            await aggiorna()
            mostraLaConclusione(esito)
            return
        }
        await aggiorna()
    }

    // MARK: - Aggiornamento sul posto (00 §11.1)

    /// Aggiorna la schermata dallo stato: i testi degli elementi esistenti, sempre; il corpo, e con
    /// esso il fuoco, soltanto se è cambiato il momento dell'anno. Vero se il corpo è cambiato.
    @discardableResult
    private func aggiorna() async -> Bool {
        stato = await partita.stato
        guard let stato else { return false }
        let delFronte = await campagna?.stato
        dataDelFronte = delFronte?.data
        situazione = stato.campagna.fronteAperto == nil ? nil : delFronte.map(PonteRegnoCampagna.situazione)
        etichettaData.text = testoDellaData(stato)
        etichettaCampagna.text = testoDellaCampagna(stato)
        let nuovo = corpo(per: stato)
        let cambiato = nuovo != corpoMostrato
        if cambiato {
            corpoMostrato = nuovo
            ricostruisciIlCorpo(nuovo, stato: stato)
        }
        aggiornaIlCorpo(stato)
        return cambiato
    }

    private func corpo(per stato: StatoRegno) -> Corpo {
        if stato.momento.eInverno { return .inverno }
        switch stato.campagna {
        case .nonAperta: return .daAprire
        case .aperta: return .aperta
        case .conclusa: return .condotta
        }
    }

    private func testoDellaData(_ stato: StatoRegno) -> String {
        if let stazione = stato.momento.stazione {
            return testi.frase("patria.data_inverno", stato.anno, stazione,
                               MomentoDellAnno.stazioniInvernali).testo
        }
        // Con la campagna aperta la data è quella del fronte (01 §5.6.10.2).
        if stato.campagna.fronteAperto != nil, let data = dataDelFronte {
            return testi.frase("patria.data_fronte", data.anno,
                               testi.termine(data.stagione.chiaveTesto).testo,
                               data.giorno, data.giornateOperative).testo
        }
        let stagione = stato.stagione(giornatePerStagione: partita.valori.giornatePerStagione)
        return testi.frase("patria.data_operativa", stato.anno,
                           testi.termine(stagione.chiaveTesto).testo).testo
    }

    private func testoDellaCampagna(_ stato: StatoRegno) -> String {
        switch stato.campagna {
        case .nonAperta:
            return testi.frase(stato.momento.eInverno ? "patria.nessuna_campagna_condotta"
                                                       : "patria.campagna_non_aperta").testo
        case .aperta(let fronte):
            return testi.frase("patria.campagna_aperta", traduttore.fronte(fronte)).testo
        case .conclusa(let esito):
            let nome = traduttore.fronte(esito.fronte)
            switch esito.modo {
            case .inverno: return testi.frase("patria.campagna_interrotta", nome).testo
            case .annientamento:
                return testi.frase(esito.vinta ? "patria.campagna_vinta" : "patria.campagna_perduta", nome).testo
            }
        }
    }

    /// L'informazione di stato del regno (02 §6.5): la data, la campagna dell'anno e, d'inverno,
    /// quanti lavori sono ordinati.
    private func informazioneDiStato() -> String {
        guard let stato else { return "" }
        var testo = testi.frase("patria.stato", testoDellaData(stato), testoDellaCampagna(stato)).testo
        if stato.momento.eInverno {
            testo += testi.frase("regno.stato_lavori", stato.lavori.count).testo
        }
        return testo
    }

    // MARK: - Il corpo

    private func intestazione(_ chiave: String) -> UILabel {
        let etichetta = TestoDinamico.applica(UILabel(), stile: .title2)
        etichetta.text = testi.frase(chiave).testo
        etichetta.accessibilityTraits = .header
        return etichetta
    }

    private func comando(_ chiave: String, _ azione: Selector) -> PulsanteMultiriga {
        let pulsante = PulsanteMultiriga.crea(titolo: testi.frase(chiave).testo, stile: .body)
        pulsante.accessibilityIdentifier = chiave
        pulsante.addTarget(self, action: azione, for: .touchUpInside)
        return pulsante
    }

    private func ricostruisciIlCorpo(_ quale: Corpo, stato: StatoRegno) {
        for vista in corpo.arrangedSubviews { vista.removeFromSuperview() }
        etichetteRiserve = [:]
        pulsantiVoci = []
        righeForze = []
        pulsanteProsegui = nil

        // Il riquadro delle riserve: navigabile voce per voce, in valore assoluto (01 §5.9.1.5,
        // 02 §8.7.2).
        corpo.addArrangedSubview(intestazione("patria.riserve"))
        for risorsa in Risorsa.allCases {
            let etichetta = TestoDinamico.applica(UILabel(), stile: .body)
            etichetteRiserve[risorsa] = etichetta
            corpo.addArrangedSubview(etichetta)
        }
        // Il mantenimento che il gioco ha prelevato da sé: lo dichiara la prima schermata
        // dell'inverno, subito dopo le riserve da cui è uscito (01 §4.14.1.1).
        if quale == .inverno { corpo.addArrangedSubview(pilaMantenimento) }

        // Le forze: una riga per formazione, col nome che resta lo stesso da un anno all'altro
        // (01 §5.6.0.4). In primavera, prima di aprire la campagna, ogni riga è un comando: lo si
        // attiva per tenere la formazione in patria o rimandarla al fronte, e la riga dice sempre
        // dove va. Negli altri momenti è testo. Il numero delle righe cambia soltanto quando
        // cambia il momento dell'anno; fra un cambio e l'altro i testi si aggiornano sul posto.
        corpo.addArrangedSubview(intestazione("patria.forze"))
        let forze = traduttore.forze(stato.forze)
        if forze.isEmpty {
            let etichetta = TestoDinamico.applica(UILabel(), stile: .body)
            etichetta.text = testi.frase("patria.nessuna_forza").testo
            corpo.addArrangedSubview(etichetta)
        }
        for riga in forze {
            if quale == .daAprire {
                let pulsante = PulsanteMultiriga.crea(titolo: "", stile: .body, allineamento: .natural)
                pulsante.accessibilityIdentifier = "formazione." + riga.unita
                pulsante.accessibilityHint = testi.frase("patria.destina_suggerimento").testo
                let unita = riga.unita
                pulsante.addAction(UIAction { [weak self] _ in self?.cambiaDestinazione(di: unita) },
                                   for: .touchUpInside)
                righeForze.append((riga.unita, pulsante))
                corpo.addArrangedSubview(pulsante)
            } else {
                let etichetta = TestoDinamico.applica(UILabel(), stile: .body)
                etichetta.accessibilityIdentifier = "formazione." + riga.unita
                righeForze.append((riga.unita, etichetta))
                corpo.addArrangedSubview(etichetta)
            }
        }

        switch quale {
        case .daAprire:
            corpo.addArrangedSubview(comando("patria.apri_campagna", #selector(scegliIlFronte)))
            corpo.addArrangedSubview(comando("patria.attendi_inverno", #selector(attendiLInverno)))
        case .aperta:
            let pulsante = PulsanteMultiriga.crea(
                titolo: testi.frase("patria.entra_nel_fronte",
                                    traduttore.fronte(stato.campagna.fronteAperto ?? "")).testo, stile: .body)
            pulsante.accessibilityIdentifier = "patria.entra_nel_fronte"
            pulsante.addTarget(self, action: #selector(entraNelFronte), for: .touchUpInside)
            corpo.addArrangedSubview(pulsante)
        case .condotta:
            corpo.addArrangedSubview(comando("patria.attendi_inverno", #selector(attendiLInverno)))
        case .inverno:
            // Ciascuna delle quattro schermate contiene sempre tutte le voci, nella stessa forma
            // (01 §5.9.1.3, 02 §8.7.3): il giocatore ne impara una e la ritrova quattro volte. Le
            // voci sono ripartite in LINGUETTE ordinate per durata, le più lunghe per prime: ogni
            // linguetta è un'intestazione, che il rotore delle intestazioni raggiunge, seguita dalle
            // sue voci — tutte nella stessa colonna, perché nulla sparisca dietro una scheda.
            corpo.addArrangedSubview(intestazione("patria.lavori_da_ordinare"))
            for linguetta in partita.valori.linguette {
                let voci = partita.valori.voci(in: linguetta)
                guard !voci.isEmpty else { continue }
                let titolo = TestoDinamico.applica(UILabel(), stile: .title3)
                titolo.text = traduttore.linguetta(linguetta.identificatore)
                titolo.accessibilityTraits = .header
                titolo.accessibilityIdentifier = "linguetta." + linguetta.identificatore
                corpo.addArrangedSubview(titolo)
                for voce in voci {
                    let pulsante = PulsanteMultiriga.crea(titolo: "", stile: .body, allineamento: .natural)
                    pulsante.accessibilityIdentifier = "voce." + voce.identificatore
                    pulsante.addAction(UIAction { [weak self, weak pulsante] _ in
                        if voce.effetto.richiedeBersaglio { self?.scegliIlBersaglio(di: voce, da: pulsante) }
                        else { self?.ordina(voce) }
                    }, for: .touchUpInside)
                    pulsantiVoci.append((voce, pulsante))
                    corpo.addArrangedSubview(pulsante)
                }
            }
            corpo.addArrangedSubview(intestazione("patria.lavori_ordinati"))
            corpo.addArrangedSubview(pilaLavori)
            // Annullamento e azzeramento seguono le voci nell'ordine di lettura: ogni budget che si
            // consuma li richiede (00 §13.8).
            corpo.addArrangedSubview(comando("patria.annulla_spesa", #selector(annullaSpesa)))
            corpo.addArrangedSubview(comando("patria.azzera_spese", #selector(azzeraSpese)))
            let prosegui = PulsanteMultiriga.crea(titolo: "", stile: .body)
            prosegui.accessibilityIdentifier = "patria.prosegui"
            prosegui.addTarget(self, action: #selector(proseguiNellInverno), for: .touchUpInside)
            pulsanteProsegui = prosegui
            corpo.addArrangedSubview(prosegui)
        }
        corpo.addArrangedSubview(comando("patria.registro", #selector(apriRegistro)))
        corpo.addArrangedSubview(comando("resoconto.torna", #selector(esci)))
    }

    /// Aggiorna sul posto ciò che cambia dentro lo stesso momento dell'anno: le riserve, le righe
    /// delle forze, il costo delle voci sulla riserva, l'elenco dei lavori ordinati, il comando per
    /// proseguire, e ciò che la prima schermata dell'inverno dichiara del mantenimento.
    private func aggiornaIlCorpo(_ stato: StatoRegno) {
        for (risorsa, etichetta) in etichetteRiserve {
            etichetta.text = testi.frase("patria.riserva", traduttore.termine(risorsa, fase: stato.fase),
                                         stato.riserve[risorsa]).testo
        }
        // D'inverno ogni reparto dice anche lo stato del proprio miglioramento (01 §4.14).
        // A campagna aperta ogni riga dice dov'è adesso la formazione (S29q, punto d; incarico 32).
        let forze = traduttore.forze(stato.forze, lavori: stato.momento.eInverno ? stato.lavori : nil,
                                     fronte: situazione, condotta: corpo(per: stato) == .condotta)
        for (riga, elemento) in zip(forze, righeForze) where riga.unita == elemento.unita {
            if let pulsante = elemento.vista as? PulsanteMultiriga {
                pulsante.setTitle(riga.testo, for: .normal)
                pulsante.accessibilityLabel = riga.testo
                pulsante.invalidateIntrinsicContentSize()
            } else if let etichetta = elemento.vista as? UILabel {
                etichetta.text = riga.testo
            }
        }
        for (voce, pulsante) in pulsantiVoci {
            let pronta = partita.prontoIn(voce, stato: stato)
            let testo: String
            if voce.effetto.richiedeBersaglio {
                testo = traduttore.etichetta(dellaVoceConBersaglio: voce,
                                             bersagli: partita.bersagli(di: voce, stato: stato).count,
                                             pronta: pronta, verbosita: Impostazioni.verbosita)
            } else {
                testo = traduttore.etichetta(dellaVoce: voce, costo: partita.costo(di: voce, stato: stato) ?? .vuote,
                                             riserve: stato.riserve, pronta: pronta,
                                             fase: stato.fase, verbosita: Impostazioni.verbosita)
            }
            pulsante.setTitle(testo, for: .normal)
            pulsante.accessibilityLabel = testo
            pulsante.invalidateIntrinsicContentSize()
        }
        if let stazione = stato.momento.stazione {
            for vista in pilaMantenimento.arrangedSubviews { vista.removeFromSuperview() }
            if stazione == 1 {
                for riga in traduttore.dichiarazioneDelMantenimento(prelevato: stato.mantenimento,
                                                                    sciolti: stato.sciolti, fase: stato.fase) {
                    let etichetta = TestoDinamico.applica(UILabel(), stile: .body)
                    etichetta.text = riga
                    pilaMantenimento.addArrangedSubview(etichetta)
                }
            }
            for vista in pilaLavori.arrangedSubviews { vista.removeFromSuperview() }
            let righe = stato.lavori.isEmpty ? [testi.frase("patria.nessun_lavoro_ordinato").testo]
                                             : stato.lavori.map { traduttore.lavoroElencato($0, forze: stato.forze) }
            for riga in righe {
                let etichetta = TestoDinamico.applica(UILabel(), stile: .body)
                etichetta.text = riga
                pilaLavori.addArrangedSubview(etichetta)
            }
            let titoloProsegui = stazione < MomentoDellAnno.stazioniInvernali
                ? testi.frase("patria.prosegui_stazione", stazione + 1, MomentoDellAnno.stazioniInvernali).testo
                : testi.frase("patria.prosegui_primavera").testo
            pulsanteProsegui?.setTitle(titoloProsegui, for: .normal)
            pulsanteProsegui?.invalidateIntrinsicContentSize()
        }
    }

    /// Dopo un cambio del momento dell'anno la schermata è un'altra: il fuoco torna in testa, alla
    /// data, e la colonna si riporta in cima (00 §11.1: è l'apertura di una schermata nuova).
    private func portaIlFuocoInTesta() {
        scorrimento?.setContentOffset(.zero, animated: false)
        Fuoco.sposta(a: etichettaData, perche: .schermataAperta)
    }

    private func annuncia(_ testo: String, significato: SignificatoSegnale? = nil, interrompente: Bool = false) {
        let localizzato = TestoLocalizzato(testo: testo, lingua: testi.lingua)
        if let significato {
            segnali.annuncia(localizzato, significato: significato)
        } else {
            segnali.annuncia(localizzato, interrompente: interrompente)
        }
    }

    // MARK: - Comandi del regno

    /// Esegue un comando del regno. Se è respinto ne annuncia il motivo; se cambia il momento
    /// dell'anno porta il fuoco in testa, altrimenti aggiorna sul posto senza muoverlo.
    private func esegui(_ comando: ComandoRegno) async {
        guard let esito = try? await partita.esegui(comando) else { return }
        if let motivo = esito.motivo {
            let fase = stato?.fase ?? partita.valori.faseIniziale
            let conRisorse: Bool
            if case .risorseInsufficienti = motivo { conRisorse = true } else { conRisorse = false }
            annuncia(traduttore.motivo(motivo, fase: fase).testo,
                     significato: conRisorse ? .risorsaInsufficiente : nil)
            return
        }
        if await aggiorna() { portaIlFuocoInTesta() }
    }

    @objc private func attendiLInverno() { Task { await esegui(.attendiInverno) } }
    @objc private func proseguiNellInverno() { Task { await esegui(.prosegui) } }
    private func ordina(_ voce: VoceDelRegno, bersaglio: BersaglioMilitare? = nil) {
        Task { await esegui(.ordina(voce: voce.identificatore, bersaglio: bersaglio)) }
    }

    /// La scelta di chi parte (incarico 31): attivando la riga di una formazione la si tiene in
    /// patria, o la si rimanda al fronte. La riga si aggiorna sul posto e il fuoco non si sposta.
    private func cambiaDestinazione(di unita: IdentificatoreDati) {
        guard let alFronte = stato?.forze.destinataAlFronte(unita) else { return }
        Task { await esegui(.destina(unita: unita, alFronte: !alFronte)) }
    }

    /// Le voci che si ordinano SU un reparto esistente (01 §4.13, §4.14): si sceglie il reparto da
    /// un elenco in cui ciascuna scelta dichiara il proprio costo sulla riserva, e l'impossibilità
    /// se c'è (02 §8.7). Scelto il reparto il lavoro è ordinato; il fuoco torna sulla voce da cui si
    /// era partiti.
    private func scegliIlBersaglio(di voce: VoceDelRegno, da origine: UIView?) {
        guard let stato else { return }
        let bersagli = partita.bersagli(di: voce, stato: stato)
        guard !bersagli.isEmpty else {
            annuncia(testi.frase("patria.nessun_bersaglio").testo)
            return
        }
        let voci = bersagli.map { bersaglio in
            traduttore.etichetta(delBersaglio: bersaglio, forze: stato.forze,
                                 costo: partita.costo(di: voce, bersaglio: bersaglio, stato: stato) ?? .vuote,
                                 riserve: stato.riserve, fase: stato.fase)
        }
        let schermata = SchermataScelta(
            titolo: testi.frase("regno.voce_nome", soggetto: traduttore.voce(voce.identificatore)).testo,
            domanda: testi.frase("patria.scegli_bersaglio").testo, voci: voci,
            congedo: testi.frase("pannello.chiudi").testo)
        schermata.modalPresentationStyle = .fullScreen
        schermata.allaScelta = { [weak self] indice in
            Fuoco.sposta(a: origine, perche: .schermataChiusa)
            self?.ordina(voce, bersaglio: bersagli[indice])
        }
        schermata.alCongedo = { Fuoco.sposta(a: origine, perche: .schermataChiusa) }
        sceltaAperta = schermata
        present(schermata, animated: false)
        Fuoco.sposta(a: nil, perche: .schermataAperta)
    }
    /// La scelta del reparto in corso, se ce n'è una: attrezzo per le prove ospitate.
    private weak var sceltaAperta: SchermataScelta?

    @objc private func annullaSpesa() {
        Task {
            do {
                let lavoro = try await partita.annullaSpesa()
                await aggiorna()
                segnali.annuncia(traduttore.spesaAnnullata(lavoro), significato: .annullamento)
            } catch {
                annuncia(testi.frase("regno.niente_da_annullare").testo)
            }
        }
    }

    @objc private func azzeraSpese() {
        Task {
            do {
                let quante = try await partita.azzeraSpese()
                await aggiorna()
                annuncia(testi.frase("regno.spese_azzerate", quante).testo, significato: .annullamento)
            } catch {
                annuncia(testi.frase("regno.niente_da_azzerare").testo)
            }
        }
    }

    // MARK: - La campagna dell'anno

    /// La scelta del fronte: una voce per fronte, ciascuna in una frase, e il congedo (00 §8.2: si
    /// seleziona da una lista e si conferma).
    @objc private func scegliIlFronte() { Task { await offriLaSceltaDelFronte() } }

    /// Se il regno rifiuterebbe la campagna su qualunque fronte — non c'è un gruppo armato da mandare —
    /// il rifiuto si dichiara PRIMA di aprire la scelta (S29q, punto c; incarico 32): scegliere un fronte
    /// per sentirsi dire che non si poteva è un'operazione a vuoto. Il motivo è quello della validazione.
    private func offriLaSceltaDelFronte() async {
        var motivo: MotivoNonValidoRegno?
        var apribile = false
        for fronte in partita.valori.fronti {
            let esito = await partita.anteprima(.apriCampagna(fronte: fronte.identificatore))
            if esito.eValido { apribile = true; break }
            motivo = motivo ?? esito.motivo
        }
        guard apribile else {
            if let motivo {
                annuncia(traduttore.motivo(motivo, fase: stato?.fase ?? partita.valori.faseIniziale).testo)
            }
            return
        }
        mostraLaSceltaDelFronte()
    }

    private func mostraLaSceltaDelFronte() {
        let pannello = UIAlertController(title: testi.frase("patria.scegli_fronte").testo,
                                         message: nil, preferredStyle: .alert)
        for fronte in partita.valori.fronti {
            var titolo = traduttore.fronte(fronte.identificatore)
            if let formato = partita.mappa(delFronte: fronte.identificatore) {
                titolo = testi.frase("patria.fronte_voce", titolo, formato.righe, formato.colonne).testo
            }
            pannello.addAction(UIAlertAction(title: titolo, style: .default) { [weak self] _ in
                // Il pannello si chiude e la schermata cambia: gli annunci dell'apertura li
                // accompagnano (incarico 32, RDA-183).
                Fuoco.staPerSpostarsi()
                Task { await self?.apriLaCampagna(sul: fronte.identificatore) }
            })
        }
        pannello.addAction(UIAlertAction(title: testi.frase("pannello.chiudi").testo, style: .cancel))
        present(pannello, animated: false)
    }

    private func apriLaCampagna(sul fronte: IdentificatoreDati) async {
        do {
            let aperta = try await partita.apriCampagna(fronte: fronte)
            guard let nuova = aperta.campagna else {
                if let motivo = aperta.esito.motivo {
                    annuncia(traduttore.motivo(motivo, fase: stato?.fase ?? partita.valori.faseIniziale).testo)
                }
                return
            }
            campagna = nuova
            await aggiorna()
            // Il pannello della scelta si è appena congedato, e VoiceOver vi sta ancora rifocalizzando la
            // patria: presentata subito, la mappa perdeva il proprio fuoco d'apertura, che finiva su
            // «Torna in patria» (trovato e misurato nell'incarico 32; era così anche prima).
            try? await Task.sleep(nanoseconds: UInt64(Fuoco.attesaDelSistema * 1_000_000_000))
            presentaIlFronte(nuova)
        } catch {
            annuncia(testi.frase("patria.campagna_non_apribile").testo, interrompente: true)
        }
    }

    @objc private func entraNelFronte() {
        Task {
            if campagna == nil { campagna = try? await partita.campagnaAperta() }
            guard let campagna else {
                annuncia(testi.frase("patria.campagna_non_apribile").testo, interrompente: true)
                return
            }
            presentaIlFronte(campagna)
        }
    }

    /// Entra nel fronte: la mappa di campagna (02 §6.5.4). Uscendone si torna qui; se la campagna
    /// vi si conclude, la mappa lo dice e si torna qui con la dichiarazione di conclusione.
    private func presentaIlFronte(_ campagna: PartitaCampagna) {
        let schermata = SchermataMappaCampagna(partita: campagna)
        schermata.modalPresentationStyle = .fullScreen
        schermata.alTermine = { [weak self] in
            self?.dismiss(animated: false) { Task { await self?.tornatoDalFronte() } }
        }
        schermata.allaConclusione = { [weak self] in
            self?.dismiss(animated: false) { Task { await self?.tornatoDalFronte() } }
        }
        present(schermata, animated: false)
        Fuoco.azzeraRegistro()
    }

    /// Al ritorno dal fronte: se la campagna si è conclusa l'esito arriva in patria e si dichiara;
    /// altrimenti la patria si aggiorna — la data è quella del fronte — e il fuoco torna sul comando
    /// da cui si era entrati.
    private func tornatoDalFronte() async {
        if let campagna, let esito = try? await partita.riportaEsitoSeConclusa(campagna) {
            self.campagna = nil
            await aggiorna()
            mostraLaConclusione(esito)
            return
        }
        await aggiorna()
        let origine = corpo.arrangedSubviews.first { $0.accessibilityIdentifier == "patria.entra_nel_fronte" }
        Fuoco.sposta(a: origine ?? etichettaData, perche: .schermataChiusa)
    }

    /// La dichiarazione di conclusione della campagna, con l'esito e le conseguenze (05 §9.3):
    /// voci in ordine fisso, una frase ciascuna; congedata, il fuoco torna in testa alla patria.
    private func mostraLaConclusione(_ esito: EsitoCampagna) {
        let fase = stato?.fase ?? partita.valori.faseIniziale
        let schermata = SchermataResoconto(
            voci: traduttore.dichiarazioneDiConclusione(esito, premi: partita.premi(per: esito), fase: fase),
            testi: testi, chiaveTitolo: "conclusione.titolo", chiaveCongedo: "conclusione.torna")
        schermata.modalPresentationStyle = .fullScreen
        schermata.alTermine = { [weak self] in self?.portaIlFuocoInTesta() }
        present(schermata, animated: false)
        Fuoco.sposta(a: nil, perche: .schermataAperta)
    }

    // MARK: - Registro, uscita, gesti (02 §6.6, §6.7)

    @objc private func apriRegistro() {
        guard let stato else { return }
        let schermata = SchermataRegistro(
            voci: stato.registroDalPiuRecente.map {
                SchermataRegistro.Voce(frase: traduttore.voceDiRegistro($0, fase: stato.fase).testo, luogo: nil) },
            testi: testi, chiaveTitolo: "registro_patria.titolo", conLuoghi: false)
        schermata.modalPresentationStyle = .fullScreen
        present(schermata, animated: false)
        Fuoco.sposta(a: nil, perche: .schermataAperta)
    }

    @objc private func esci() { alTermine?() }

    /// Il tocco magico richiama l'informazione di stato senza lasciare la schermata (02 §6.7).
    override func accessibilityPerformMagicTap() -> Bool {
        guard stato != nil else { return false }
        annuncia(informazioneDiStato(), interrompente: true)
        return true
    }

    /// Il gesto di fuga risale di un livello: dalla patria all'avvio (02 §6.7).
    override func accessibilityPerformEscape() -> Bool {
        alTermine?()
        return true
    }

    // MARK: - Attrezzi per le prove ospitate

    /// Attende che il caricamento iniziale sia compiuto e la schermata rispecchi lo stato.
    func aggiornaPerProva() async { await carica() }
    func eseguiPerProva(_ comando: ComandoRegno) async { await esegui(comando) }
    func annullaSpesaPerProva() { annullaSpesa() }
    func azzeraSpesePerProva() { azzeraSpese() }
    func apriLaCampagnaPerProva(sul fronte: IdentificatoreDati) async { await apriLaCampagna(sul: fronte) }
    func tornatoDalFrontePerProva() async { await tornatoDalFronte() }
    func informazioneDiStatoPerProva() -> String { informazioneDiStato() }
    var partitaPerProva: PartitaRegno { partita }
    var campagnaPerProva: PartitaCampagna? { campagna }
    var colonnaPerProva: UIStackView { colonna }
    var corpoPerProva: UIStackView { corpo }
    var sceltaPerProva: SchermataScelta? { sceltaAperta }
    func cambiaDestinazionePerProva(di unita: IdentificatoreDati) async {
        guard let alFronte = stato?.forze.destinataAlFronte(unita) else { return }
        await esegui(.destina(unita: unita, alFronte: !alFronte))
    }
    func scegliIlBersaglioPerProva(di voce: VoceDelRegno) { scegliIlBersaglio(di: voce, da: nil) }
    func ordinaPerProva(_ voce: VoceDelRegno, bersaglio: BersaglioMilitare?) async {
        await esegui(.ordina(voce: voce.identificatore, bersaglio: bersaglio))
    }
}
