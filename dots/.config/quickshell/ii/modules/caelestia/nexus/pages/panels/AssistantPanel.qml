pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)
import "../../registry/E4Defaults.js" as E4Defaults

// caelestia4: Panels > Assistant (the drawer that hosts end-4's AI chat, translator and anime tabs): AI policy and
// tools, the translator, the anime tab, then the prompt, models and image sources in Advanced (work safety is on
// the Launcher page: only its clipboard search reads it). The same
// keys as end-4's Settings app (Apps & services). The menus come from the registry entries' options (registry/RegPanels.qml)
PageBase {
    id: root

    title: Tr.tr("Assistant")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("AI assistant")
        }

        SelectRow {
            setting: "e4:policies.ai"
        }

        SelectRow {
            setting: "e4:ai.tool"
        }

        // caelestia4: the Translator tab (assistant/Translator.qml)
        SectionHeader {
            text: Tr.tr("Translator")
        }

        ToggleRow {
            setting: "e4:sidebar.translator.enable"
        }

        // caelestia4: "auto" shows as the empty field with "Automatic" (x: ids, AutoLanguage below)
        TextFieldRow {
            id: fromRow

            setting: "x:assistant.translateFrom"
            placeholderText: Tr.tr("Automatic")
        }

        TextFieldRow {
            id: toRow

            setting: "x:assistant.translateTo"
            placeholderText: Tr.tr("Automatic")
        }

        DurationRow {
            setting: "e4:sidebar.translator.delay"
        }

        SectionHeader {
            text: Tr.tr("Image boards")
        }

        SelectRow {
            setting: "e4:policies.weeb"
        }

        // caelestia4: one Advanced section, last: the AI's prompt, models and reply animation, and the Anime tab's
        // sources (registry `advanced`)
        AdvancedSection {
            SectionHeader {
                text: Tr.tr("Prompt and models")
            }

            TextAreaRow {
                setting: "e4:ai.systemPrompt"
            }

            KeyValueListRow {
                setting: "e4:ai.extraModels"
            }

            ToggleRow {
                setting: "e4:sidebar.ai.textFadeIn"
            }

            SectionHeader {
                text: Tr.tr("Image sources")
            }

            StepperRow {
                setting: "e4:sidebar.booru.limit"
            }

            MultiSelectRow {
                id: wallhavenRow

                setting: "x:assistant.wallhavenCategories"
                allowEmpty: false
            }

            SelectRow {
                setting: "e4:sidebar.booru.wallhaven.sorting"
            }

            // caelestia4: end-4's default is the text "[unset]": an x: id (zerochanOption below) shows it as the empty
            // field with a placeholder, and an empty field saves "[unset]"
            TextFieldRow {
                id: zerochanRow

                setting: "x:assistant.zerochanUsername"
                placeholderText: Tr.tr("Not set")
            }
        }

        // Not an item: the Zerochan row's value, with "[unset]" (end-4's default) as ""
        QtObject {
            id: zerochanOption

            function shown(v: var): string {
                const t = String(v ?? "");
                return t === "[unset]" ? "" : t;
            }

            readonly property Binding _value: Binding {
                target: zerochanRow.link.s
                property: "customValue"
                value: zerochanOption.shown(E4C.Config.options.sidebar.booru.zerochan.username)
            }

            readonly property Binding _default: Binding {
                target: zerochanRow.link.s
                property: "customDefault"
                value: zerochanOption.shown(E4Defaults.defaults["sidebar.booru.zerochan.username"])
            }

            readonly property Connections _writes: Connections {
                function onCustomSet(v: var): void {
                    const t = String(v ?? "").trim();
                    E4C.Config.options.sidebar.booru.zerochan.username = t.length > 0 ? t : E4Defaults.defaults["sidebar.booru.zerochan.username"];
                }

                function onCustomReset(): void {
                    E4C.Config.options.sidebar.booru.zerochan.username = E4Defaults.defaults["sidebar.booru.zerochan.username"];
                }

                target: zerochanRow.link.s
            }
        }

        AutoLanguage {
            row: fromRow
            key: "sourceLanguage"
        }

        AutoLanguage {
            row: toRow
            key: "targetLanguage"
        }

        // Not an item: Wallhaven's categories are a bit string ("010" = general off, anime on, people off), shown as
        // the list of the categories that are on
        QtObject {
            id: wallhavenOption

            readonly property list<string> keys: ["general", "anime", "people"]

            function toList(bits: string): var {
                return wallhavenOption.keys.filter((k, i) => String(bits ?? "")[i] === "1");
            }

            function toBits(list: var): string {
                return wallhavenOption.keys.map(k => Array.from(list ?? []).indexOf(k) >= 0 ? "1" : "0").join("");
            }

            readonly property Binding _value: Binding {
                target: wallhavenRow.link.s
                property: "customValue"
                value: wallhavenOption.toList(E4C.Config.options.sidebar.booru.wallhaven.categories)
            }

            readonly property Binding _default: Binding {
                target: wallhavenRow.link.s
                property: "customDefault"
                value: wallhavenOption.toList(E4Defaults.defaults["sidebar.booru.wallhaven.categories"])
            }

            readonly property Connections _writes: Connections {
                function onCustomSet(v: var): void {
                    E4C.Config.options.sidebar.booru.wallhaven.categories = wallhavenOption.toBits(v);
                }

                function onCustomReset(): void {
                    E4C.Config.options.sidebar.booru.wallhaven.categories = E4Defaults.defaults["sidebar.booru.wallhaven.categories"];
                }

                target: wallhavenRow.link.s
            }
        }
    }

    // caelestia4: not an item: a translator language row's value, with "auto" as "" (the field then shows
    // "Automatic"), and an empty field saved as "auto"
    component AutoLanguage: QtObject {
        id: lang

        required property TextFieldRow row
        required property string key

        function shown(v: var): string {
            const t = String(v ?? "");
            return t === "auto" ? "" : t;
        }

        readonly property Binding _value: Binding {
            target: lang.row.link.s
            property: "customValue"
            value: lang.shown(E4C.Config.options.language.translator[lang.key])
        }

        readonly property Binding _default: Binding {
            target: lang.row.link.s
            property: "customDefault"
            value: lang.shown(E4Defaults.defaults["language.translator." + lang.key])
        }

        readonly property Connections _writes: Connections {
            function onCustomSet(v: var): void {
                const t = String(v ?? "").trim();
                E4C.Config.options.language.translator[lang.key] = t.length > 0 ? t : "auto";
            }

            function onCustomReset(): void {
                E4C.Config.options.language.translator[lang.key] = E4Defaults.defaults["language.translator." + lang.key];
            }

            target: lang.row.link.s
        }
    }
}
