pragma ComponentBehavior: Bound

// caelestia4: Colours sub-page (upstream Caelestia ships it as "under construction"). Pick where the desktop's
// colours come from: the wallpaper (end-4's matugen pipeline, with its colour style) or one of Caelestia's preset
// schemes. Both go through the same end-4 outputs (shell, Hyprland, hyprlock, fuzzel, terminals); see
// utils/scripts/scheme.py. Light / dark stays on the parent page ("Dark theme").
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 palette type, switchwall.sh path)

PageBase {
    id: root

    readonly property bool dynamic: Colours.scheme === "dynamic"

    // end-4's palette types ("auto" lets end-4 pick one for the wallpaper)
    readonly property list<MenuItem> styleItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "M3 scheme variant name")
            value: "auto"
        },
        MenuItem {
            text: Tr.trCtx("Tonal Spot", "M3 scheme variant name")
            value: "scheme-tonal-spot"
        },
        MenuItem {
            text: Tr.trCtx("Expressive", "M3 scheme variant name")
            value: "scheme-expressive"
        },
        MenuItem {
            text: Tr.trCtx("Fidelity", "M3 scheme variant name")
            value: "scheme-fidelity"
        },
        MenuItem {
            text: Tr.trCtx("Content", "M3 scheme variant name")
            value: "scheme-content"
        },
        MenuItem {
            text: Tr.trCtx("Fruit Salad", "M3 scheme variant name")
            value: "scheme-fruit-salad"
        },
        MenuItem {
            text: Tr.trCtx("Rainbow", "M3 scheme variant name")
            value: "scheme-rainbow"
        },
        MenuItem {
            text: Tr.trCtx("Neutral", "M3 scheme variant name")
            value: "scheme-neutral"
        },
        MenuItem {
            text: Tr.trCtx("Monochrome", "M3 scheme variant name")
            value: "scheme-monochrome"
        }
    ]

    title: Tr.tr("Colours")
    isSubPage: true

    Component.onCompleted: Colours.reloadSchemes()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        SectionHeader {
            first: true
            text: Tr.tr("Wallpaper colours")
        }

        // Use the wallpaper's colours (end-4's default)
        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: wallRow.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: Colours.setScheme("dynamic", "")
            }

            RowLayout {
                id: wallRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ClipRect {
                    implicitWidth: 96
                    implicitHeight: 54
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: Wallpapers.current
                        sourceSize: Qt.size(width, height)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Follow the wallpaper")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Colours are generated from the current wallpaper and change with it")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                MaterialIcon {
                    text: root.dynamic ? "check_circle" : "radio_button_unchecked"
                    fill: root.dynamic ? 1 : 0
                    color: root.dynamic ? Colours.palette.m3primary : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }
            }
        }

        // end-4's colour style; choosing one also switches back to wallpaper colours
        SelectRow {
            last: true
            label: Tr.tr("Colour style")
            subtext: root.dynamic ? Tr.tr("How colours are picked from the wallpaper") : Tr.tr("Choosing a style switches back to wallpaper colours")
            menuItems: root.styleItems
            active: root.styleItems.find(i => i.value === E4C.Config.options.appearance.palette.type) ?? root.styleItems[0]
            onSelected: item => {
                E4C.Config.options.appearance.palette.type = item.value;
                // --type explicitly (config.json is written with a delay); switchwall.sh --type also leaves a preset
                Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--type", item.value, "--mode", Colours.light ? "light" : "dark"]);
            }
        }

        SectionHeader {
            text: Tr.tr("Preset schemes")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("A preset stays when the wallpaper changes. Presets with only one mode keep it when the theme is switched.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(2, Math.floor(width / 190))
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: Colours.schemes

                SchemeCard {}
            }
        }
    }
}
