import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a ToggleRow with an icon before its text, as a RowButton has (Desktop > Widgets on the desktop). Moved
// here from pages/IconToggleRow.qml with the Wallpaper & style split; the description wraps instead of eliding
ToggleRow {
    id: root

    property string iconName // not "icon": a ToggleRow (AbstractButton) has an icon group already
    // caelestia4: a registry-style id the page can land on (scroll to and pulse), without the row reading or writing
    // it as `setting` does (the page turns the widget on with PresetLayout)
    property string landingId
    readonly property RowSetting landLink: RowSetting {
        sid: root.landingId
        row: root
    }

    RowPulse {
        parent: root.background
        link: root.landLink
    }

    // caelestia4: the widget's own sub-page ("widget.<key>"): a chevron after the switch opens it (openRequested);
    // the row itself still toggles. Empty = no chevron
    property string openName
    signal openRequested
    readonly property real openWidth: openName ? openBtn.implicitWidth + Tokens.spacing.small : 0

    indicator.anchors.rightMargin: horizontalPadding + openWidth
    rightPadding: horizontalPadding + implicitIndicatorWidth + Tokens.spacing.medium + openWidth

    IconButton {
        id: openBtn

        anchors.right: parent.right
        anchors.rightMargin: root.horizontalPadding - Tokens.padding.extraSmall / 2
        anchors.verticalCenter: parent.verticalCenter
        visible: root.openName
        icon: "chevron_right"
        type: IconButton.Text
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Tr.tr("%1 settings").arg(root.text)
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: Tr.tr("%1 settings").arg(root.text)
        onClicked: root.openRequested()
        Keys.onReturnPressed: root.openRequested()
        Keys.onEnterPressed: root.openRequested()
    }

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
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
