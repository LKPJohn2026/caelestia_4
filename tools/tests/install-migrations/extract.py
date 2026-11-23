"""Pieces of tools/install-main.sh for tools/tests/install-migrations/run.sh (prints nothing when not found once):
  extract.py sed FILE NEEDLE         the one `sed -i` statement holding NEEDLE, continued lines joined
  extract.py heredoc FILE START      the body of the <<'PY' here-document on the line holding START
  extract.py sed-address STATEMENT   the text the first /^...$/{N;...} address of a sed statement matches
"""
import re
import sys


def statements(text):
    """Logical lines: a line ending in a backslash goes on with the next one"""
    out, cur = [], ""
    for line in text.splitlines():
        if line.endswith("\\"):
            cur += line[:-1] + " "
            continue
        out.append(cur + line)
        cur = ""
    return out


def main():
    mode = sys.argv[1]
    if mode == "sed":
        text = open(sys.argv[2], encoding="utf-8").read()
        hits = [s.strip() for s in statements(text) if s.strip().startswith("sed -i") and sys.argv[3] in s]
        if len(hits) != 1:
            print(f"extract.py: {len(hits)} sed statements hold {sys.argv[3]!r}", file=sys.stderr)
            return
        print(hits[0])
    elif mode == "heredoc":
        lines = open(sys.argv[2], encoding="utf-8").read().splitlines()
        starts = [i for i, l in enumerate(lines) if sys.argv[3] in l and l.rstrip().endswith("<<'PY'")]
        if len(starts) != 1:
            print(f"extract.py: {len(starts)} here-documents start with {sys.argv[3]!r}", file=sys.stderr)
            return
        body = []
        for line in lines[starts[0] + 1:]:
            if line == "PY":
                print("\n".join(body))
                return
            body.append(line)
    elif mode == "sed-address":
        m = re.search(r"'/\^(.*?)\$?/\{N;", sys.argv[2])
        if m:
            print(re.sub(r"\\(.)", r"\1", m.group(1)))


main()
