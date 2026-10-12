#!/usr/bin/env bash
# caelestia4: instantiate settings pages headlessly (no window shown) and print errors/warnings they produce.
# Usage: tools/check-settings-pages.sh [page.qml ...]   (paths relative to the ii config; default: modules/settings/c4/*Page.qml)
set -uo pipefail
ii="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii"
cd "$ii"
pages=("$@"); ((${#pages[@]})) || mapfile -t pages < <(ls modules/settings/c4/*Page.qml 2>/dev/null)
list=$(printf '"%s",' "${pages[@]}")
cat > zz-pagecheck.qml <<QML
import QtQuick
import Quickshell
import qs.modules.settings.c4
ShellRoot {
    Component.onCompleted: {
        for (const f of [${list%,}]) {
            const c = Qt.createComponent("file://" + Quickshell.shellPath(f));
            if (c.status !== Component.Ready) { console.log("PAGECHECK FAIL", f, c.errorString()); continue; }
            const o = c.createObject(null, { width: 900, height: 900 });
            console.log("PAGECHECK", o ? "OK  " : "FAIL", f);
        }
        quitTimer.start();
    }
    Timer { id: quitTimer; interval: 2500; onTriggered: Qt.quit() }
}
QML
timeout 40 qs -p zz-pagecheck.qml 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g' | grep -E "PAGECHECK|WARN|ERROR" | grep -vE "Translation.qml|vi_VN.json|compose table|textinput" | sed 's/^ *//' | sort | uniq -c | sort -rn | head -40
rm -f zz-pagecheck.qml
