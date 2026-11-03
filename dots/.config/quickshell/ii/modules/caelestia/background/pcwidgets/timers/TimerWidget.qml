import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.caelestia.background.pcwidgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "timers"
    hoverEnabled: true

    property real widgetWidth: 420
    property real cardSpacing: 12
    property real cardHeight: 120
    property real cardWidth: (widgetWidth - cardSpacing * 2) / 3
    property bool isVertical: root.configEntry.vertical ?? false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    component TimerCard: WidgetCard {
        id: timerCard
        property string icon: ""
        property string value: ""
        property string label: ""
        property bool running: false
        property int shape: MaterialShape.Shape.Cookie12Sided
        property color bgColor: Appearance.colors.colPrimaryContainer
        property color shapeColor: Appearance.colors.colPrimary
        // caelestia4: each card's own "on" colours, as the resources widget's cards (a tertiary container can be light
        // where the primary one is dark)
        property color symbolColor: Appearance.colors.colOnPrimary
        property color textColor: Appearance.colors.colOnPrimaryContainer
        property var onToggle: () => {}
        property var onReset: () => {}
        default property alias extraContent: extraSlot.data

        implicitWidth: root.cardWidth
        implicitHeight: root.cardHeight
        widget: root
        color: timerCard.bgColor

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: timerCard.onReset()
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: -4

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Item { Layout.fillWidth: true }

                MaterialShapeWrappedMaterialSymbol {
                    shape: timerCard.shape
                    color: timerCard.shapeColor
                    colSymbol: timerCard.symbolColor
                    text: timerCard.running ? "pause" : timerCard.icon
                    iconSize: 18
                    fill: 1
                    padding: 6
                    implicitWidth: 34
                    implicitHeight: 34

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: timerCard.onToggle()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            ColumnLayout {
                Layout.leftMargin: 2
                Layout.topMargin: -40
                spacing: -4
                StyledText {
                    text: timerCard.value
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    color: timerCard.textColor
                }

                StyledText {
                    text: timerCard.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: timerCard.textColor
                    opacity: 0.6
                }
            }

            Item {
                id: extraSlot
                Layout.fillWidth: true
                Layout.preferredHeight: children.length > 0 ? 22 : 0
                Layout.topMargin: children.length > 0 ? 6 : 0
            }
        }
    }

    Grid {
        id: row
        columns: root.isVertical ? 1 : 3
        rows: root.isVertical ? 3 : 1
        spacing: root.cardSpacing

        Behavior on columns {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        // Pomodoro
        TimerCard {
            icon: TimerService.pomodoroBreak ? "coffee" : "visibility"
            value: TimerService.formatSeconds(TimerService.pomodoroSecondsLeft)
            label: TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
            running: TimerService.pomodoroRunning
            bgColor: Appearance.colors.colTertiaryContainer
            shapeColor: Appearance.colors.colTertiary
            symbolColor: Appearance.colors.colOnTertiary
            textColor: Appearance.colors.colOnTertiaryContainer
            shape: MaterialShape.Shape.Flower
            onToggle: () => TimerService.togglePomodoro()
            onReset: () => TimerService.resetPomodoro()
        }

        // Stopwatch
        TimerCard {
            icon: "timer"
            value: TimerService.formatSeconds(TimerService.stopwatchTime / 100)
            label: Translation.tr("Stopwatch")
            running: TimerService.stopwatchRunning
            shape: MaterialShape.Shape.Sunny
            bgColor: Appearance.colors.colSecondaryContainer
            shapeColor: Appearance.colors.colSecondary
            symbolColor: Appearance.colors.colOnSecondary
            textColor: Appearance.colors.colOnSecondaryContainer
            onToggle: () => TimerService.toggleStopwatch()
            onReset: () => TimerService.stopwatchReset()
        }

        // Countdown
        TimerCard {
            icon: "hourglass_top"
            value: TimerService.formatSeconds(TimerService.countdownSecondsLeft)
            label: Translation.tr("Countdown")
            running: TimerService.countdownRunning
            shape: MaterialShape.Shape.Bun
            onToggle: () => TimerService.toggleCountdown()
            onReset: () => TimerService.resetCountdown()

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: [1, 5]
                    delegate: Rectangle {
                        required property int modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.rounding.full
                        color: ColorUtils.transparentize(Appearance.colors.colOnTertiaryContainer, 0.85)

                        StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("+%1m").arg(modelData)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TimerService.addCountdownMinutes(modelData)
                        }
                    }
                }
            }
        }
    }

    WidgetFlipHandle {
        anchorItem: root
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        onClicked: {
            root.isVertical = !root.isVertical
            root.configEntry.vertical = root.isVertical
            PresetLayout.requestSave()
        }
    }
}
