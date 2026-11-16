pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

ConnectedRect {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias subtext: subLabel.text
    property string trailingIcon
    property alias disabled: stateLayer.disabled
    // caelestia4: set before giving the row focus after a mouse action, so the ring stays hidden (DialogRowButton)
    property alias pointerFocus: focusRing.pointerFocus

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias subLabel: subLabel

    signal clicked(event: MouseEvent)

    // caelestia4: keyboard: Tab focuses the row, Enter/Space click it (event null)
    function keyClick(): void {
        if (!root.disabled)
            root.clicked(null);
    }

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    activeFocusOnTab: !disabled
    Keys.onReturnPressed: keyClick()
    Keys.onEnterPressed: keyClick()
    Keys.onSpacePressed: keyClick()
    onActiveFocusChanged: {
        if (!activeFocus)
            focusRing.pointerFocus = false;
    }

    Accessible.role: Accessible.Button
    Accessible.name: label.text
    Accessible.description: subLabel.text
    Accessible.onPressAction: keyClick()

    StateLayer {
        id: stateLayer

        onPressed: {
            if (root.activeFocus)
                focusRing.pointerFocus = true;
        }
        onClicked: e => root.clicked(e)
    }

    FocusRing {
        id: focusRing

        focusItem: root
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.largeIncreased

        spacing: Tokens.spacing.medium
        opacity: root.disabled ? 0.5 : 1

        Behavior on opacity {
            Anim {}
        }

        MaterialIcon {
            id: iconLabel

            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        Column {
            id: column

            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                anchors.left: parent.left
                anchors.right: parent.right

                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledText {
                id: subLabel

                anchors.left: parent.left
                anchors.right: parent.right

                visible: text
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            asynchronous: true
            active: root.trailingIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
    }
}
