import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: Hyprland option with fixed values; menuItems are MenuItems whose `value` is the option's value
SelectRow {
    id: root

    required property string key

    active: menuItems.find(i => i.value == opt.value) ?? null // == : Hyprland reports ints, items may hold either
    onSelected: item => E4.HyprlandConfig.set(root.key, item.value)

    E4H.HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
