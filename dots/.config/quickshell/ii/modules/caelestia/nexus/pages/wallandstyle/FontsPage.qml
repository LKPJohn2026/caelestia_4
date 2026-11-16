pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's monospace font follows Caelestia's)

// caelestia4: Wallpaper & style > Fonts (route appearance/fonts): the fonts people change (the panels', the icons', the
// end-4 parts': assistant, desktop widgets), then a link to Type scale (TypeScalePage.qml, appearance/fonts/scale), where
// each text style's sizes are. Rows name their registry setting (registry/RegFonts.qml)
PageBase {
    id: root

    title: Tr.tr("Fonts")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Panels")
        }

        // Writes the body family; headline, title and label follow it (entry `mirrors`), also after a reset. An Undo
        // after the page is gone: registry/RegAppearance.qml
        FontRow {
            id: panelFont

            setting: "c:appearance.font.body.family"

            MirrorWatch {
                setting: panelFont.link.s
                onFollow: v => {
                    if (NexusActions.undoing || typeof v !== "string" || !v.trim())
                        return;
                    const f = GlobalConfig.appearance.font;
                    if (f.headline.family !== v)
                        f.headline.family = v;
                    if (f.title.family !== v)
                        f.title.family = v;
                    if (f.label.family !== v)
                        f.label.family = v;
                }
            }
        }

        // end-4's widgets follow it (entry `mirrors`)
        FontRow {
            id: monoFont

            setting: "c:appearance.font.mono.family"

            MirrorWatch {
                setting: monoFont.link.s
                onFollow: v => {
                    if (typeof v === "string" && v.trim() && E4C.Config.options.appearance.fonts.monospace !== v)
                        E4C.Config.options.appearance.fonts.monospace = v;
                }
            }
        }

        // caelestia4: a Material Symbols font; the entry's description warns about others
        FontRow {
            setting: "c:appearance.font.icon.family"
        }

        FontRow {
            setting: "c:appearance.font.workspaces"
        }

        // end-4's parts kept in caelestia4 (Appearance.font.family.*)
        SectionHeader {
            text: Tr.tr("Desktop widgets and apps")
        }

        FontRow {
            setting: "e4:appearance.fonts.main"
        }

        FontRow {
            setting: "e4:appearance.fonts.title"
        }

        FontRow {
            setting: "e4:appearance.fonts.numbers"
        }

        // caelestia4: the two desktop clocks' fonts together: Caelestia's clock, end-4's cookie and digital clocks
        FontRow {
            setting: "c:appearance.font.clock"
        }

        FontRow {
            setting: "e4:appearance.fonts.expressive"
        }

        FontRow {
            setting: "e4:appearance.fonts.reading"
        }

        // caelestia4: Caelestia's text styles (Tokens.font.<style>.<size>) on their own sub-page
        SectionHeader {
            text: Tr.tr("Text styles")
        }

        NavRow {
            icon: "format_size"
            text: Tr.tr("Type scale")
            subtext: Tr.tr("Font, size and weight of headlines, titles, body text, labels and icons")
            onClicked: root.nState.openSubPage("scale")
        }
    }
}
