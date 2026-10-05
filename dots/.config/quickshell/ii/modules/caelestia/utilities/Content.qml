pragma ComponentBehavior: Bound

import "cards"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.bar.popouts as BarPopouts
import qs.modules.common as E4C // caelestia4: keep

Item {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    // caelestia4: + System row and quick sliders (end-4 sidebar features)
    readonly property int enabledCards: (system.active ? 1 : 0) + (idleInhibit.active ? 1 : 0) + (record.active ? 1 : 0) + (sliders.active ? 1 : 0) + (toggles.active ? 1 : 0)
    readonly property real nonAnimHeight: ((system.item as System)?.implicitHeight ?? 0) + ((idleInhibit.item as IdleInhibit)?.nonAnimHeight ?? 0) + ((record.item as Record)?.nonAnimHeight ?? 0) + ((sliders.item as Sliders)?.implicitHeight ?? 0) + ((toggles.item as Toggles)?.implicitHeight ?? 0) + layout.spacing * Math.max(0, enabledCards - 1)

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        Loader {
            id: system

            Layout.fillWidth: true
            active: E4C.Config.options.caelestia.utilitiesSystem
            visible: active

            sourceComponent: System {
                objectName: "utilitiesSystem"

                screenState: root.screenState
            }
        }

        Loader {
            id: idleInhibit

            Layout.fillWidth: true
            active: Config.utilities.cards.keepAwake
            visible: active

            sourceComponent: IdleInhibit {
                objectName: "utilitiesKeepAwake"
            }
        }

        Loader {
            id: record

            Layout.fillWidth: true
            active: Config.utilities.cards.recorder
            visible: active
            z: 1

            sourceComponent: Record {
                objectName: "utilitiesScreenRecorder"

                props: root.props
                screenState: root.screenState
            }
        }

        Loader {
            id: sliders

            Layout.fillWidth: true
            active: E4C.Config.options.caelestia.utilitiesSliders
            visible: active

            sourceComponent: Sliders {
                objectName: "utilitiesQuickSliders"

                screenState: root.screenState
            }
        }

        Loader {
            id: toggles

            Layout.fillWidth: true
            active: Config.utilities.cards.quickToggles
            visible: active

            sourceComponent: Toggles {
                objectName: "utilitiesQuickToggles"

                screenState: root.screenState
                popouts: root.popouts
            }
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
