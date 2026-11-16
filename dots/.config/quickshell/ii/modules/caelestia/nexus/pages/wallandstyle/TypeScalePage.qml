pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Fonts > Type scale (route appearance/fonts/scale): Caelestia's text styles (Tokens.font.<style>.<size>),
// one CollapsibleGroup per style, closed, its header saying the style's font, medium size and weight. Inside: the
// style's font, then each size (a FONT_CONFIG node: font, size, weight, italic, variable font axes) as a group. The
// axes row sits in the size's group: the page has no "Advanced" part. Sizes are in points, times Text size (Look &
// feel). Rows name their registry setting (registry/RegFonts.qml)
PageBase {
    id: root

    // One size of a style, its axes row last in the same group
    component SizeGroup: FontGroup {
        id: sizeGroup

        showAxes: false

        KeyValueListRow {
            setting: sizeGroup.prefix ? sizeGroup.prefix + ".vaxes" : ""
            fields: [
                {
                    key: "key",
                    title: Tr.mark("Axis"),
                    type: "string"
                },
                {
                    key: "value",
                    title: Tr.mark("Value"),
                    type: "real"
                }
            ]
        }
    }

    readonly property var fontCfg: GlobalConfig.appearance.font

    function weightName(w: int): string {
        switch (w) {
        case 100:
            return Tr.trCtx("Thin", "font weight");
        case 200:
            return Tr.trCtx("Extra light", "font weight");
        case 300:
            return Tr.trCtx("Light", "font weight");
        case 400:
            return Tr.trCtx("Regular", "font weight");
        case 500:
            return Tr.trCtx("Medium", "font weight");
        case 600:
            return Tr.trCtx("Semi-bold", "font weight");
        case 700:
            return Tr.trCtx("Bold", "font weight");
        case 800:
            return Tr.trCtx("Extra bold", "font weight");
        case 900:
            return Tr.trCtx("Black", "font weight");
        }
        return String(w);
    }

    // A group's header line: "Inter · 15 pt · Medium" from the style's medium size (an empty family is the style's)
    function summaryOf(styleFamily: string, size: var): string {
        if (!size)
            return "";
        const parts = [size.family || styleFamily, Tr.tr("%1 pt").arg(size.size), root.weightName(size.weight)];
        if (size.italic)
            parts.push(Tr.tr("Italic"));
        return parts.filter(s => s).join(" · ");
    }

    title: Tr.tr("Type scale")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("The font, size and weight of each kind of text in the panels. Text size on Look & feel makes them all bigger or smaller")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        CollapsibleGroup {
            key: "headline"
            summary: root.summaryOf(root.fontCfg.headline.family, root.fontCfg.headline.medium)
            title: Tr.tr("Headlines")

            FontRow {
                setting: "c:appearance.font.headline.family"
            }

            SizeGroup {
                prefix: "c:appearance.font.headline.large"
                title: Tr.trCtx("Large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.headline.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.headline.small"
                title: Tr.trCtx("Small", "font size")
            }
        }

        CollapsibleGroup {
            key: "title"
            summary: root.summaryOf(root.fontCfg.title.family, root.fontCfg.title.medium)
            title: Tr.tr("Titles")

            FontRow {
                setting: "c:appearance.font.title.family"
            }

            SizeGroup {
                prefix: "c:appearance.font.title.large"
                title: Tr.trCtx("Large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.title.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.title.small"
                title: Tr.trCtx("Small", "font size")
            }
        }

        // The body style's font is the panel font (Fonts)
        CollapsibleGroup {
            key: "body"
            summary: root.summaryOf(root.fontCfg.body.family, root.fontCfg.body.medium)
            title: Tr.tr("Body text")

            SizeGroup {
                prefix: "c:appearance.font.body.large"
                title: Tr.trCtx("Large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.body.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.body.small"
                title: Tr.trCtx("Small", "font size")
            }
        }

        CollapsibleGroup {
            key: "label"
            summary: root.summaryOf(root.fontCfg.label.family, root.fontCfg.label.medium)
            title: Tr.tr("Labels")

            FontRow {
                setting: "c:appearance.font.label.family"
            }

            SizeGroup {
                prefix: "c:appearance.font.label.large"
                title: Tr.trCtx("Large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.label.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.label.small"
                title: Tr.trCtx("Small", "font size")
            }
        }

        // The mono style's font is the monospace font (Fonts); nothing uses its large size (registry/ignored.json)
        CollapsibleGroup {
            key: "mono"
            summary: root.summaryOf(root.fontCfg.mono.family, root.fontCfg.mono.medium)
            title: Tr.tr("Monospace")

            SizeGroup {
                prefix: "c:appearance.font.mono.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.mono.small"
                title: Tr.trCtx("Small", "font size")
            }
        }

        // The icon font is on Fonts
        CollapsibleGroup {
            key: "icon"
            summary: root.summaryOf(root.fontCfg.icon.family, root.fontCfg.icon.medium)
            title: Tr.tr("Icons")

            SizeGroup {
                prefix: "c:appearance.font.icon.extraLarge"
                title: Tr.trCtx("Extra large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.icon.large"
                title: Tr.trCtx("Large", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.icon.medium"
                title: Tr.trCtx("Medium", "font size")
            }

            SizeGroup {
                prefix: "c:appearance.font.icon.small"
                title: Tr.trCtx("Small", "font size")
            }
        }
    }
}
