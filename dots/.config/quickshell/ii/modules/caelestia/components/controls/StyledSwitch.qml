import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

Switch {
    id: root

    property int cLayer: 1
    property bool disabled
    // caelestia4: the state this switch shows, usually a setting; bind this, not `checked`. A click sets `checked`
    // itself, which replaced a binding on it for good, so the switch stopped following the setting (changed elsewhere,
    // or the file reloading). After a click, `checked` follows `value` again once the handlers have written it
    // (async ones, like Hyprland options, take a moment: up to 2 s; then it shows what `value` really is)
    property var value
    property bool awaitingValue

    enabled: !disabled
    checked: !!value

    onToggled: {
        if (value === undefined)
            return;
        awaitingValue = true;
        Qt.callLater(() => {
            if (!!value === checked)
                rebind();
        });
        rebindTimer.restart();
    }
    onValueChanged: {
        if (awaitingValue)
            rebind();
    }

    function rebind(): void {
        awaitingValue = false;
        rebindTimer.stop();
        checked = Qt.binding(() => !!value);
    }

    Timer {
        id: rebindTimer

        interval: 2000
        onTriggered: root.rebind()
    }

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: StyledRect {
        radius: Tokens.rounding.full
        color: {
            if (root.disabled)
                return root.checked ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.38);
            return root.checked ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer);
        }

        implicitWidth: implicitHeight * 1.7
        implicitHeight: Tokens.font.body.medium.pointSize + Tokens.padding.small * 2

        StyledRect {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.2 : implicitHeight

            radius: Tokens.rounding.full
            color: {
                if (root.disabled)
                    return root.checked ? Colours.palette.m3surface : Qt.alpha(Colours.palette.m3onSurface, 0.12);
                return root.checked ? Colours.palette.m3onPrimary : Colours.layer(Colours.palette.m3outline, root.cLayer + 1);
            }

            x: root.checked ? parent.implicitWidth - nonAnimWidth - Tokens.padding.extraSmall / 2 : Tokens.padding.extraSmall / 2
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - Tokens.padding.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                anchors.fill: parent
                radius: parent.radius

                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: root.pressed ? 0.1 : root.hovered ? 0.08 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.15, height * 0.15);
                }
                property point end1: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.8, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.85, height * 0.85);
                }
                property point start2: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.2, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.15, height * 0.85);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.2);
                    return Qt.point(width * 0.85, height * 0.15);
                }

                anchors.centerIn: parent
                width: height
                height: parent.implicitHeight - Tokens.padding.medium
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    strokeWidth: root.Tokens.font.body.large.pointSize * 0.15
                    strokeColor: {
                        if (root.disabled)
                            return root.checked ? Colours.palette.m3outline : Colours.palette.m3surfaceContainer;
                        return root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest;
                    }
                    fillColor: "transparent"
                    capStyle: root.Tokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

                    startX: icon.start1.x
                    startY: icon.start1.y

                    PathLine {
                        x: icon.end1.x
                        y: icon.end1.y
                    }
                    PathMove {
                        x: icon.start2.x
                        y: icon.start2.y
                    }
                    PathLine {
                        x: icon.end2.x
                        y: icon.end2.y
                    }

                    Behavior on strokeColor {
                        CAnim {}
                    }
                }

                Behavior on start1 {
                    PropAnim {}
                }
                Behavior on end1 {
                    PropAnim {}
                }
                Behavior on start2 {
                    PropAnim {}
                }
                Behavior on end2 {
                    PropAnim {}
                }
            }

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    component PropAnim: PropertyAnimation {
        duration: Tokens.anim.durations.expressiveFastSpatial
        easing: Tokens.anim.expressiveFastSpatial
    }
}
