#!/usr/bin/env bash
# Tests for tools/i18n-missing.py: a copy of it runs on a small fake tree under a temporary directory (QML, a script
# with tr_, an end-4 catalogue and a Caelestia .po), and the counts, --json, --under and --strict's exit code are checked.
# Usage: tools/tests/i18n-missing/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tool="$here/../../i18n-missing.py"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

qml="$tmp/dots/.config/quickshell/ii"
mkdir -p "$tmp/tools/i18n" "$qml/translations" "$qml/scripts/caelestia4" "$qml/modules/nexus"
cp "$tool" "$tmp/tools/"
cat >"$qml/modules/Bar.qml" <<'QML'
Text { text: Translation.tr("Battery") }
Text { text: Tr.tr("Wallpaper") }
Text { text: Tr.trCtx("Open", "menu") }
QML
cat >"$qml/modules/nexus/Page.qml" <<'QML'
Text { text: Tr.tr("Nexus only") }
QML
cat >"$qml/scripts/caelestia4/job.sh" <<'SH'
echo "$(tr_ "Job done")"
SH

# catalogues END4_JSON PO: write both
catalogues() {
  printf '%s\n' "$1" >"$qml/translations/vi_VN.json"
  printf '%s\n' "$2" >"$tmp/tools/i18n/caelestia-vi_VN.po"
}
po_wallpaper='msgid "Wallpaper"
msgstr "Hình nền"'
po_open='msgctxt "menu"
msgid "Open"
msgstr "Mở"'
po_nexus='msgid "Nexus only"
msgstr "Chỉ Nexus"'
run() { python3 -I "$tmp/tools/i18n-missing.py" "$@"; }

# 1. everything translated: --strict passes
catalogues '{"Battery": "Pin", "Job done": "Xong"}' "$po_wallpaper"$'\n\n'"$po_open"$'\n\n'"$po_nexus"
if out=$(run --strict); then
  if grep -q '^end-4: 2 strings, 0 missing' <<<"$out" && grep -q '^Caelestia: 3 strings, 0 missing' <<<"$out"; then
    ok "all translated: counts, exit 0"
  else
    bad "all translated: unexpected output: $out"
  fi
else
  bad "all translated: --strict exited $?"
fi

# 2. one of each missing: a plain run exits 0, --strict exits 1 and names them
catalogues '{"Battery": "Pin"}' "$po_wallpaper"$'\n\n'"$po_nexus"
if out=$(run); then
  if grep -q '^end-4: 2 strings, 1 missing' <<<"$out" && grep -q '^Caelestia: 3 strings, 1 missing' <<<"$out"; then
    ok "missing: counts without --strict, exit 0"
  else
    bad "missing: unexpected output: $out"
  fi
else
  bad "missing: plain run exited $?"
fi
rc=0
out=$(run --strict) || rc=$?
if [[ $rc -eq 1 ]] && grep -q "missing (end-4): 'Job done'" <<<"$out" \
  && grep -q "missing (Caelestia): 'Open' (context 'menu')" <<<"$out"; then
  ok "missing: --strict exits 1 and lists them"
else
  bad "missing: --strict gave $rc: $out"
fi

# 3. --json lists the same; --under counts only that folder (and no scripts)
run --json "$tmp/out.json" >/dev/null
if [[ $(jq -c . "$tmp/out.json") == '{"end4":["Job done"],"caelestia":[["menu","Open",""]]}' ]]; then
  ok "--json"
else
  bad "--json: $(cat "$tmp/out.json")"
fi
if out=$(run --strict --under "$qml/modules/nexus") && grep -q '^Caelestia: 1 strings, 0 missing' <<<"$out" \
  && grep -q '^end-4: 0 strings' <<<"$out"; then
  ok "--under with --strict"
else
  bad "--under: $out"
fi

# 4. no catalogue: everything counts as missing
rm "$qml/translations/vi_VN.json"
rc=0
run --strict >/dev/null || rc=$?
if [[ $rc -eq 1 ]]; then ok "no catalogue: --strict exits 1"; else bad "no catalogue: --strict exited $rc"; fi

if ((fails)); then
  echo "i18n-missing tests: $fails FAILED"
  exit 1
fi
echo "i18n-missing tests: OK"
