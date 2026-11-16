pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import "keybinds"

// caelestia4: sub-page of HyprlandPage (route hyprland/keybinds): every Hyprland shortcut by category, with search.
// The list comes from keybinds.lua and custom/keybinds.lua (scripts/caelestia4/nexus-keybinds.py); changes go only to
// ~/.config/hypr/custom/nexus-keybinds.lua, which hyprland.lua loads before keybinds.lua. Helper keys (Super or Alt
// alone, used by the shell) and Reset all are under Advanced
PageBase {
    id: root

    readonly property KeyNames names: KeyNames {}
    readonly property KeybindsModel kb: KeybindsModel {}

    // Most used first; any other category after these, "" (none) last
    readonly property var categoryOrder: ["App", "Window", "Workspace", "Shell", "Utilities", "Media", "Screen", "Session"]

    function categoryTitle(c: string): string {
        switch (c) {
        case "App":
            return Tr.trCtx("Apps", "shortcut category");
        case "Window":
            return Tr.trCtx("Windows", "shortcut category");
        case "Workspace":
            return Tr.trCtx("Workspaces", "shortcut category");
        case "Shell":
            return Tr.trCtx("Shell", "shortcut category");
        case "Utilities":
            return Tr.trCtx("Screenshots & tools", "shortcut category");
        case "Media":
            return Tr.trCtx("Media & volume", "shortcut category");
        case "Screen":
            return Tr.trCtx("Screen & zoom", "shortcut category");
        case "Session":
            return Tr.trCtx("Lock & power", "shortcut category");
        case "Virtual machines":
            return Tr.trCtx("Virtual machines", "shortcut category");
        case "":
            return Tr.trCtx("Other", "shortcut category");
        }
        return c;
    }

    // Shortcuts shown in the groups: not the helper keys. Twins (keypad, second keys) after the main ones
    readonly property var mainShortcuts: kb.shortcuts.filter(s => !s.internal)
    readonly property var helperShortcuts: kb.shortcuts.filter(s => s.internal)

    readonly property var groups: {
        const by = {};
        for (const s of root.mainShortcuts) {
            const c = s.source === "added" ? "Added" : s.source === "other" ? "Other" : (s.category || "");
            (by[c] = by[c] ?? []).push(s);
        }
        const rank = c => c === "Added" ? -1 : c === "Other" ? 1001 : c === "" ? 1000 : (root.categoryOrder.indexOf(c) + 1 || 500);
        return Object.keys(by).sort((a, b) => rank(a) - rank(b)).map(c => ({
                    category: c,
                    shortcuts: by[c].filter(s => !s.variant).concat(by[c].filter(s => !!s.variant))
                }));
    }

    readonly property string query: searchField.text.trim().toLowerCase()
    readonly property var matches: {
        if (!root.query)
            return [];
        const words = root.query.split(/\s+/);
        return root.kb.shortcuts.filter(s => {
            const hay = [root.names.actionWords(s), root.names.label(s.currentKeys), root.categoryTitle(s.category ?? ""), s.category ?? ""].join(" ").toLowerCase();
            return words.every(w => hay.indexOf(w) >= 0);
        });
    }

    function groupTitle(c: string): string {
        if (c === "Added")
            return Tr.trCtx("Added in Nexus", "shortcut category");
        if (c === "Other")
            return Tr.trCtx("Made outside Nexus", "shortcut category");
        return root.categoryTitle(c);
    }

    title: Tr.tr("Keyboard shortcuts")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // The dotfiles' hyprland.lua does not load the changes yet
        RowGroup {
            Layout.fillWidth: true
            visible: root.kb.loaded && !root.kb.canApply

            InfoRow {
                icon: "warning"
                iconColour: Colours.palette.m3error
                label: Tr.tr("Changes here don't work yet")
                subtext: Tr.tr("Your Hyprland setup is older than this page. Update the dotfiles, then changes apply.")
            }
        }

        // caelestia4: a shortcuts file could not be read (a mistake in it): the list may miss some
        RowGroup {
            Layout.fillWidth: true
            visible: root.kb.loaded && root.kb.error.length > 0

            InfoRow {
                icon: "error"
                iconColour: Colours.palette.m3error
                label: Tr.tr("Some shortcuts could not be read")
                subtext: Tr.tr("A shortcuts file has a mistake, so this list may miss some. Fix the file, then open this page again.")
            }
        }

        SearchBar {
            id: searchField

            Layout.fillWidth: true

            placeholderText: Tr.tr("Search shortcuts or keys")
            font: Tokens.font.body.medium
            bg.color: Colours.tPalette.m3surfaceContainerLowest
            bg.border.color: Colours.palette.m3outlineVariant

            Accessible.name: Tr.tr("Search shortcuts or keys")

            // Esc clears the text; with no text it goes on to Nexus
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape && text.length > 0) {
                    clear();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }

        RowGroup {
            Layout.fillWidth: true
            visible: !root.query

            RowButton {
                icon: "add"
                text: Tr.tr("New shortcut")
                subtext: root.kb.canApply ? Tr.tr("Run a command or open an app with your own keys") : Tr.tr("Not until changes here work")
                disabled: !root.kb.canApply
                onClicked: dialog.openNew()
            }
        }

        // Search results
        RowGroup {
            Layout.fillWidth: true
            visible: root.query.length > 0 && root.matches.length > 0

            Repeater {
                model: root.matches

                ShortcutRow {
                    names: root.names
                    clashWith: modelData.conflict ? root.kb.byId(modelData.conflict) : null
                    onClicked: dialog.openFor(modelData)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: root.query.length > 0 && root.matches.length === 0
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "search_off"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("No shortcuts match “%1”").arg(searchField.text.trim())
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("Try what it does, such as “screenshot”, or a key, such as “Super + Q”.")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.kb.loaded
            horizontalAlignment: Text.AlignHCenter
            text: Tr.tr("Reading shortcuts…")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        // One group per category
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.query
            spacing: Tokens.spacing.medium

            Repeater {
                model: root.groups

                CollapsibleGroup {
                    id: group

                    required property var modelData
                    readonly property int changedHere: modelData.shortcuts.filter(s => s.status === "changed" || s.status === "disabled").length

                    title: root.groupTitle(modelData.category)
                    key: modelData.category || "none"
                    summary: {
                        const parts = [Tr.trN("%n shortcut", "%n shortcuts", modelData.shortcuts.length)];
                        if (changedHere > 0)
                            parts.push(Tr.trN("%n changed", "%n changed", changedHere));
                        return parts.join(" · ");
                    }

                    Repeater {
                        model: group.modelData.shortcuts

                        ShortcutRow {
                            names: root.names
                            clashWith: modelData.conflict ? root.kb.byId(modelData.conflict) : null
                            onClicked: dialog.openFor(modelData)
                        }
                    }
                }
            }
        }

        RowGroup {
            Layout.fillWidth: true
            visible: !root.query && root.kb.loaded

            AdvancedSection {
                RowButton {
                    icon: "restart_alt"
                    text: Tr.tr("Reset all shortcuts")
                    subtext: root.kb.changedCount > 0 ? Tr.trN("%n change made here goes away", "%n changes made here go away", root.kb.changedCount) : Tr.tr("Nothing changed here yet")
                    disabled: root.kb.changedCount === 0
                    onClicked: resetConfirm.open()
                }

                SectionHeader {
                    text: Tr.tr("Helper keys")
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Tokens.spacing.small
                    text: Tr.tr("Super or Alt pressed alone, which the shell watches for the launcher and switchers. Turning one off can break those.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.helperShortcuts

                    ShortcutRow {
                        names: root.names
                        clashWith: modelData.conflict ? root.kb.byId(modelData.conflict) : null
                        onClicked: dialog.openFor(modelData)
                    }
                }
            }
        }

        ShortcutDialog {
            id: dialog

            names: root.names
            model: root.kb
        }

        ConfirmDialog {
            id: resetConfirm

            title: Tr.tr("Reset all shortcuts?")
            text: Tr.tr("Every shortcut goes back to its default and the ones added here are removed.")
            confirmText: Tr.trCtx("Reset", "button")
            destructive: true
            onAccepted: root.kb.run(Tr.tr("Reset all shortcuts"), ["reset-all"])
        }
    }
}
