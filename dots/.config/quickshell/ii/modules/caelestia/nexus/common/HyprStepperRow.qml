import QtQml
import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: numeric Hyprland option (whole or decimal, by stepSize), read live and saved to the shell overrides.
// New rows use `StepperRow { setting: "h:<option>" }` instead; with `setting` set this row is just that
StepperRow {
    id: root

    property string key

    value: root.setting ? Number(root.link.shownValue ?? 0) : (typeof opt.value === "string" ? parseFloat(opt.value) || 0 : Number(opt.value ?? 0))
    onMoved: v => {
        if (!root.setting)
            E4.HyprlandConfig.set(root.key, stepSize < 1 ? v.toFixed(2) : Math.round(v));
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
