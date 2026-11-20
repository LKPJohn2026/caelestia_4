import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Hyprland options (Caelestia has none): what end-4's Settings app had on its Windows and Input pages,
// plus options neither app had. Read live from Hyprland, saved to hypr/hyprland/shellOverrides/main.lua (end-4's
// HyprlandConfig, loaded last, so it wins over custom/*.lua), which Hyprland reloads on change. This page is an overview: the options are on three sub-pages (pages/hyprland/), each with live summaries
// here; their entries are in registry/RegHyprland.qml
PageBase {
    id: root

    // Live values for the summaries (Setting objects as properties: PageBase's default property takes one item)
    readonly property Setting kbLayout: Setting {
        sid: "h:input:kb_layout"
    }
    readonly property Setting followMouse: Setting {
        sid: "h:input:follow_mouse"
    }
    readonly property Setting gapsIn: Setting {
        sid: "h:general:gaps_in"
    }
    readonly property Setting gapsOut: Setting {
        sid: "h:general:gaps_out"
    }
    readonly property Setting rounding: Setting {
        sid: "h:decoration:rounding"
    }
    readonly property Setting tiling: Setting {
        sid: "h:general:layout"
    }
    readonly property Setting tearing: Setting {
        sid: "h:general:allow_tearing"
    }
    readonly property Setting bgFps: Setting {
        sid: "h:misc:render_unfocused_fps"
    }

    // The label of an enum setting's current value ("" while Hyprland hasn't answered)
    function optionLabel(s: Setting): string {
        const opt = (s.entry?.options ?? []).find(o => s.same(o.value, s.value));
        return opt ? Tr.tr(opt.label) : "";
    }

    // gaps are CSS-style ("4 4 4 4"): the first number
    function num(v: var): string {
        const n = parseFloat(v);
        return isNaN(n) ? "–" : String(Math.round(n * 100) / 100);
    }

    title: Tr.tr("Hyprland")

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        NavRow {
            icon: "keyboard"
            text: Tr.tr("Keyboard, mouse & touchpad")
            subtext: {
                const layouts = String(root.kbLayout.value ?? "").split(",").map(l => l.trim()).filter(l => l).join(", ");
                const parts = [layouts ? Tr.tr("Layouts: %1").arg(layouts) : "", root.optionLabel(root.followMouse) ? Tr.tr("Focus follows the mouse: %1").arg(root.optionLabel(root.followMouse)) : ""];
                return parts.filter(p => p).join(" · ") || Tr.tr("Layouts, key repeat, mouse, touchpad, cursor");
            }
            onClicked: root.nState.openSubPage("input")
        }

        // caelestia4: the shortcut editor (pages/hyprland/KeybindsPage.qml); its registry entry stays noRow
        NavRow {
            icon: "keyboard_command_key"
            text: Tr.tr("Keyboard shortcuts")
            subtext: Tr.tr("Change, turn off or add shortcuts")
            onClicked: root.nState.openSubPage("keybinds")
        }

        NavRow {
            icon: "select_window"
            text: Tr.tr("Windows & effects")
            subtext: {
                if (root.gapsIn.value === undefined)
                    return Tr.tr("Gaps, borders, blur, tiling layout");
                const parts = [Tr.tr("Gaps %1 / %2 px").arg(root.num(root.gapsIn.value)).arg(root.num(root.gapsOut.value)), Tr.tr("Corners %1 px").arg(root.num(root.rounding.value)), root.optionLabel(root.tiling)];
                return parts.filter(p => p).join(" · ");
            }
            onClicked: root.nState.openSubPage("windows")
        }

        NavRow {
            icon: "speed"
            text: Tr.tr("Rendering & games")
            subtext: {
                if (root.tearing.value === undefined)
                    return Tr.tr("Direct scanout, tearing, games in the background");
                const parts = [root.tearing.value ? Tr.tr("Tearing allowed") : Tr.tr("No tearing"), Tr.tr("%1 fps in the background").arg(root.num(root.bgFps.value))];
                return parts.join(" · ");
            }
            onClicked: root.nState.openSubPage("rendering")
        }
    }
}
