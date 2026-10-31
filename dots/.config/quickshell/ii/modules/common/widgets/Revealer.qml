import qs.modules.common
import QtQuick

/**
 * Recreation of GTK revealer. Expects one single child.
 */
Item {
    id: root
    property bool reveal
    property bool vertical: false
    clip: true

    // caelestia4: the child's implicit size, not childrenRect (end4-pC): a child anchored to this item's centre made
    // childrenRect depend on this item's own height, a binding loop
    readonly property Item child: children.length > 0 ? children[0] : null
    readonly property real childWidth: child ? child.implicitWidth : 0
    readonly property real childHeight: child ? child.implicitHeight : 0

    implicitWidth: (reveal || vertical) ? childWidth : 0
    implicitHeight: (reveal || !vertical) ? childHeight : 0
    visible: reveal || (implicitWidth > 0 && !vertical) || (implicitHeight > 0 && vertical)

    Behavior on implicitWidth {
        enabled: !vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        enabled: vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
}
