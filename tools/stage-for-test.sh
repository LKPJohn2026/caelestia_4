#!/usr/bin/env bash
# Stage this repo's Quickshell config + the user-local Caelestia plugin in /var/tmp so a TEST user
# (e.g. e4test) can install them into its own home. Run as the main user; then, as the test user:
#   bash /var/tmp/caelestia4-stage/deploy.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
STAGE=/var/tmp/caelestia4-stage
PLUGIN="$HOME/.local/lib/qt6/qml/Caelestia"
[[ -d "$PLUGIN" ]] || { echo "Plugin not built: run tools/build-caelestia-plugin.sh" >&2; exit 1; }
./tools/lint-caelestia.sh
./tools/compile-check.sh || { echo "Refusing to stage: compile-check failed" >&2; exit 1; }

rm -rf "$STAGE"
mkdir -p "$STAGE/qml"
rsync -a --exclude '.git' dots/.config/quickshell/ii/ "$STAGE/ii/"
rsync -a "$PLUGIN/" "$STAGE/qml/Caelestia/"
git rev-parse --short HEAD > "$STAGE/REVISION"
cat > "$STAGE/deploy.sh" <<'DEPLOY'
#!/usr/bin/env bash
# Run as the TEST user. Installs the staged caelestia_4 config + Caelestia plugin into this user's home.
set -euo pipefail
STAGE=/var/tmp/caelestia4-stage
QS="$HOME/.config/quickshell"
[[ "$(id -un)" != "windy_dust_2026" ]] || { echo "Refusing: run this as a TEST user, not the main account." >&2; exit 1; }
mkdir -p "$QS" "$HOME/.local/lib/qt6/qml"
if [[ -d "$QS/ii" && ! -d "$QS/ii.upstream-backup" ]]; then
  cp -a "$QS/ii" "$QS/ii.upstream-backup"
  echo "Backed up upstream end-4 config to $QS/ii.upstream-backup"
fi
rsync -a --delete "$STAGE/ii/" "$QS/ii/"
rsync -a --delete "$STAGE/qml/Caelestia/" "$HOME/.local/lib/qt6/qml/Caelestia/"
ENV="$HOME/.config/hypr/custom/env.lua"
if [[ -f "$ENV" ]] && ! grep -q 'QML_IMPORT_PATH' "$ENV"; then
  printf '\n-- caelestia_4: make the user-local Caelestia QML plugin visible to Quickshell (this session only)\nhl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")\n' >> "$ENV"
  echo "Added QML_IMPORT_PATH to $ENV (log out and back in once for it to apply)"
fi
echo "Deployed caelestia_4 @ $(cat "$STAGE/REVISION")"
echo "Restart the shell:  qs kill -c ii; qs -c ii -d    (or log out/in if QML_IMPORT_PATH was just added)"
DEPLOY
chmod -R a+rX "$STAGE"; chmod a+rx "$STAGE/deploy.sh"
echo "Staged @ $(cat "$STAGE/REVISION") in $STAGE"
