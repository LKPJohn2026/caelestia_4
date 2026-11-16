import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of HyprlandPage (route hyprland/rendering): games in the background, tearing, and in the
// Advanced section direct scanout, X11 scaling and the game window pattern (from end-4's Settings app; VRR is on the
// Display page). Rows take title, range and default from registry/RegHyprland.qml. Direct scanout and tearing can
// break the display on some GPUs: a change reverts after 10 s unless kept (KeepRevert)
PageBase {
    id: root

    title: Tr.tr("Rendering & games")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Games in the background")
        }

        ToggleRow {
            setting: "e4:caelestia.backgroundMute.enable"
        }

        StepperRow {
            setting: "h:misc:render_unfocused_fps"
        }

        SectionHeader {
            text: Tr.tr("Latency")
        }

        ToggleRow {
            id: tearing

            setting: "h:general:allow_tearing"
        }

        KeepRevert {
            link: tearing.link
        }

        AdvancedSection {
            SelectRow {
                id: scanout

                setting: "h:render:direct_scanout"
            }

            KeepRevert {
                link: scanout.link
            }

            ToggleRow {
                setting: "h:xwayland:force_zero_scaling"
            }

            // An invalid pattern is not saved (the old one stays)
            TextFieldRow {
                setting: "e4:caelestia.backgroundMute.classes"
                validate: t => {
                    try {
                        new RegExp(t);
                        return true;
                    } catch (e) {
                        return false;
                    }
                }
                errorText: Tr.tr("Not a valid pattern")
            }
        }
    }
}
