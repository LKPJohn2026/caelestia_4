pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    // caelestia4: launcher.actions items for the actions row (x:launcher.actions): plain objects with every field
    // (the default list leaves some out), `command` (a list) as one line since the list editor has no list field, and
    // the default name and description translated. Their marked text is kept in `_name`/`_description` and saved back
    // while the shown text is unchanged, so the launcher still translates them
    readonly property var actionFields: ({
            enabled: true,
            name: "",
            icon: "",
            description: "",
            command: [],
            dangerous: false
        })

    function actionsAsText(list: var): var {
        return Array.from(list ?? [], node => {
            const o = Object.assign({}, root.actionFields, JSON.parse(JSON.stringify(node ?? {})));
            delete o.objectName;
            o._name = o.name;
            o._description = o.description;
            o.name = o.name ? Tr.trMarked(o.name) : "";
            o.description = o.description ? Tr.trMarked(o.description) : "";
            o.command = Array.from(o.command ?? []).join(" ");
            // caelestia4: the editor shows "Hidden" (not `enabled`), so a new item, whose bools start off, is shown
            o.hidden = !o.enabled;
            delete o.enabled;
            return o;
        });
    }

    function actionFromText(a: var): var {
        const o = Object.assign({}, a);
        if (o._name && o.name === Tr.trMarked(o._name))
            o.name = o._name;
        if (o._description && o.description === Tr.trMarked(o._description))
            o.description = o._description;
        delete o._name;
        delete o._description;
        o.command = String(o.command ?? "").trim().split(/\s+/).filter(x => x);
        o.enabled = !o.hidden;
        delete o.hidden;
        return o;
    }

    title: Tr.tr("Launcher")
    isSubPage: true

    // caelestia4: General, Results, Apps, Actions, Search, Fuzzy search, Work safety; the prefixes and search tuning in Advanced
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:launcher.enabled"
        }

        ToggleRow {
            setting: "c:launcher.showOnHover"
        }

        StepperRow {
            setting: "c:launcher.dragThreshold"
        }

        ToggleRow {
            setting: "c:launcher.vimKeybinds"
        }

        SectionHeader {
            text: Tr.tr("Results")
        }

        StepperRow {
            setting: "c:launcher.maxShown"
        }

        StepperRow {
            setting: "c:launcher.maxWallpapers"
        }

        SectionHeader {
            text: Tr.tr("Apps")
        }

        KeyValueListRow {
            setting: "c:launcher.favouriteApps"
        }

        KeyValueListRow {
            setting: "c:launcher.hiddenApps"
        }

        SectionHeader {
            text: Tr.tr("Actions")
        }

        KeyValueListRow {
            id: actionsRow

            setting: "x:launcher.actions"
        }

        ToggleRow {
            setting: "c:launcher.enableDangerousActions"
        }

        // caelestia4: end-4's search (LauncherSearch, merged into this launcher)
        SectionHeader {
            text: Tr.tr("Search")
        }

        TextFieldRow {
            setting: "e4:search.engineBaseUrl"
        }

        KeyValueListRow {
            setting: "e4:search.excludedSites"
        }

        ToggleRow {
            setting: "e4:search.prefix.showDefaultActionsWithoutPrefix"
        }

        SectionHeader {
            text: Tr.tr("Fuzzy search")
        }

        ToggleRow {
            setting: "c:launcher.useFuzzy.apps"
        }

        ToggleRow {
            setting: "c:launcher.useFuzzy.actions"
        }

        ToggleRow {
            setting: "c:launcher.useFuzzy.schemes"
        }

        ToggleRow {
            setting: "c:launcher.useFuzzy.variants"
        }

        ToggleRow {
            setting: "c:launcher.useFuzzy.wallpapers"
        }

        // caelestia4: end-4's work safety: only the clipboard search (services/LauncherSearch.qml) reads it
        SectionHeader {
            text: Tr.tr("Work safety")
        }

        ToggleRow {
            setting: "e4:workSafety.enable.clipboard"
        }

        KeyValueListRow {
            setting: "e4:workSafety.triggerCondition.networkNameKeywords"
        }

        KeyValueListRow {
            setting: "e4:workSafety.triggerCondition.linkKeywords"
        }

        // caelestia4: the prefixes and search tuning (registry `advanced`)
        AdvancedSection {
            SectionHeader {
                text: Tr.tr("Prefixes")
            }

            // caelestia4: the default ">" shows as an empty field with ">" as its placeholder; an empty field saves ">".
            // An x: id over c:launcher.actionPrefix (prefixOption below maps "" to ">"), so the row's one write and its undo
            // step hold the real value
            TextFieldRow {
                id: prefixRow

                setting: "x:launcher.actionPrefix"
                errorText: Tr.tr("Prefix must not be alphanumeric")
                placeholderText: ">"
                maximumLength: 1
                smallField: true
                // Typing ">" itself saves the default: show it as the empty field
                onEditingFinished: {
                    if (field.valid && GlobalConfig.launcher.actionPrefix === ">")
                        clear();
                }
            }

            // Not an item: it feeds the action prefix row
            QtObject {
                readonly property Binding _value: Binding {
                    target: prefixRow.link.s
                    property: "customValue"
                    value: GlobalConfig.launcher.actionPrefix === ">" ? "" : GlobalConfig.launcher.actionPrefix // TODO: replace with empty only when not loaded once loaded state is exposed
                }

                readonly property Binding _default: Binding {
                    target: prefixRow.link.s
                    property: "customDefault"
                    value: GlobalConfig.launcher.descriptorFor("actionPrefix").defaultValue === ">" ? "" : GlobalConfig.launcher.descriptorFor("actionPrefix").defaultValue
                }

                readonly property Connections _writes: Connections {
                    function onCustomSet(v: var): void {
                        GlobalConfig.launcher.actionPrefix = String(v ?? "") || ">";
                    }

                    function onCustomReset(): void {
                        /// TODO: replace with GlobalConfig.launcher.resetOption("actionPrefix") when reset is fixed
                        GlobalConfig.launcher.actionPrefix = ">";
                    }

                    target: prefixRow.link.s
                }
            }

            TextFieldRow {
                setting: "c:launcher.specialPrefix"
                field.emptyIsValid: false
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.shellCommand"
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.clipboard"
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.emojis"
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.math"
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.webSearch"
                field.emptyIsValid: false
                smallField: true
            }

            TextFieldRow {
                setting: "e4:search.prefix.action"
                field.emptyIsValid: false
                smallField: true
            }

            SectionHeader {
                text: Tr.tr("Search tuning")
            }

            ToggleRow {
                setting: "e4:search.sloppy"
            }

            DurationRow {
                setting: "e4:search.nonAppResultDelay"
            }
        }

        // Not an item: it feeds the actions row
        QtObject {
            readonly property Binding _value: Binding {
                target: actionsRow.link.s
                property: "customValue"
                value: root.actionsAsText(GlobalConfig.launcher.actions.values)
            }

            readonly property Binding _default: Binding {
                target: actionsRow.link.s
                property: "customDefault"
                value: root.actionsAsText(GlobalConfig.launcher.descriptorFor("actions").defaultValue)
            }

            readonly property Connections _writes: Connections {
                function onCustomSet(v: var): void {
                    const list = GlobalConfig.launcher.actions;
                    list.clear();
                    for (const a of v ?? [])
                        list.insert(root.actionFromText(a));
                }

                function onCustomReset(): void {
                    GlobalConfig.launcher.resetOption("actions");
                }

                target: actionsRow.link.s
            }
        }
    }
}
