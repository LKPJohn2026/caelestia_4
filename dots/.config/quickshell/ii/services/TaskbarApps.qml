pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    // caelestia4: which pins are neither a desktop entry nor a command (the dock runs a pin with no entry as one). Asked
    // again when the pins or the entries change: the entries arrive after the start
    property var absentPins: ({})
    readonly property var pinsWithoutEntry: {
        void DesktopEntries.applications.values;
        return (Config.options?.dock.pinnedApps ?? []).filter(appId => !DesktopEntries.heuristicLookup(appId));
    }
    onPinsWithoutEntryChanged: pinProbeDelay.restart()
    Timer {
        id: pinProbeDelay
        interval: 1000
        running: true
        onTriggered: {
            if (pinProbe.running) {
                restart();
            } else if (root.pinsWithoutEntry.length === 0) {
                root.absentPins = ({});
            } else {
                pinProbe.command = ["bash", "-c", 'for pin in "$@"; do command -v -- "${pin%% *}" >/dev/null || printf "%s\\n" "$pin"; done', "_", ...root.pinsWithoutEntry];
                pinProbe.running = true;
            }
        }
    }
    Process {
        id: pinProbe
        stdout: StdioCollector {
            onStreamFinished: {
                const absent = {};
                for (const pin of text.split("\n"))
                    if (pin) absent[pin] = true;
                root.absentPins = absent;
            }
        }
    }

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        // caelestia4: a pin for an app this machine doesn't have stays in the settings but shows nothing
        const openWindows = ToplevelManager.toplevels.values;
        const pinnedApps = (Config.options?.dock.pinnedApps ?? []).filter(appId => !root.absentPins[appId]
            || openWindows.some(toplevel => toplevel.appId.toLowerCase() === appId.toLowerCase()));
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned }));
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}
