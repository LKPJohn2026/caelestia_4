pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: reference page for registry rows (registry/RegPanels.qml): each row names its setting and takes title,
// description, value, range, modified/reset and the "turn on X first" reason from the registry. RowGroup sets the
// rows' first/last
PageBase {
    id: root

    title: Tr.tr("Sidebar")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:sidebar.enabled"
        }

        ToggleRow {
            setting: "c:sidebar.showOnHover"
        }

        StepperRow {
            setting: "c:sidebar.minHoverThreshold"
        }

        StepperRow {
            setting: "c:sidebar.dragThreshold"
        }

        // caelestia4: the picture of the empty notification list (sidebar/NotifDock.qml)
        SectionHeader {
            text: Tr.tr("Look")
        }

        AssetPathRow {
            setting: "c:paths.noNotifsPic"
            hint: Tr.tr("None")
        }
    }
}
