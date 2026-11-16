pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    title: Tr.tr("Workspaces")
    isSubPage: true

    // caelestia4: General, Style (how each workspace looks), Window icons, Special workspaces, then the labels, letter
    // case and ignored tags in Advanced
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        StepperRow {
            setting: "c:bar.workspaces.shown"
        }

        ToggleRow {
            setting: "c:bar.workspaces.showUnoccupied"
        }

        ToggleRow {
            setting: "c:bar.workspaces.perMonitor"
        }

        SectionHeader {
            text: Tr.tr("Style")
        }

        // Shapes, Numbers, Icons: the menu comes from the entry's options
        SelectRow {
            setting: "c:bar.workspaces.displayType"
        }

        KeyValueListRow {
            setting: "c:bar.workspaces.workspaceIcons"
        }

        ToggleRow {
            setting: "c:bar.workspaces.activeIndicator"
        }

        ToggleRow {
            setting: "c:bar.workspaces.activeTrail"
        }

        ToggleRow {
            setting: "c:bar.workspaces.occupiedBg"
        }

        // caelestia4: from end-4's Settings app (Desktop > Bar: workspaces)
        ToggleRow {
            setting: "e4:bar.workspaces.alwaysShowNumbers"
        }

        DurationRow {
            setting: "e4:bar.workspaces.showNumberDelay"
        }

        SectionHeader {
            text: Tr.tr("Window icons")
        }

        ToggleRow {
            setting: "c:bar.workspaces.showWindows"
        }

        StepperRow {
            setting: "c:bar.workspaces.maxWindowIcons"
        }

        KeyValueListRow {
            setting: "c:bar.workspaces.windowIcons"
        }

        SectionHeader {
            text: Tr.tr("Special workspaces")
        }

        ToggleRow {
            setting: "c:bar.workspaces.showWindowsOnSpecialWorkspaces"
        }

        SelectRow {
            setting: "c:bar.workspaces.specialDisplayType"
        }

        KeyValueListRow {
            setting: "c:bar.workspaces.specialWorkspaceIcons"
        }

        AdvancedSection {
            TextFieldRow {
                setting: "c:bar.workspaces.label"
            }

            TextFieldRow {
                setting: "c:bar.workspaces.occupiedLabel"
            }

            TextFieldRow {
                setting: "c:bar.workspaces.activeLabel"
            }

            SelectRow {
                setting: "c:bar.workspaces.capitalisation"
            }

            KeyValueListRow {
                setting: "c:bar.workspaces.ignoredTags"
            }
        }
    }
}
