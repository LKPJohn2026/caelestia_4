pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: polkit authentication dialog in Caelestia style (replaces end-4's modules/ii/polkit in the caelestia
// family). Same agent (end-4 PolkitService). Every screen gets a dimmed scrim; the dialog itself (and keyboard
// focus) is on the monitor that was focused when the request came in.
// Enter = authenticate, Esc = cancel. Wrong password: the field shakes and the error shows; verifying: spinner.
Scope {
    id: root

    readonly property var flow: E4.PolkitService.flow
    property string dialogScreen

    Connections {
        target: E4.PolkitService

        function onActiveChanged(): void {
            if (E4.PolkitService.active)
                root.dialogScreen = Hypr.focusedMonitor?.name ?? Quickshell.screens[0].name;
        }
    }

    Loader {
        active: E4.PolkitService.active

        sourceComponent: Variants {
            model: Quickshell.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData
                readonly property bool hasDialog: modelData.name === (root.dialogScreen || Hypr.focusedMonitor?.name)

                screen: modelData
                name: "polkit"
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: hasDialog ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.palette.m3scrim, 0.5)
                    opacity: 0
                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Loader {
                    anchors.centerIn: parent
                    active: win.hasDialog
                    sourceComponent: dialogComp
                }
            }
        }
    }

    Component {
        id: dialogComp

        StyledRect {
            id: dialog

            readonly property bool verifying: !E4.PolkitService.interactionAvailable && !(root.flow?.isCompleted ?? false)
            property bool failed: false
            property bool reveal: false

            function submit(): void {
                if (!E4.PolkitService.interactionAvailable)
                    return;
                failed = false;
                E4.PolkitService.submit(input.text);
            }

            implicitWidth: 480
            implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surface

            scale: 0.92
            opacity: 0
            Component.onCompleted: {
                scale = 1;
                opacity = 1;
                input.forceActiveFocus();
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

            Connections {
                target: root.flow

                function onAuthenticationFailed(): void {
                    dialog.failed = true;
                    input.text = "";
                    shake.restart();
                    input.forceActiveFocus();
                }
            }

            Connections {
                target: E4.PolkitService

                function onInteractionAvailableChanged(): void {
                    if (E4.PolkitService.interactionAvailable)
                        input.forceActiveFocus();
                }
            }

            Keys.onEscapePressed: E4.PolkitService.cancel()

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: 3
            }

            ColumnLayout {
                id: layout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.extraLarge
                spacing: Tokens.spacing.medium

                // Shield, with the requesting app's icon as a badge when polkit gives one
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Tokens.spacing.small
                    implicitWidth: 72
                    implicitHeight: 72

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: dialog.failed ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: dialog.failed ? "gpp_bad" : "shield_lock"
                            fill: 1
                            color: dialog.failed ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.extraLarge
                        }
                    }

                    StyledRect {
                        visible: (root.flow?.iconName ?? "") !== ""
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: -4
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3surfaceContainerHighest

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 20
                            source: visible ? Quickshell.iconPath(root.flow.iconName, "dialog-password") : ""
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Tr.tr("Authentication required")
                    font: Tokens.font.title.large
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: E4.PolkitService.cleanMessage
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                StyledRect {
                    visible: (root.flow?.actionId ?? "") !== ""
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: layout.width
                    implicitWidth: actionText.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: actionText.implicitHeight + Tokens.padding.extraSmall * 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainer

                    StyledText {
                        id: actionText

                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, layout.width - Tokens.padding.medium * 2)
                        elide: Text.ElideMiddle
                        text: root.flow?.actionId ?? ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }

                // Password pill
                StyledRect {
                    id: pill

                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.medium
                    implicitHeight: 56
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: input.activeFocus || dialog.failed ? 2 : 0
                    border.color: dialog.failed ? Colours.palette.m3error : Colours.palette.m3primary

                    transform: Translate {
                        id: shakeOffset
                    }

                    SequentialAnimation {
                        id: shake

                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: -12
                            duration: 50
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: 10
                            duration: 70
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: -6
                            duration: 60
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: 0
                            duration: 60
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "key"
                            color: dialog.failed ? Colours.palette.m3error : Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextInput {
                                id: input

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: E4.PolkitService.interactionAvailable
                                echoMode: (root.flow?.responseVisible ?? false) || dialog.reveal ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "●"
                                color: Colours.palette.m3onSurface
                                selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                                selectedTextColor: Colours.palette.m3onSurface
                                font: Tokens.font.body.large
                                clip: true
                                focus: true
                                onAccepted: dialog.submit()
                                onTextEdited: dialog.failed = false
                                Keys.onEscapePressed: E4.PolkitService.cancel()
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text.length === 0
                                text: dialog.verifying ? Tr.tr("Checking…") : E4.PolkitService.cleanPrompt
                                color: Colours.palette.m3outline
                                font: Tokens.font.body.large
                            }
                        }

                        LoadingIndicator {
                            visible: dialog.verifying
                            implicitWidth: 32
                            implicitHeight: 32
                        }

                        IconButton {
                            visible: !dialog.verifying && !(root.flow?.responseVisible ?? false)
                            type: IconButton.Text
                            icon: dialog.reveal ? "visibility_off" : "visibility"
                            onClicked: {
                                dialog.reveal = !dialog.reveal;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }

                // Status: error / polkit info / caps lock
                StyledText {
                    readonly property string supp: root.flow?.supplementaryMessage ?? ""

                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.large
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: {
                        if (dialog.failed)
                            return supp && (root.flow?.supplementaryIsError ?? false) ? supp : Tr.tr("Wrong password, try again");
                        if (supp)
                            return supp;
                        return Hypr.capsLock ? Tr.tr("Caps Lock is on") : "";
                    }
                    color: dialog.failed || (root.flow?.supplementaryIsError ?? false) ? Colours.palette.m3error : Colours.palette.m3tertiary
                    font: Tokens.font.body.small
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        type: TextButton.Text
                        text: Tr.tr("Cancel")
                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.medium
                        onClicked: E4.PolkitService.cancel()
                    }

                    TextButton {
                        type: TextButton.Filled
                        text: Tr.tr("Authenticate")
                        disabled: !E4.PolkitService.interactionAvailable || input.text.length === 0
                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.medium
                        onClicked: dialog.submit()
                    }
                }
            }
        }
    }
}
