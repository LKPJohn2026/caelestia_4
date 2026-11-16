pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

ConnectedRect {
    id: root

    property alias icon: icon.text
    property alias label: label.text
    property alias valueLabel: valueLabel.text
    // caelestia4: with `setting`, the value, range and wheel step come from the registry entry (min/max/step), the
    // value label from its unit, and a change is written once the slider stays put for 300 ms (onMoved runs at once)
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }
    property string subtext: link.desc
    property real value: link.active ? Number(link.shownValue ?? 0) : 0
    // caelestia4: the value's range, and how far one wheel notch or arrow key moves it (volume sliders set
    // GlobalConfig.services.audioIncrement)
    property real from: link.entry?.min ?? 0
    property real to: link.entry?.max ?? 1
    property real wheelStep: link.entry?.step ?? 0.05

    signal moved(value: real)

    onMoved: v => {
        if (link.active)
            link.setLater(v);
    }

    function nudge(delta: real): void {
        if (root.link.blocked)
            return;
        const lo = Math.min(root.from, root.to);
        const hi = Math.max(root.from, root.to);
        const v = Math.max(lo, Math.min(hi, root.value + delta));
        if (v !== root.value)
            root.moved(v);
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins + rowLayout.anchors.topMargin

    HoverHandler {
        id: hover
    }

    RowPulse {
        link: root.link
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        anchors.topMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            opacity: root.link.blocked ? 0.5 : 1
            visible: text.length > 0 // caelestia4: no gap before the label of an icon-less row
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    text: root.link.title
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                    opacity: root.link.blocked ? 0.5 : 1
                }

                SettingMarks {
                    link: root.link
                    hot: hover.hovered || slider.activeFocus
                }

                StyledText {
                    id: valueLabel

                    text: root.link.active ? root.link.format(root.value) : ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    opacity: root.link.blocked ? 0.5 : 1
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: -Tokens.spacing.medium
                visible: text.length > 0
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            SettingNotes {
                Layout.fillWidth: true
                Layout.topMargin: -Tokens.spacing.medium
                link: root.link
            }

            CustomMouseArea {
                function onWheel(event: WheelEvent): void {
                    if (event.angleDelta.y > 0)
                        root.nudge(root.wheelStep);
                    else if (event.angleDelta.y < 0)
                        root.nudge(-root.wheelStep);
                }

                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 2

                StyledSlider {
                    id: slider

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.implicitHeight

                    radius: Tokens.rounding.small
                    from: root.from
                    to: root.to
                    value: root.value
                    enabled: root.enabled && !root.link.blocked
                    opacity: root.link.blocked ? 0.5 : 1
                    // The slider reports a position (0..1)
                    onInteraction: v => root.moved(root.from + v * (root.to - root.from))

                    // Arrow keys step like the wheel; handled here so the slider's value binding stays
                    Accessible.name: root.label
                    Accessible.description: root.valueLabel
                    Keys.onLeftPressed: root.nudge(-root.wheelStep)
                    Keys.onDownPressed: root.nudge(-root.wheelStep)
                    Keys.onRightPressed: root.nudge(root.wheelStep)
                    Keys.onUpPressed: root.nudge(root.wheelStep)
                }
            }
        }
    }

    FocusRing {
        focusItem: slider
    }
}
