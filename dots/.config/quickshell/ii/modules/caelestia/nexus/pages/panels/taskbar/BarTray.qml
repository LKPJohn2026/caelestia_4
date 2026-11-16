pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: reference page for registry rows (registry/RegPanels.qml): `setting` gives each row its title, value and
// write; RowGroup sets first/last
PageBase {
    id: root

    title: Tr.tr("Tray")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: General and Style, as on the other taskbar pages
        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: the apps in the tray now; hidden ids of apps that are not running stay listed
        MultiSelectRow {
            setting: "c:bar.tray.hiddenIcons"
            options: SystemTray.items.values.map(i => ({
                        value: i.id,
                        label: i.title && i.title !== i.id ? `${i.title} (${i.id})` : i.id
                    }))
        }

        ToggleRow {
            setting: "c:bar.popouts.tray"
        }

        SectionHeader {
            text: Tr.tr("Style")
        }

        ToggleRow {
            setting: "c:bar.tray.background"
        }

        ToggleRow {
            setting: "c:bar.tray.recolour"
        }

        ToggleRow {
            setting: "c:bar.tray.compact"
        }

        AdvancedSection {
            ToggleRow {
                setting: "e4:tray.invertPinnedItems"
            }

            KeyValueListRow {
                setting: "e4:tray.pinnedItems"
            }

            KeyValueListRow {
                setting: "c:bar.tray.iconSubs"
            }
        }
    }
}
