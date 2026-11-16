pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// caelestia4: whether Nexus's first-run welcome (navpane/Welcome.qml) was seen: a small file in
// ${XDG_STATE_HOME:-~/.local/state}/caelestia4, written on Done or Skip. `known` stays false until the file was read,
// so the welcome never flashes up for someone who has seen it. showAgain() (About) brings it back
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia4`
    readonly property string path: `${dir}/nexus-welcome.json`
    property bool known
    property bool done
    // Set by showAgain(): the welcome shows on the page that is open now (not only on a plain first open)
    property bool requested

    function finish(): void {
        root.done = true;
        root.requested = false;
        Quickshell.execDetached(["sh", "-c", 'mkdir -p -- "$1" && printf \'{"done": true}\\n\' > "$2"', "sh", root.dir, root.path]);
    }

    function showAgain(): void {
        Quickshell.execDetached(["rm", "-f", "--", root.path]);
        root.done = false;
        root.known = true;
        root.requested = true;
    }

    FileView {
        path: root.path
        printErrors: false
        onLoaded: {
            root.done = true;
            root.known = true;
        }
        onLoadFailed: {
            root.done = false;
            root.known = true;
        }
    }
}
