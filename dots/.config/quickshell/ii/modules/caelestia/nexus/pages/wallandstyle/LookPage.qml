import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of WallpaperAndStyle (route appearance/look): Caelestia's appearance scales and frame
// (shell.json), the same keys as end-4's Settings app (Appearance), so both stay in step, and end-4's own transparency.
// Percent rows show the 0-2 scales as 0-200 % (StepperRow, entry `scale`). Fonts: FontsPage.qml. Most-used first; one
// Advanced section, last: the assistant's own transparency and the frame's smoothing
PageBase {
    id: root

    title: Tr.tr("Look & feel")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Size & shape")
        }

        StepperRow {
            setting: "c:appearance.font.scale"
        }

        StepperRow {
            setting: "c:appearance.rounding.scale"
        }

        StepperRow {
            setting: "c:appearance.spacing.scale"
        }

        StepperRow {
            setting: "c:appearance.padding.scale"
        }

        SectionHeader {
            text: Tr.tr("Transparency")
        }

        StepperRow {
            setting: "c:appearance.transparency.base"
        }

        StepperRow {
            setting: "c:appearance.transparency.layers"
        }

        SectionHeader {
            text: Tr.tr("Motion")
        }

        StepperRow {
            setting: "c:appearance.anim.durations.scale"
        }

        SliderRow {
            setting: "c:appearance.deformScale"
        }

        SectionHeader {
            text: Tr.tr("Screen frame")
        }

        StepperRow {
            setting: "c:border.thickness"
        }

        StepperRow {
            setting: "c:border.rounding"
        }

        // caelestia4: end-4's own layer transparency, for the assistant, overlay and desktop widgets, and the frame's
        // corner smoothing
        AdvancedSection {
            StepperRow {
                setting: "c:border.smoothing"
            }

            ToggleRow {
                setting: "e4:appearance.transparency.automatic"
            }

            // caelestia4: end-4 uses it only with Transparency on as well (Appearance.qml), a second condition the
            // registry's `requires` (automatic off) can't hold: disabled here, with the reason as its description
            SliderRow {
                setting: "e4:appearance.transparency.backgroundTransparency"
                enabled: Tokens.transparency.enabled
                subtext: enabled ? link.desc : Tr.tr("Turn on “%1” first, on Wallpaper & style").arg(Tr.tr("Transparency"))
                opacity: enabled || link.blocked ? 1 : 0.6 // blocked: its text is dimmed already
            }

            SliderRow {
                setting: "e4:appearance.transparency.contentTransparency"
            }

            ToggleRow {
                setting: "e4:appearance.extraBackgroundTint"
            }
        }
    }
}
