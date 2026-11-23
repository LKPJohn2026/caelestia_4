#!/usr/bin/env bash
# caelestia4: scripts/caelestia4/random-wallpaper.sh downloads only an https link from the wallpaper site's reply (not
# file://, gopher://, plain http://), with a plain file extension, and tells curl to stay on https.
# A copy of the script in a temporary directory, a fake HOME, a stub curl (answers the API with the link under test,
# writes a file for the download; never the network) and a stub switchwall.sh.
# Usage: tools/tests/random-wallpaper/run.sh
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
fails=0
ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails + 1)); }

mkdir -p "$tmp/bin" "$tmp/home" "$tmp/pics" "$tmp/ii/scripts/caelestia4" "$tmp/ii/scripts/colors"
cp "$repo/dots/.config/quickshell/ii/scripts/caelestia4/random-wallpaper.sh" "$tmp/ii/scripts/caelestia4/"
log="$tmp/calls.log"
cat >"$tmp/bin/curl" <<EOF
#!/usr/bin/env bash
# the API: the link under test (\$LINK); a download: a file at -o
echo "curl \$*" >>"$log"
case " \$* " in
  *" --proto =https --proto-redir =https "*) ;;
  *) echo "noproto" >>"$log" ;;
esac
if [[ " \$* " == *" -o "* ]]; then
  while [[ \$# -gt 0 ]]; do [[ \$1 == -o ]] && { printf x >"\$2"; echo download >>"$log"; }; shift; done
else
  jq -n --arg l "\$LINK" '{data: [{path: \$l, resolution: "1x1"}]}'
fi
EOF
printf '#!/bin/sh\necho "switchwall $*" >>"%s"\n' "$log" >"$tmp/ii/scripts/colors/switchwall.sh"
printf '#!/bin/sh\necho "%s"\n' "$tmp/pics" >"$tmp/bin/xdg-user-dir"
chmod +x "$tmp/bin/curl" "$tmp/bin/xdg-user-dir" "$tmp/ii/scripts/colors/switchwall.sh"

fetch() { # fetch LINK: the script with the API giving LINK; its exit code
  : >"$log"; rm -rf "${tmp:?}/pics/Wallpapers"
  local code=0
  env -i PATH="$tmp/bin:/usr/bin:/bin" HOME="$tmp/home" LINK="$1" bash "$tmp/ii/scripts/caelestia4/random-wallpaper.sh" wallhaven >/dev/null 2>&1 || code=$?
  return $code
}

for link in "file:///etc/hostname" "file://$tmp/home/notes.secret" "gopher://127.0.0.1:70/_x.jpg" "http://w.example/a.jpg" \
  "dict://127.0.0.1/x.png" "https://w.example/a.jp/g" "https://w.example/a b.jpg" "https://w.example/noext"; do
  code=0; fetch "$link" || code=$?
  if [[ $code -eq 1 ]] && ! grep -qE '^(download|switchwall)' "$log" && ! compgen -G "$tmp/pics/Wallpapers/*" >/dev/null; then
    ok "refused: $link"
  else bad "not refused (exit $code): $link: $(cat "$log")"; fi
done

code=0; fetch "https://w.example/full/ab/wallhaven-ab12cd.jpg" || code=$?
[[ $code -eq 0 ]] && grep -q '^download' "$log" && grep -q "^switchwall --image $tmp/pics/Wallpapers/random_wallpaper.jpg" "$log" &&
  ok "an https link is downloaded and applied" || bad "an https link (exit $code): $(cat "$log")"
grep -q '^noproto' "$log" && bad "a curl without --proto =https --proto-redir =https" || ok "every curl stays on https"

if ((fails)); then echo "random-wallpaper tests: $fails FAILED"; exit 1; fi
echo "random-wallpaper tests: OK"
