pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.services as E4 // caelestia4: keep

Item {
    id: root

    required property PopoutState popouts

    // caelestia4: per-app mixer (end-4 volumeMixer) — playback streams only
    readonly property list<PwNode> appStreams: Audio.streams.filter(s => s.isSink)

    PwObjectTracker {
        objects: root.appStreams
    }

    implicitWidth: Tokens.sizes.bar.audioWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.trCtx("Output device", "audio output device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sinks

            StyledRadioButton {
                id: control

                required property PwNode modelData

                Layout.fillWidth: true
                ButtonGroup.group: sinks
                checked: Audio.sink?.id === modelData.id
                onClicked: Audio.setAudioSink(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: Tr.trCtx("Input device", "audio input device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sources

            StyledRadioButton {
                required property PwNode modelData

                Layout.fillWidth: true
                ButtonGroup.group: sources
                checked: Audio.source?.id === modelData.id
                onClicked: Audio.setAudioSource(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: Audio.muted ? Tr.tr("Volume (muted)") : Tr.tr("Volume (%1%)").arg(Math.round(Audio.volume * 100))
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: Audio.volume
                onInteraction: value => Audio.setVolume(value)
            }
        }

        // caelestia4: microphone level (end-4 quick sliders), only with an input device
        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            visible: Audio.source !== null
            text: Audio.sourceMuted ? Tr.tr("Microphone (muted)") : Tr.tr("Microphone (%1%)").arg(Math.round(Audio.sourceVolume * 100))
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3
            visible: Audio.source !== null

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementSourceVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementSourceVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: Audio.sourceVolume
                onInteraction: value => Audio.setSourceVolume(value)
            }
        }

        // caelestia4: per-app volume mixer (end-4 volumeMixer)
        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            visible: root.appStreams.length > 0
            text: Tr.tr("Apps")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: root.appStreams

            RowLayout {
                id: streamRow

                required property PwNode modelData
                readonly property bool muted: Audio.getStreamMuted(modelData)

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StreamIcon {
                    stream: streamRow.modelData
                    muted: streamRow.muted
                    onClicked: Audio.setStreamMuted(streamRow.modelData, !streamRow.muted)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const app = Audio.getStreamName(streamRow.modelData);
                            const media = streamRow.modelData.properties["media.name"];
                            return media && media !== app ? `${app} · ${media}` : app;
                        }
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }

                    CustomMouseArea {
                        Layout.fillWidth: true
                        implicitHeight: Tokens.padding.medium * 2.5

                        onWheel: event => {
                            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
                            Audio.setStreamVolume(streamRow.modelData, Audio.getStreamVolume(streamRow.modelData) + step);
                        }

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: parent.implicitHeight
                            opacity: streamRow.muted ? 0.5 : 1

                            value: Audio.getStreamVolume(streamRow.modelData)
                            onInteraction: value => Audio.setStreamVolume(streamRow.modelData, value)
                        }
                    }
                }
            }
        }

        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: Tr.tr("Open settings")
            icon: "settings"

            onClicked: root.popouts.detachRequested("audio")
        }
    }

    // caelestia4: app icon for a playback stream; click mutes/unmutes it. Icon resolution, best first:
    //  1. the stream's application.icon-name, if the icon theme has it
    //  2. the icon of the window that owns the stream: walk the stream's process parents up to a pid that
    //     has a Hyprland window, and resolve that window class like the dock does (end-4 AppSearch). This
    //     handles Chromium/Electron apps, whose audio comes from a child process and whose icon-name is
    //     generic (Brave Origin reports "brave-browser", which isn't installed)
    //  3. a desktop entry matching the binary / application name
    //  4. a music-note symbol (never a broken image)
    component StreamIcon: Item {
        id: appIcon

        required property PwNode stream
        property bool muted
        property list<int> ancestors: []

        readonly property var props: stream?.properties ?? ({})
        readonly property string iconSource: {
            const named = props["application.icon-name"] ?? "";
            if (named && Quickshell.iconPath(named, true) !== "")
                return Quickshell.iconPath(named);

            // Nearest ancestor with a window; among windows of the same process prefer the plain app over web-app
            // shortcuts (shortest class, e.g. "brave-origin" over "brave-<app id>-Default")
            for (const pid of ancestors) {
                const windows = E4.HyprlandData.windowList.filter(w => w.pid === pid);
                if (windows.length === 0)
                    continue;
                windows.sort((a, b) => a.class.length - b.class.length);
                const icon = E4.AppSearch.guessIcon(windows[0].class);
                if (icon && Quickshell.iconPath(icon, true) !== "")
                    return Quickshell.iconPath(icon);
            }

            for (const name of [props["application.process.binary"], props["application.name"]]) {
                const icon = name ? DesktopEntries.heuristicLookup(name)?.icon : "";
                if (icon && Quickshell.iconPath(icon, true) !== "")
                    return Quickshell.iconPath(icon);
            }
            return "";
        }

        signal clicked

        implicitWidth: Tokens.padding.medium * 4
        implicitHeight: implicitWidth

        Process {
            running: (appIcon.props["application.process.id"] ?? "") !== ""
            command: ["sh", "-c", "p=\"$1\"; while [ \"$p\" -gt 1 ] 2>/dev/null; do echo \"$p\"; p=$(sed 's/.*) //' /proc/$p/stat 2>/dev/null | cut -d' ' -f2) || break; done", "sh", String(appIcon.props["application.process.id"] ?? "")]
            stdout: StdioCollector {
                onStreamFinished: appIcon.ancestors = text.split("\n").filter(l => l.length > 0).map(l => parseInt(l))
            }
        }

        IconImage {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            visible: appIcon.iconSource !== ""
            asynchronous: true
            source: appIcon.iconSource
            opacity: appIcon.muted ? 0.35 : 1
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: appIcon.iconSource === "" || appIcon.muted
            text: appIcon.muted ? "volume_off" : "music_note"
            color: appIcon.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        }

        StateLayer {
            radius: Tokens.rounding.full
            onClicked: appIcon.clicked()
        }
    }
}
