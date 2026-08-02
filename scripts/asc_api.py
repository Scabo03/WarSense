#!/usr/bin/env python3
"""Chiamate all'API di App Store Connect con JWT ES256 (chiave letta da percorso esterno)."""
import base64, json, sys, time, urllib.request, urllib.parse, os

# Le credenziali NON vivono nel repository: si leggono dall'ambiente, valorizzato
# dal file locale di configurazione fuori dal versionamento (vedi memoria-infrastruttura.md).
KEY_ID = os.environ["APP_STORE_CONNECT_API_KEY_ID"]
ISSUER = os.environ["APP_STORE_CONNECT_API_KEY_ISSUER_ID"]
KEY_PATH = os.path.expanduser(os.environ["APP_STORE_CONNECT_API_KEY_PATH"])

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

def b64url(d: bytes) -> str:
    return base64.urlsafe_b64encode(d).rstrip(b"=").decode()

def token() -> str:
    with open(KEY_PATH, "rb") as f:
        chiave = serialization.load_pem_private_key(f.read(), password=None)
    ora = int(time.time())
    header = {"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}
    payload = {"iss": ISSUER, "iat": ora, "exp": ora + 1200, "aud": "appstoreconnect-v1"}
    base = b64url(json.dumps(header).encode()) + "." + b64url(json.dumps(payload).encode())
    firma_der = chiave.sign(base.encode(), ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(firma_der)
    firma = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return base + "." + b64url(firma)

def chiama(metodo: str, percorso: str, corpo=None):
    url = "https://api.appstoreconnect.apple.com" + percorso
    dati = json.dumps(corpo).encode() if corpo is not None else None
    req = urllib.request.Request(url, data=dati, method=metodo)
    req.add_header("Authorization", "Bearer " + token())
    if dati: req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            testo = r.read().decode()
            return json.loads(testo) if testo else {}
    except urllib.error.HTTPError as e:
        print("ERRORE", e.code, e.read().decode()[:500], file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    metodo, percorso = sys.argv[1], sys.argv[2]
    corpo = json.loads(sys.stdin.read()) if len(sys.argv) > 3 and sys.argv[3] == "-" else None
    print(json.dumps(chiama(metodo, percorso, corpo), indent=1))
