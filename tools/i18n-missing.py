#!/usr/bin/env python3
"""caelestia4: list UI strings with no Vietnamese translation yet.
end-4 strings: Translation.tr("...") -> dots/.config/quickshell/ii/translations/<lang>.json
Caelestia strings: Tr.tr / Tr.trCtx / Tr.trN -> tools/i18n/caelestia-<lang>.po (compiled into the Caelestia plugin)
Usage: tools/i18n-missing.py [lang=vi_VN] [--json OUT]   (prints counts; --json writes {"end4": [...], "caelestia": [...]})
"""
import glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QML = os.path.join(ROOT, "dots/.config/quickshell/ii")
lang = next((a for a in sys.argv[1:] if not a.startswith("--") and "/" not in a), "vi_VN")
out = sys.argv[sys.argv.index("--json") + 1] if "--json" in sys.argv else None

S = r'"((?:[^"\\]|\\.)*)"'
pat_e4 = re.compile(r'Translation\.tr\(\s*' + S)
pat_tr = re.compile(r'\bTr\.tr\(\s*' + S)
pat_ctx = re.compile(r'\bTr\.trCtx\(\s*' + S + r'\s*,\s*' + S)
pat_n = re.compile(r'\bTr\.trN\(\s*' + S + r'\s*,\s*' + S)
unesc = lambda s: json.loads('"' + s + '"')

e4, cae = set(), set()
for f in glob.glob(QML + "/**/*.qml", recursive=True):
    s = open(f, errors="ignore").read()
    e4.update(unesc(x) for x in pat_e4.findall(s))
    cae.update(("", unesc(x), "") for x in pat_tr.findall(s))
    cae.update((unesc(c), unesc(x), "") for x, c in pat_ctx.findall(s))
    cae.update(("", unesc(x), unesc(p)) for x, p in pat_n.findall(s))

tfile = os.path.join(QML, "translations", f"{lang}.json")
have = json.load(open(tfile)) if os.path.exists(tfile) else {}
miss_e4 = sorted(x for x in e4 if x not in have)

po = os.path.join(ROOT, "tools/i18n", f"caelestia-{lang}.po")
done = set()
if os.path.exists(po):
    txt = open(po).read()
    for m in re.finditer(r'(?:msgctxt "((?:[^"\\]|\\.)*)"\n)?msgid "((?:[^"\\]|\\.)*)"', txt):
        done.add((unesc(m.group(1) or ""), unesc(m.group(2))))
miss_cae = sorted(k for k in cae if (k[0], k[1]) not in done)

print(f"end-4: {len(e4)} strings, {len(miss_e4)} missing in {os.path.relpath(tfile, ROOT)}")
print(f"Caelestia: {len(cae)} strings, {len(miss_cae)} missing in {os.path.relpath(po, ROOT)}")
if out:
    json.dump({"end4": miss_e4, "caelestia": [list(k) for k in miss_cae]}, open(out, "w"), ensure_ascii=False, indent=1)
