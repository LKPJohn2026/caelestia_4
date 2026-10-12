// caelestia4: "scroll to bottom" for the Assistant lists, a Caelestia tonal button that appears when scrolled up
import QtQuick
import Caelestia.Config
import qs.services as E4 // caelestia4: keep (Translation)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls

IconTextButton {
    id: root

    required property ListView target

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Tokens.padding.medium
    }
    opacity: !target.atYEnd ? 1 : 0
    scale: !target.atYEnd ? 1 : 0.7
    visible: opacity > 0
    type: IconTextButton.Tonal
    icon: "arrow_downward"
    text: E4.Translation.tr("Scroll to bottom")
    onClicked: target.positionViewAtEnd()

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on scale {
        Anim {}
    }
}
