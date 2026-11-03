import qs.modules.common
import qs.modules.common.functions
import QtQuick

StyledText {
    id: root
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real fill: 0
    property real truncatedFill: fill.toFixed(1) // Reduce memory consumption spikes from constant font remapping
    // caelestia4: native glyphs are drawn once at the window's scale, so a desktop widget's Scale stretches them soft;
    // curves are drawn at whatever size they end up. But the variable font's glyphs keep overlapping outlines (a filled
    // play button's, the note over the page in "lyrics"), which the GPU's curve renderer draws as holes: in a scaled
    // widget an icon takes Material Symbols Rounded Outline or Filled, the same glyphs with the overlaps merged. Half
    // filled (mid-animation) or before those fonts load it's a native glyph, whole but soft
    readonly property string staticFamily: !WidgetScale.transformed(root) ? ""
        : truncatedFill === 0 ? (Appearance?.font.family.iconMaterialOutline ?? "")
        : truncatedFill === 1 ? (Appearance?.font.family.iconMaterialFilled ?? "") : ""
    readonly property bool staticGlyphs: staticFamily !== "" // a static font: no variable axes
    renderType: staticGlyphs ? Text.CurveRendering : Text.NativeRendering
    font {
        hintingPreference: Font.PreferNoHinting
        family: staticGlyphs ? staticFamily : (Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded")
        pixelSize: iconSize
        weight: staticGlyphs ? Font.Normal : Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
        variableAxes: staticGlyphs ? ({}) : { 
            "FILL": truncatedFill,
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize,
        }
    }

    Behavior on fill { // Leaky leaky, no good
        NumberAnimation {
            duration: Appearance?.animation.elementMoveFast.duration ?? 200
            easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
            easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
}
