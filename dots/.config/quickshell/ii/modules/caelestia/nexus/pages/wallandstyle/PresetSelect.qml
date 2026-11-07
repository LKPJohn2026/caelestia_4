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
// scripts/presets/preset-import.py, which keeps a backup for Undo. Two lists, each installed on demand and applied with a
// click: the main repo's (pctrade/end4-pCpresets), and the third parties' (Blapples/wallpapers and any repo added by its
// link; a copy of a preset the main repo has is skipped).
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

    // the lists (--catalog --json): name -> entry, and the names shown (search, filter)
    property var catalog: ({})
    property var catalogNames: []
    property real fetched // unix seconds, 0 = never
    property string catalogError
    property var thumbsTried: ({}) // name -> true: a preview asked for once (again after a refresh)
    property string search
    property bool installedOnly
    property int mainCount: 24 // each list grows by this much with "Show more"
    property int thirdCount: 24
    property var recentNames: [] // the presets of a repo just added: first in their list
    property string installing // the preset being installed, offered to apply once it's in
    property string justInstalled
    property string toggleStatus // the last "Use presets" switch's outcome

    // the third parties (--add-source adds one): the catalog's list of them, and what the last one came to
    property var addedSources: [] // {repo, count}
    property string addMessage
    property string addSkipped
    property bool addFailed
    property string removing // the repo asked to be taken out, for the second click

    // the words for why a repo couldn't be added (the script's own, in English, when it's something else)
    function addError(code: string, error: string): string {
        if (code === "bad_link")
            return Tr.tr("That isn't a link to a GitHub repo");
        if (code === "not_github")
            return Tr.tr("Only GitHub repos can be added");
        if (code === "already")
            return Tr.tr("This repo is in the list already");
        if (code === "not_found")
            return Tr.tr("No public repo or branch at that link");
        if (code === "private")
            return Tr.tr("This repo is private: only public ones can be added");
        if (code === "no_presets")
            return Tr.tr("No presets there: each needs a folder with one .json and a picture");
        if (code === "too_many")
            return Tr.tr("This repo has too many folders to check");
        if (code === "network") {
            console.warn(`PresetSelect: --add-source: ${error}`);
            return Tr.tr("GitHub couldn't be reached");
        }
        if (code === "limit")
            return Tr.tr("GitHub's limit of listings is reached: try again in a while, or sign in with gh auth login");
        return error || Tr.tr("The repo couldn't be added");
    }

    function addSource(link: string): void {
        if (root.addProc.running || !link.trim())
            return;
        root.addMessage = Tr.tr("Comparing its presets with pctrade/end4-pCpresets…");
        root.addSkipped = "";
        root.addFailed = false;
        root.addProc.command = [root.script, "--add-source", link.trim(), "--json"];
        root.addProc.running = true;
    }

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

    // the names of a list that pass the search and the filter, in the catalog's order (by title), the presets of a repo
    // just added first. Installing doesn't move a preset: its second click, on the same spot, applies it
    function namesOf(third: bool): var {
        const q = root.search.trim().toLowerCase();
        const names = root.catalogNames.filter(n => {
            const p = root.catalog[n];
            if (!p || (p.source !== "community") !== third || (root.installedOnly && !p.installed))
                return false;
            return !q || `${p.title ?? ""} ${p.name} ${p.author ?? ""}`.toLowerCase().includes(q);
        });
        const recent = n => root.recentNames.includes(n);
        return [...names.filter(recent), ...names.filter(n => !recent(n))]; // (QML's sort isn't stable)
    }

    readonly property var mainNames: namesOf(false)
    readonly property var thirdNames: namesOf(true)

    // the items: replaced only when the names change, so a listing (a preview arriving) keeps the grid
    property var mainShown: []
    property var thirdShown: []
    function updateShown(): void {
        const m = root.mainNames.slice(0, root.mainCount);
        if (m.join("\n") !== root.mainShown.join("\n"))
            root.mainShown = m;
        const t = root.thirdNames.slice(0, root.thirdCount);
        if (t.join("\n") !== root.thirdShown.join("\n"))
            root.thirdShown = t;
        thumbsDue.restart();
    }
    onMainNamesChanged: updateShown()
    onThirdNamesChanged: updateShown()
    onMainCountChanged: updateShown()
    onThirdCountChanged: updateShown()

    // previews only for the presets on screen (all of them would be ~200 MB), each asked for once
    function fetchThumbs(): void {
        if (root.thumbsProc.running) {
            thumbsDue.restart();
            return;
        }
        const names = [...root.mainShown, ...root.thirdShown].filter(n => root.catalog[n] && !root.catalog[n].preview && !root.thumbsTried[n]);
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

    // a preset's name as shown
    function titleOf(p: var): string {
        return p ? (p.title || p.name || "") : "";
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
                    // the installed ones at once: --catalog may take a while on a bad network
                    if (root.catalogNames.length === 0 && d.presets.length > 0) {
                        const map = {};
                        for (const p of d.presets)
                            map[p.name] = Object.assign({}, p, {installed: true});
                        root.catalog = map;
                        root.catalogNames = d.presets.map(p => p.name);
                    }
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
                    if (JSON.stringify(d.sources ?? []) !== JSON.stringify(root.addedSources))
                        root.addedSources = d.sources ?? [];
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

    readonly property Process addProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    root.addFailed = true;
                    root.addMessage = Tr.tr("The repo couldn't be added");
                    return;
                }
                if (!d.ok) {
                    root.addFailed = true;
                    root.addMessage = root.addError(d.code ?? "", d.error ?? "");
                    return;
                }
                root.addFailed = false;
                const skipped = d.skipped ?? [];
                // TRANSLATORS: %1 = a repo, %2 = presets added, %3 = duplicates skipped
                let said = d.added > 0 ? Tr.tr("%1: %2 presets added, %3 duplicates skipped").arg(d.repo).arg(d.added).arg(skipped.length)
                // TRANSLATORS: %1 = a repo, %2 = how many presets it has
                : Tr.tr("%1: all %2 presets are already in the list, nothing added").arg(d.repo).arg(d.total);
                if (d.stale)
                    said += " " + Tr.tr("(compared with the list kept from before: GitHub couldn't be reached)");
                root.addMessage = said;
                // TRANSLATORS: %1 = the names of the presets left out
                const shown = skipped.slice(0, 12).map(x => {
                    const a = x.name.split("--").pop();
                    const b = x.of.split("--").pop();
                    return a === b ? a : `${a} (${b})`;
                });
                root.addSkipped = shown.length === 0 ? "" : Tr.tr("Skipped: %1").arg(shown.join(", "))
                    // TRANSLATORS: %1 = how many more presets were left out
                    + (skipped.length > shown.length ? " " + Tr.tr("and %1 more").arg(skipped.length - shown.length) : "");
                if (d.added > 0) {
                    sourceField.clear();
                    searchField.clear();
                    root.installedOnly = false;
                    filterRow.active = filterRow.menuItems[0];
                    root.recentNames = d.names ?? [];
                    root.thirdCount = 24;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn(`PresetSelect: --add-source: ${text.trim()}`);
            }
        }
        onExited: root.listCatalog(false)
    }

    readonly property Timer removeConfirm: Timer {
        interval: 4000
        onTriggered: root.removing = ""
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

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.spacing.small
                visible: root.presetsOn && Config.dashboard.enabled
                text: Tr.tr("With presets on, the screen's top edge doesn't open the dashboard: Super+M does.")
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

            // the main repo's presets
            SectionHeader {
                text: Tr.tr("Presets from pctrade/end4-pCpresets")
            }

            RowButton {
                first: true
                disabled: root.catalogProc.running
                icon: root.catalogProc.running || root.thumbsProc.running ? "hourglass_top" : "refresh"
                text: root.catalogProc.running ? Tr.tr("Loading the presets…") : Tr.tr("Refresh the presets")
                subtext: root.catalogError || (root.thumbsProc.running ? Tr.tr("Getting previews…") : root.fetchedText()) || Tr.tr("From GitHub; click a preset to install it, click again to apply it")
                subLabel.color: root.catalogError ? Colours.palette.m3error : Colours.palette.m3outline
                onClicked: root.listCatalog(true)
            }

            SelectRow {
                id: filterRow

                last: true
                label: Tr.tr("Show")
                // TRANSLATORS: %1 = how many presets of the main repo match, %2 = of third parties
                subtext: Tr.tr("%1 from pctrade, %2 from third parties").arg(root.mainNames.length).arg(root.thirdNames.length)
                holdsSelection: true
                menuItems: [
                    MenuItem {
                        text: Tr.tr("All")
                        value: "all"
                    },
                    MenuItem {
                        text: Tr.tr("Installed")
                        value: "installed"
                    }
                ]
                onSelected: item => {
                    root.installedOnly = item.value === "installed";
                    root.mainCount = 24;
                    root.thirdCount = 24;
                }
            }

            SearchBar {
                id: searchField

                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.bottomMargin: Tokens.spacing.small

                placeholderText: Tr.tr("Search presets")
                font: Tokens.font.body.medium
                onTextChanged: {
                    root.search = text;
                    root.mainCount = 24;
                    root.thirdCount = 24;
                }
            }

            Component {
                id: presetDelegate

                PresetItem {
                    required property string modelData
                    readonly property var preset: root.catalog[modelData] ?? ({})
                    readonly property string shownName: root.titleOf(preset)
                    readonly property string givenTo: E4C.Config.options.background.workspacePresets ? root.workspacesOf(modelData) : ""
                    // TRANSLATORS: %1 = a preset's name, %2 = who made it
                    readonly property string credited: preset.author ? Tr.tr("%1 · by %2").arg(shownName).arg(preset.author) : shownName

                    enabled: !root.runProc.running
                    opacity: enabled ? 1 : 0.6
                    source: preset.preview ?? ""
                    badge: preset.installed ? Tr.tr("Installed") : ""
                    actions: !!preset.installed
                    // TRANSLATORS: %1 = a preset's name, %2 = the workspaces it's given to ("1, 3")
                    text: (modelData === root.current ? "✓ " : "") + (givenTo ? Tr.tr("%1 · %2").arg(credited).arg(givenTo) : credited)
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
                    onUpdateClicked: root.run(["--update", modelData], Tr.tr("Updating %1…").arg(shownName), Tr.tr("%1 is up to date").arg(shownName))
                    onUninstallClicked: {
                        if (root.justInstalled === modelData)
                            root.justInstalled = "";
                        root.run(["--uninstall", modelData], Tr.tr("Uninstalling %1…").arg(shownName), Tr.tr("Uninstalled %1").arg(shownName));
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true

                columns: Math.max(1, Config.nexus.wallpapersPerRow - 1)
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.mainShown
                    delegate: presetDelegate
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: root.mainNames.length === 0 && !root.catalogProc.running
                text: root.catalogNames.length === 0 ? Tr.tr("Nothing listed yet: refresh the presets (it needs the internet once)") : Tr.tr("No preset matches")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            RowButton {
                first: true
                last: true
                visible: root.mainNames.length > root.mainCount
                icon: "expand_more"
                // TRANSLATORS: %1 = how many more presets the list has
                text: Tr.tr("Show more (%1 left)").arg(root.mainNames.length - root.mainCount)
                onClicked: root.mainCount += 24
            }

            // the third parties: Blapples and the repos added by link
            SectionHeader {
                text: Tr.tr("From third parties")
            }

            // the address bar: a repo's link, Enter adds its presets that the main repo doesn't have
            SearchBar {
                id: sourceField

                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.spacing.small

                searchIcon.text: root.addProc.running ? "hourglass_top" : "link"
                readOnly: root.addProc.running
                placeholderText: Tr.tr("Add a repo: paste its GitHub link and press Enter")
                font: Tokens.font.body.medium
                onAccepted: root.addSource(text)
                onTextChanged: {
                    if (root.addFailed && !root.addProc.running) { // the next try: that one's error is old
                        root.addFailed = false;
                        root.addMessage = "";
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.spacing.small
                visible: root.addMessage !== ""
                text: root.addMessage
                color: root.addFailed ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.spacing.small
                visible: root.addSkipped !== ""
                text: root.addSkipped
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.Wrap
            }

            Repeater {
                model: root.addedSources

                RowButton {
                    id: sourceRow

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    first: index === 0
                    last: index === root.addedSources.length - 1
                    disabled: root.runProc.running
                    icon: root.removing === modelData.repo ? "delete_forever" : "link"
                    text: modelData.repo
                    // TRANSLATORS: %1 = how many presets of a third party's are listed
                    subtext: root.removing === modelData.repo ? Tr.tr("Click again to take it out of the list (installed presets stay)") : Tr.tr("%1 presets · click to remove the repo").arg(modelData.count)
                    onClicked: {
                        if (root.removing === sourceRow.modelData.repo) {
                            root.removing = "";
                            root.removeConfirm.stop();
                            root.addMessage = "";
                            root.addSkipped = "";
                            root.addFailed = false;
                            root.run(["--remove-source", sourceRow.modelData.repo], Tr.tr("Removing %1…").arg(sourceRow.modelData.repo), Tr.tr("Removed %1").arg(sourceRow.modelData.repo));
                        } else {
                            root.removing = sourceRow.modelData.repo;
                            root.removeConfirm.restart();
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.medium

                columns: Math.max(1, Config.nexus.wallpapersPerRow - 1)
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.large

                Repeater {
                    model: root.thirdShown
                    delegate: presetDelegate
                }
            }

            RowButton {
                first: true
                last: true
                visible: root.thirdNames.length > root.thirdCount
                icon: "expand_more"
                // TRANSLATORS: %1 = how many more presets the list has
                text: Tr.tr("Show more (%1 left)").arg(root.thirdNames.length - root.thirdCount)
                onClicked: root.thirdCount += 24
            }
        }
    }
}
