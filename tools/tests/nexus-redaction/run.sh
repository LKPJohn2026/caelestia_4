#!/usr/bin/env bash
# Tests that scripts/caelestia4/nexus-export.sh (Nexus > About > Export my changes) and nexus-diagnostics.sh (Copy
# diagnostics), whose output goes into public bug reports, never let a secret through. Copies of both run on a fake
# HOME under a temporary directory with fake secrets planted in shell.json, a per-screen file, config.json and the
# shell's log (a stub qs); stub hyprctl, journalctl. Offline, nothing outside that directory is read but the scripts.
# The fake secrets are put together at run time, so this file has none for a secret scanner to find. Every one of them
# carries the marker below: none may appear in the output, and the settings that only look like secrets are kept.
# Usage: tools/tests/nexus-redaction/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

ii="$tmp/ii"
mkdir -p "$ii/scripts/caelestia4" "$ii/modules/caelestia/nexus/registry"
cp "$repo/dots/.config/quickshell/ii/scripts/caelestia4/nexus-export.sh" \
  "$repo/dots/.config/quickshell/ii/scripts/caelestia4/nexus-diagnostics.sh" "$ii/scripts/caelestia4/"
cp "$repo/dots/.config/quickshell/ii/modules/caelestia/nexus/registry/E4Defaults.js" "$ii/modules/caelestia/nexus/registry/"

# Pieces of the fake secrets: each value holds $m, the marker
m="QZXmark"
sk="sk""-${m}AbCdEf012345"
gh="gh""p_${m}0123456789abcdef"
goog="AI""za${m}SyAbCdEfGh"
basic="Basic ${m}dXNlcjpwYXNz="

export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" LC_ALL=C
cfg="$XDG_CONFIG_HOME"
mkdir -p "$cfg/caelestia/monitors/screen-a" "$cfg/illogical-impulse"

jq -n --arg m "$m" --arg sk "$sk" --arg gh "$gh" --arg goog "$goog" --arg basic "$basic" '{
  services: {apiKey: "plain\($m)1", weatherLocation: "Hanoi", city: "Plain city kept"},
  lock: {hidePasswordAfter: 5, requirePassword: true, password: "\($m)2"},
  launcher: {url: "https://bob:\($m)3@host.example/feed", home: "https://example.org/kept"},
  notes: {text: "my password is \($m)4"},
  ai: {accessToken: "\($m)5", model: "gemini kept", openaiKey: $sk},
  env: ["OPENAI_API_KEY=\($m)6", "EDITOR=nvim"],
  github: {line: "GITHUB_TOKEN=\($m)7", pat: $gh},
  weather: {api_key: "\($m)8", units: "metric"},
  feed: {link: "https://api.example/v1?q=news&key=\($m)9"},
  look: {label: $goog, header: $basic, auth: {user: "\($m)10", enabled: true}},
  bar: {clock: {cookie: {style: "kept object"}}, session: {cookie: "\($m)11"}},
  apps: {changePassword: "kitty -1 passwd"}
}' >"$cfg/caelestia/shell.json"
jq -n --arg m "$m" '{privateKey: "\($m)12", scale: "kept"}' >"$cfg/caelestia/monitors/screen-a/shell.json"
jq -n --arg m "$m" '{
  bar: {weather: {city: "Kept town"}},
  custom: {header: "Bearer \($m)13abcdefgh", credentials: {token: "\($m)14", note: "\($m)15", enabled: true}}
}' >"$cfg/illogical-impulse/config.json"

# ---- nexus-export.sh
out="$tmp/export.json"
if "$ii/scripts/caelestia4/nexus-export.sh" --stdout >"$out" 2>"$tmp/export.err" && jq empty "$out" 2>/dev/null; then
  ok "export: valid JSON"
else
  bad "export failed: $(cat "$tmp/export.err")"
fi
if grep -q "$m" "$out"; then
  bad "export: a planted secret got through:"$'\n'"$(grep -o "[^\"]*${m}[^\"]*" "$out" | sort -u)"
else
  ok "export: no planted secret in the output"
