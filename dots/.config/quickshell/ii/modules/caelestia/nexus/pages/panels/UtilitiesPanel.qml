pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    // caelestia4: the quick toggle buttons are items of the utilities.quickToggles list: each row is an x: id
    // ("x:utilities.quickToggles.wifi") over its item's `enabled`. The rows need the Quick toggles card (registry
    // `requires`)
    readonly property list<string> quickToggleIds: ["wifi", "bluetooth", "mic", "settings", "gameMode", "dnd", "vpn"]
    readonly property var quickToggleDefaults: GlobalConfig.utilities.descriptorFor("quickToggles").defaultValue ?? []

    function isToggleOn(id: string): bool {
        const item = Config.utilities.quickToggles.values.find(t => t.id === id);
        return item?.enabled ?? false;
    }

    function isToggleOnByDefault(id: string): bool {
        return Array.from(root.quickToggleDefaults).find(t => t.id === id)?.enabled ?? false;
    }

    function setToggleOn(id: string, on: bool): void {
        const list = GlobalConfig.utilities.quickToggles;
        for (let i = 0; i < list.count; i++) {
            const item = list.at(i);
            if (item.id === id) {
                item.enabled = on;
                return;
            }
        }
        list.insert({
            id,
            enabled: on
        });
    }

    title: Tr.tr("Utilities")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:utilities.enabled"
        }

        SectionHeader {
            text: Tr.tr("Cards")
        }

        ToggleRow {
            setting: "c:utilities.cards.keepAwake"
        }

        ToggleRow {
            setting: "c:utilities.cards.recorder"
        }

        ToggleRow {
            setting: "c:utilities.cards.quickToggles"
        }

        // caelestia4: cards added here (end-4's system card and sliders)
        ToggleRow {
            setting: "e4:caelestia.utilitiesSystem"
        }

        ToggleRow {
            setting: "e4:caelestia.utilitiesSliders"
        }

        SectionHeader {
            text: Tr.tr("Quick toggles")
        }

        Repeater {
            model: root.quickToggleIds

            ToggleRow {
                id: toggleRow

                required property string modelData

                setting: "x:utilities.quickToggles." + modelData

                Binding {
                    target: toggleRow.link.s
                    property: "customValue"
                    value: root.isToggleOn(toggleRow.modelData)
                }

                Binding {
                    target: toggleRow.link.s
                    property: "customDefault"
                    value: root.isToggleOnByDefault(toggleRow.modelData)
                }

                Connections {
                    function onCustomSet(v: var): void {
                        root.setToggleOn(toggleRow.modelData, !!v);
                    }

                    function onCustomReset(): void {
                        root.setToggleOn(toggleRow.modelData, root.isToggleOnByDefault(toggleRow.modelData));
                    }

                    target: toggleRow.link.s
                }
            }
        }

        // caelestia4: the quick toggles' saved layout (e4:caelestia.quickToggles)
        RowButton {
            icon: "restart_alt"
            text: Tr.tr("Reset quick toggles")
            subtext: Tr.tr("Order and visibility are edited in the drawer (pencil button). %1 saved").arg((E4C.Config.options.caelestia.quickToggles ?? []).length)
            onClicked: E4C.Config.options.caelestia.quickToggles = []
        }

        SectionHeader {
            text: Tr.tr("On-screen keyboard")
        }

        ToggleRow {
            setting: "e4:osk.pinnedOnStartup"
        }
    }
}
