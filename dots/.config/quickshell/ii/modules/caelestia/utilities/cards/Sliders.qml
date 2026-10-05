pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: end-4's quick sliders (sidebarRight/QuickSliders) in Caelestia style: brightness of this
// screen, output volume and microphone. The icon button mutes (volume/mic); scrolling over a row nudges it.
StyledRect {
    id: root

    required property ScreenState screenState

    readonly property var monitor: Brightness.getMonitorForScreen(screenState.modelData)

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        SliderRow {
            visible: root.monitor?.ready ?? false
            icon: "light_mode"
            tip: Tr.tr("Brightness")
            value: root.monitor?.brightness ?? 0
            onMoved: v => root.monitor?.setBrightness(v)
            onStep: up => up ? Brightness.increaseBrightness() : Brightness.decreaseBrightness()
        }

        SliderRow {
            icon: Audio.muted ? "volume_off" : "volume_up"
            tip: Audio.muted ? Tr.tr("Volume (muted) · click to unmute") : Tr.tr("Volume · click to mute")
            muted: Audio.muted
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onStep: up => up ? Audio.incrementVolume() : Audio.decrementVolume()
            onIconClicked: {
                const audio = Audio.sink?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
        }

        SliderRow {
            visible: Audio.source !== null // no input device -> no mic row
            icon: Audio.sourceMuted ? "mic_off" : "mic"
            tip: Audio.sourceMuted ? Tr.tr("Microphone (muted) · click to unmute") : Tr.tr("Microphone · click to mute")
            muted: Audio.sourceMuted
            value: Audio.sourceVolume
            onMoved: v => Audio.setSourceVolume(v)
            onStep: up => up ? Audio.incrementSourceVolume() : Audio.decrementSourceVolume()
            onIconClicked: {
                const audio = Audio.source?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
        }
    }

    component SliderRow: RowLayout {
        id: row

        required property string icon
        property string tip
        property bool muted
        property real value

        signal moved(v: real)
        signal step(up: bool)
        signal iconClicked

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        IconButton {
            type: IconButton.Text
            icon: row.icon
            inactiveOnColour: row.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            onClicked: row.iconClicked()
            ToolTip.visible: hovered
            ToolTip.delay: 500
            ToolTip.text: row.tip
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3

            onWheel: event => {
                if (event.angleDelta.y !== 0)
                    row.step(event.angleDelta.y > 0);
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight
                opacity: row.muted ? 0.5 : 1
                value: row.value
                onInteraction: v => row.moved(v)
            }
        }

        StyledText {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(row.value * 100)}%`
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
    }
}
