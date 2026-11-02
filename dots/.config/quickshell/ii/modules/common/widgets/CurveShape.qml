import QtQuick
import QtQuick.Shapes
import "shapes/shapes/morph.js" as Morph

// caelestia4: shapes/ShapeCanvas.qml (end-4/rounded-polygon-qmljs, a submodule, left as it is) drawn as curves
// (QtQuick.Shapes' CurveRenderer) rather than on a Canvas: a Canvas is a texture at the window's scale, which a desktop
// widget's Scale transform stretches soft; curves are drawn at the size they end up, sharp at any scale (and a morph
// is a new path, not a repaint). An Item holding the Shape: a Shape sizes itself to its path, which here follows the
// size (a binding loop, the shape gone in a layout)
Item {
    id: root
    property color color: "#685496"
    property var roundedPolygon: null
    property bool polygonIsNormalized: true
    property real borderWidth: 0
    property color borderColor: color
    property bool debug: false // the Canvas version's anchor dots; nothing here
    property real xOffset: 0
    property real yOffset: 0

    // Internals: size
    property var bounds: roundedPolygon.calculateBounds()
    implicitWidth: bounds[2] - bounds[0]
    implicitHeight: bounds[3] - bounds[1]

    // Internals: anim
    property var prevRoundedPolygon: null
    property double progress: 1
    property var morph: new Morph.Morph(roundedPolygon, roundedPolygon)
    property Animation animation: NumberAnimation {
        duration: 350
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1] // Material 3 Expressive fast spatial (https://m3.material.io/styles/motion/overview/specs)
    }

    onRoundedPolygonChanged: {
        delete root.morph;
        root.morph = new Morph.Morph(root.prevRoundedPolygon ?? root.roundedPolygon, root.roundedPolygon);
        morphBehavior.enabled = false;
        root.progress = 0;
        morphBehavior.enabled = true;
        root.progress = 1;
        root.prevRoundedPolygon = root.roundedPolygon;
    }

    Behavior on progress {
        id: morphBehavior
        animation: root.animation
    }

    // The outline at this progress as SVG path data, in the item's pixels (the Canvas version scaled its context by
    // the smaller side and moved it by the offsets)
    readonly property string pathData: {
        if (!root.morph)
            return "";
        const cubics = root.morph.asCubics(root.progress);
        if (cubics.length === 0)
            return "";
        const k = root.polygonIsNormalized ? Math.min(root.width, root.height) : 1;
        const px = x => ((x + root.xOffset) * k).toFixed(3);
        const py = y => ((y + root.yOffset) * k).toFixed(3);
        const d = [`M${px(cubics[0].anchor0X)} ${py(cubics[0].anchor0Y)}`];
        for (const c of cubics)
            d.push(`C${px(c.control0X)} ${py(c.control0Y)} ${px(c.control1X)} ${py(c.control1Y)} ${px(c.anchor1X)} ${py(c.anchor1Y)}`);
        d.push("Z");
        return d.join("");
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            fillRule: ShapePath.WindingFill // a Canvas fills non-zero
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth > 0 ? root.borderWidth : -1

            PathSvg {
                path: root.pathData
            }
        }
    }
}
