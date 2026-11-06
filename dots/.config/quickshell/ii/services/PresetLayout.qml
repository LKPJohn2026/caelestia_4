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
 * A widget put on or taken off the desktop (Nexus > Wallpaper & style > Widgets on the desktop, a widget's menu) is
 * saved the same way: the script writes its enable into the preset. Nothing with presets off (background.presetsEnabled):
 * the desktop is your own layout then, not a preset's.
 */
Singleton {
    id: root

    // a save asked for or running: another preset must wait for it, or the move goes into that one's widgets
    // (WorkspacePresets)
    readonly property bool busy: saveTimer.running || saveProc.running

    function requestSave(): void {
        if (Config.options.background.saveToPreset && Config.options.background.presetsEnabled)
            saveTimer.restart();
    }

    // A desktop widget on or off (background.widgets[key].enable), saved into the preset like a move. One turned on
    // where another already is (a free widget never moved sits at its default 400, 100, as most do) steps down and
    // right until it's clear, so it doesn't open hidden under that one
    function setWidgetEnabled(key: string, on: bool): void {
        const widgets = Config.options.background.widgets;
        const entry = widgets[key];
        if (!entry || entry.enable === on)
            return;
        if (on && entry.placementStrategy === "free") {
            const others = ["clock", "weather", "calendar", "media", "customImage", "userCard", "worldClock", "resources", "notes", "timers", "todo", "images", "imageCard", "sticker", "customText"].filter(k => k !== key && widgets[k].enable && widgets[k].placementStrategy === "free");
            let x = entry.x, y = entry.y;
            for (let i = 0; i < 20 && others.some(k => Math.abs(widgets[k].x - x) < 32 && Math.abs(widgets[k].y - y) < 32); i++) {
                x += 48;
                y += 48;
            }
            if (x !== entry.x) {
                entry.x = x;
                entry.y = y;
            }
        }
        entry.enable = on;
        requestSave();
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
