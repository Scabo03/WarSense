set -e
A="$1"
cp "$(dirname "$0")/Registro.swift" "$A/Codice/Sources/Segnali/Lab.swift"
python3 - "$A" <<'PY'
import sys
a=sys.argv[1]
p=a+"/Codice/Sources/Segnali/PuntoSegnali.swift"
t=open(p,encoding="utf-8").read()
import re
# Ogni pubblicazione di un annuncio lascia nel registro il testo e la priorità con cui esce.
t,quante=re.subn(r"( *)(UIAccessibility\.post\(notification: \.announcement, argument: ([A-Za-z.]+)\))",
                 lambda m: m.group(1)+"Lab.pubblicato("+m.group(3)+")\n"+m.group(1)+m.group(2), t)
assert quante>=1, "nessuna pubblicazione trovata"
t=t.replace("        self.testi = testi\n        self.definizioni = definizioni","        Lab.installa()\n        self.testi = testi\n        self.definizioni = definizioni",1)
open(p,"w",encoding="utf-8").write(t)
p=a+"/Applicazione/Sorgenti/Servizi.swift"
t=open(p,encoding="utf-8").read()
t=t.replace("        UIAccessibility.post(notification: .screenChanged, argument: elemento)","        Lab.fuocoChiesto(elemento)\n        UIAccessibility.post(notification: .screenChanged, argument: elemento)")
open(p,"w",encoding="utf-8").write(t)
PY
grep -c "Lab\." "$A/Codice/Sources/Segnali/PuntoSegnali.swift"
