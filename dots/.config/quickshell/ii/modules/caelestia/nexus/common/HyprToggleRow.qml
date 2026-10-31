import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: on/off Hyprland option (wiki name, e.g. "cursor:hide_on_key_press"), read live from Hyprland and saved
// to end-4's shell overrides file, which Hyprland reloads on change
ToggleRow {
    id: root

    required property string key

    value: opt.value === true || opt.value === 1
    onToggled: E4.HyprlandConfig.set(root.key, checked ? "true" : "false")

    E4H.HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
