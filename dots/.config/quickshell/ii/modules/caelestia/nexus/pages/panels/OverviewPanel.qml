pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (overview, overlay and crosshair live in end-4's config)
import "../../registry/E4Defaults.js" as E4Defaults

// caelestia4: Panels > Overview & overlay: the workspace overview (Alt+Tab), the overlay widgets (Super+G)
// and its crosshair. The same keys as end-4's Settings app (Desktop)
PageBase {
    id: root

    title: Tr.tr("Overview & overlay")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Workspace overview")
        }

        ToggleRow {
            setting: "e4:overview.enable"
        }

        StepperRow {
            setting: "e4:overview.rows"
        }

        StepperRow {
            setting: "e4:overview.columns"
        }

        // caelestia4: overview.scale is a fraction (0.18) shown as a percent: an x: id (scaleOption below)
        StepperRow {
            id: scaleRow

            setting: "x:overview.scalePercent"
        }

        ToggleRow {
            setting: "e4:caelestia.overview.altTabSkipEmpty"
        }

        // caelestia4: the grid's fill order
        ToggleRow {
            setting: "e4:overview.orderBottomUp"
        }

        ToggleRow {
            setting: "e4:overview.orderRightLeft"
        }

        SectionHeader {
            text: Tr.tr("Overlay widgets (Super+G)")
        }

        ToggleRow {
            setting: "e4:overlay.darkenScreen"
        }

        ToggleRow {
            setting: "e4:overlay.openingZoomAnimation"
        }

        SliderRow {
            setting: "e4:overlay.clickthroughOpacity"
        }

        // caelestia4: one Advanced section, last: the floating image and the crosshair (registry `advanced`)
        AdvancedSection {
            // caelestia4: a web address is fine too (FloatingImage.qml loads it as is): no existence check, and no
            // thumbnail (it would fetch the default web address each time the page opens)
            // caelestia4: FloatingImage.qml hands the value to curl, which needs an address: a local file is saved as
            // "file:///…" (shown here as a plain path)
            PathRow {
                setting: "e4:overlay.floatingImage.imageSource"
                mustExist: false
                value: link.active ? String(link.value ?? "").replace(/^file:\/\//, "") : ""
                onChosen: path => {
                    if (path.startsWith("/"))
                        E4C.Config.options.overlay.floatingImage.imageSource = "file://" + path;
                }
            }

            TextFieldRow {
                setting: "e4:crosshair.code"
            }
        }

        // Not an item: it feeds the preview size row
        QtObject {
            id: scaleOption

            readonly property Binding _value: Binding {
                target: scaleRow.link.s
                property: "customValue"
                value: Math.round(E4C.Config.options.overview.scale * 100)
            }

            readonly property Binding _default: Binding {
                target: scaleRow.link.s
                property: "customDefault"
                value: Math.round(E4Defaults.defaults["overview.scale"] * 100)
            }

            readonly property Connections _writes: Connections {
                function onCustomSet(v: var): void {
                    E4C.Config.options.overview.scale = Number(v) / 100;
                }

                function onCustomReset(): void {
                    E4C.Config.options.overview.scale = E4Defaults.defaults["overview.scale"];
                }

                target: scaleRow.link.s
            }
        }
    }
}
