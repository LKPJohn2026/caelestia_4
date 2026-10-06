pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters
import "../../ii/cheatsheet/periodic_table.js" as PTable

// caelestia4: end-4's cheatsheet (modules/ii/cheatsheet) restyled for the Caelestia family. Same data: Hyprland
// keybinds grouped by "Category: description" (end-4 HyprlandKeybinds) and the periodic table; same IPC target
// ("cheatsheet") and global shortcuts (cheatsheetToggle/Open/Close; Super+/ in end-4's keybinds).
// Esc or clicking outside closes it; Ctrl+Tab / Ctrl+PgUp/PgDn switch tabs.
Scope {
    id: root

    property bool open: false
    readonly property var tabs: [
        {
            icon: "keyboard",
            name: Tr.tr("Keybinds")
        },
        {
            icon: "experiment",
            name: Tr.tr("Elements")
        }
    ]

    Loader {
        active: root.open

        sourceComponent: StyledWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "cheatsheet"
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            mask: Region {
                item: panel
            }

            Component.onCompleted: E4.GlobalFocusGrab.addDismissable(win)
            Component.onDestruction: E4.GlobalFocusGrab.removeDismissable(win)

            Connections {
                target: E4.GlobalFocusGrab

                function onDismissed(): void {
                    root.open = false;
                }
            }

            StyledRect {
                id: panel

                readonly property int tab: E4C.Persistent.states.cheatsheet.tabIndex

                function setTab(i: int): void {
                    E4C.Persistent.states.cheatsheet.tabIndex = (i + root.tabs.length) % root.tabs.length;
                }

                anchors.centerIn: parent
                implicitWidth: win.width * 0.72
                implicitHeight: win.height * 0.76
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surface
                focus: true

                scale: 0.96
                opacity: 0
                Component.onCompleted: {
                    scale = 1;
                    opacity = 1;
                    forceActiveFocus();
                }
                Behavior on scale {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.open = false;
                    } else if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab)
                            setTab(tab + 1);
                        else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab)
                            setTab(tab - 1);
                        else
                            return;
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 3
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.large

                    // Header: title, tabs, close
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "help"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            text: Tr.tr("Cheatsheet")
                            font: Tokens.font.title.medium
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: root.tabs

                            IconTextButton {
                                required property var modelData
                                required property int index

                                type: IconTextButton.Tonal
                                isToggle: true
                                checked: panel.tab === index
                                icon: modelData.icon
                                text: modelData.name
                                verticalPadding: Tokens.padding.small
                                horizontalPadding: Tokens.padding.large
                                onClicked: {
                                    panel.setTab(index);
                                    checked = Qt.binding(() => panel.tab === index);
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        IconButton {
                            type: IconButton.Text
                            icon: "close"
                            onClicked: root.open = false
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: panel.tab

                        // Keybinds: category cards flowing top-to-bottom, scrolling sideways
                        StyledFlickable {
                            id: keybindsFlick

                            clip: true
                            contentWidth: flow.implicitWidth
                            contentHeight: height
                            flickableDirection: Flickable.HorizontalFlick

                            Flow {
                                id: flow

                                height: keybindsFlick.height
                                flow: Flow.TopToBottom
                                spacing: Tokens.spacing.medium

                                Repeater {
                                    model: [...E4.HyprlandKeybinds.keybindCategories, ""]

                                    KeybindCategory {}
                                }
                            }

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse
                                onWheel: event => keybindsFlick.contentX = Math.max(0, Math.min(keybindsFlick.contentWidth - keybindsFlick.width, keybindsFlick.contentX - event.angleDelta.y))
                            }
                        }

                        // Periodic table (end-4 data)
                        Item {
                            Column {
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: [...PTable.elements, [], ...PTable.series]

                                    Row {
                                        id: tableRow

                                        required property var modelData

                                        spacing: Tokens.spacing.small
                                        height: modelData.length === 0 ? Tokens.spacing.large : implicitHeight

                                        Repeater {
                                            model: tableRow.modelData

                                            ElementTile {}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            root.open = !root.open;
        }

        function close(): void {
            root.open = false;
        }

        function open(): void {
            root.open = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"
        onPressed: root.open = !root.open
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"
        onPressed: root.open = true
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"
        onPressed: root.open = false
    }
}
