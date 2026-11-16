pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: the frame the P5 rows (SegmentedRow, FontRow, PathRow, ColourRow, KeyValueListRow, DurationRow,
// TimeRangeRow, MultiSelectRow) share: title, description (or `errorText` in red), the "turn on X first" link and the
// applies chip on the left; the modified dot and reset button; then the row's control (its children). The control
// goes under the text, full width, when the row is narrower than 520 px or `stacked` is set. `below` holds a full
// width part under all of it (palette chips). With `setting` the title and description come from the registry
// entry, and the row registers with its page (landing, pulse). Without it the row shows `label` and `subtext`.
ConnectedRect {
    id: root

    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }

    property string label: link.title
    property string subtext: link.desc
    // Shown in place of the subtext, in the error colour, while not empty
    property string errorText
    // The control always sits under the text, full width
    property bool stacked
    readonly property bool narrow: width > 0 && width < 520
    readonly property bool controlBelow: stacked || narrow
    // The control that takes keyboard focus: the focus ring follows it, and the reset button shows at full strength
    property Item focusItem: null
    property bool hot: hover.hovered || (focusItem?.activeFocus ?? false)
    property bool showMarks: true

    default property alias controls: controlBox.data
    property alias below: belowBox.data
    readonly property alias controlBox: controlBox
    readonly property alias focusRing: ring

    readonly property real textOpacity: link.blocked ? 0.5 : 1
    readonly property string accessibleDescription: link.blocked ? subtext + " " + link.disabledReason : subtext

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2

    HoverHandler {
        id: hover
    }

    RowPulse {
        link: root.link
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        GridLayout {
            Layout.fillWidth: true
            // Narrow: the marks stay right of the text and the control takes the next line, full width
            columns: root.controlBelow ? 2 : 3
            columnSpacing: Tokens.spacing.medium
            rowSpacing: Tokens.spacing.small

            // Cells by row and column, so the hidden marks don't move the control into their cell
            ColumnLayout {
                Layout.row: 0
                Layout.column: 0
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                    opacity: root.textOpacity
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.errorText || root.subtext
                    color: root.errorText ? Colours.palette.m3error : Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                    opacity: root.textOpacity
                }

                SettingNotes {
                    Layout.fillWidth: true
                    link: root.link
                }
            }

            // A holder, so `showMarks` can hide the marks without replacing their own `visible`
            Item {
                Layout.row: 0
                Layout.column: 1
                Layout.alignment: Qt.AlignVCenter
                visible: root.showMarks && root.link.modified
                implicitWidth: marks.implicitWidth
                implicitHeight: marks.implicitHeight

                SettingMarks {
                    id: marks

                    anchors.fill: parent
                    link: root.link
                    hot: root.hot
                }
            }

            RowLayout {
                id: controlBox

                Layout.fillWidth: root.controlBelow
                Layout.row: root.controlBelow ? 1 : 0
                Layout.column: root.controlBelow ? 0 : 2
                Layout.columnSpan: root.controlBelow ? 2 : 1
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                spacing: Tokens.spacing.small
                opacity: root.link.blocked ? 0.5 : 1
                enabled: !root.link.blocked
            }
        }

        ColumnLayout {
            id: belowBox

            Layout.fillWidth: true
            visible: Array.from(children).some(c => c.visible)
            spacing: Tokens.spacing.small
            opacity: root.link.blocked ? 0.5 : 1
            enabled: !root.link.blocked
        }
    }

    FocusRing {
        id: ring

        focusItem: root.focusItem
    }
}
