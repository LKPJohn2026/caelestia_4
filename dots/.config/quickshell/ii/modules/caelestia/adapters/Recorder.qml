pragma Singleton

// caelestia4 ADAPTER: Recorder
// Backed by end-4's scripts/videos/record.sh (now gpu-screen-recorder, like `caelestia record`)
// (caelestia-cli is not installed). record.sh toggles: running it while recording stops it.
// Contract used by Caelestia UI: running, paused, elapsed, start(extraArgs), stop(), togglePause().
// Caelestia args -> record.sh args:
//   []            full screen          -> --fullscreen
//   ["-r"]        region               -> (none; record.sh asks for a region with slurp)
//   ["-s"]        full screen + sound  -> --fullscreen --sound
//   ["-sr"/"-rs"] region + sound       -> --sound
// Pause: record.sh --pause (SIGUSR2 to gpu-screen-recorder); the paused state is a marker file the script keeps
// in $XDG_RUNTIME_DIR, polled here with the running state.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/videos/record.sh")
    property bool running: false
    property bool paused: false
    readonly property string pausedFile: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/caelestia4-recording-paused`
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
        if (!running)
            return;
        Quickshell.execDetached(["bash", root.script, "--pause"]);
        root.paused = !root.paused; // optimistic; the next poll reads the marker file
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
            if (root.running && !root.paused)
                root.elapsed += interval / 1000;
            checkProc.running = true;
            pausedProc.running = true;
        }
    }

    Process {
        id: checkProc

        command: ["pidof", "gpu-screen-recorder"] // not pgrep -x: names are cut to 15 characters
        onExited: code => root.running = code === 0
    }

    Process {
        id: pausedProc

        command: ["test", "-e", root.pausedFile]
        onExited: code => root.paused = root.running && code === 0
    }
}
