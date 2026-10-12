// caelestia4: the dashboard's Timer tab in Caelestia style (replaces end-4's PomodoroWidget hosted in an E4Pane).
// Same logic as end-4: services/TimerService.qml (pomodoro + stopwatch, persisted, notifications on phase change).
// Keys as in end-4: Space / S start-pause, R reset, L lap, PgUp/PgDn switch Pomodoro / Stopwatch.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep

Item {
    id: root

    property bool stopwatch: false
    readonly property var timer: E4.TimerService

    // 10 ms units (stopwatch) -> "mm:ss.cc"
    function fmtCs(t: real): string {
        const cs = Math.floor(t);
        const s = Math.floor(cs / 100);
        return `${Math.floor(s / 60).toString().padStart(2, "0")}:${(s % 60).toString().padStart(2, "0")}.${(cs % 100).toString().padStart(2, "0")}`;
    }

    implicitWidth: 840 // same as the Weather tab, so the dashboard width stays steady
    implicitHeight: 480
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_S) {
            root.stopwatch ? timer.toggleStopwatch() : timer.togglePomodoro();
        } else if (event.key === Qt.Key_R) {
            root.stopwatch ? timer.stopwatchReset() : timer.resetPomodoro();
        } else if (event.key === Qt.Key_L) {
            timer.stopwatchRecordLap();
        } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
            root.stopwatch = event.key === Qt.Key_PageDown;
        } else {
            return;
        }
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Column {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: root.stopwatch ? Tr.tr("Stopwatch") : Tr.tr("Pomodoro")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.stopwatch ? Tr.tr("Space start / pause · L lap · R reset") : Tr.tr("%1 min focus · %2 min break · long break every %3").arg(Math.round(timer.focusTime / 60)).arg(Math.round(timer.breakTime / 60)).arg(timer.cyclesBeforeLongBreak)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            IconTextButton {
                type: IconTextButton.Tonal
                isToggle: true
                checked: !root.stopwatch
                icon: "hourglass_top"
                text: Tr.tr("Pomodoro")
                onClicked: root.stopwatch = false
            }

            IconTextButton {
                type: IconTextButton.Tonal
                isToggle: true
                checked: root.stopwatch
                icon: "timer"
                text: Tr.tr("Stopwatch")
                onClicked: root.stopwatch = true
            }
        }

        // ---- Pomodoro
        RowLayout {
            visible: !root.stopwatch
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                CircularProgress {
                    id: ring

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    strokeWidth: Tokens.padding.medium
                    value: timer.pomodoroLapDuration > 0 ? timer.pomodoroSecondsLeft / timer.pomodoroLapDuration : 0
                    fgColour: timer.pomodoroBreak ? Colours.palette.m3tertiary : Colours.palette.m3primary
                    bgColour: timer.pomodoroBreak ? Colours.palette.m3tertiaryContainer : Colours.palette.m3secondaryContainer
                    wavy: timer.pomodoroRunning
                }

                Column {
                    anchors.centerIn: ring
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `${Math.floor(timer.pomodoroSecondsLeft / 60).toString().padStart(2, "0")}:${Math.floor(timer.pomodoroSecondsLeft % 60).toString().padStart(2, "0")}`
                        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 2).weight(Font.Bold).build()
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: timer.pomodoroLongBreak ? Tr.tr("Long break") : timer.pomodoroBreak ? Tr.tr("Break") : Tr.tr("Focus")
                        font: Tokens.font.title.medium
                        color: timer.pomodoroBreak ? Colours.palette.m3tertiary : Colours.palette.m3primary
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: false // layouts fill by default; keep the controls 300 px so the ring gets the rest
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: cycleRow.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        id: cycleRow

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "repeat"
                            color: Colours.palette.m3secondary
                            fontStyle: Tokens.font.icon.large
                        }

                        Column {
                            Layout.fillWidth: true

                            StyledText {
                                text: Tr.tr("Cycle %1 of %2").arg(timer.pomodoroCycle + 1).arg(timer.cyclesBeforeLongBreak)
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            StyledText {
                                text: timer.pomodoroRunning ? Tr.tr("Running") : Tr.tr("Paused")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }

                IconTextButton {
                    Layout.fillWidth: true
                    icon: timer.pomodoroRunning ? "pause" : "play_arrow"
                    text: timer.pomodoroRunning ? Tr.tr("Pause") : timer.pomodoroSecondsLeft === timer.focusTime ? Tr.tr("Start") : Tr.tr("Resume")
                    padding: Tokens.padding.large
                    onClicked: timer.togglePomodoro()
                }

                IconTextButton {
                    Layout.fillWidth: true
                    type: IconTextButton.Tonal
                    icon: "restart_alt"
                    text: Tr.tr("Reset")
                    padding: Tokens.padding.large
                    disabled: !(timer.pomodoroSecondsLeft < timer.pomodoroLapDuration || timer.pomodoroCycle > 0 || timer.pomodoroBreak)
                    onClicked: timer.resetPomodoro()
                }
            }
        }

        // ---- Stopwatch: time + buttons centred on the left, laps pinned to the right
        Item {
            visible: root.stopwatch
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: laps.left
                anchors.rightMargin: Tokens.spacing.extraLarge
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Tokens.spacing.large

                Item {
                    Layout.fillHeight: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.fmtCs(timer.stopwatchTime)
                    font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 2.2).weight(Font.Bold).build()
                    color: timer.stopwatchRunning ? Colours.palette.m3primary : Colours.palette.m3onSurface
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        icon: timer.stopwatchRunning ? "pause" : "play_arrow"
                        text: timer.stopwatchRunning ? Tr.tr("Pause") : timer.stopwatchTime === 0 ? Tr.tr("Start") : Tr.tr("Resume")
                        padding: Tokens.padding.large
                        onClicked: timer.toggleStopwatch()
                    }

                    // While running: lap. Paused: reset (end-4's behaviour)
                    IconTextButton {
                        type: IconTextButton.Tonal
                        icon: timer.stopwatchRunning ? "flag" : "restart_alt"
                        text: timer.stopwatchRunning ? Tr.tr("Lap") : Tr.tr("Reset")
                        padding: Tokens.padding.large
                        disabled: !(timer.stopwatchTime > 0 || timer.stopwatchLaps.length > 0)
                        onClicked: timer.stopwatchRunning ? timer.stopwatchRecordLap() : timer.stopwatchReset()
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            StyledRect {
                id: laps

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 300
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                StyledListView {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.extraSmall
                    model: timer.stopwatchLaps.map((v, i, arr) => arr[arr.length - 1 - i]) // newest first

                    delegate: RowLayout {
                        id: lap

                        required property var modelData
                        required property int index
                        readonly property int number: root.timer.stopwatchLaps.length - index
                        readonly property real previous: number > 1 ? root.timer.stopwatchLaps[number - 2] : 0

                        width: ListView.view.width
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: `${lap.number}.`
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.preferredWidth: 32
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.fmtCs(lap.modelData)
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            text: `+${root.fmtCs(lap.modelData - lap.previous)}`
                            color: Colours.palette.m3primary
                            font: Tokens.font.body.small
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: root.timer.stopwatchLaps.length === 0
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "flag"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Tr.tr("Laps show up here")
                        color: Colours.palette.m3outline
                    }
                }
            }
        }
    }
}
