import QtQuick
import qs.services as E4 // caelestia4: keep (HyprlandConfig: hypr/hyprland/shellOverrides/main.lua)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.modules.caelestia.nexus.common

// caelestia4: numeric Hyprland option (whole or decimal, by stepSize), read live and saved to the shell overrides
StepperRow {
    id: root

    required property string key

    value: typeof opt.value === "string" ? parseFloat(opt.value) || 0 : Number(opt.value ?? 0)
    onMoved: v => E4.HyprlandConfig.set(root.key, stepSize < 1 ? v.toFixed(2) : Math.round(v))

    E4H.HyprlandConfigOption {
        id: opt

        key: root.key
    }
}
