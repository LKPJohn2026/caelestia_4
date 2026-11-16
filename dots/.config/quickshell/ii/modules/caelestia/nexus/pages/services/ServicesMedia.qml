pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of ServicesPage (route services/media). Rows name registry ids (registry/RegServices.qml)
PageBase {
    id: root

    title: Tr.tr("Media & music recognition")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                value: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        SectionHeader {
            text: Tr.tr("Media & lyrics")
        }

        SelectRow {
            setting: "c:services.lyricsBackend"
        }

        SelectRow {
            setting: "c:services.defaultPlayer"
            menuItems: playerVariants.instances
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || Tr.trCtx("Auto", "default media player")
        }

        SectionHeader {
            text: Tr.tr("Music recognition")
        }

        StepperRow {
            setting: "e4:musicRecognition.timeout"
        }

        StepperRow {
            setting: "e4:musicRecognition.interval"
        }

        AdvancedSection {
            KeyValueListRow {
                setting: "c:services.playerAliases"
            }

            PathRow {
                setting: "c:paths.lyricsDir"
            }

            ToggleRow {
                setting: "e4:media.filterDuplicatePlayers"
            }
        }
    }
}
