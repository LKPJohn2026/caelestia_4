pragma Singleton

// caelestia4 ADAPTER: Recorder
// Backed by end-4's scripts/videos/record.sh (wf-recorder) instead of `caelestia record`
// (caelestia-cli is not installed). record.sh toggles: running it while recording stops it.
// Contract used by Caelestia UI: running, paused, elapsed, start(extraArgs), stop(), togglePause().
// Caelestia args -> record.sh args:
//   []            full screen          -> --fullscreen
//   ["-r"]        region               -> (none; record.sh asks for a region with slurp)
//   ["-s"]        full screen + sound  -> --fullscreen --sound
//   ["-sr"/"-rs"] region + sound       -> --sound
// Not supported: pause (wf-recorder has no pause). `paused` stays false; togglePause() only logs.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/videos/record.sh")
    property bool running: false
    readonly property bool paused: false
    property real elapsed: 0

    function mapArgs(extraArgs: var): list<string> {
        const a = (extraArgs ?? []).join("");
        const region = a.includes("r");
        const sound = a.includes("s");
        const out = [];
        if (!region)
            out.push("--fullscreen");
        if (sound)
            out.push("--sound");
        return out;
    }

    function start(extraArgs = []): void {
        if (running)
            return;
        Quickshell.execDetached(["bash", root.script, ...mapArgs(extraArgs)]);
        pollTimer.restart();
    }

    function stop(): void {
        if (!running)
            return;
        Quickshell.execDetached(["bash", root.script]);
        pollTimer.restart();
    }

    function togglePause(): void {
        console.warn("[caelestia4 Recorder] pause is not supported by end-4's wf-recorder script");
    }

    onRunningChanged: {
        if (running)
            elapsed = 0;
    }

    Timer {
        id: pollTimer

        interval: root.running ? 1000 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.running)
                root.elapsed += interval / 1000;
            checkProc.running = true;
        }
    }

    Process {
        id: checkProc

        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => root.running = code === 0
    }
}
