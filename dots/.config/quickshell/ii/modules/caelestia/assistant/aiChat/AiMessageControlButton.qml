import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

GroupButton {
    id: button
    property string buttonIcon
    property bool activated: false
    toggled: activated
    baseWidth: height
    colBackgroundHover: Qt.tint(Colours.palette.m3secondaryContainer, Qt.alpha(Colours.palette.m3onSurface, 0.08))
    colBackgroundActive: Qt.tint(Colours.palette.m3secondaryContainer, Qt.alpha(Colours.palette.m3onSurface, 0.12))

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        iconSize: Appearance.font.pixelSize.larger
        text: buttonIcon
        color: button.activated ? Colours.palette.m3onPrimary :
            button.enabled ? Colours.palette.m3onSurface :
            Qt.alpha(Colours.palette.m3onSurface, 0.38)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
