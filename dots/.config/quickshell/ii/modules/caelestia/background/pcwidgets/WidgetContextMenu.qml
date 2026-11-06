import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

/*
 * caelestia4: a desktop widget's right-click menu (AbstractBackgroundWidget.openContextMenu): lock / unlock the widgets,
 * take this one off the desktop. A popup in the background window itself, not a window of its own: it closes on a
 * click anywhere on the desktop or on Esc, and when a window is clicked (the background window loses the keyboard,
 * which it takes while the menu is open, the way a click on a widget does)
 */
Menu {
    id: root

    required property Item widget

    padding: 6
    topPadding: 6
    bottomPadding: 6
    margins: 8 // kept inside the screen, off its edges
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    transformOrigin: Item.TopLeft

    // made when asked for and gone when closed (AbstractBackgroundWidget)
    onClosed: root.destroy()

    Connections {
        target: GlobalStates

        function onDesktopWidgetKeyboardFocusChanged(): void {
            if (!GlobalStates.desktopWidgetKeyboardFocus)
                root.close();
        }

        // (a lock screen over it)
        function onScreenLockedChanged(): void {
            if (GlobalStates.screenLocked)
                root.close();
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "scale"
                from: 0.6
                to: 1
                duration: 500
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animationCurves.expressiveEffectsDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "scale"
                to: 0.85
                duration: 160
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 140
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
        }
    }

    background: Rectangle {
        implicitWidth: 210
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        StyledRectangularShadow {
            target: parent
            z: -1
        }
    }

    component Entry: MenuItem {
        id: entry

        property string iconName: ""
        property color colContent: Appearance.m3colors.m3onSurface

        implicitHeight: 40
        leftPadding: 12
        rightPadding: 12

        background: Rectangle {
            radius: Appearance.rounding.small
            color: entry.down ? ColorUtils.mix(Appearance.m3colors.m3surfaceContainer, entry.colContent, 0.8)
                : entry.highlighted || entry.hovered ? ColorUtils.mix(Appearance.m3colors.m3surfaceContainer, entry.colContent, 0.9)
                : "transparent"

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        contentItem: RowLayout {
            spacing: 12
            opacity: entry.enabled ? 1 : 0.38

            MaterialSymbol {
                text: entry.iconName
                iconSize: 20
                color: entry.colContent
            }
            StyledText {
                Layout.fillWidth: true
                text: entry.text
                font.pixelSize: Appearance.font.pixelSize.small
                color: entry.colContent
                elide: Text.ElideRight
            }
        }
    }

    Entry {
        text: Config.options.background.widgetsLocked ? Translation.tr("Unlock widgets") : Translation.tr("Lock widgets")
        iconName: Config.options.background.widgetsLocked ? "lock_open" : "lock"
        onTriggered: root.widget.toggleWidgetsLocked(Translation.tr("Right-click a widget for its menu"))
    }

    MenuSeparator {
        topPadding: 4
        bottomPadding: 4
        contentItem: Rectangle {
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }
    }

    Entry {
        text: Translation.tr("Remove from desktop")
        iconName: "visibility_off"
        colContent: Appearance.m3colors.m3error
        // after the menu has gone: the widget (its parent) fades out and is destroyed with it
        onTriggered: {
            const widget = root.widget;
            Qt.callLater(() => widget.requestDelete());
        }
    }
}
