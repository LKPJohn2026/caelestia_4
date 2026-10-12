pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep

// caelestia4: end-4's sidebar system row (sidebarRight/SidebarRightContent SystemButtonRow) in Caelestia style:
// uptime, reload Hyprland + Quickshell, end-4 settings app, session menu.
StyledRect {
    id: root

    required property ScreenState screenState

    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.medium
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "schedule"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Up %1").arg(E4.DateTime.uptime)
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }

        SystemButton {
            icon: "restart_alt"
            tip: Tr.tr("Reload Hyprland & Quickshell")
            onClicked: {
                // caelestia4: restart the shell unit, not Quickshell.reload(): in-process reloads leave theme icons blank
                Quickshell.execDetached(["sh", "-c", "hyprctl reload; systemctl --user restart caelestia4-shell.service"]);
            }
        }

        SystemButton {
            icon: "tune"
            tip: Tr.tr("end-4 settings")
            onClicked: {
                root.screenState.utilities = false;
                E4.AppLauncher.exec(["qs", "-p", Quickshell.shellPath("settings.qml")]);
            }
        }

        SystemButton {
            icon: "power_settings_new"
            tip: Tr.tr("Session")
            onClicked: {
                root.screenState.utilities = false;
                root.screenState.session = true;
            }
        }
    }

    component SystemButton: IconButton {
        property string tip

        type: IconButton.Tonal
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: tip
    }
}
