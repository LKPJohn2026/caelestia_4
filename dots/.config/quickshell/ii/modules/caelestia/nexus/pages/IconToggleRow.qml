import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a ToggleRow with an icon before its text, as a RowButton has (Widgets on the desktop)
ToggleRow {
    id: root

    property string iconName // not "icon": a ToggleRow (AbstractButton) has an icon group already

    contentItem: Item {
        anchors.left: parent.left
        anchors.right: root.indicator.left
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: Tokens.spacing.medium

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        RowLayout {
            id: row

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.medium
            opacity: root.disabled ? 0.5 : 1

            MaterialIcon {
                text: root.iconName
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: root.checked ? 1 : 0

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    text: root.text
                    font: root.font
                    elide: Text.ElideRight
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: root.subtext
                    text: root.subtext
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
