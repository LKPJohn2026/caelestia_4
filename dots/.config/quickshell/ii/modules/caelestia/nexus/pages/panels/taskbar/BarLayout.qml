pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: the bar's items (Caelestia's bar.entries), top to bottom: drag to reorder, switch, remove, add.
// Same editor as Status icons; Bar.qml draws the enabled entries in this order.
PageBase {
    id: root

    readonly property var builtinEntries: ({
            logo: Tr.tr("Logo"),
            workspaces: Tr.tr("Workspaces"),
            spacer: Tr.tr("Spacer"),
            activeWindow: Tr.tr("Active window"),
            tray: Tr.tr("Tray"),
            clock: Tr.tr("Clock"),
            statusIcons: Tr.tr("Status icons"),
            power: Tr.tr("Power button")
        })

    title: Tr.tr("Layout")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Bar items")
        }

        ListEditor {
            function labelFor(item: var): string {
                return root.builtinEntries[item.id] ?? item.id;
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: Config.bar.entries.values
            onItemMoved: (from, to) => GlobalConfig.bar.entries.move(from, to)
            onItemRemoved: index => GlobalConfig.bar.entries.remove(index)
            onItemToggled: (index, checked) => GlobalConfig.bar.entries.at(index).enabled = checked
        }

        DialogSelectButton {
            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Add item")
            header: Tr.tr("Add a bar item")
            acceptLabel: Tr.trCtx("Add", "button")

            // Spacers can repeat; the other items appear once
            model: Object.keys(root.builtinEntries).filter(k => k === "spacer" || !Config.bar.entries.values.some(e => e.id === k)).map(k => ({
                        id: k,
                        label: root.builtinEntries[k]
                    }))

            onAccepted: {
                if (selectedItem)
                    GlobalConfig.bar.entries.insert({
                        id: selectedItem,
                        enabled: true
                    });
            }
        }
    }
}
