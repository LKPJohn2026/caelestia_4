pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io

/**
 * caelestia4: desktop widgets moved, resized or turned with the mouse are saved into the preset applied last
 * (scripts/presets/preset-import.py --save-layout), so it opens as it was left. Once a second after the last change:
 * a group drag or a few resizes in a row make one save, and the config is on disk by then (Config.readWriteDelay).
 */
Singleton {
    id: root

    // a save asked for or running: another preset must wait for it, or the move goes into that one's widgets
    // (WorkspacePresets)
    readonly property bool busy: saveTimer.running || saveProc.running

    function requestSave(): void {
        if (Config.options.background.saveToPreset)
            saveTimer.restart();
    }

    // the save asked for, now rather than in a second
    function flush(): void {
        if (saveTimer.running) {
            saveTimer.stop();
            saveProc.start();
        }
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: saveProc.start()
    }

    Process {
        id: saveProc

        property bool again // moved again while saving: once more after

        function start(): void {
            if (running)
                again = true;
            else
                running = true;
        }

        command: ["python3", FileUtils.trimFileProtocol(`${Directories.scriptPath}/presets/preset-import.py`), "--save-layout"]
        onExited: {
            if (again) {
                again = false;
                running = true;
            }
        }
    }
}
