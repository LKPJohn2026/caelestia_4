import qs.modules.common
import QtQuick
import QtQuick.Controls

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    color: Appearance.colors.colOnLayer1
    renderType: Text.QtRendering // caelestia4: native rendering rounds each glyph to whole device pixels; at 1.5x that opened gaps ("f older", "ser vices")
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferNoHinting // caelestia4: full hinting broke glyph spacing at 1.5x scale
        variableAxes: Appearance.font.variableAxes.main
    }
}
