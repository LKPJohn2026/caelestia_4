// caelestia4: one preset colour scheme in Nexus > Wallpaper & style > Colours: a small mock-up drawn in the
// scheme's own colours (surface, primary / secondary / tertiary dots, a container bar), its name and flavour, and
// which modes it has. Picking it applies the scheme (Colours.setScheme).
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    required property var modelData // { name, flavour, modes: { dark?: {role: hex}, light?: {...} } }
    readonly property var colours: modelData.modes[Colours.light ? "light" : "dark"] ?? Object.values(modelData.modes)[0]
    readonly property bool selected: Colours.scheme === modelData.name && Colours.flavour === modelData.flavour

    function c(role: string): color {
        return `#${root.colours?.[role] ?? "808080"}`;
    }

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: c("surface")
    border.width: selected ? 3 : 1
    border.color: selected ? Colours.palette.m3primary : Qt.alpha(c("outline"), 0.5)

    StateLayer {
        color: root.c("onSurface")
        onClicked: Colours.setScheme(root.modelData.name, root.modelData.flavour)
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: ["primary", "secondary", "tertiary"]

                StyledRect {
                    required property string modelData

                    implicitWidth: 18
                    implicitHeight: 18
                    radius: Tokens.rounding.full
                    color: root.c(modelData)
                }
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                visible: root.selected
                text: "check_circle"
                fill: 1
                color: root.c("primary")
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 8
            radius: Tokens.rounding.full
            color: root.c("primaryContainer")
        }

        StyledText {
            Layout.fillWidth: true
            text: root.modelData.name
            color: root.c("onSurface")
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.flavour
                color: root.c("outline")
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            // Modes the scheme has (most presets are dark only)
            Repeater {
                model: Object.keys(root.modelData.modes)

                MaterialIcon {
                    required property string modelData

                    text: modelData === "light" ? "light_mode" : "dark_mode"
                    color: root.c("outline")
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
