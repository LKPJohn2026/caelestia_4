import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// caelestia4: Caelestia-style section: title row (icon in primary) above a rounded card holding the options
ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias contentData: sectionContent.data
    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        spacing: 10
        Layout.leftMargin: 6
        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.huge
            iconColor: Appearance.m3colors.m3primary
        }
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.m3colors.m3onSurface
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + 16 * 2
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainer

        ColumnLayout {
            id: sectionContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 6
        }
    }
}
