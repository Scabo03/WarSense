import Foundation
import Dati

/// Le regole della campagna: validazione e applicazione dei comandi (05 §3.1).
/// Deterministico: stesso comando su stesso stato, stesso esito e stessi eventi
/// (00 §3.1). Nessun numero di gioco vive qui (00 §13.1).
public struct MotoreCampagna: Sendable {
    public let valori: ValoriDiGioco
    public let valoriCampagna: ValoriCampagna

    public init(valori: ValoriDiGioco, valoriCampagna: ValoriCampagna) {
        self.valori = valori
        self.valoriCampagna = valoriCampagna
    }

    // MARK: - Validazione (05 §3.1, §3.2)

    /// Nessuna mutazione: dice se il comando è ammissibile e, se non lo è, perché,
    /// con un motivo del vocabolario chiuso. Un solo percorso di codice produce sia
    /// il controllo sia l'annuncio, e i due non possono divergere (05 §3.2).
    public func valida(_ comando: ComandoCampagna, parte: Parte,
                       stato: StatoCampagna) -> EsitoValidazioneCampagna {
        switch comando {
        case .marcia(let idGruppo, let destinazione, let giorni):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // Un gruppo che ha concluso la giornata non riceve ordini, e un gruppo
            // in marcia lunga ha concluso la giornata anche quando l'azione non è
            // spesa dal giocatore (01 §5.16.1): a distinguerlo serve
            // `haConclusoLaGiornata`. È l'invariante «un gruppo in marcia non riceve
            // mai un ordine» reso impossibile qui, non soltanto sorvegliato.
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            guard stato.griglia.contiene(destinazione) else { return .nonValido(.fuoriMappa) }
            guard stato.griglia.adiacenti(gruppo.posizione, destinazione) else {
                return .nonValido(.nonAdiacente)
            }
            // Ogni casella ospita al massimo una formazione della stessa parte
            // (01 §5.6.0.2). La casella di arrivo dev'essere libera ADESSO e non
            // già puntata da un'altra marcia in corso: due marce verso la stessa
            // casella si scontrerebbero alla risoluzione, e il gruppo in marcia
            // resta nella casella di partenza fino a compimento, sicché la sua
            // destinazione è prenotata quanto una casella occupata.
            guard stato.occupante(di: destinazione, parte: parte) == nil else {
                return .nonValido(.occupata)
            }
            guard !stato.gruppi.values.contains(where: {
                $0.parte == parte && $0.marcia?.destinazione == destinazione
            }) else {
                return .nonValido(.occupata)
            }
            // Il costo dichiarato dal comando dev'essere quello che i dati
            // prescrivono per quello scatto: un comando che ne porti un altro non
            // è un comando del gioco (01 §5.6.3.1, RDA-75).
            guard giorni == costoInGiorni(da: gruppo.posizione, a: destinazione, stato: stato) else {
                return .nonValido(.costoNonCoerente)
            }
            return .valido

        case .presidio(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            guard !gruppo.haConclusoLaGiornata else { return .nonValido(.azioneGiaSpesa) }
            return .valido

        case .revocaMarcia(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            // La revoca si compie solo su una marcia in corso (01 §5.6.3.3). Non
            // controlla `azioneSpesa`: la revoca non è un'azione e si può compiere
            // in qualunque momento, anche nel giorno stesso dell'ordine.
            guard gruppo.inMarcia else { return .nonValido(.gruppoNonInMarcia) }
            return .valido
        }
    }

    // MARK: - Volume della colonna (01 §5.6.0, §5.6.3, §3.4.4)

    /// Il volume complessivo di un gruppo: la somma, sui reparti, di atomi per
    /// `volume_per_atomo` dell'archetipo. È la STESSA grandezza del volume di
    /// battaglia (`MotoreBattaglia.volume(di sciame:)`, `atomi × volume_per_atomo`):
    /// 01 §3.4.4 la dichiara «unica e stabile per archetipo», e qui si legge lo
    /// stesso campo dell'archetipo. Non è mai un campo dello stato: derivarla dalla
    /// composizione rende impossibile che diverga da ciò che compone il gruppo
    /// (invariante «il volume è la somma di ciò che lo compone»). Gli archetipi sono
    /// noti per costruzione, perché la fabbrica respinge lo scenario che ne nomini
    /// uno ignoto; l'accesso forzato rispecchia `MotoreBattaglia`.
    public func volume(di gruppo: Gruppo) -> Int64 {
        gruppo.composizione.reduce(0) { somma, reparto in
            somma + Int64(reparto.atomi) * valori.archetipi[reparto.archetipo]!.volumePerAtomo
        }
    }

    // MARK: - Costo in giorni dello scatto (01 §5.6.3.1, §5.6.3.2)

    /// I giorni necessari a entrare nella casella di arrivo venendo da quella di
    /// partenza. È UNA SOLA grandezza, come 01 §5.6.3.2 impone: vi confluiscono, per
    /// somma e senza regole separate che si sommino in modo opaco, il costo base, la
    /// natura della casella di partenza e quella di arrivo con pesi distinti, il tipo
    /// di strada della casella di arrivo, il costo fisso della strettoia e il VOLUME
    /// della colonna (quinto fattore di 01 §5.6.3.2). Il volume è quello del gruppo
    /// che occupa la casella di partenza — la colonna che marcia — letto dallo stato,
    /// senza spostare il punto di calcolo (RDA-75, `impatto-marcia-lunga.md` §1 ora
    /// superato): una colonna più voluminosa è più lunga e percorre meno strada in
    /// una giornata (01 §5.6.3), sicché il suo contributo è POSITIVO e cresce col
    /// volume. Se la casella di partenza non ha occupante il contributo è nullo: il
    /// costo esiste anche per una casella libera (anteprime, banco). Il costo non
    /// scende mai sotto uno, che 00 §13.6 fissa per impedire lo scatto gratuito.
    public func costoInGiorni(da partenza: Cella, a arrivo: Cella,
                              stato: StatoCampagna) -> Int {
        let m = valoriCampagna.marcia
        var costo = m.costoGiorniBase
        costo += m.pesoTerrenoPartenza[stato.mappa.terreno(di: partenza).rawValue] ?? 0
        costo += m.pesoTerrenoArrivo[stato.mappa.terreno(di: arrivo).rawValue] ?? 0
        costo += m.pesoStradaArrivo[stato.mappa.strada(di: arrivo).rawValue] ?? 0
        if stato.mappa.strettoia == arrivo { costo += m.costoStrettoia }
        // Il volume entra sulla MEDESIMA grandezza, per somma: giorni aggiuntivi pari
        // al volume diviso la soglia (troncamento). Formula nel codice, coefficiente
        // nei dati (00 §13.1): la soglia è provvisoria. Il contributo è monotòno nel
        // volume e nullo per una colonna leggera sotto la soglia.
        if let colonna = stato.occupante(di: partenza, parte: .giocatore) {
            costo += Int(volume(di: colonna) / Int64(m.sogliaVolumePerGiornoAggiuntivo))
        }
        return max(1, costo)
    }

    /// La posizione dell'avanzamento visivo, fra le `posizioni_visive` disposte a
    /// quadrato dentro la casella (01 §5.6.3.4): DERIVATA per troncamento dalla
    /// proporzione fra giorni compiuti e giorni totali, mai una grandezza autonoma.
    /// Chi ascolta riceve i giorni; questa è la sola grandezza che chi vede riceve,
    /// e non può divergere dai giorni perché è una funzione pura di essi. Restituisce
    /// un indice in `0 ..< posizioni_visive` per una marcia in corso.
    public func avanzamentoVisivo(giorniCompiuti: Int, giorniTotali: Int) -> Int {
        guard giorniTotali > 0 else { return 0 }
        return (giorniCompiuti * valoriCampagna.marcia.posizioniVisive) / giorniTotali
    }

    // MARK: - Applicazione (05 §3.1)

    /// Applica soltanto comandi validi: la validazione è rieseguita internamente e
    /// un comando non valido è un errore di programmazione, non un caso d'uso.
    public func applica(_ comando: ComandoCampagna, parte: Parte,
                        stato: StatoCampagna) -> (StatoCampagna, [EventoCampagna]) {
        precondition(valida(comando, parte: parte, stato: stato).eValido,
                     "comando.di.campagna.non.valido.applicato")
        var nuovo = stato
        var eventi: [EventoCampagna] = []

        switch comando {
        case .marcia(let idGruppo, let destinazione, let giorni):
            let partenza = nuovo.gruppi[idGruppo]!.posizione
            let nome = nuovo.gruppi[idGruppo]!.nome
            // La marcia REGISTRA un ordine e spende l'azione, ma NON muove il gruppo:
            // con il costo maggiore di uno il movimento matura alla risoluzione di
            // fine giornata (01 §5.6.3.3). Con costo uno matura alla chiusura della
            // stessa giornata, ma passa comunque per la marcia in corso, sicché un
            // solo percorso vale per ogni durata.
            nuovo.gruppi[idGruppo]!.marcia = MarciaInCorso(destinazione: destinazione,
                                                           giorniTotali: giorni, giorniCompiuti: 0)
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.marciaOrdinata(gruppo: idGruppo, nome: nome,
                                          da: partenza, a: destinazione, giorni: giorni))
            annota(.marciaOrdinata(gruppo: nome, da: partenza, a: destinazione), in: &nuovo)

        case .presidio(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.presidioOrdinato(gruppo: idGruppo, nome: gruppo.nome,
                                            casella: gruppo.posizione))
            annota(.presidioOrdinato(gruppo: gruppo.nome, casella: gruppo.posizione), in: &nuovo)

        case .revocaMarcia(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            let giorniPersi = gruppo.marcia!.giorniCompiuti
            let casella = gruppo.posizione
            // La revoca cancella la marcia e con essa i giorni spesi; il gruppo resta
            // nella casella di partenza (01 §5.6.3.3). Non restituisce la giornata:
            // il gruppo l'ha già spesa con l'ordine di marcia e non compie altro
            // (decisione del titolare, RDA-100). `azioneSpesa` a vero lo dichiara.
            nuovo.gruppi[idGruppo]!.marcia = nil
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.marciaRevocata(gruppo: idGruppo, nome: gruppo.nome,
                                          casella: casella, giorniPersi: giorniPersi))
            annota(.marciaRevocata(gruppo: gruppo.nome, casella: casella), in: &nuovo)
        }

        eventi.append(contentsOf: chiudiLaGiornataSeServe(&nuovo))
        return (nuovo, eventi)
    }

    /// La chiusura del turno (01 §5.6.0.6): il turno si chiude automaticamente quando
    /// tutti i gruppi hanno CONCLUSO la giornata — spendendola o essendo in marcia
    /// lunga, che la consuma senza comando — e NON esiste alcun comando di fine
    /// giornata. La chiusura resta la conseguenza dell'ultimo ordine del giocatore e
    /// non un'iniziativa del programma.
    ///
    /// È un CICLO e non un solo passo: se tutti i gruppi restano in marcia lunga dopo
    /// l'apertura della giornata nuova, non c'è nulla da ordinare e le giornate
    /// scorrono da sé finché una marcia non si compie e libera un gruppo. Il ciclo
    /// termina perché ogni giro avanza tutte le marce di un giorno, e una marcia si
    /// compie entro i propri giorni totali.
    func chiudiLaGiornataSeServe(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        while !stato.gruppi.isEmpty,
              stato.gruppi.values.allSatisfy({ $0.haConclusoLaGiornata }) {
            let chiuso = stato.giorno
            eventi.append(.giornataChiusa(giorno: chiuso))
            eventi.append(contentsOf: risolviFineGiornata(&stato))
            stato.giorno += 1
            // Le azioni si azzerano; le marce in corso restano e continuano a
            // consumare la giornata (01 §5.16.1).
            for id in stato.gruppi.keys.sorted() { stato.gruppi[id]!.azioneSpesa = false }
            // L'apertura della giornata NON produce una voce di registro: il giorno è
            // una proprietà di ciascuna voce (02 §6.6) e non un fatto a sé. Resta
            // l'annuncio, che il cambiamento di stato rilevante richiede (00 §11.4).
            eventi.append(.giornataAperta(giorno: stato.giorno))
        }
        return eventi
    }

    /// Le risoluzioni di fine giornata (01 §5.6.11): un MOMENTO DICHIARATO E ORDINATO,
    /// non una funzione che fa una cosa sola. L'ordine è quello di 01 §5.6.11:
    /// avanzamento delle marce lunghe, scatto delle imboscate, valutazione dei tagli
    /// di rifornimento, completamenti di costruzione, invecchiamento e decadimento
    /// della conoscenza. Di questi, questa unità realizza SOLTANTO il primo; gli
    /// altri appartengono a materie non ancora costruite e trovano qui il proprio
    /// posto già preparato. Una sessione futura aggiunge il proprio passo come una
    /// riga in coda a questa funzione, senza toccare gli altri: ciascun passo è
    /// indipendente e riceve e restituisce lo stato per riferimento.
    func risolviFineGiornata(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        eventi.append(contentsOf: avanzaLeMarce(&stato))
        // Passo successivo (unità futura): scattaLeImboscate(&stato)
        // Passo successivo (unità futura): valutaITagliDiRifornimento(&stato)
        // Passo successivo (unità futura): completaLeCostruzioni(&stato)
        // Passo successivo (unità futura): invecchiaLaConoscenza(&stato)
        return eventi
    }

    /// Primo e unico passo realizzato della risoluzione: ogni marcia in corso avanza
    /// di un giorno; quella che raggiunge i giorni totali si compie e il gruppo entra
    /// nella casella di arrivo (01 §5.6.3.3). L'ordine è deterministico (per id). La
    /// casella di arrivo è libera per costruzione, perché la validazione impedisce
    /// che due marce puntino la stessa casella o che una punti una casella occupata.
    func avanzaLeMarce(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        for id in stato.gruppi.keys.sorted() {
            guard var marcia = stato.gruppi[id]!.marcia else { continue }
            marcia.giorniCompiuti += 1
            if marcia.giorniCompiuti >= marcia.giorniTotali {
                let partenza = stato.gruppi[id]!.posizione
                let nome = stato.gruppi[id]!.nome
                stato.gruppi[id]!.posizione = marcia.destinazione
                stato.gruppi[id]!.marcia = nil
                eventi.append(.marciaCompiuta(gruppo: id, nome: nome,
                                              da: partenza, a: marcia.destinazione))
                annota(.marciaCompiuta(gruppo: nome, da: partenza, a: marcia.destinazione), in: &stato)
            } else {
                stato.gruppi[id]!.marcia = marcia
            }
        }
        return eventi
    }

    /// Annota un fatto nel registro della campagna (01 §5.17, 02 §6.6). Il giorno
    /// è quello corrente al momento del fatto e resta scritto nella voce.
    public func annota(_ fatto: FattoRegistrato, in stato: inout StatoCampagna) {
        stato.registro.append(VoceRegistro(numero: stato.prossimoNumeroVoce,
                                           giorno: stato.giorno, fatto: fatto))
        stato.prossimoNumeroVoce += 1
    }
}
