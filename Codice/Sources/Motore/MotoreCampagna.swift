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
        case .marcia(let idGruppo, let destinazione):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            guard !gruppo.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            guard stato.griglia.contiene(destinazione) else { return .nonValido(.fuoriMappa) }
            guard stato.griglia.adiacenti(gruppo.posizione, destinazione) else {
                return .nonValido(.nonAdiacente)
            }
            // Ogni casella ospita al massimo una formazione della stessa parte
            // (01 §5.6.0.2), così che l'annuncio della casella resti di una frase.
            guard stato.occupante(di: destinazione, parte: parte) == nil else {
                return .nonValido(.occupata)
            }
            return .valido

        case .presidio(let idGruppo):
            guard let gruppo = stato.gruppi[idGruppo], gruppo.parte == parte else {
                return .nonValido(.gruppoIgnoto)
            }
            guard !gruppo.azioneSpesa else { return .nonValido(.azioneGiaSpesa) }
            return .valido
        }
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
        case .marcia(let idGruppo, let destinazione):
            let partenza = nuovo.gruppi[idGruppo]!.posizione
            let nome = nuovo.gruppi[idGruppo]!.nome
            nuovo.gruppi[idGruppo]!.posizione = destinazione
            // Ogni azione consuma l'intera giornata del gruppo, la marcia compresa
            // (01 §5.6.0.5): è la regola che rende il turno annunciabile con una
            // frase per gruppo.
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.marciaEseguita(gruppo: idGruppo, nome: nome,
                                          da: partenza, a: destinazione))

        case .presidio(let idGruppo):
            let gruppo = nuovo.gruppi[idGruppo]!
            nuovo.gruppi[idGruppo]!.azioneSpesa = true
            eventi.append(.presidioOrdinato(gruppo: idGruppo, nome: gruppo.nome,
                                            casella: gruppo.posizione))
        }

        eventi.append(contentsOf: chiudiLaGiornataSeServe(&nuovo))
        return (nuovo, eventi)
    }

    /// La chiusura del turno (01 §5.6.0.6): il turno di campagna si chiude
    /// automaticamente quando tutti i gruppi hanno agito, e NON esiste alcun
    /// comando di fine giornata. La chiusura è quindi la conseguenza dell'ultimo
    /// ordine del giocatore e non un'iniziativa del programma: nessun gruppo agisce
    /// da sé, nessuna risoluzione automatica interviene.
    func chiudiLaGiornataSeServe(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        guard !stato.gruppi.isEmpty,
              stato.gruppi.values.allSatisfy({ $0.azioneSpesa }) else { return [] }
        let chiuso = stato.giorno
        var eventi: [EventoCampagna] = [.giornataChiusa(giorno: chiuso)]
        stato.giorno += 1
        for id in stato.gruppi.keys.sorted() { stato.gruppi[id]!.azioneSpesa = false }
        annota(.giornataAperta, luogo: nil, in: &stato)
        eventi.append(.giornataAperta(giorno: stato.giorno))
        return eventi
    }

    /// Annota nel registro un fatto che il giocatore non ha deciso (01 §5.17.1).
    func annota(_ fatto: FattoRegistrato, luogo: Cella?, in stato: inout StatoCampagna) {
        stato.registro.append(VoceRegistro(numero: stato.prossimoNumeroVoce,
                                           giorno: stato.giorno, fatto: fatto, luogo: luogo))
        stato.prossimoNumeroVoce += 1
    }
}
