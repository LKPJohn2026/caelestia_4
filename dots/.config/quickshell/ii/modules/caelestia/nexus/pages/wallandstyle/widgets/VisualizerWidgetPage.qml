pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Audio visualiser (route appearance/desktop/widget.visualizer). One
// visualiser on the desktop: Caelestia's bars (background.visualiser) or end4-pC's widget (background.widgets.visualizer)
// in one of its styles. Show (on/off) first, as on the other widget pages, then General (style, size, placement), the
// chosen style's look, and Advanced (Caelestia's bars only). While it is off, the rows are the style it comes back in.
// Rows name their registry setting (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("Audio visualiser")
    isSubPage: true

    readonly property var e4Vis: E4C.Config.options.background.widgets.visualizer
    readonly property string desktopVisualiser: e4Vis.enable ? e4Vis.style : (Config.background.visualiser.enabled ? "caelestia" : "none")
    readonly property bool visOn: desktopVisualiser !== "none"
    // caelestia4: the style Show turns it back on in: the one it had when turned off here, or one picked since
    property string pickedStyle
    // The style the rows are for: the visualiser's, or (off) the one Show brings back: the picked one, else end-4's
    // last style, as Desktop's widget list does
    readonly property string shownStyle: visOn ? desktopVisualiser : (pickedStyle || e4Vis.style)
    readonly property bool caelestiaVis: shownStyle === "caelestia"
    readonly property bool ring: shownStyle === "ring"
    // end-4's shader styles; its "bars" style has no options
    readonly property bool shader: ["mirror", "aurora", "dots", "ring"].includes(shownStyle)

    // x:desktop.visualiser: Caelestia's, one of end-4's styles, or none. end-4's goes on through PresetLayout (on or
    // off in the preset too, as Desktop's widget list does)
    function setDesktopVisualiser(v: string): void {
        // caelestia4: off keeps the style it had, so Show (or undo) brings back the same visualiser, Caelestia's too
        if (v === "none" && root.visOn)
            root.pickedStyle = root.desktopVisualiser;
        const end4 = v !== "caelestia" && v !== "none";
        GlobalConfig.background.visualiser.enabled = v === "caelestia";
        if (end4)
            root.e4Vis.style = v;
        if (end4 !== root.e4Vis.enable)
            E4.PresetLayout.setWidgetEnabled("visualizer", end4);
        else
            E4.PresetLayout.requestSave();
    }

    // x:desktop.visualiser: the style. While it is off it is only remembered (end-4's in its own key)
    function pickStyle(v: string): void {
        if (root.visOn) {
            root.setDesktopVisualiser(v);
            return;
        }
        root.pickedStyle = v;
        if (v !== "caelestia")
            root.e4Vis.style = v;
    }

    // caelestia4: rows shown for one visualiser or style only. A route or search result that names a hidden one
    // lands on the picker (PageBase can't scroll to a hidden row). end-4's own on/off and style are the picker
    readonly property var shownFor: ({
            "e4:background.widgets.visualizer.enable": "show",
            "e4:background.widgets.visualizer.style": "never",
            "e4:background.widgets.visualizer.placementStrategy": "ring",
            "e4:background.widgets.visualizer.ringSize": "ring",
            "e4:background.widgets.visualizer.height": "band",
            "e4:background.widgets.visualizer.colorSource": "shader",
            "e4:background.widgets.visualizer.sensitivity": "shader",
            "c:background.visualiser.autoHide": "caelestia",
            "c:background.visualiser.blur": "caelestia",
            "c:background.visualiser.rounding": "caelestia",
            "c:background.visualiser.spacing": "caelestia"
        })

    function shown(group: string): bool {
        switch (group) {
        case "never":
        case "show":
            return false;
        case "ring":
            return root.ring;
        case "band":
            return root.shader && !root.ring;
        case "shader":
            return root.shader;
        case "caelestia":
            return root.caelestiaVis;
        }
        return false;
    }

    function landOnShown(): void {
        const key = root.nState?.focusKey ?? "";
        const group = root.shownFor[key];
        if (group && !root.shown(group))
            root.nState.focusKey = group === "show" ? "x:desktop.visualiser.show" : "x:desktop.visualiser";
    }

    // A property: PageBase's default property takes the page's one content item
    readonly property Connections focusWatch: Connections {
        function onFocusKeyChanged(): void {
            root.landOnShown();
        }

        target: root.nState
    }

    Component.onCompleted: landOnShown()

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: showRow

            setting: "x:desktop.visualiser.show"

            Binding {
                target: showRow.link.s
                property: "customValue"
                value: root.visOn
            }

            Binding {
                target: showRow.link.s
                property: "customDefault"
                value: false
            }

            Connections {
                function onCustomSet(v: var): void {
                    root.setDesktopVisualiser(v ? root.shownStyle : "none");
                }

                function onCustomReset(): void {
                    root.setDesktopVisualiser("none");
                }

                target: showRow.link.s
            }
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        SelectRow {
            id: visRow

            setting: "x:desktop.visualiser"
            subtext: root.ring ? Tr.tr("A ring around the album cover: drag it, or resize it from a corner") : Tr.tr("Along the bottom of the wallpaper, moving with the sound. A preset may pick its own")

            Binding {
                target: visRow.link.s
                property: "customValue"
                value: root.shownStyle
            }

            // end-4's visualiser in its first style, as a new install has it
            Binding {
                target: visRow.link.s
                property: "customDefault"
                value: "bars"
            }

            Connections {
                function onCustomSet(v: var): void {
                    root.pickStyle(v);
                }

                function onCustomReset(): void {
                    root.pickStyle("bars");
                }

                target: visRow.link.s
            }
        }

        StepperRow {
            visible: root.shown("ring")
            setting: "e4:background.widgets.visualizer.ringSize"
        }

        // caelestia4: Size is in the same place on every widget page; end-4's bars and Caelestia's have one size
        InfoRow {
            visible: !root.shader
            label: Tr.tr("Size")
            value: Tr.tr("Fixed")
            subtext: Tr.tr("This style has one size. Other styles can be resized")
        }

        StepperRow {
            visible: root.shown("band")
            setting: "e4:background.widgets.visualizer.height"
        }

        SelectRow {
            visible: root.shown("ring")
            setting: "e4:background.widgets.visualizer.placementStrategy"
        }

        SectionHeader {
            visible: root.shader || root.caelestiaVis
            text: root.caelestiaVis ? Tr.tr("Caelestia's visualiser") : Tr.tr("Look")
        }

        SelectRow {
            visible: root.shown("shader")
            setting: "e4:background.widgets.visualizer.colorSource"
        }

        StepperRow {
            visible: root.shown("shader")
            setting: "e4:background.widgets.visualizer.sensitivity"
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "c:background.visualiser.autoHide"
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "c:background.visualiser.blur"
        }

        // Caelestia's bars only: end-4's styles have no details beyond the rows above
        AdvancedSection {
            visible: root.caelestiaVis

            StepperRow {
                setting: "c:background.visualiser.rounding"
            }

            StepperRow {
                setting: "c:background.visualiser.spacing"
            }
        }
    }
}
