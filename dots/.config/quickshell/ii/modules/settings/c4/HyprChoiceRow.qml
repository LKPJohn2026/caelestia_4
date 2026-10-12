import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Hyprland option with a fixed set of values (layout, follow_mouse, vrr, accel_profile).
ChoiceRow {
    id: root

    required property string key

    value: opt.value === "[[EMPTY]]" ? "" : opt.value
    onSelected: v => HyprlandConfig.set(root.key, v)

    HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
