// caelestia4: the overlay's top bar (Super+G) in Caelestia style: a pill with one toggle per widget (click opens /
// closes it, right-click recentres it), the time and the battery. Same state as end-4 (Persistent.states.overlay).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs as E4G // caelestia4: keep (GlobalStates)
import Quickshell.Services.UPower
import qs.modules.common as E4C // caelestia4: keep (Persistent)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

StyledRect {
    id: root
    // caelestia4: battery straight from UPower (as Caelestia does); "low" = Caelestia's highest warning level
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryCharging: battery.state === UPowerDeviceState.Charging
    readonly property bool batteryLow: !batteryCharging && battery.percentage * 100 <= Math.max(...GlobalConfig.general.battery.warnLevels.values.map(l => l.level), 0)


    opacity: E4G.GlobalStates.overlayOpen ? 1 : 0
    implicitWidth: row.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3surfaceContainer

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Repeater {
            model: ScriptModel {
                values: OverlayContext.availableWidgets
            }

            IconButton {
                id: widgetButton

                required property var modelData
                readonly property string identifier: modelData.identifier

                type: IconButton.Tonal
                isToggle: true
                isRound: true
                checked: E4C.Persistent.states.overlay.open.includes(identifier)
                icon: modelData.materialSymbol
                padding: Tokens.padding.medium
                font: Tokens.font.icon.builders.medium.build()

                onClicked: {
                    if (checked)
                        E4C.Persistent.states.overlay.open = E4C.Persistent.states.overlay.open.filter(type => type !== identifier);
                    else
                        E4C.Persistent.states.overlay.open.push(identifier);
                }

                // Right-click: bring the widget back to the centre
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: OverlayContext.requestCenter(widgetButton.identifier)
                }
            }
        }

        StyledRect {
            Layout.fillHeight: true
            Layout.topMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.padding.small
            Layout.leftMargin: Tokens.spacing.small
            Layout.rightMargin: Tokens.spacing.small
            implicitWidth: 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            Layout.rightMargin: Tokens.padding.small
            text: Time.timeStr
            font: Tokens.font.clock.size(Tokens.font.title.large.pointSize).weight(Font.Bold).build()
            color: Colours.palette.m3primary
        }

        RowLayout {
            visible: root.battery.isLaptopBattery
            Layout.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: root.batteryCharging ? "bolt" : "battery_android_full"
                fill: 1
                color: root.batteryLow ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: `${Math.round(root.battery.percentage * 100)}%`
                font: Tokens.font.title.small
                color: root.batteryLow ? Colours.palette.m3error : Colours.palette.m3onSurface
            }
        }
    }
}
