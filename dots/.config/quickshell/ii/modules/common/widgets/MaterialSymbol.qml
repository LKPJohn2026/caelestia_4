import qs.modules.common
import qs.modules.common.functions
import QtQuick

StyledText {
    id: root
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    property real fill: 0
    property real truncatedFill: fill.toFixed(1) // Reduce memory consumption spikes from constant font remapping
    // caelestia4: native glyphs are drawn once at the window's scale, so a desktop widget's Scale stretches them soft;
    // curves are drawn at whatever size they end up. A filled glyph of the variable font keeps overlapping outlines,
    // which the GPU's curve renderer draws as holes (slivers through a play button, a dotted ring in a cloud): a filled
    // one takes Material Symbols Rounded Filled, the same glyphs with the overlaps merged. Half filled (mid-animation)
    // or without that font it's a native glyph, whole but soft
    readonly property bool scaled: WidgetScale.transformed(root)
    readonly property bool staticFilled: scaled && truncatedFill === 1 && (Appearance?.font.family.iconMaterialFilled ?? "") !== ""
    renderType: scaled && (truncatedFill === 0 || staticFilled) ? Text.CurveRendering : Text.NativeRendering
    font {
        hintingPreference: Font.PreferNoHinting
        family: staticFilled ? Appearance.font.family.iconMaterialFilled : (Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded")
        pixelSize: iconSize
        weight: staticFilled ? Font.Normal : Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
        variableAxes: staticFilled ? ({}) : { 
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
