pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.caelestia.overlay
import Caelestia.Config
import qs.modules.common as E4C // caelestia4: end-4 Config / Directories
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

StyledOverlayWidget {
    id: root
    minimumWidth: 310
    minimumHeight: 150

    // caelestia4: Caelestia style: four round tonal actions with labels, and a text button for the folder
    contentItem: OverlayBackground {
        id: contentItem

        radius: root.contentRadius

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.medium

                Action {
                    icon: "screenshot_region"
                    label: Translation.tr("Region")
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                    }
                }

                Action {
                    icon: "photo_camera"
                    label: Translation.tr("Screen")
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["bash", "-c", "grim - | wl-copy"]);
                    }
                }

                Action {
                    icon: "screen_record"
                    label: Translation.tr("Record region")
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
                    }
                }

                Action {
                    icon: "capture"
                    label: Translation.tr("Record screen")
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached([E4C.Directories.recordScriptPath, "--fullscreen", "--sound"]);
                    }
                }
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                type: IconTextButton.Text
                icon: "folder_open"
                text: Translation.tr("Open recordings folder")
                onClicked: {
                    GlobalStates.overlayOpen = false;
                    Qt.openUrlExternally(`file://${E4C.Config.options.screenRecord.savePath}`);
                }
            }
        }
    }

    component Action: ColumnLayout {
        id: action

        property string icon
        property string label

        signal clicked

        Layout.preferredWidth: 72 // fixed, so four fit and long labels wrap instead of overflowing
        Layout.alignment: Qt.AlignTop
        spacing: Tokens.spacing.extraSmall

        IconButton {
            Layout.alignment: Qt.AlignHCenter
            type: IconButton.Tonal
            isRound: true
            icon: action.icon
            padding: Tokens.padding.medium
            font: Tokens.font.icon.builders.medium.build()
            onClicked: action.clicked()
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: action.label
            font: Tokens.font.label.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
