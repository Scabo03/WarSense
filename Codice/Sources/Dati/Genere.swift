import Foundation

/// Il genere e il numero grammaticale di un termine chiuso che fa da soggetto di frase (02 §4.6,
/// decisione del titolare del 2026-11-21, incarico 29). Quattro valori, perché in italiano articoli e
/// accordi cambiano col genere e col numero: «La tua fanteria leggera A è stata ingaggiata», «Il tuo
/// carro B è stato ingaggiato», «I tuoi tiratori C sono stati ingaggiati».
public enum Genere: String, CaseIterable, Sendable {
    case maschile, femminile
    case maschilePlurale = "maschile_plurale"
    case femminilePlurale = "femminile_plurale"
}

/// Le categorie dei termini chiusi che fanno da soggetto di frase e perciò dichiarano il proprio
/// genere nel file del vocabolario (02 §4.6): i reparti e gli archetipi, i nomi dei gruppi. I titoli
/// dei campioni della modalità a campioni si aggiungeranno qui quando la modalità sarà costruita
/// (documento della modalità a campioni, 7.4), e il controllo del collaudo li coprirà da sé.
public enum CategoriaSoggetto: String, CaseIterable, Sendable {
    case unita
    case gruppo = "gruppo.nome"

    /// Il prefisso delle chiavi della categoria nel vocabolario.
    public var prefisso: String { rawValue + "." }
}

/// Un termine chiuso che fa da soggetto, con il genere che il vocabolario gli dichiara. Si ottiene
/// soltanto da `Testi.soggetto(_:_:)` e il suo testo entra in una frase soltanto attraverso
/// `Testi.frase(_:soggetto:verbosita:tavola:_:)`, che sceglie la forma scritta per il suo genere: il
/// testo del termine non è pubblico, sicché il compilatore stesso impedisce di incollarlo in una frase
/// che non ne conosce il genere (00 §14.2). L'unica uscita del termine da solo, per una voce che non è
/// una frase, è `Testi.nomeIsolato(_:)`, e il controllo del collaudo ne sorveglia i luoghi.
public struct Soggetto: Sendable, Hashable {
    public let categoria: CategoriaSoggetto
    public let identificatore: String
    /// Il genere dichiarato nel vocabolario; nulla se non è dichiarato o è fuori dai quattro, e allora
    /// ogni frase che lo riceve si risolve nel marcatore di chiave irrisolta (il collaudo lo rifiuta).
    public let genere: Genere?
    /// Il termine nella lingua del pacchetto: interno al modulo.
    let testo: String

    /// La chiave del termine nel vocabolario.
    public var chiave: String { categoria.prefisso + identificatore }
}

extension Testi {

    /// La chiave della dichiarazione di genere di un termine del vocabolario.
    public static func chiaveDelGenere(_ chiaveTermine: String) -> String { "genere." + chiaveTermine }

    /// La chiave della forma di una frase per un genere: `<chiave>.<genere>`.
    public static func chiaveAccordata(_ chiave: String, genere: Genere) -> String { chiave + "." + genere.rawValue }

    /// Il termine chiuso di una categoria di soggetti, con il suo genere (02 §4.6).
    public func soggetto(_ categoria: CategoriaSoggetto, _ identificatore: String) -> Soggetto {
        let chiave = categoria.prefisso + identificatore
        let testo = risolvi(chiave, tavola: "Vocabolario", argomenti: []).testo
        let dichiarato = risolvi(Testi.chiaveDelGenere(chiave), tavola: "Vocabolario", argomenti: []).testo
        return Soggetto(categoria: categoria, identificatore: identificatore,
                        genere: Genere(rawValue: dichiarato), testo: testo)
    }

    /// La frase accordata al genere del soggetto: la forma `<chiave>.<genere>`, oppure la sua variante di
    /// verbosità `<chiave>.<genere>.<livello>` se esiste (05 §8.5). Il soggetto è SEMPRE l'argomento 1
    /// della frase: le forme che lo nominano altrove lo indicano per posizione (`%1$@`), e gli altri
    /// argomenti seguono nell'ordine dato. Una forma mancante, o un soggetto senza genere dichiarato, dà
    /// il marcatore di chiave irrisolta, che il collaudo intercetta.
    public func frase(_ chiave: String, soggetto: Soggetto, verbosita: Verbosita? = nil,
                      tavola: String = "Annunci", _ argomenti: any CVarArg...) -> TestoLocalizzato {
        guard let genere = soggetto.genere, soggetto.testo != Testi.segnaposto else {
            return TestoLocalizzato(testo: Testi.segnaposto, lingua: lingua)
        }
        let forma = Testi.chiaveAccordata(chiave, genere: genere)
        let tutti: [any CVarArg] = [soggetto.testo] + argomenti
        if let verbosita {
            let specifica = risolvi(forma + "." + verbosita.rawValue, tavola: tavola, argomenti: tutti)
            if specifica.testo != Testi.segnaposto { return specifica }
        }
        return risolvi(forma, tavola: tavola, argomenti: tutti)
    }

    /// Il termine da solo, per una voce che non è una frase: il nome di una tessera del deck, l'iniziale
    /// di un gruppo disegnata sulla casella. Il controllo del collaudo ammette questa uscita soltanto nei
    /// luoghi che dichiara (`AccordoDiGenereTest`).
    public func nomeIsolato(_ soggetto: Soggetto) -> TestoLocalizzato {
        TestoLocalizzato(testo: soggetto.testo, lingua: lingua)
    }
}
