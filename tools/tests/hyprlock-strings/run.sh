#!/usr/bin/env bash
# caelestia4: translations stay text where they meet code.
#  1. scripts/caelestia4/hyprlock-strings.sh writes hyprlock's strings.conf: with a catalogue whose values carry a line
#     break and a label block, or $(...), backticks and quotes, every line is still one $str_... variable, and the
#     cmd[] line of hyprlock/layout-full.conf that uses $str_locked_at / $str_keyboard, run with sh as hyprlock would,
#     runs nothing of it. The real Vietnamese strings come out unchanged.
#  2. QML: no `bash -c` command has a translation (Tr.tr / Translation.tr / qsTr) pasted into it.
# A fake HOME and a copy of the scripts in a temporary directory; never runs hyprlock or touches the desktop.
# Usage: tools/tests/hyprlock-strings/run.sh
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
ii="$repo/dots/.config/quickshell/ii"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

mkdir -p "$tmp/ii/scripts/caelestia4" "$tmp/ii/translations" "$tmp/home/.config/illogical-impulse" "$tmp/home/.config/hypr/hyprlock"
cp "$ii/scripts/caelestia4/tr.sh" "$ii/scripts/caelestia4/hyprlock-strings.sh" "$tmp/ii/scripts/caelestia4/"
cp "$ii/translations/vi_VN.json" "$tmp/ii/translations/"
conf="$tmp/home/.config/hypr/hyprlock/strings.conf"
strings() { # strings LANG: hyprlock-strings.sh in the fake HOME with language.ui = LANG
  printf '{"language":{"ui":"%s"}}\n' "$1" >"$tmp/home/.config/illogical-impulse/config.json"
  env -i PATH="$PATH" HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" bash "$tmp/ii/scripts/caelestia4/hyprlock-strings.sh"
}
value() { sed -n "s/^\$$1 = //p" "$conf"; }

# 1a. Vietnamese, unchanged
strings vi_VN
[[ "$(value str_password)" == "Nhập mật khẩu" && "$(value str_locked_at)" == "Khoá lúc" && "$(value str_keyboard)" == "Bàn phím" ]] &&
  ok "the Vietnamese strings are written as they are" || bad "the Vietnamese strings changed: $(cat "$conf")"

# 1b. A hostile catalogue
python3 -I - "$tmp/ii/translations/xx_XX.json" "$tmp/home" <<'PY'
import json, sys
home = sys.argv[2]
json.dump({
    "Enter password": "Pw\nlabel {\n    text = cmd[update:0] touch " + home + "/pwned-newline\n}",
    "Locked at": 'Locked $(touch "' + home + '/pwned-dollar") `touch ' + home + '/pwned-tick` at',
    "Keyboard": 'Kb" ; touch ' + home + '/pwned-quote ; echo "\\ <b>&#',
}, open(sys.argv[1], "w"))
PY
strings xx_XX
if grep -qvE '^(#.*|\$str_[a-z_]+ = [^$`"\\]*)$' "$conf"; then
  bad "strings.conf has a line that isn't one plain variable: $(grep -vE '^(#.*|\$str_[a-z_]+ = [^$`"\\]*)$' "$conf")"
else ok "every line of strings.conf is one variable with no \$ \` \" \\"; fi
[[ $(grep -c '^\$str_' "$conf") -eq 3 ]] && ok "three variables, no more" || bad "not three variables"
value str_keyboard | grep -q '&lt;b&gt;&amp;##' && ok "Pango's & < > escaped, # doubled for hyprlang" || bad "markup not escaped: $(value str_keyboard)"

