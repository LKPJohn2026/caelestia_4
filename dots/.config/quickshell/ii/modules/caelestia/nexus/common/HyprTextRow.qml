import QtQml
import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: free-text Hyprland option (keyboard layouts, XKB options), read live and saved to the shell overrides
// when editing finishes. Hyprland reports an empty string option as "[[EMPTY]]". New rows use
// `TextFieldRow { setting: "h:<option>" }` instead; with `setting` set this row is just that
TextFieldRow {
    id: root

    property string key

    value: {
        const v = root.setting ? root.link.value : opt.value;
        return v === "[[EMPTY]]" ? "" : String(v ?? "");
    }
    onEditingFinished: v => {
        if (!root.setting && v !== root.value)
            E4.HyprlandConfig.set(root.key, v);
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
