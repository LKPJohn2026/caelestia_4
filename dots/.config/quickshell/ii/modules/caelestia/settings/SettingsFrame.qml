pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.functions as E4F // caelestia4: keep

// caelestia4: Caelestia-style frame for end-4's settings app (settings.qml): sidebar with pill navigation and a
// "Config file" button, and a rounded page container that loads end-4's settings pages (unchanged; ContentSection
// renders sections as cards). Lives in its own file so Caelestia's `Config` type doesn't shadow end-4's `Config`.
Item {
    id: root

    required property var pages // [{ name, icon, iconRotation?, component }]
    property int currentPage: 0
    property string screenName

    signal closeRequested

    Config.screen: screenName
    Tokens.screen: screenName

    readonly property string configPath: E4F.FileUtils.trimFileProtocol(`${E4C.Directories.config}/illogical-impulse/config.json`)

    RowLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.large

        ColumnLayout {
            id: sidebar

            readonly property bool expanded: root.width > 880
            property real railWidth: expanded ? 230 : 64

            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: railWidth
            Layout.topMargin: Tokens.padding.small
            spacing: Tokens.spacing.small

            Behavior on railWidth {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.medium
                Layout.bottomMargin: Tokens.spacing.medium
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "settings"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                    fill: 1
                }

                StyledText {
                    visible: sidebar.expanded
                    Layout.fillWidth: true
                    text: E4.Translation.tr("Settings")
                    font: Tokens.font.title.large
                    elide: Text.ElideRight
                }
            }

            IconTextButton {
                id: configButton

                property bool justCopied: false

                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.spacing.medium
                type: IconTextButton.Tonal
                icon: justCopied ? "check" : "edit"
                text: sidebar.expanded ? (justCopied ? E4.Translation.tr("Path copied") : E4.Translation.tr("Config file")) : ""
                verticalPadding: Tokens.padding.medium
                onClicked: Qt.openUrlExternally(`file://${root.configPath}`)
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: E4.Translation.tr("Open the shell config file · right-click to copy its path")

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        Quickshell.clipboardText = root.configPath;
                        configButton.justCopied = true;
                        revertTimer.restart();
                    }
                }

                Timer {
                    id: revertTimer

                    interval: 1500
                    onTriggered: configButton.justCopied = false
                }
            }

            // caelestia4: the page list scrolls (12 pages + header no longer fit a short window; About was cut off)
            Flickable {
                id: navFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: navCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: navFlick.contentHeight > navFlick.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ColumnLayout {
                    id: navCol

                    width: navFlick.width
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.pages

                        StyledRect {
                            id: navItem

                            required property var modelData
                            required property int index
                            readonly property bool active: root.currentPage === index

                            Layout.fillWidth: true
                            implicitHeight: navRow.implicitHeight + Tokens.padding.medium * 2
                            radius: Tokens.rounding.full
                            color: active ? Colours.palette.m3secondaryContainer : "transparent"

                            StateLayer {
                                radius: Tokens.rounding.full
                                color: navItem.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                onClicked: root.currentPage = navItem.index
                            }

                            RowLayout {
                                id: navRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.large
                                anchors.rightMargin: Tokens.padding.large
                                spacing: Tokens.spacing.medium

                                MaterialIcon {
                                    text: navItem.modelData.icon
                                    rotation: navItem.modelData.iconRotation || 0
                                    fill: navItem.active ? 1 : 0
                                    color: navItem.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    visible: sidebar.expanded
                                    Layout.fillWidth: true
                                    text: navItem.modelData.name
                                    font: Tokens.font.label.large
                                    color: navItem.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainerLow
            clip: true

            Loader {
                id: pageLoader

                anchors.fill: parent
                active: E4C.Config.ready
                source: Quickshell.shellPath(root.pages[0].component) // page paths are relative to settings.qml

                // Fade/slide between pages
                Connections {
                    target: root

                    function onCurrentPageChanged(): void {
                        switchAnim.restart();
                    }
                }

                SequentialAnimation {
                    id: switchAnim

                    Anim {
                        target: pageLoader
                        property: "opacity"
                        to: 0
                        type: Anim.FastEffects
                    }
                    PropertyAction {
                        target: pageLoader
                        property: "source"
                        value: Quickshell.shellPath(root.pages[root.currentPage].component)
                    }
                    PropertyAction {
                        target: pageLoader
                        property: "anchors.topMargin"
                        value: 20
                    }
                    ParallelAnimation {
                        Anim {
                            target: pageLoader
                            property: "opacity"
                            to: 1
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: pageLoader
                            property: "anchors.topMargin"
                            to: 0
                            type: Anim.DefaultSpatial
                        }
                    }
                }
            }

            IconButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Tokens.padding.large
                type: IconButton.Text
                icon: "close"
                onClicked: root.closeRequested()
            }
        }
    }
}
