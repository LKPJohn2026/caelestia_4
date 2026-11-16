import QtQml
import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: on/off Hyprland option (wiki name, e.g. "cursor:hide_on_key_press"), read live from Hyprland and saved
// to end-4's shell overrides file, which Hyprland reloads on change. New rows use `ToggleRow { setting: "h:<option>" }`
// instead (registry title, modified/reset); with `setting` set this row is just that
ToggleRow {
    id: root

    property string key

    value: root.setting ? root.link.value : (opt.value === true || opt.value === 1)
    onToggled: {
        if (!root.setting)
            E4.HyprlandConfig.set(root.key, checked ? "true" : "false");
    }

    // Only the old way reads the option itself (the setting has its own reader)
    readonly property var opt: optInst.object ?? ({})

    Instantiator {
        id: optInst

        model: root.setting ? 0 : 1

        E4H.HyprlandConfigOption {
            key: root.key
        }
    }
}