# The cmd[] line as hyprlock runs it: hyprlang puts the variables in (## is a #), then sh -c
line=$(sed -n 's/^ *text = cmd\[update:0\] \(.*\$str_locked_at.*\)$/\1/p' "$repo/dots/.config/hypr/hyprlock/layout-full.conf")
[[ -n "$line" ]] || bad "layout-full.conf has no cmd[] line with \$str_locked_at (update this test)"
locked=$(value str_locked_at | sed 's/##/#/g') keyboard=$(value str_keyboard | sed 's/##/#/g')
line=${line//\$str_locked_at/$locked}
line=${line//\$str_keyboard/$keyboard}
line=${line//\$LAYOUT/us}
(cd "$tmp/home" && env -i PATH="$PATH" HOME="$tmp/home" sh -c "$line" >/dev/null 2>&1) || true
if compgen -G "$tmp/home/pwned-*" >/dev/null; then bad "a translation ran in hyprlock's cmd[]: $(ls "$tmp/home")"
else ok "nothing in a translation runs in layout-full.conf's cmd[]"; fi

# 2. QML: a translation never inside a bash -c command
# The code after "-c" up to the next argument's comma, across lines: template literals and "..." + "..." joins
guard() {
  python3 -I - "$1" <<'PY'
import pathlib, re, sys
tr = re.compile(r"\b(Tr\.tr|Translation\.tr|qsTr)\(")


def script(text, i):
    """The code of the argument after "-c" (from i): its JS, with strings and nested `${...}` followed, up to the
    comma or ] that ends it. A translation anywhere in it is part of the shell code"""
    stack, j = [["code", 0]], i  # frames: code (with its bracket depth), a template literal, a quoted string
    while j < len(text):
        c, top = text[j], stack[-1]
        if top[0] == "tpl":
            if c == "\\": j += 1
            elif c == "`": stack.pop()
            elif text.startswith("${", j): stack.append(["code", 0]); j += 1
        elif top[0] in ('"', "'"):
            if c == "\\": j += 1
            elif c == top[0] or c == "\n": stack.pop()
        elif c in "\"'": stack.append([c, 0])
        elif c == "`": stack.append(["tpl", 0])
        elif c == "/" and text[i:j].rstrip()[-1:] in tuple("(,=:[!&|?{};"):  # a regex literal, as in .replace(/x/, "")
            m = re.compile(r"/(?:[^/\\\[\n]|\\.|\[(?:[^\]\\\n]|\\.)*\])*/").match(text, j)
            if m: j = m.end() - 1
        elif text.startswith("//", j):
            j = text.find("\n", j)
            if j < 0: break
        elif c in "([{": top[1] += 1
        elif c in ")]}":
            if top[1]: top[1] -= 1
            elif len(stack) > 1: stack.pop()  # the } of a ${...}
            else: break
        elif c == "," and top[1] == 0 and len(stack) == 1: break
        j += 1
    return text[i:j]


for f in sorted(pathlib.Path(sys.argv[1]).rglob("*.qml")):
    text = f.read_text(errors="replace")
    for m in re.finditer(r'"-c"\s*,', text):
        if tr.search(script(text, m.end())):
            print(f"{f}:{text.count(chr(10), 0, m.start()) + 1}")
PY
}
hits=$(guard "$ii")
[[ -z "$hits" ]] && ok "no translation pasted into a bash -c command in QML" || bad "a translation is pasted into bash -c: $hits"
# the guard itself, on a command split over lines as BooruImage.qml's was
mkdir -p "$tmp/qml"
printf '%s\n' 'x(["bash", "-c",' '    `a && notify-send '"'"'${Translation.tr("Done")}'"'"'`])' >"$tmp/qml/A.qml"
printf '%s\n' 'x(["bash", "-c", "a " +' '    Tr.tr("Done")])' 'y(["bash", "-c", '"'"'notify-send "$1"'"'"', "bash", Tr.tr("Done")])' >"$tmp/qml/B.qml"
[[ "$(guard "$tmp/qml" | sed 's|.*/||')" == $'A.qml:1\nB.qml:1' ]] &&
  ok "the guard finds a translation in a command over two lines, and leaves one passed as an argument" ||
  bad "the guard missed a split command or flagged an argument: $(guard "$tmp/qml")"
hits=$(grep -rnE 'runInTerminal\(`[^`]*\$\{(Tr\.tr|Translation\.tr|qsTr)\(' "$ii" --include='*.qml' || true)
[[ -z "$hits" ]] && ok "no translation pasted into a runInTerminal command" || bad "a translation is pasted into runInTerminal: $hits"

if ((fails)); then echo "hyprlock-strings tests: $fails FAILED"; exit 1; fi
echo "hyprlock-strings tests: OK"
