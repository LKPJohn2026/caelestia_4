pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.services as E4 // caelestia4: keep
import qs.modules.common.functions as E4F // caelestia4: keep

Column {
    id: root

    required property ScreenState screenState

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    // caelestia4: end-4's session-screen warnings (package manager running / download in progress), refreshed on open
    Connections {
        function onSessionChanged(): void {
            if (root.screenState.session)
                E4.SessionWarnings.refresh();
        }

        target: root.screenState
    }

    Repeater {
        model: [
            {
                shown: E4.SessionWarnings.packageManagerRunning,
                icon: "deployed_code_update",
                text: Tr.tr("Updating")
            },
            {
                shown: E4.SessionWarnings.downloadRunning,
                icon: "downloading",
                text: Tr.tr("Downloading")
            }
        ]

        StyledRect {
            required property var modelData

            visible: modelData.shown
            implicitWidth: Tokens.sizes.session.button
            implicitHeight: warnCol.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.large
            color: Colours.palette.m3errorContainer

            Column {
                id: warnCol

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    color: Colours.palette.m3onErrorContainer
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.text
                    color: Colours.palette.m3onErrorContainer
                    font: Tokens.font.label.small
                }
            }
        }
    }

    // caelestia4: end-4's extra session actions (lock, sleep), through end-4's Session functions
    SessionButton {
        id: lock

        icon: "lock"
        action: () => E4F.Session.lock()

        KeyNavigation.down: sleep
    }

    SessionButton {
        id: sleep

        icon: "dark_mode"
        action: () => E4F.Session.suspend()

        KeyNavigation.up: lock
        KeyNavigation.down: logout
    }

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        command: Config.session.commands.logout

        KeyNavigation.up: sleep
        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    logout.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    AnimatedImage {
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width // caelestia4: Qt applies the devicePixelRatio itself

        playing: visible
        asynchronous: true
        speed: Config.general.sessionGifSpeed
        source: Paths.absolutePath(Config.paths.sessionGif)
        fillMode: AnimatedImage.PreserveAspectFit
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
        KeyNavigation.down: firmware
    }

    // caelestia4: end-4's reboot to firmware settings (UEFI) and task manager
    SessionButton {
        id: firmware

        icon: "settings_applications"
        action: () => E4F.Session.rebootToFirmware()

        KeyNavigation.up: reboot
        KeyNavigation.down: taskManager
    }

    SessionButton {
        id: taskManager

        icon: "browse_activity"
        action: () => E4F.Session.launchTaskManager()

        KeyNavigation.up: firmware
    }

    component SessionButton: IconButton {
        id: button

        property list<string> command
        property var action: null // caelestia4: a function instead of a command (end-4 Session actions)

        function exec(): void {
            if (action) {
                root.screenState.session = false;
                action();
                return;
            }
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: exec()

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
