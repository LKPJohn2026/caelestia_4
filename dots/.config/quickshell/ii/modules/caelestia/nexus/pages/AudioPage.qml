pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    title: Tr.tr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: Tr.trCtx("Output", "audio output")
            valueLabel: Strings.percentOne(value)
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio output muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks
            currentId: Audio.sink?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: Tr.trCtx("No output devices", "no audio outputs")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Input
        SliderRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: Tr.trCtx("Input", "audio input")
            valueLabel: Strings.percentOne(value)
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio input muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
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
            onClicked: root.nState.openSubPage(1)
        }

        // caelestia4: from end-4's Settings app (Sound)
        SectionHeader {
            text: Tr.tr("Hearing protection")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Block sudden loud jumps")
            subtext: Tr.tr("Undo volume changes that are too big or go over the limit, whoever makes them")
            checked: E4C.Config.options.audio.protection.enable
            onToggled: E4C.Config.options.audio.protection.enable = checked
        }

        StepperRow {
            enabled: E4C.Config.options.audio.protection.enable
            label: Tr.tr("Largest allowed jump (%)")
            value: E4C.Config.options.audio.protection.maxAllowedIncrease
            from: 1
            to: 100
            onMoved: v => E4C.Config.options.audio.protection.maxAllowedIncrease = v
        }

        StepperRow {
            last: true
            enabled: E4C.Config.options.audio.protection.enable
            label: Tr.tr("Volume limit (%)")
            value: E4C.Config.options.audio.protection.maxAllowed
            from: 10
            to: 150
            onMoved: v => E4C.Config.options.audio.protection.maxAllowed = v
        }

        SectionHeader {
            text: Tr.tr("System sounds")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Battery warnings")
            checked: E4C.Config.options.sounds.battery
            onToggled: E4C.Config.options.sounds.battery = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Timer and Pomodoro")
            checked: E4C.Config.options.sounds.pomodoro
            onToggled: E4C.Config.options.sounds.pomodoro = checked
        }
    }
}
