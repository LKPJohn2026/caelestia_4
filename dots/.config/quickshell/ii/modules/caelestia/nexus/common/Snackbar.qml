import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: Nexus's in-window message (Undo, "Saved", write errors). One at a time: a new message replaces the shown
// one. Hides itself after `timeout` ms; hovering it keeps it up. Nexus.qml hosts it and feeds it NexusActions.message
StyledRect {
    id: root

    property int timeout: 5000
    property string text
    property string actionLabel
    property var actionFn: null
    readonly property bool shown: state === "shown"

    // Shows `text`, with a button `actionLabel` that calls `actionFn` (both optional)
    function show(text: string, actionLabel: string, actionFn: var): void {
        root.text = text;
        root.actionLabel = actionLabel ?? "";
        root.actionFn = typeof actionFn === "function" ? actionFn : null;
        state = "shown";
        hideTimer.restart();
    }

    function hide(): void {
        state = "";
        hideTimer.stop();
    }

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: Math.max(layout.implicitHeight + Tokens.padding.small * 2, Tokens.padding.large * 4)
    radius: Tokens.rounding.small
    color: Colours.palette.m3inverseSurface

    opacity: 0
    scale: 0.9
    visible: opacity > 0

    Accessible.role: Accessible.AlertMessage
    Accessible.name: text

    states: State {
        name: "shown"

        PropertyChanges {
            root.opacity: 1
            root.scale: 1
        }
    }

    transitions: Transition {
        Anim {
            properties: "opacity,scale"
            type: Anim.DefaultEffects
        }
    }

    Timer {
        id: hideTimer

        interval: root.timeout
        onTriggered: {
            if (hover.hovered)
                restart();
            else
                root.hide();
        }
    }

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.small
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: root.parent ? root.parent.width * 0.7 : implicitWidth
            Layout.topMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.padding.small
            text: root.text
            color: Colours.palette.m3inverseOnSurface
            font: Tokens.font.body.medium
            wrapMode: Text.WordWrap
        }

        TextButton {
            visible: root.actionLabel.length > 0
            text: root.actionLabel
            type: TextButton.Text
            inactiveOnColour: Colours.palette.m3inversePrimary
            onClicked: {
                const fn = root.actionFn;
                root.hide();
                if (fn)
                    fn();
            }
        }

        IconButton {
            icon: "close"
            type: IconButton.Text
            inactiveOnColour: Colours.palette.m3inverseOnSurface
            Accessible.name: Tr.tr("Dismiss")
            onClicked: root.hide()
        }
    }
}
