import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.services as E4 // caelestia4: keep (Translation: end-4 languages)

PageBase {
    id: root

    readonly property Component e4LangComp: Component {
        MenuItem {}
    }
    readonly property list<MenuItem> e4LangItems: ["auto", ...E4.Translation.allAvailableLanguages].map(l => e4LangComp.createObject(root, {
            // caelestia4: "Automatic" on every row of this page
            text: l === "auto" ? Tr.tr("Automatic") : l,
            value: l
        }))

    // caelestia4: long date format: the presets are the registry entry's `options` (labels for search and Changed);
    // the menu shows each one as today's date. "Custom…" (or a saved value that is no preset) shows the raw field
    readonly property var dateNow: new Date()
    readonly property var datePresets: dateRow.link.entry?.options ?? []
    readonly property list<MenuItem> dateItems: datePresets.map(o => e4LangComp.createObject(root, {
            text: Qt.locale().toString(root.dateNow, o.value),
            value: o.value
        }))
    property bool dateCustomPicked
    // caelestia4: a change from outside the menu (reset, undo, the field) drops the Custom pick; a non-preset value
    // still shows Custom by itself. Picking Custom… does not change the value, so the pick stays until then
    // caelestia4: held in a property: a bare Connections here crashes qs's type loader (compile-check SIGSEGV)
    readonly property Connections _dateLinkWatch: Connections {
        target: dateRow.link

        function onValueChanged() {
            root.dateCustomPicked = false;
        }
    }

    readonly property bool dateCustom: dateCustomPicked || !datePresets.some(o => o.value === dateRow.link.value)

    title: Tr.tr("Language & region")

    // caelestia4: sections most-used first: language, time & date, units, weather. No Advanced section: its two rows
    // (GPS, date format) sit with their groups. The rows take their titles, descriptions, values and the unit menus
    // from registry/RegLanguage.qml
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // Language
        SectionHeader {
            text: Tr.tr("Language")
        }

        SelectRow {
            setting: "c:general.language"
            menuItems: [autoLang, ...langItems.instances]

            MenuItem {
                id: autoLang

                text: Tr.tr("Automatic")
                value: ""
            }

            Variants {
                id: langItems

                model: Tr.supportedLanguages

                MenuItem {
                    required property string modelData

                    value: modelData
                    text: {
                        const locale = Qt.locale(modelData);
                        return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                    }
                }
            }
        }

        // caelestia4: the language of the parts that come from end-4 and use its own translations
        // (E4.Translation, language.ui)
        SelectRow {
            setting: "e4:language.ui"
            menuItems: root.e4LangItems
        }

        // Time & date
        SectionHeader {
            text: Tr.tr("Time & date")
        }

        SelectRow {
            setting: "c:services.clockFormat"
        }

        SelectRow {
            id: dateRow

            setting: "e4:time.dateFormat"
            // caelestia4: keep the entry's description and add today's date in the chosen format
            // TRANSLATORS: %1 = what the setting does, %2 = today's date written in the chosen format
            subtext: Tr.tr("%1. Today: %2").arg(link.desc).arg(Qt.locale().toString(root.dateNow, String(link.value ?? "")))
            menuItems: [...root.dateItems, dateCustomItem]
            active: root.dateCustom ? dateCustomItem : (root.dateItems.find(i => i.value === link.value) ?? null)
            onSelected: item => root.dateCustomPicked = item === dateCustomItem

            MenuItem {
                id: dateCustomItem

                text: Tr.tr("Custom…")
                activeText: Tr.tr("Custom")
            }
        }

        // caelestia4: no `setting` (the row above holds it, so search and links land there): it saves through it
        TextFieldRow {
            visible: root.dateCustom
            label: Tr.tr("Custom format")
            subtext: Tr.tr("d day, M month, yyyy year, ddd day name, MMM month name")
            value: String(dateRow.link.value ?? "")
            validate: /\S/
            onEditingFinished: v => {
                if (v.trim() && v !== String(dateRow.link.value ?? ""))
                    dateRow.link.set(v);
            }
        }

        // Units
        SectionHeader {
            text: Tr.tr("Units")
        }

        SelectRow {
            setting: "c:services.weatherUnits"
        }

        SelectRow {
            setting: "c:services.sensorUnits"
        }

        SelectRow {
            setting: "c:services.dataUnits"
        }

        // Weather
        SectionHeader {
            text: Tr.tr("Weather")
        }

        // caelestia4: Caelestia's, shared with end-4's weather widget. The row saves what was typed; spaces around it
        // are trimmed after
        TextFieldRow {
            setting: "c:services.weatherLocation"
            // caelestia4: empty means found automatically (the description says so)
            placeholderText: Tr.tr("Automatic")
            onEditingFinished: v => {
                if (v !== v.trim())
                    Qt.callLater(() => GlobalConfig.services.weatherLocation = v.trim());
            }
        }

        // caelestia4: with the location (was an Advanced section of two rows)
        ToggleRow {
            setting: "e4:bar.weather.enableGPS"
        }
    }
}
