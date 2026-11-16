import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

StyledSwitch {
    id: root

    property string subtext
    property alias first: bg.first
    property alias last: bg.last
    readonly property alias bg: bg

    // caelestia4: a registry id ("c:bar.tray.compact"): the row takes its title, description and value from it, writes
    // it when toggled (onToggled handlers still run), and shows modified/reset, the applies chip and the disabled reason.
    // `text`, `subtext` and `value` set by the page win over the registry's
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }

    text: link.title
    subtext: link.desc
    value: link.active ? link.value : undefined

    Layout.fillWidth: true

    horizontalPadding: Tokens.padding.largeIncreased
    verticalPadding: Tokens.padding.medium
    // caelestia4: the label sits in the control's content area, its right edge kept clear of the switch (and the
    // modified marks) by padding. It used to anchor to the indicator, which isn't its parent or sibling (runtime
    // warnings, a null parent)
    rightPadding: horizontalPadding + implicitIndicatorWidth + Tokens.spacing.medium + (marks.visible ? marks.implicitWidth + Tokens.spacing.small : 0)
    font: Tokens.font.body.small

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(implicitContentHeight, implicitIndicatorHeight) + verticalPadding * 2
    cLayer: 2

    // caelestia4: a row whose parent setting is off stays enabled (its reason link must take clicks) but can't toggle
    checkable: !link.blocked
    indicator.opacity: link.blocked ? 0.5 : 1
    indicator.anchors.verticalCenter: verticalCenter
    indicator.anchors.right: right
    indicator.anchors.rightMargin: root.horizontalPadding

    Accessible.name: text
    Accessible.description: link.blocked ? subtext + " " + link.disabledReason : subtext

    function keyToggle(): void {
        if (root.disabled)
            return;
        if (link.blocked) {
            link.followReason();
            return;
        }
        root.toggle();
        root.toggled();
    }

    // Space toggles (Switch); Enter too
    Keys.onReturnPressed: keyToggle()
    Keys.onEnterPressed: keyToggle()

    onPressed: {
        if (!link.blocked)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }
    onToggled: {
        if (link.active)
            link.set(checked);
    }

    background: ConnectedRect {
        id: bg

        StateLayer {
            id: stateLayer

            disabled: root.disabled || root.link.blocked
            manualPressOverride: root.pressed && !root.link.blocked
        }

        FocusRing {
            focusItem: root
        }

        RowPulse {
            link: root.link
        }
    }

    contentItem: Item {
        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                id: label

                width: parent.width
                text: root.text
                font: root.font
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            StyledText {
                width: parent.width
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            SettingNotes {
                width: parent.width
                link: root.link
            }
        }
    }

    SettingMarks {
        id: marks

        anchors.right: parent.right
        anchors.rightMargin: root.horizontalPadding + root.implicitIndicatorWidth + Tokens.spacing.medium
        anchors.verticalCenter: parent.verticalCenter
        link: root.link
        hot: hover.hovered || root.activeFocus
    }

    HoverHandler {
        id: hover
    }
}
