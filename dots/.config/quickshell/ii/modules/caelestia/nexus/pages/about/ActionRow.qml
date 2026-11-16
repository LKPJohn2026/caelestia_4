pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a RowButton with a second action at its end (About > Your settings, Changed settings): click the row
// (`clicked`) or its icon button (`actionIcon`, named by `actionText`; `actionClicked`). Tab reaches both; Enter or
// Space clicks the focused one. `busy` dims the row and ignores clicks while a script runs
// caelestia4: a second icon button after it (`action2Icon`, `action2Text`; `action2Clicked`), e.g. Profiles' Delete
ConnectedRect {
    id: root

    property string icon
    property string text
    property string subtext
    property string actionIcon
    property string actionText
    property string action2Icon
    property string action2Text
    property string trailingIcon
    property bool busy
    // caelestia4: cut the subtext to this many lines with "…" (0: no limit)
    property int subtextLines

    signal clicked
    signal actionClicked
    signal action2Clicked

    function keyClick(): void {
        if (!root.busy)
            root.clicked();
    }

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    activeFocusOnTab: true
    Keys.onReturnPressed: keyClick()
    Keys.onEnterPressed: keyClick()
    Keys.onSpacePressed: keyClick()
    onActiveFocusChanged: {
        if (!activeFocus)
            focusRing.pointerFocus = false;
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.description: root.subtext
    Accessible.onPressAction: keyClick()

    StateLayer {
        disabled: root.busy
        onPressed: {
            if (root.activeFocus)
                focusRing.pointerFocus = true;
        }
        onClicked: root.clicked()
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
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: root.actionIcon || root.action2Icon ? Tokens.padding.medium : Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium
        opacity: root.busy ? 0.5 : 1

        Behavior on opacity {
            Anim {}
        }

        MaterialIcon {
            visible: root.icon
            text: root.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.text
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: text
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                maximumLineCount: root.subtextLines > 0 ? root.subtextLines : 1000
                elide: root.subtextLines > 0 ? Text.ElideRight : Text.ElideNone
            }
        }

        IconButton {
            id: actionBtn

            visible: root.actionIcon
            icon: root.actionIcon
            type: IconButton.Text
            disabled: root.busy
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            activeFocusOnTab: visible
            Accessible.role: Accessible.Button
            Accessible.name: root.actionText
            ToolTip.visible: hovered
            ToolTip.delay: 500
            ToolTip.text: root.actionText
            onClicked: root.actionClicked()
            Keys.onReturnPressed: root.actionClicked()
            Keys.onEnterPressed: root.actionClicked()
            Keys.onSpacePressed: root.actionClicked()

            FocusRing {
                focusItem: actionBtn
            }
        }

        IconButton {
            id: action2Btn

            visible: root.action2Icon
            icon: root.action2Icon
            type: IconButton.Text
            disabled: root.busy
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            activeFocusOnTab: visible
            Accessible.role: Accessible.Button
            Accessible.name: root.action2Text
            ToolTip.visible: hovered
            ToolTip.delay: 500
            ToolTip.text: root.action2Text
            onClicked: root.action2Clicked()
            Keys.onReturnPressed: root.action2Clicked()
            Keys.onEnterPressed: root.action2Clicked()
            Keys.onSpacePressed: root.action2Clicked()

            FocusRing {
                focusItem: action2Btn
            }
        }

        MaterialIcon {
            visible: root.trailingIcon
            text: root.trailingIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }
    }
}
