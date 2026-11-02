pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * caelestia4: desktop widgets moved, resized or turned with the mouse are saved into the preset applied last
 * (scripts/presets/preset-import.py --save-layout), so it opens as it was left. Once a second after the last change:
 * a group drag or a few resizes in a row make one save, and the config is on disk by then (Config.readWriteDelay).
 */
Singleton {
    id: root

    function requestSave(): void {
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: Quickshell.execDetached(["python3", FileUtils.trimFileProtocol(`${Directories.scriptPath}/presets/preset-import.py`), "--save-layout"])
    }
}
