pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Caelestia's session menu (session.*): on/off, vim keys and the commands it runs. The commands run as
// given, without a shell (split on spaces). They are lists shown as one line: x: ids over session.commands.*
PageBase {
    id: root

    function split(text: string): list<string> {
        return text.trim().split(/\s+/).filter(s => s);
    }

    title: Tr.tr("Session menu")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:session.enabled"
        }

        ToggleRow {
            setting: "c:session.vimKeybinds"
        }

        StepperRow {
            setting: "c:session.dragThreshold"
        }

        // caelestia4: the GIF between the buttons (session/Content.qml)
        SectionHeader {
            text: Tr.tr("Look")
        }

        AssetPathRow {
            setting: "c:paths.sessionGif"
            hint: Tr.tr("None")
        }

        SliderRow {
            setting: "c:general.sessionGifSpeed"
        }

        SectionHeader {
            text: Tr.tr("Button icons")
        }

        // caelestia4: icons are picked from a grid (IconPickerRow), not typed as names

        IconPickerRow {
            setting: "c:session.icons.logout"
        }

        IconPickerRow {
            setting: "c:session.icons.hibernate"
        }

        IconPickerRow {
            setting: "c:session.icons.reboot"
        }

        IconPickerRow {
            setting: "c:session.icons.shutdown"
        }

        // caelestia4: the command each button runs (registry `advanced`). Reset page resets them through the row-less
        // c:session.commands.* entries
        AdvancedSection {
            SectionHeader {
                text: Tr.tr("Commands")
            }

            TextFieldRow {
                id: logoutRow

                setting: "x:session.commands.logout"
                field.emptyIsValid: false
            }

            TextFieldRow {
                id: hibernateRow

                setting: "x:session.commands.hibernate"
                field.emptyIsValid: false
            }

            TextFieldRow {
                id: rebootRow

                setting: "x:session.commands.reboot"
                field.emptyIsValid: false
            }

            TextFieldRow {
                id: shutdownRow

                setting: "x:session.commands.shutdown"
                field.emptyIsValid: false
            }
        }

        // Not items: they only feed the four rows above
        CommandOption {
            link: logoutRow.link
            key: "logout"
        }

        CommandOption {
            link: hibernateRow.link
            key: "hibernate"
        }

        CommandOption {
            link: rebootRow.link
            key: "reboot"
        }

        CommandOption {
            link: shutdownRow.link
            key: "shutdown"
        }
    }

    // A GlobalConfig.session.commands list behind an x: text row: shown joined with spaces, saved split on them. An
    // empty line is invalid (the entry's validate and emptyIsValid: false): the row shows the error and saves nothing
    component CommandOption: QtObject {
        id: opt

        required property RowSetting link
        required property string key

        readonly property Binding _value: Binding {
            target: opt.link.s
            property: "customValue"
            value: Array.from(root.Config.session.commands[opt.key] ?? []).join(" ")
        }

        readonly property Binding _default: Binding {
            target: opt.link.s
            property: "customDefault"
            value: Array.from(GlobalConfig.session.commands.descriptorFor(opt.key).defaultValue ?? []).join(" ")
        }

        readonly property Connections _writes: Connections {
            function onCustomSet(v: var): void {
                const parts = root.split(String(v ?? ""));
                if (parts.length)
                    GlobalConfig.session.commands[opt.key] = parts;
            }

            function onCustomReset(): void {
                GlobalConfig.session.commands.resetOption(opt.key);
            }

            target: opt.link.s
        }
    }
}
