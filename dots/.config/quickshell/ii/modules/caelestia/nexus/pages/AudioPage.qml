pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.services // caelestia4: keep (ScaledOption)

PageBase {
    id: root

    title: Tr.tr("Audio")

    // caelestia4: one menu item per sound theme in /usr/share/sounds: a folder with a stereo/ folder, which is what
    // Audio.playSystemSound plays from (other folders there, like alsa, are not themes)
    property list<MenuItem> themeItems: []

    function _setThemes(text: string): void {
        const names = text.split("\n").map(p => p.trim().split("/")[4] ?? "").filter(n => n.length > 0);
        const old = Array.from(root.themeItems); // a copy: the list property is live
        root.themeItems = [...new Set(names)].sort().map(n => root.menuItemComp.createObject(root, {
                text: n,
                value: n
            }));
        for (const o of old)
            o.destroy();
    }

    // As properties: PageBase's default property takes the page's one content item
    readonly property Process themeScan: Process {
        running: true
        command: ["find", "-L", "/usr/share/sounds", "-mindepth", "2", "-maxdepth", "2", "-type", "d", "-name", "stereo"]
        stdout: StdioCollector {
            onStreamFinished: root._setThemes(text)
        }
    }

    readonly property Component menuItemComp: Component {
        MenuItem {}
    }

    // caelestia4: with no device the volume and Muted rows have nothing to act on: only the empty state shows
    readonly property bool hasOutput: Audio.sinks.length > 0
    readonly property bool hasInput: Audio.sources.length > 0

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            visible: root.hasOutput
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: Tr.trCtx("Output", "audio output")
            valueLabel: Strings.percentOne(value)
            value: Audio.volume
            enabled: !Audio.muted
            wheelStep: GlobalConfig.services.audioIncrement
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            visible: root.hasOutput
            text: Tr.trCtx("Muted", "audio output muted")
            value: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            first: !root.hasOutput
            nodes: Audio.sinks
            currentId: Audio.sink?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: Tr.trCtx("No output devices", "no audio outputs")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Input
        SliderRow {
            visible: root.hasInput
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: Tr.trCtx("Input", "audio input")
            valueLabel: Strings.percentOne(value)
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            wheelStep: GlobalConfig.services.audioIncrement
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            visible: root.hasInput
            text: Tr.trCtx("Muted", "audio input muted")
            value: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            Layout.topMargin: root.hasInput ? 0 : Tokens.spacing.large - parent.spacing
            first: !root.hasInput
            nodes: Audio.sources
            currentId: Audio.source?.id ?? -1
            iconName: "mic"
            placeholderIcon: "mic_off"
            placeholderText: Tr.trCtx("No input devices", "no audio inputs")
            onSelected: node => Audio.setAudioSource(node)
        }

        // Per-app volumes
        NavRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true

            icon: "tune"
            text: Tr.tr("App volumes")
            subtext: Audio.streams.length === 0 ? Tr.tr("No apps playing audio") : Tr.trN("%n app playing audio", "%n apps playing audio", Audio.streams.length)
            onClicked: root.nState.openSubPage("apps")
        }

        // caelestia4: moved from Services (proposal 2.3). Stored as fractions (0.05), shown as percents: x: ids over
        // the c: options (ScaledOption)
        SectionHeader {
            text: Tr.tr("Volume")
        }

        StepperRow {
            id: volumeStep

            first: true
            setting: "x:services.audioIncrementPercent"
        }

        StepperRow {
            id: maxVolume

            last: true
            setting: "x:services.maxVolumePercent"
        }

        // Not items: they only feed the two rows above
        ScaledOption {
            link: volumeStep.link
            node: GlobalConfig.services
            key: "audioIncrement"
            factor: 100
        }

        ScaledOption {
            link: maxVolume.link
            node: GlobalConfig.services
            key: "maxVolume"
            factor: 100
        }

        // caelestia4: from end-4's Settings app (Sound)
        SectionHeader {
            text: Tr.tr("Hearing protection")
        }

        ToggleRow {
            first: true
            setting: "e4:audio.protection.enable"
        }

        StepperRow {
            setting: "e4:audio.protection.maxAllowedIncrease"
        }

        StepperRow {
            last: true
            setting: "e4:audio.protection.maxAllowed"
        }

        SectionHeader {
            text: Tr.tr("System sounds")
        }

        ToggleRow {
            first: true
            setting: "e4:sounds.battery"
        }

        ToggleRow {
            setting: "e4:sounds.pomodoro"
        }

        // caelestia4: the sound themes are the folders in /usr/share/sounds with a stereo/ folder
        // (Audio.playSystemSound plays <theme>/stereo/<name>.oga). With the other sounds, not in an Advanced section
        // of one row
        SelectRow {
            id: themeRow

            last: true
            setting: "e4:sounds.theme"
            menuItems: root.themeItems
            fallbackText: String(themeRow.link.value ?? "")
            menuOnTop: true
        }
    }
}
