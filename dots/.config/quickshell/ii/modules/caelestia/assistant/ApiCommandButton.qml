// caelestia4: a command / tag / suggestion chip in Caelestia style (was end-4's GroupButton). Same interface as before:
// buttonText (or a custom contentItem), colBackground, downAction (run on click), hovered, clicked.
import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    property string buttonText
    property color colBackground: Colours.tPalette.m3surfaceContainerHighest
    property bool bounce: true // kept for compatibility (end-4 press animation); unused
    property var downAction
    property Item contentItem: StyledText {
        text: root.buttonText
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }
    readonly property alias hovered: stateLayer.containsMouse

    signal clicked

    implicitWidth: (contentItem?.implicitWidth ?? 0) + Tokens.padding.medium * 2
    implicitHeight: (contentItem?.implicitHeight ?? 0) + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: colBackground

    onContentItemChanged: {
        if (contentItem) {
            contentItem.parent = root;
            contentItem.anchors.centerIn = root;
        }
    }
    Component.onCompleted: contentItemChanged()

    StateLayer {
        id: stateLayer

        radius: root.radius
        onClicked: {
            root.downAction?.();
            root.clicked();
        }
    }
}
