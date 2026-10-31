import QtQuick

import qs.modules.common

Loader {
    id: root
    property bool shown: true
    property alias fade: opacityBehavior.enabled
    property alias animation: opacityBehavior.animation
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0
    z: item?.z ?? 0 // caelestia4: from end4-pC: a desktop widget's z (in a loader each) orders it among the others

    Behavior on opacity {
        id: opacityBehavior
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
