pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep

// caelestia4: mute games while they are in the background.
// Games only hear about focus through Wine/X11 focus events, and many have no "mute in background" option, so the
// shell does it: playback streams whose process (application.process.id) owns a game window (class matches
// caelestia.backgroundMute.classes) are muted while that window is not the focused one, and unmuted when it is
// focused again. Only streams muted here are ever unmuted, so a manual mute is kept. Opening shell panels
// (launcher, drawers) does not count as leaving the game: they are layers, not windows.
// The process id is a property of the PipeWire client, and only some clients (pipewire-pulse ones) copy it onto
// their stream nodes; Wine's native streams don't (Star Rail: the node has only client.id). Quickshell exposes nodes,
// not clients, so the client ids are mapped to process ids with pw-dump (clientPids) when the streams change.
// Toggle: quick toggle "Mute games in background" / caelestia.backgroundMute.enable.
Scope {
    id: root

    readonly property var cfg: E4C.Config.options.caelestia.backgroundMute
    readonly property var classRegex: {
        try {
            return new RegExp(cfg.classes);
        } catch (e) {
            return /^(steam_app_\d+|gamescope)$/;
        }
    }

    readonly property var windows: E4.HyprlandData.windowList
    readonly property list<int> gamePids: windows.filter(w => root.classRegex.test(w.class)).map(w => w.pid)
    readonly property int focusedPid: windows.find(w => w.focusHistoryID === 0)?.pid ?? -1
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)

    property var mutedByUs: ({}) // PwNode id -> true
    property var clientPids: ({}) // PipeWire client id -> process id, from pw-dump

    function streamPid(stream: PwNode): int {
        const props = stream.properties;
        return parseInt(props["application.process.id"] ?? clientPids[props["client.id"]] ?? "-1");
    }

    function apply(): void {
        const muted = Object.assign({}, mutedByUs);
        for (const stream of streams) {
            if (!stream.ready || !stream.audio)
                continue;
            const pid = streamPid(stream);
            const isGame = gamePids.includes(pid);
            const background = cfg.enable && isGame && pid !== focusedPid;
            if (background && !stream.audio.muted) {
                stream.audio.muted = true;
                muted[stream.id] = true;
            } else if (!background && muted[stream.id]) {
                stream.audio.muted = false;
                delete muted[stream.id];
            }
        }
        mutedByUs = muted;
    }

    function restoreAll(): void {
        for (const stream of streams)
            if (mutedByUs[stream.id] && stream.ready && stream.audio)
                stream.audio.muted = false;
        mutedByUs = {};
    }

    onFocusedPidChanged: apply()
    onGamePidsChanged: apply()
    onStreamsChanged: {
        clientsProc.running = true;
        apply();
    }
    Component.onDestruction: restoreAll()

    Connections {
        target: root.cfg

        function onEnableChanged(): void {
            root.apply();
        }
    }

    Process {
        id: clientsProc

        command: ["sh", "-c", "pw-dump | jq -c '[.[] | select(.type == \"PipeWire:Interface:Client\") | {key: (.id | tostring), value: .info.props[\"application.process.id\"]}] | from_entries'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clientPids = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.apply();
            }
        }
    }

    PwObjectTracker {
        objects: root.streams
    }

    // New streams become ready asynchronously; re-check briefly while a game is running
    Timer {
        running: root.gamePids.length > 0
        repeat: true
        interval: 1000
        onTriggered: {
            // A stream whose client pw-dump hasn't seen yet (it connected after the last dump)
            if (root.streams.some(s => s.ready && s.properties["application.process.id"] === undefined && !(s.properties["client.id"] in root.clientPids)))
                clientsProc.running = true;
            root.apply();
        }
    }
}
