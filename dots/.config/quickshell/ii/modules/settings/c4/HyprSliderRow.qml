import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: decimal Hyprland option (opacity, sensitivity). Saved 400 ms after the slider stops moving: each save
// rewrites the overrides file and Hyprland reloads its config.
SliderRow {
    id: root

    required property string key
    property real lastMoved

    value: Number(opt.value ?? 0)
    onMoved: v => {
        root.lastMoved = v;
        saveTimer.restart();
    }

    HyprlandConfigOption {
        id: opt

        key: root.key
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: HyprlandConfig.set(root.key, root.lastMoved.toFixed(2))
    }
}
