pragma ComponentBehavior: Bound

// caelestia4: app icon for an audio stream (bar audio popout and the overlay mixer); click mutes/unmutes it.
// Icon resolution, best first:
//  1. the stream's application.icon-name, if the icon theme has it
//  2. the icon of the window that owns the stream: walk the stream's process parents up to a pid that
//     has a Hyprland window, and resolve that window class like the dock does (end-4 AppSearch). This
//     handles Chromium/Electron apps, whose audio comes from a child process and whose icon-name is
//     generic (Brave Origin reports "brave-browser", which isn't installed)
//  3. a desktop entry matching the binary / application name
//  4. a music-note symbol (never a broken image)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

Item {
    id: appIcon

    required property PwNode stream
    property bool muted
    property list<int> ancestors: []

    readonly property var props: stream?.properties ?? ({})
    readonly property string iconSource: {
        const named = props["application.icon-name"] ?? "";
        if (named && Quickshell.iconPath(named, true) !== "")
            return Quickshell.iconPath(named);

        // Nearest ancestor with a window; among windows of the same process prefer the plain app over web-app
        // shortcuts (shortest class, e.g. "brave-origin" over "brave-<app id>-Default")
        for (const pid of ancestors) {
            const windows = E4.HyprlandData.windowList.filter(w => w.pid === pid);
            if (windows.length === 0)
                continue;
            windows.sort((a, b) => a.class.length - b.class.length);
            const icon = E4.AppSearch.guessIcon(windows[0].class);
            if (icon && Quickshell.iconPath(icon, true) !== "")
                return Quickshell.iconPath(icon);
        }

        for (const name of [props["application.process.binary"], props["application.name"]]) {
            const icon = name ? DesktopEntries.heuristicLookup(name)?.icon : "";
            if (icon && Quickshell.iconPath(icon, true) !== "")
                return Quickshell.iconPath(icon);
        }
        return "";
    }

    signal clicked

    implicitWidth: Tokens.padding.medium * 4
    implicitHeight: implicitWidth

    Process {
        running: (appIcon.props["application.process.id"] ?? "") !== ""
        command: ["sh", "-c", "p=\"$1\"; while [ \"$p\" -gt 1 ] 2>/dev/null; do echo \"$p\"; p=$(sed 's/.*) //' /proc/$p/stat 2>/dev/null | cut -d' ' -f2) || break; done", "sh", String(appIcon.props["application.process.id"] ?? "")]
        stdout: StdioCollector {
            onStreamFinished: appIcon.ancestors = text.split("\n").filter(l => l.length > 0).map(l => parseInt(l))
        }
    }

    IconImage {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall
        visible: appIcon.iconSource !== ""
        asynchronous: true
        source: appIcon.iconSource
        opacity: appIcon.muted ? 0.35 : 1
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: appIcon.iconSource === "" || appIcon.muted
        text: appIcon.muted ? "volume_off" : "music_note"
        color: appIcon.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
    }

    StateLayer {
        radius: Tokens.rounding.full
        onClicked: appIcon.clicked()
    }
}
