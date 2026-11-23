#!/usr/bin/env python3
"""caelestia4: list UI strings with no Vietnamese translation yet.
end-4 strings: Translation.tr("...") -> dots/.config/quickshell/ii/translations/<lang>.json
Caelestia strings: Tr.tr / Tr.trCtx / Tr.trN, and Tr.mark / Tr.markCtx / Tr.markN / Tr.markCtxN (data tables,
translated later with Tr.tr) -> tools/i18n/caelestia-<lang>.po (compiled into the Caelestia plugin)
Usage: tools/i18n-missing.py [lang=vi_VN] [--json OUT] [--under DIR] [--strict]
  (prints counts; --json writes {"end4": [...], "caelestia": [...]}; --under counts only strings used in files under DIR;
  --strict also lists the missing strings and exits 1 when there are any)
"""
import argparse, glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QML = os.path.join(ROOT, "dots/.config/quickshell/ii")
# argparse, so the --json value (out.json, no slash) is never taken for the language
ap = argparse.ArgumentParser(description="List UI strings with no translation yet.")
ap.add_argument("lang", nargs="?", default="vi_VN")
ap.add_argument("--json", metavar="OUT", help='write {"end4": [...], "caelestia": [...]} to OUT')
ap.add_argument("--under", metavar="DIR", help="only strings used in files under DIR (e.g. the Nexus folder)")
ap.add_argument("--strict", action="store_true", help="list the missing strings and exit 1 when there are any")
args = ap.parse_args()
under = os.path.abspath(args.under) if args.under else None
lang, out = args.lang, args.json

S = r'"((?:[^"\\]|\\.)*)"'
pat_e4 = re.compile(r'Translation\.tr\(\s*' + S)
pat_tr = re.compile(r'\bTr\.tr\(\s*' + S)
pat_ctx = re.compile(r'\bTr\.trCtx\(\s*' + S + r'\s*,\s*' + S)
pat_n = re.compile(r'\bTr\.trN\(\s*' + S + r'\s*,\s*' + S)
# caelestia4: Tr.mark* only tags a string (data tables); the row shows it with Tr.tr later, so it needs a .po entry too
pat_mark = re.compile(r'\bTr\.mark\(\s*' + S)
pat_markctx = re.compile(r'\bTr\.markCtx\(\s*' + S + r'\s*,\s*' + S)
pat_markn = re.compile(r'\bTr\.markN\(\s*' + S + r'\s*,\s*' + S)
pat_markctxn = re.compile(r'\bTr\.markCtxN\(\s*' + S + r'\s*,\s*' + S + r'\s*,[^,]*,\s*' + S)
unesc = lambda s: json.loads('"' + s + '"')

e4, cae = set(), set()
for f in glob.glob(QML + "/**/*.qml", recursive=True):
    if under and not os.path.abspath(f).startswith(under + os.sep):
        continue
    s = open(f, errors="ignore").read()
    e4.update(unesc(x) for x in pat_e4.findall(s))
    cae.update(("", unesc(x), "") for x in pat_tr.findall(s))
    cae.update((unesc(c), unesc(x), "") for x, c in pat_ctx.findall(s))
    cae.update(("", unesc(x), unesc(p)) for x, p in pat_n.findall(s))
    cae.update(("", unesc(x), "") for x in pat_mark.findall(s))
    cae.update((unesc(c), unesc(x), "") for x, c in pat_markctx.findall(s))
    cae.update(("", unesc(x), unesc(p)) for x, p in pat_markn.findall(s))
    cae.update((unesc(c), unesc(x), unesc(p)) for x, p, c in pat_markctxn.findall(s))

# caelestia4: shell scripts and the lock screen use the end-4 catalogue too (scripts/caelestia4/tr.sh)
HYPRLOCK = os.path.join(ROOT, "dots/.config/hypr/hyprlock")
pat_sh = re.compile(r'''\btr_ "((?:[^"\\]|\\.)*)"''')
pat_py = re.compile(r'''\btr\(\s*["']([^"']+)["']''')
for f in [] if under else [*glob.glob(QML + "/scripts/**/*.sh", recursive=True), *glob.glob(HYPRLOCK + "/**/*.sh", recursive=True)]:
    s = open(f, errors="ignore").read()
    e4.update(unesc(x) for x in pat_sh.findall(s) if not x.startswith("$"))
    e4.update(pat_py.findall(s))
for f, keys in {os.path.join(QML, "scripts/caelestia4/hyprlock-strings.sh"): re.compile(r'line \w+ "([^"]+)"'),
                os.path.join(ROOT, "tools/greetd-gen.py"): pat_py}.items():
    if os.path.exists(f) and not under:
        e4.update(keys.findall(open(f, errors="ignore").read()))

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
if args.strict and (miss_e4 or miss_cae):
    for x in miss_e4:
        print(f"  missing (end-4): {x!r}")
    for c, x, _ in miss_cae:
        print(f"  missing (Caelestia): {x!r}" + (f" (context {c!r})" if c else ""))
    sys.exit(1)