fi
for kept in "Plain city kept" "https://example.org/kept" "gemini kept" "EDITOR=nvim" "metric" "kept object" \
  "kitty -1 passwd" "Kept town" '"hidePasswordAfter": 5' '"requirePassword": true' '"enabled": true' \
  '"scale": "kept"'; do
  if grep -qF -- "$kept" <(jq . "$out"); then ok "export keeps: $kept"; else bad "export dropped: $kept"; fi
done
removed=$(jq -r '.removed[]' "$out" 2>/dev/null | sort | tr '\n' ' ')
for p in shell.services.apiKey shell.lock.password shell.launcher.url shell.notes.text shell.ai.accessToken \
  shell.ai.openaiKey shell.env.0 shell.github.line shell.github.pat shell.weather.api_key shell.feed.link \
  shell.look.label shell.look.header shell.look.auth.user shell.bar.session.cookie screens.screen-a.privateKey \
  config.custom.header config.custom.credentials.token config.custom.credentials.note; do
  if [[ " $removed" == *" $p "* ]]; then ok "export lists removed $p"; else bad "export doesn't list $p as removed (removed: $removed)"; fi
done
# A file target is private to its owner
mkdir -p "$tmp/out"
target=$("$ii/scripts/caelestia4/nexus-export.sh" "$tmp/out")
if [[ -f $target && $(stat -c %a "$target") == 600 && $target == "$tmp/out/caelestia4-settings-"*.json ]]; then
  ok "export to a folder: a dated file, mode 0600"
else
  bad "export to a folder: '$target'"
fi

# ---- nexus-diagnostics.sh: the export again, and the log through the stub qs
bin="$tmp/bin"
mkdir -p "$bin"
log_text="Loaded 12 wallpapers from $HOME/Pictures
Authorization: Bearer ${m}20abcdefghij
GET https://api.example/v1?api_key=${m}21&q=1
token '${m}22'
fetch https://alice:${m}23@git.example/repo.git
the password is ${m}24
X-Api-Key: ${m}25
key $sk
header $basic
proxy-authorization=Digest ${m}26
using $gh in a log line
Plain log line kept"
printf '#!/usr/bin/env bash\ncase "$1" in\n  --version) echo "quickshell 0.0.0-test" ;;\n  log) cat "%s" ;;\nesac\n' "$tmp/qs.log" >"$bin/qs"
printf '%s\n' "$log_text" >"$tmp/qs.log"
printf '#!/usr/bin/env bash\n[[ "$1 $2" == "version -j" ]] && echo %q\n' '{"tag":"v0.0.0","commit":"0123456789abc","branch":"main"}' >"$bin/hyprctl"
printf '#!/usr/bin/env bash\nexit 1\n' >"$bin/journalctl"
chmod +x "$bin"/*
diag="$tmp/diag.txt"
if PATH="$bin:$PATH" NEXUS_SHELL_PID=1 "$ii/scripts/caelestia4/nexus-diagnostics.sh" "$diag" >/dev/null 2>"$tmp/diag.err" && [[ -s $diag ]]; then
  ok "diagnostics: written"
else
  bad "diagnostics failed: $(cat "$tmp/diag.err")"
fi
[[ $(stat -c %a "$diag" 2>/dev/null) == 600 ]] && ok "diagnostics: mode 0600" || bad "diagnostics mode $(stat -c %a "$diag" 2>/dev/null)"
if grep -q "$m" "$diag"; then
  bad "diagnostics: a planted secret got through:"$'\n'"$(grep "$m" "$diag")"
else
  ok "diagnostics: no planted secret in the output"
fi
for kept in "Loaded 12 wallpapers from ~/Pictures" "Plain log line kept" "quickshell 0.0.0-test" "v0.0.0 (012345678, main)" \
  "Plain city kept" "== Changed settings (without secrets)"; do
  if grep -qF -- "$kept" "$diag"; then ok "diagnostics keeps: $kept"; else bad "diagnostics dropped: $kept"; fi
done
if grep -qF -- "$HOME" "$diag"; then bad "diagnostics: \$HOME not shortened to ~"; else ok "diagnostics: \$HOME reads ~"; fi
n=$(grep -c '<removed>' "$diag" || true)
[[ $n -ge 11 ]] && ok "diagnostics: $n values replaced in the log" || bad "diagnostics: only $n values replaced"

if ((fails)); then
  echo "nexus-redaction tests: $fails FAILED"
  exit 1
fi
echo "nexus-redaction tests: OK"
