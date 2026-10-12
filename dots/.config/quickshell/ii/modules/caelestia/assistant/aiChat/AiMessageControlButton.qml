// caelestia4: message / code-block action button in Caelestia style (was end-4's GroupButton). Same interface:
// buttonIcon, activated (shown as checked), enabled, onClicked; child StyledToolTips still follow `hovered`.
import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components.controls

IconButton {
    property string buttonIcon
    property bool activated: false

    type: IconButton.Text
    isRound: true
    isToggle: true
    checked: activated
    disabled: !enabled
    icon: buttonIcon
    padding: Tokens.padding.extraSmall
    font: Tokens.font.icon.builders.small.build()
}
