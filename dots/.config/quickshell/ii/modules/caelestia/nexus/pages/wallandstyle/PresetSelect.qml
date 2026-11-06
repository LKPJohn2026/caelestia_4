pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: end4-pC presets: a wallpaper, desktop widgets, a lock screen wallpaper and an avatar each, applied by
// scripts/presets/preset-import.py, which keeps a backup for Undo. Installed ones (the library) are applied with a
// click; the gallery lists Blapples/wallpapers' and the community's (pctrade/end4-pCpresets), installed on demand.
// "Use presets" off puts back your own desktop (--disable) and refuses presets until it's on again (--enable)
PageBase {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/presets/preset-import.py")
    property var presets: []
    property string current
    property bool canUndo
    property var workspaces: ({}) // workspace -> preset (background.workspacePresets)

    // the workspaces a preset is given to, in order: "1, 3"
    function workspacesOf(name: string): string {
        return Object.keys(root.workspaces).filter(ws => root.workspaces[ws] === name).sort((a, b) => (parseInt(a) || 0) - (parseInt(b) || 0) || a.localeCompare(b)).join(", ");
    }
    property string status
    property string doneStatus

    // "Use presets": the switch shows the state asked for while the script puts it in place (it sets the key)
    readonly property bool presetsOn: E4C.Config.options.background.presetsEnabled
    property bool toggling
    property bool toggleTo

    // the gallery (--catalog --json): name -> entry, and the names shown (search, filter), in the catalog's order
    property var catalog: ({})
    property var catalogNames: []
    property real fetched // unix seconds, 0 = never
    property string catalogError
    property var thumbsTried: ({}) // name -> true: a preview asked for once (again after a refresh)
    property string search
    property string sourceFilter: "all" // "all", "blapples", "community"
    property int shownCount: 24 // the gallery grows by this much with "Show more"
    property string installing // the preset being installed, offered to apply once it's in
    property string justInstalled
    property string toggleStatus // the last "Use presets" switch's outcome

    // turned on or off from elsewhere (a terminal): what was said about the last switch is old
    onPresetsOnChanged: {
        if (toggleSettle.running) { // the script is done and the config has caught up: the switch shows the real state
            if (presetsOn === toggleTo) {
                toggleSettle.stop();
                toggling = false;
            }
        } else if (!toggling) {
            toggleStatus = "";
        }
    }

    // the config is read back a moment after the script wrote it: the switch waits for that, not jumping back
    readonly property Timer toggleSettle: Timer {
        interval: 3000
        onTriggered: root.toggling = false
    }

    readonly property var galleryNames: {
        const q = root.search.trim().toLowerCase();
        return root.catalogNames.filter(n => {
            const p = root.catalog[n];
            if (!p || (root.sourceFilter !== "all" && p.source !== root.sourceFilter))
                return false;
            return !q || `${p.title ?? ""} ${p.name} ${p.author ?? ""}`.toLowerCase().includes(q);
        });
    }

    // the gallery's items: replaced only when the names change, so a listing (a preview arriving) keeps the grid
    property var shownNames: []
    function updateShown(): void {
        const n = root.galleryNames.slice(0, root.shownCount);
        if (n.join("\n") !== root.shownNames.join("\n"))
            root.shownNames = n;
        thumbsDue.restart();
    }
    onGalleryNamesChanged: updateShown()
    onShownCountChanged: updateShown()

    // previews only for the presets on screen (all of them would be ~200 MB), each asked for once
    function fetchThumbs(): void {
        if (root.thumbsProc.running) {
            thumbsDue.restart();
            return;
        }
        const names = root.shownNames.filter(n => root.catalog[n] && !root.catalog[n].preview && !root.thumbsTried[n]);
        if (names.length === 0)
            return;
        const tried = Object.assign({}, root.thumbsTried);
        for (const n of names)
            tried[n] = true;
        root.thumbsTried = tried;
        root.thumbsProc.command = [root.script, "--thumbs", ...names];
        root.thumbsProc.running = true;
    }

    readonly property Timer thumbsDue: Timer {
        interval: 400
        onTriggered: root.fetchThumbs()
    }

    // a preset's name as shown: community presets ("pctrade--name" in the library) say so
    function titleOf(p: var): string {
        if (!p)
            return "";
        const title = p.title || p.name;
        // TRANSLATORS: %1 = a community preset's name
        return p.source === "community" ? Tr.tr("%1 (community)").arg(title) : title;
    }

    // label while it runs (the script's own lines follow), done once it exits
    function run(args: list<string>, label: string, done: string): void {
        if (runProc.running)
            return;
        root.status = label;
        root.doneStatus = done;
        runProc.command = [root.script, ...args];
        runProc.running = true;
    }

    function setPresetsOn(on: bool): void {
        if (runProc.running)
            return;
        root.toggling = true;
        root.toggleTo = on;
        root.justInstalled = "";
        if (on)
            root.run(["--enable"], Tr.tr("Putting the last preset back…"), Tr.tr("Presets on"));
        else
            root.run(["--disable"], Tr.tr("Putting your own desktop back…"), Tr.tr("Presets off: your own desktop is back"));
    }

    function listCatalog(refresh: bool): void {
        if (refresh) {
            root.thumbsTried = {};
            catalogProc.refresh = true;
        }
        if (catalogProc.running) {
            catalogProc.again = true;
            return;
        }
        catalogProc.command = [root.script, "--catalog", ...(catalogProc.refresh ? ["--refresh"] : []), "--json"];
        catalogProc.refresh = false;
        catalogProc.running = true;
    }

    function fetchedText(): string {
        if (root.fetched <= 0)
            return "";
        const d = new Date(root.fetched * 1000);
        // TRANSLATORS: %1 = when the gallery was last fetched (a date and time)
        return Tr.tr("Fetched %1").arg(d.toLocaleString(Qt.locale(), Locale.ShortFormat));
    }

    title: Tr.tr("Presets")
    isSubPage: true

    Component.onCompleted: {
        listProc.running = true;
        root.listCatalog(false);
    }

    // Properties: PageBase's default property takes the page's one content item
    readonly property Process listProc: Process {
        command: [root.script, "--list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.presets = d.presets;
                    root.current = d.current;
                    root.canUndo = d.canUndo;
                    root.workspaces = d.workspaces ?? {};
                } catch (e) {
                    root.presets = [];
                }
            }
        }
    }

    readonly property Process runProc: Process {
        stdout: SplitParser {
            onRead: data => root.status = data.trim()
        }
        onExited: code => {
            root.status = code === 0 ? root.doneStatus : Tr.tr("Failed (exit code %1)").arg(code);
            if (root.toggling) {
                root.toggleStatus = root.status; // said on the switch, not on Update
                root.status = "";
                if (code === 0 && root.presetsOn !== root.toggleTo)
                    root.toggleSettle.restart();
                else
                    root.toggling = false;
            }
            if (root.installing && code === 0)
                root.justInstalled = root.installing;
            root.installing = "";
            root.listProc.running = true;
            root.listCatalog(false); // installed or not
        }
    }

    readonly property Process catalogProc: Process {
        property bool refresh
        property bool again // asked for while listing: once more after

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const map = {};
                    const names = [];
                    for (const p of d.presets ?? []) {
                        map[p.name] = p;
                        names.push(p.name);
                    }
                    root.catalog = map;
                    // the same presets: the grid keeps its items (a preview arriving changes only its picture)
                    if (names.join("\n") !== root.catalogNames.join("\n"))
                        root.catalogNames = names;
                    root.fetched = d.fetched ?? 0;
                    root.catalogError = d.error ?? "";
                } catch (e) {
                    root.catalogError = text.trim() ? Tr.tr("The gallery couldn't be read") : root.catalogError;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn(`PresetSelect: --catalog: ${text.trim()}`);
            }
        }
        onExited: {
            if (again) {
                again = false;
                root.listCatalog(false);
            } else {
                root.thumbsDue.restart();
            }
        }
    }

    // previews downloaded in the background, one "thumb <name>" line each: the catalog listed again a moment after
    readonly property Process thumbsProc: Process {
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("thumb "))
                    thumbsSettle.restart();
            }
        }
        onExited: root.listCatalog(false)
    }

    readonly property Timer thumbsSettle: Timer {
        interval: 800
        onTriggered: root.listCatalog(false)
    }

    // a preset applied from elsewhere (Ctrl+Super+P, a terminal) moves the check mark and Undo too
    readonly property FileView currentFile: FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia4/preset-current`
        watchChanges: true
        printErrors: false
        onFileChanged: root.listProc.running = true
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ToggleRow {
            first: true
            last: true
            disabled: root.runProc.running
            text: Tr.tr("Use presets")
            subtext: root.toggling ? root.status : root.toggleStatus || (root.presetsOn ? Tr.tr("A preset sets the wallpaper, widgets, colours, lock screen and avatar") : Tr.tr("Off: your own wallpaper, widgets and colours; presets aren't applied"))
            value: root.toggling ? root.toggleTo : root.presetsOn
            onToggled: root.setPresetsOn(checked)
        }

        // everything below waits for presets to be on
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.small

            enabled: root.presetsOn && !root.toggling
            opacity: enabled ? 1 : 0.5

            Behavior on opacity {
                Anim {}
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.spacing.small
                visible: !root.presetsOn
                text: Tr.tr("Your own layout is shown: the widgets you pick in Wallpaper & style > Widgets on the desktop. Turn presets on to apply one again (the last one comes back).")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            RowButton {
                first: true
                disabled: root.runProc.running || root.presets.length === 0
                icon: root.runProc.running && !root.toggling ? "hourglass_top" : "cloud_sync"
                text: Tr.tr("Update installed presets")
                subtext: (root.toggling ? "" : root.status) || Tr.tr("Your changes to a preset are kept; pictures stay on this computer")
                onClicked: root.run(["--update"], Tr.tr("Updating…"), Tr.tr("Installed presets are up to date"))
            }

            RowButton {
                disabled: root.runProc.running || !root.canUndo
                icon: "undo"
                text: Tr.tr("Undo the last preset")
                subtext: Tr.tr("Back to the wallpaper, widgets and lock screen from before it")
                onClicked: root.run(["--undo"], Tr.tr("Restoring…"), Tr.tr("Restored"))
            }

            RowButton {
                visible: root.justInstalled !== ""
                disabled: root.runProc.running
                icon: "check_circle"
                // TRANSLATORS: %1 = the preset just installed
                text: Tr.tr("Apply %1").arg(root.titleOf(root.catalog[root.justInstalled] ?? {
                    name: root.justInstalled
                }))
                subtext: Tr.tr("Installed: apply it now, or later from the installed ones")
                onClicked: {
                    const name = root.justInstalled;
                    root.justInstalled = "";
                    root.run([name], Tr.tr("Applying %1…").arg(name), Tr.tr("Applied %1").arg(name));
                }
            }

            // caelestia4: services/WorkspacePresets.qml
            ToggleRow {
                last: !E4C.Config.options.background.workspacePresets

                text: Tr.tr("A preset per workspace")
                subtext: Tr.tr("Going back to a workspace applies its preset again, colours too")
                value: E4C.Config.options.background.workspacePresets
                onToggled: E4C.Config.options.background.workspacePresets = checked
            }

            RowButton {
                visible: E4C.Config.options.background.workspacePresets
                last: true
                disabled: root.runProc.running || Object.keys(root.workspaces).length === 0
                icon: "layers_clear"
                text: Tr.tr("Forget the workspaces' presets")
                subtext: Object.keys(root.workspaces).length > 0 ? Tr.tr("Workspaces with a preset: %1").arg(Object.keys(root.workspaces).sort((a, b) => (parseInt(a) || 0) - (parseInt(b) || 0)).join(", ")) : Tr.tr("No workspace has a preset yet: apply one on it")
                onClicked: root.run(["--forget"], Tr.tr("Forgetting…"), Tr.tr("Each workspace keeps the preset on"))
            }

            SectionHeader {
                // TRANSLATORS: %1 = how many presets are installed
                text: root.presets.length > 0 ? Tr.tr("%1 installed: click one to apply it").arg(root.presets.length) : Tr.tr("Installed")
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: root.presets.length === 0
                text: Tr.tr("None yet: install some from the gallery below")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true

                columns: Math.max(1, Config.nexus.wallpapersPerRow - 1)
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.presets

                    PresetItem {
                        required property var modelData
                        readonly property string onWorkspaces: E4C.Config.options.background.workspacePresets ? root.workspacesOf(modelData.name) : ""
                        readonly property string shownName: root.titleOf(modelData)

                        enabled: !root.runProc.running
                        opacity: enabled ? 1 : 0.6
                        // the gallery's small preview when there's one, else the preset's own
                        source: root.catalog[modelData.name]?.preview || modelData.preview
                        actions: true

                        // TRANSLATORS: %1 = a preset's name, %2 = the workspaces it's given to ("1, 3")
                        text: (modelData.name === root.current ? "✓ " : "") + (onWorkspaces ? Tr.tr("%1 · %2").arg(shownName).arg(onWorkspaces) : shownName)
                        onClicked: root.run([modelData.name], Tr.tr("Applying %1…").arg(shownName), Tr.tr("Applied %1").arg(shownName))
                        onUpdateClicked: root.run(["--update", modelData.name], Tr.tr("Updating %1…").arg(shownName), Tr.tr("%1 is up to date").arg(shownName))
                        onUninstallClicked: root.run(["--uninstall", modelData.name], Tr.tr("Uninstalling %1…").arg(shownName), Tr.tr("Uninstalled %1").arg(shownName))
                    }
                }
            }

            // the gallery: every preset of both sources, installed with a click
            SectionHeader {
                text: Tr.tr("Gallery")
            }

            RowButton {
                first: true
                disabled: root.catalogProc.running
                icon: root.catalogProc.running || root.thumbsProc.running ? "hourglass_top" : "refresh"
                text: root.catalogProc.running ? Tr.tr("Loading the gallery…") : Tr.tr("Refresh the gallery")
                subtext: root.catalogError || (root.thumbsProc.running ? Tr.tr("Getting previews…") : root.fetchedText()) || Tr.tr("From Blapples/wallpapers and pctrade/end4-pCpresets on GitHub")
                subLabel.color: root.catalogError ? Colours.palette.m3error : Colours.palette.m3outline
                onClicked: root.listCatalog(true)
            }

            SelectRow {
                last: true
                label: Tr.tr("Show")
                // TRANSLATORS: %1 = how many gallery presets match the search and filter
                subtext: Tr.tr("%1 presets").arg(root.galleryNames.length)
                holdsSelection: true
                menuItems: [
                    MenuItem {
                        text: Tr.tr("All")
                        value: "all"
                    },
                    MenuItem {
                        text: Tr.tr("Blapples")
                        value: "blapples"
                    },
                    MenuItem {
                        text: Tr.tr("Community")
                        value: "community"
                    }
                ]
                onSelected: item => {
                    root.sourceFilter = item.value;
                    root.shownCount = 24;
                }
            }

            SearchBar {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.bottomMargin: Tokens.spacing.small

                placeholderText: Tr.tr("Search presets")
                font: Tokens.font.body.medium
                onTextChanged: {
                    root.search = text;
                    root.shownCount = 24;
                }
            }

            GridLayout {
                Layout.fillWidth: true

                columns: Math.max(1, Config.nexus.wallpapersPerRow - 1)
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.shownNames

                    PresetItem {
                        required property string modelData
                        readonly property var preset: root.catalog[modelData] ?? ({})
                        readonly property string shownName: root.titleOf(preset)

                        enabled: !root.runProc.running
                        opacity: enabled ? 1 : 0.6
                        source: preset.preview ?? ""
                        badge: preset.installed ? Tr.tr("Installed") : preset.source === "community" ? Tr.tr("Community") : ""
                        // TRANSLATORS: %1 = a preset's name, %2 = who made it
                        text: preset.author ? Tr.tr("%1 · by %2").arg(preset.title || preset.name).arg(preset.author) : (preset.title || preset.name || "")
                        onClicked: {
                            if (preset.installed) {
                                root.run([modelData], Tr.tr("Applying %1…").arg(shownName), Tr.tr("Applied %1").arg(shownName));
                            } else {
                                if (root.runProc.running)
                                    return;
                                root.justInstalled = "";
                                root.installing = modelData;
                                root.run(["--install", modelData], Tr.tr("Installing %1…").arg(shownName), Tr.tr("Installed %1").arg(shownName));
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: root.galleryNames.length === 0 && !root.catalogProc.running
                text: root.catalogNames.length === 0 ? Tr.tr("Nothing listed yet: refresh the gallery (it needs the internet once)") : Tr.tr("No preset matches")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            RowButton {
                first: true
                last: true
                visible: root.galleryNames.length > root.shownCount
                icon: "expand_more"
                // TRANSLATORS: %1 = how many more presets the gallery has
                text: Tr.tr("Show more (%1 left)").arg(root.galleryNames.length - root.shownCount)
                onClicked: root.shownCount += 24
            }
        }
    }
}
