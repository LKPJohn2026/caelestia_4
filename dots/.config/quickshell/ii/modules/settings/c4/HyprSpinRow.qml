import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: whole-number Hyprland option. "css" values like gaps ("4 4 4 4") show the first number and are saved
// as a single number (same on all sides).
SpinRow {
    id: root

    required property string key

    value: typeof opt.value === "string" ? parseInt(opt.value) || 0 : Math.round(opt.value ?? 0)
    onMoved: v => HyprlandConfig.set(root.key, v)

    HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
