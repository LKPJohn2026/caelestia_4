import QtQml
import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: Hyprland option with fixed values; menuItems are MenuItems whose `value` is the option's value.
// New rows use `SelectRow { setting: "h:<option>" }` instead; with `setting` set this row is just that
SelectRow {
    id: root

    property string key

    // == : Hyprland reports ints, items may hold either. An empty string option comes back as "[[EMPTY]]"
    readonly property var current: {
        const v = root.setting ? root.link.value : opt.value;
        return v === "[[EMPTY]]" ? "" : v;
    }

    active: menuItems.find(i => i.value == current) ?? null
    onSelected: item => {
        if (!root.setting)
            E4.HyprlandConfig.set(root.key, item.value);
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
