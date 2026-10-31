pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (the assistant's AI and content settings live in end-4's config)

// caelestia4: Panels > Assistant (the drawer that hosts end-4's AI chat, translator and anime tabs): AI policy and
// tools, the system prompt, the anime tab and work safety. The same keys as end-4's Settings app (Apps & services)
PageBase {
    id: root

    readonly property list<MenuItem> aiItems: [
        MenuItem {
            text: Tr.tr("Yes")
            value: 1
        },
        MenuItem {
            text: Tr.tr("Local models only")
            value: 2
        },
        MenuItem {
            text: Tr.tr("No")
            value: 0
        }
    ]

    readonly property list<MenuItem> toolItems: [
        MenuItem {
            text: Tr.tr("Tools (shell, settings)")
            value: "functions"
        },
        MenuItem {
            text: Tr.tr("Web search")
            value: "search"
        },
        MenuItem {
            text: Tr.tr("Nothing")
            value: "none"
        }
    ]

    readonly property list<MenuItem> animeItems: [
        MenuItem {
            text: Tr.tr("Shown")
            value: 1
        },
        MenuItem {
            text: Tr.tr("Hidden tab")
            value: 2
        },
        MenuItem {
            text: Tr.tr("Off")
            value: 0
        }
    ]

    title: Tr.tr("Assistant")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("AI assistant")
        }

        SelectRow {
            first: true
            label: Tr.tr("Allow AI")
            menuItems: root.aiItems
            active: root.aiItems.find(i => i.value === E4C.Config.options.policies.ai) ?? null
            onSelected: item => E4C.Config.options.policies.ai = item.value
        }

        SelectRow {
            label: Tr.tr("What the AI may use")
            menuItems: root.toolItems
            active: root.toolItems.find(i => i.value === E4C.Config.options.ai.tool) ?? null
            onSelected: item => E4C.Config.options.ai.tool = item.value
        }

        TextAreaRow {
            last: true
            label: Tr.tr("Instructions for the AI")
            subtext: Tr.tr("System prompt. {DISTRO}, {DE}, {DATETIME} and {WINDOWCLASS} are filled in")
            value: E4C.Config.options.ai.systemPrompt
            onEditingFinished: v => E4C.Config.options.ai.systemPrompt = v
        }

        SectionHeader {
            text: Tr.tr("Content")
        }

        SelectRow {
            first: true
            label: Tr.tr("Anime tab")
            subtext: Tr.tr("Image boards in the assistant panel")
            menuItems: root.animeItems
            active: root.animeItems.find(i => i.value === E4C.Config.options.policies.weeb) ?? null
            onSelected: item => E4C.Config.options.policies.weeb = item.value
        }

        ToggleRow {
            text: Tr.tr("Hide unsafe images in the clipboard")
            subtext: Tr.tr("Images copied from adult or anime sites show blurred in clipboard history")
            value: E4C.Config.options.workSafety.enable.clipboard
            onToggled: E4C.Config.options.workSafety.enable.clipboard = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Hide unsafe wallpapers")
            subtext: Tr.tr("Blur wallpapers whose name suggests adult or anime content")
            value: E4C.Config.options.workSafety.enable.wallpaper
            onToggled: E4C.Config.options.workSafety.enable.wallpaper = checked
        }
    }
}
