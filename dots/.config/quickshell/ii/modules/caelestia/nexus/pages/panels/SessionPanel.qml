pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Caelestia's session menu (session.*): on/off, vim keys and the commands it runs. The commands run as
// given, without a shell (split on spaces).
PageBase {
    id: root

    function split(text: string): list<string> {
        return text.trim().split(/\s+/).filter(s => s);
    }

    title: Tr.tr("Session menu")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Session menu")
            subtext: Tr.tr("Lock, sleep, log out, restart and shut down from the screen edge")
            value: Config.session.enabled
            onToggled: GlobalConfig.session.enabled = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Vim keys (h j k l)")
            value: Config.session.vimKeybinds
            onToggled: GlobalConfig.session.vimKeybinds = checked
        }

        SectionHeader {
            text: Tr.tr("Commands")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Log out")
            value: Config.session.commands.logout.join(" ")
            onEditingFinished: v => {
                if (root.split(v).length)
                    GlobalConfig.session.commands.logout = root.split(v);
            }
        }

        TextFieldRow {
            label: Tr.tr("Hibernate")
            value: Config.session.commands.hibernate.join(" ")
            onEditingFinished: v => {
                if (root.split(v).length)
                    GlobalConfig.session.commands.hibernate = root.split(v);
            }
        }

        TextFieldRow {
            label: Tr.tr("Restart")
            value: Config.session.commands.reboot.join(" ")
            onEditingFinished: v => {
                if (root.split(v).length)
                    GlobalConfig.session.commands.reboot = root.split(v);
            }
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Shut down")
            value: Config.session.commands.shutdown.join(" ")
            onEditingFinished: v => {
                if (root.split(v).length)
                    GlobalConfig.session.commands.shutdown = root.split(v);
            }
        }
    }
}
