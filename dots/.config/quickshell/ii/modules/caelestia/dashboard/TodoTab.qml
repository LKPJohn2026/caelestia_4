// caelestia4: the dashboard's Todo tab in Caelestia style (replaces end-4's TodoWidget hosted in an E4Pane).
// Same data and actions as end-4: services/Todo.qml (tasks in ~/.local/state/quickshell/user/todo.json).
// Add a task in the field (Enter); N focuses it, PgUp/PgDn switch To do / Done.
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

    property bool showDone: false
    readonly property var tasks: E4.Todo.list.map((item, i) => Object.assign({}, item, {
            originalIndex: i
        }))
    readonly property var unfinished: tasks.filter(t => !t.done)
    readonly property var done: tasks.filter(t => t.done)
    readonly property var shown: showDone ? done : unfinished

    function addTask(): void {
        const text = input.text.trim();
        if (!text)
            return;
        E4.Todo.addTask(text);
        input.text = "";
        root.showDone = false;
    }

    implicitWidth: 840 // same as the Weather tab, so the dashboard width stays steady
    implicitHeight: 480
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_N && !input.activeFocus) {
            input.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
            root.showDone = event.key === Qt.Key_PageDown;
            event.accepted = true;
        }
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
                    text: Tr.tr("Tasks")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.unfinished.length === 0 ? Tr.tr("All done") : root.unfinished.length === 1 ? Tr.tr("1 task left") : Tr.tr("%1 tasks left").arg(root.unfinished.length)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            IconTextButton {
                type: IconTextButton.Tonal
                isToggle: true
                checked: !root.showDone
                icon: "checklist"
                text: Tr.tr("To do · %1").arg(root.unfinished.length)
                onClicked: root.showDone = false
            }

            IconTextButton {
                type: IconTextButton.Tonal
                isToggle: true
                checked: root.showDone
                icon: "task_alt"
                text: Tr.tr("Done · %1").arg(root.done.length)
                onClicked: root.showDone = true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: input

                Layout.fillWidth: true
                leadingIcon: "add_task"
                placeholderText: Tr.tr("Add a task")
                onAccepted: root.addTask()
                Keys.onEscapePressed: event => {
                    if (text) {
                        text = "";
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }

            IconButton {
                icon: "add"
                isRound: true
                disabled: !input.text.trim()
                onClicked: root.addTask()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            StyledListView {
                id: list

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall
                model: root.shown

                delegate: StyledRect {
                    id: task

                    required property var modelData

                    width: ListView.view.width
                    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: "transparent"

                    StateLayer {
                        radius: task.radius
                        onClicked: task.modelData.done ? E4.Todo.markUnfinished(task.modelData.originalIndex) : E4.Todo.markDone(task.modelData.originalIndex)
                    }

                    RowLayout {
                        id: row

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: task.modelData.done ? "check_circle" : "radio_button_unchecked"
                            fill: task.modelData.done ? 1 : 0
                            color: task.modelData.done ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: task.modelData.content
                            wrapMode: Text.Wrap
                            font.strikeout: task.modelData.done
                            color: task.modelData.done ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                        }

                        IconButton {
                            type: IconButton.Text
                            icon: "delete"
                            onClicked: E4.Todo.deleteItem(task.modelData.originalIndex)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: root.shown.length === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.showDone ? "checklist" : "task_alt"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.showDone ? Tr.tr("Finished tasks will show up here") : Tr.tr("Nothing to do. Add a task above")
                    color: Colours.palette.m3outline
                }
            }
        }
    }
}
