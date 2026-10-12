import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: on/off Hyprland option (wiki name, e.g. "decoration:blur:enabled"). Read live from Hyprland, saved to
// hypr/hyprland/shellOverrides/main.lua (end-4 HyprlandConfig; Hyprland reloads the file on change).
SwitchRow {
    id: root

    required property string key

    checked: opt.value === true || opt.value === 1
    onToggled: v => HyprlandConfig.set(root.key, v ? "true" : "false")

    HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
