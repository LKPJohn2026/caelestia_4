import QtQuick
import qs.services
import qs.modules.common.models.hyprland
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: free-text Hyprland option (keyboard layouts, kb_options).
TextRow {
    id: root

    required property string key

    value: opt.value === "[[EMPTY]]" ? "" : (opt.value ?? "")
    onEdited: v => HyprlandConfig.set(root.key, v)

    HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
