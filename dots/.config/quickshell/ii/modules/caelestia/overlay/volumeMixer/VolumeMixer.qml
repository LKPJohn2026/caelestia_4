// caelestia4: the overlay's volume mixer in Caelestia style (replaces end-4's sidebar VolumeDialogContent).
// Output / Input: pick the device, set its volume, and each app's own volume (scroll on a slider works too).
// Built on Caelestia's Audio adapter and the shared StreamIcon (same icons as the bar's audio popout).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: end-4 Persistent (selected tab)
import qs.modules.caelestia.overlay
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.widgets
import qs.modules.caelestia.adapters

StyledOverlayWidget {
    id: root

    readonly property bool output: E4C.Persistent.states.overlay.volumeMixer.tabIndex === 0
    readonly property list<PwNode> devices: output ? Audio.sinks : Audio.sources
    readonly property PwNode device: output ? Audio.sink : Audio.source
    // Playback streams on Output, recording streams on Input
    readonly property list<PwNode> appStreams: Audio.streams.filter(s => s.isSink === root.output)

    minimumWidth: 320
    minimumHeight: 380

    PwObjectTracker {
        objects: [...root.appStreams, ...(root.device ? [root.device] : [])]
    }

    contentItem: OverlayBackground {
        radius: root.contentRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    type: IconTextButton.Tonal
                    isToggle: true
                    checked: root.output
                    icon: "media_output"
                    text: Tr.tr("Output")
                    onClicked: E4C.Persistent.states.overlay.volumeMixer.tabIndex = 0
                }

                IconTextButton {
                    Layout.fillWidth: true
                    type: IconTextButton.Tonal
                    isToggle: true
                    checked: !root.output
                    icon: "mic"
                    text: Tr.tr("Input")
                    onClicked: E4C.Persistent.states.overlay.volumeMixer.tabIndex = 1
                }
            }

            StyledFlickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: column.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    id: column

                    width: parent.width
                    spacing: Tokens.spacing.small

                    ButtonGroup {
                        id: deviceGroup
                    }

                    Repeater {
                        model: root.devices

                        StyledRadioButton {
                            required property PwNode modelData

                            Layout.fillWidth: true
                            ButtonGroup.group: deviceGroup
                            checked: root.device?.id === modelData.id
                            text: modelData.description
                            onClicked: root.output ? Audio.setAudioSink(modelData) : Audio.setAudioSource(modelData)
                        }
                    }

                    // Device volume
                    Row_ {
                        Layout.topMargin: Tokens.spacing.small
                        icon: root.output ? (Audio.muted ? "volume_off" : "volume_up") : (Audio.sourceMuted ? "mic_off" : "mic")
                        title: root.output ? Tr.tr("Device volume") : Tr.tr("Microphone")
                        muted: root.output ? Audio.muted : Audio.sourceMuted
                        value: root.output ? Audio.volume : Audio.sourceVolume
                        onToggleMute: {
                            if (root.device?.audio)
                                root.device.audio.muted = !root.device.audio.muted;
                        }
                        onMoved: v => root.output ? Audio.setVolume(v) : Audio.setSourceVolume(v)
                    }

                    StyledText {
                        Layout.topMargin: Tokens.spacing.medium
                        visible: root.appStreams.length > 0
                        text: Tr.tr("Apps")
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                    }

                    Repeater {
                        model: root.appStreams

                        RowLayout {
                            id: stream

                            required property PwNode modelData
                            readonly property bool muted: Audio.getStreamMuted(modelData)

                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StreamIcon {
                                stream: stream.modelData
                                muted: stream.muted
                                onClicked: Audio.setStreamMuted(stream.modelData, !stream.muted)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        const app = Audio.getStreamName(stream.modelData);
                                        const media = stream.modelData.properties["media.name"];
                                        return media && media !== app ? `${app} · ${media}` : app;
                                    }
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                }

                                Slider_ {
                                    Layout.fillWidth: true
                                    muted: stream.muted
                                    value: Audio.getStreamVolume(stream.modelData)
                                    onMoved: v => Audio.setStreamVolume(stream.modelData, v)
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.topMargin: Tokens.spacing.medium
                        visible: root.appStreams.length === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: root.output ? Tr.tr("No apps are playing sound") : Tr.tr("No apps are recording")
                        color: Colours.palette.m3outline
                    }
                }
            }
        }
    }

    // A labelled volume row with a mute toggle
    component Row_: RowLayout {
        id: row

        property string icon
        property string title
        property bool muted
        property real value

        signal toggleMute
        signal moved(real value)

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        IconButton {
            type: IconButton.Tonal
            isRound: true
            isToggle: true
            checked: row.muted
            icon: row.icon
            onClicked: row.toggleMute()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: row.muted ? Tr.tr("%1 (muted)").arg(row.title) : `${row.title} · ${Math.round(row.value * 100)}%`
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Slider_ {
                Layout.fillWidth: true
                muted: row.muted
                value: row.value
                onMoved: v => row.moved(v)
            }
        }
    }

    // Caelestia slider that also follows the mouse wheel (5 % steps)
    component Slider_: CustomMouseArea {
        id: wheelArea

        property bool muted
        property real value

        signal moved(real value)

        implicitHeight: Tokens.padding.medium * 2.5
        onWheel: event => wheelArea.moved(Math.max(0, Math.min(1, wheelArea.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))

        StyledSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: parent.implicitHeight
            opacity: wheelArea.muted ? 0.5 : 1
            value: wheelArea.value
            onInteraction: v => wheelArea.moved(v)
        }
    }
}
