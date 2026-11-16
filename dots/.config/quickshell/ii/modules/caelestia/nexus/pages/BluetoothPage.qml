pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.network

PageBase {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter?.enabled ?? false

    title: Tr.tr("Connected devices")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            id: btToggle

            first: true
            text: Tr.tr("Bluetooth")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            value: root.btEnabled
            onToggled: {
                if (root.adapter)
                    root.adapter.enabled = checked;
            }

            ActionMark {
                parent: btToggle.bg
                row: btToggle
                sid: "x:bluetooth.enabled"
            }
        }

        ItemList {
            id: savedList

            showList: root.btEnabled
            placeholderIcon: root.btEnabled ? "devices_other" : "bluetooth_disabled"
            placeholderText: root.btEnabled ? Tr.tr("No saved devices") : Tr.tr("Bluetooth disabled")

            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.bonded).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
            }

            delegate: StyledRect {
                id: device

                required property BluetoothDevice modelData
                readonly property bool connected: modelData && modelData.state === BluetoothDeviceState.Connected
                readonly property bool loading: modelData && (modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting)
                property real textOpacity: loading ? 0.5 : 1

                anchors.left: savedList.list.contentItem.left
                anchors.right: savedList.list.contentItem.right
                implicitHeight: deviceLayout.implicitHeight + deviceLayout.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                color: "transparent"

                Behavior on textOpacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StateLayer {
                    disabled: device.loading
                    onClicked: {
                        if (!device.modelData || device.loading)
                            return;
                        device.modelData.connected = !device.connected;
                    }
                }

                RowLayout {
                    id: deviceLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: deviceIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: device.connected ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            id: deviceIcon

                            anchors.centerIn: parent
                            text: Icons.getBluetoothIcon(device.modelData?.icon ?? "")
                            color: device.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.medium
                            fill: device.connected ? 1 : 0
                            opacity: device.textOpacity

                            Behavior on fill {
                                Anim {}
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        opacity: device.textOpacity

                        StyledText {
                            Layout.fillWidth: true
                            text: device.modelData?.name ?? Tr.trCtx("Unknown", "unknown bluetooth device")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (!device.connected)
                                    return Tr.trCtx("Saved", "bluetooth device state");
                                if (device.modelData?.batteryAvailable)
                                    // TRANSLATORS: %1 = battery level, already formatted as a percentage
                                    return Tr.trCtx("Connected • %1", "bluetooth device state with battery").arg(Strings.percentOne(device.modelData.battery));
                                return Tr.trCtx("Connected", "bluetooth device state");
                            }
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            animate: true
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        implicitWidth: height

                        AnimLoader {
                            anchors.centerIn: parent
                            sourceComp: device.loading ? loadingComp : btnComp

                            Component {
                                id: btnComp

                                IconButton {
                                    icon: "settings"
                                    type: IconButton.Text
                                    padding: Tokens.padding.small
                                    inactiveOnColour: device.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    label.fill: 0

                                    onClicked: {
                                        root.nState.selectedBtDevice = device.modelData;
                                        root.nState.openSubPage("device");
                                    }
                                }
                            }

                            Component {
                                id: loadingComp

                                LoadingIndicator {
                                    implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                                }
                            }
                        }
                    }
                }
            }
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Pair new device")
            subtext: root.btEnabled ? "" : Tr.tr("Turn on Bluetooth first")
            disabled: !root.btEnabled
            onClicked: root.nState.openSubPage("pairing")

            ActionMark {
                sid: "x:bluetooth.pair"
            }
        }

        ToggleRow {
            id: discoverableToggle

            Layout.topMargin: Tokens.spacing.large - parent.spacing

            first: true
            // TRANSLATORS: adjective: other devices can find this computer
            text: Tr.trCtx("Discoverable", "bluetooth setting")
            // caelestia4: says why it is off while Bluetooth is off
            subtext: root.btEnabled ? Tr.tr("Allow nearby devices to find this one") : Tr.tr("Turn on Bluetooth first")
            disabled: !root.btEnabled
            // caelestia4: dims the title and reason too, as "Pair new device" above does (`disabled` only greys the switch)
            contentItem.opacity: root.btEnabled ? 1 : 0.5
            value: root.adapter?.discoverable ?? false
            onToggled: {
                if (root.adapter)
                    root.adapter.discoverable = checked;
            }

            ActionMark {
                parent: discoverableToggle.bg
                row: discoverableToggle
                sid: "x:bluetooth.discoverable"
            }

            Behavior on opacity {
                Anim {}
            }
        }

        ToggleRow {
            id: pairableToggle

            last: true
            // TRANSLATORS: adjective: other devices are allowed to pair with this computer
            text: Tr.trCtx("Pairable", "bluetooth setting")
            subtext: root.btEnabled ? Tr.tr("Allow nearby devices to pair with this one") : Tr.tr("Turn on Bluetooth first")
            disabled: !root.btEnabled
            contentItem.opacity: root.btEnabled ? 1 : 0.5
            value: root.adapter?.pairable ?? false
            onToggled: {
                if (root.adapter)
                    root.adapter.pairable = checked;
            }

            ActionMark {
                parent: pairableToggle.bg
                row: pairableToggle
                sid: "x:bluetooth.pairable"
            }

            Behavior on opacity {
                Anim {}
            }
        }
    }
}
