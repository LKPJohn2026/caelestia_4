import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: free-text Hyprland option (keyboard layouts, XKB options), read live and saved to the shell overrides
// when editing finishes. Hyprland reports an empty string option as "[[EMPTY]]"
TextFieldRow {
    id: root

    required property string key

    value: opt.value === "[[EMPTY]]" ? "" : String(opt.value ?? "")
    onEditingFinished: v => {
        if (v !== root.value)
            E4.HyprlandConfig.set(root.key, v);
    }

    E4H.HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
