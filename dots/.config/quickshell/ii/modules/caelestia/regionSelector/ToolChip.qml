import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: a pill button for the region tools / screen translator toolbars. checked = filled primary;
// text is optional (icon-only when empty).
StyledRect {
    id: root

    property string icon
    property string text
    property bool checked
    property bool danger

    signal clicked

    implicitWidth: row.implicitWidth + (text ? Tokens.padding.large * 2 : Tokens.padding.medium * 2)
    implicitHeight: Math.max(row.implicitHeight + Tokens.padding.medium * 2, 44)
    radius: checked ? Tokens.rounding.medium : Tokens.rounding.full
    color: checked ? Colours.palette.m3primary : danger ? Colours.palette.m3errorContainer : "transparent"

    Behavior on radius {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StateLayer {
        radius: root.radius
        color: root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.icon
            fill: root.checked ? 1 : 0
            color: root.checked ? Colours.palette.m3onPrimary : root.danger ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            visible: root.text !== ""
            text: root.text
            color: root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            font: Tokens.font.body.medium
        }
    }
}
