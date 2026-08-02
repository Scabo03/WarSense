import Foundation

/// SHA-256 in Swift puro. Serve alle impronte dei file (05 §7.2) e all'impronta
/// canonica dello stato (05 §2.9). Implementazione propria perché Dati e Motore
/// importano soltanto Foundation (05 §1.3) e CryptoKit resterebbe fuori confine.
/// Deterministica per costruzione su ogni piattaforma.
public enum SHA256 {
    private static let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ]

    public static func impronta(_ dati: Data) -> Data {
        var h: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                           0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
        var messaggio = dati
        let lunghezzaBit = UInt64(dati.count) * 8
        messaggio.append(0x80)
        while messaggio.count % 64 != 56 { messaggio.append(0) }
        for spostamento in stride(from: 56, through: 0, by: -8) {
            messaggio.append(UInt8((lunghezzaBit >> UInt64(spostamento)) & 0xff))
        }
        var w = [UInt32](repeating: 0, count: 64)
        for inizioBlocco in stride(from: 0, to: messaggio.count, by: 64) {
            for i in 0..<16 {
                let base = messaggio.index(messaggio.startIndex, offsetBy: inizioBlocco + i * 4)
                w[i] = (UInt32(messaggio[base]) << 24) | (UInt32(messaggio[messaggio.index(after: base)]) << 16)
                    | (UInt32(messaggio[messaggio.index(base, offsetBy: 2)]) << 8) | UInt32(messaggio[messaggio.index(base, offsetBy: 3)])
            }
            for i in 16..<64 {
                let s0 = rotazione(w[i - 15], 7) ^ rotazione(w[i - 15], 18) ^ (w[i - 15] >> 3)
                let s1 = rotazione(w[i - 2], 17) ^ rotazione(w[i - 2], 19) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }
            var (a, b, c, d, e, f, g, hh) = (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7])
            for i in 0..<64 {
                let s1 = rotazione(e, 6) ^ rotazione(e, 11) ^ rotazione(e, 25)
                let ch = (e & f) ^ (~e & g)
                let temp1 = hh &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = rotazione(a, 2) ^ rotazione(a, 13) ^ rotazione(a, 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj
                (hh, g, f, e, d, c, b, a) = (g, f, e, d &+ temp1, c, b, a, temp1 &+ temp2)
            }
            h[0] = h[0] &+ a; h[1] = h[1] &+ b; h[2] = h[2] &+ c; h[3] = h[3] &+ d
            h[4] = h[4] &+ e; h[5] = h[5] &+ f; h[6] = h[6] &+ g; h[7] = h[7] &+ hh
        }
        var uscita = Data(capacity: 32)
        for parola in h {
            uscita.append(UInt8((parola >> 24) & 0xff)); uscita.append(UInt8((parola >> 16) & 0xff))
            uscita.append(UInt8((parola >> 8) & 0xff)); uscita.append(UInt8(parola & 0xff))
        }
        return uscita
    }

    public static func improntaEsadecimale(_ dati: Data) -> String {
        impronta(dati).map { String(format: "%02x", $0) }.joined()
    }

    private static func rotazione(_ x: UInt32, _ n: UInt32) -> UInt32 { (x >> n) | (x << (32 - n)) }
}
