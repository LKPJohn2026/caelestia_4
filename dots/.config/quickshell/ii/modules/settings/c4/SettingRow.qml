import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: one setting per row, the standard settings-app pattern: [icon] title + one-line description on the
// left, the control on the right. Base for SwitchRow, SpinRow, SliderRow, ChoiceRow, TextRow, ButtonRow.
// clickable: the whole row emits rowClicked (SwitchRow toggles with it); the control itself stays on top.
Item {
    id: root

    property string title
    property string description
    property string icon
    property bool clickable: false
    default property alias control: controlSlot.data
    signal rowClicked

    Layout.fillWidth: true
    implicitHeight: Math.max(52, row.implicitHeight)
    opacity: enabled ? 1 : 0.45

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.rowClicked()
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        OptionalMaterialSymbol {
            visible: root.icon !== ""
            icon: root.icon
            iconSize: Appearance.font.pixelSize.huge
            iconColor: Appearance.m3colors.m3onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3onSurfaceVariant
            }
        }

        Item {
            id: controlSlot

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
