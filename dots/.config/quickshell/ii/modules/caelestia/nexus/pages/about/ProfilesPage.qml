pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.registry
import "../../navpane"

// caelestia4: About > Profiles (route about/profiles): named sets of settings (scripts/caelestia4/nexus-profile.sh;
// only what differs from the defaults, never passwords or keys). Save the current settings under a name; rename,
// delete (asks first) or apply one. Apply shows what changes first (old → new per setting, by its registry title and
// page), saves the current settings as a "Before <date>" backup and offers Undo (applies that backup). Backups are
// listed apart, the newest 10 kept
PageBase {
    id: root

    title: Tr.tr("Profiles")
    isSubPage: true

    readonly property string script: Quickshell.shellPath("scripts/caelestia4/nexus-profile.sh")
    // [{id, name, created, count, backup}], newest first
    property var profiles: []
    readonly property var saved: profiles.filter(p => !p.backup)
    readonly property var backups: profiles.filter(p => p.backup)
    property bool loaded
    readonly property bool busy: runner.running || ProfileApply.running

    // The profile a dialog acts on, and the changes an apply would make
    property var current: null
    property var changes: []

    // Route labels as search shows them (no live values)
    readonly property SearchIndex labels: SearchIndex {}

    function refresh(): void {
        listProc.running = true;
    }

    // One script call at a time; `done(code, stdout)` runs after it
    function run(args: list<string>, done: var): void {
        if (root.busy)
            return;
        runner.done = done;
        runner.command = [root.script, ...args];
        runner.running = true;
    }

    function when(iso: string): string {
        const d = new Date(iso);
        return isNaN(d.getTime()) ? "" : d.toLocaleString(Qt.locale(), Locale.ShortFormat);
    }

    // The profile (or backup) other than `except` that has this name, as the script checks it; null if none
    function nameOwner(name: string, except: string): var {
        const n = name.trim().toLowerCase();
        return root.profiles.find(p => p.id !== except && p.name.toLowerCase() === n) ?? null;
    }

    function nameTaken(name: string, except: string): bool {
        return root.nameOwner(name, except) !== null;
    }

    function save(name: string): void {
        root.run(["save", name.trim()], (code, out) => {
            if (code === 0)
                NexusActions.toast(Tr.tr("Saved as “%1”").arg(name.trim()));
            else
                NexusActions.toast(code === 3 ? Tr.tr("A profile with that name exists") : Tr.tr("Could not save the profile"));
            root.refresh();
        });
    }

    function rename(p: var, name: string): void {
        root.run(["rename", p.id, name.trim()], code => {
            if (code !== 0)
                NexusActions.toast(code === 3 ? Tr.tr("A profile with that name exists") : Tr.tr("Could not rename the profile"));
            root.refresh();
        });
    }

    function remove(p: var): void {
        root.run(["delete", p.id], code => {
            NexusActions.toast(code === 0 ? Tr.tr("Deleted “%1”").arg(p.name) : Tr.tr("Could not delete the profile"));
            root.refresh();
        });
    }

    // The changes first, then the dialog
    function preview(p: var): void {
        root.run(["diff", p.id], (code, out) => {
            let list = null;
            try {
                list = code === 0 ? JSON.parse(out).changes : null;
            } catch (e) {}
            if (!list) {
                NexusActions.toast(Tr.tr("Could not read the profile"));
                return;
            }
            if (!list.length) {
                NexusActions.toast(Tr.tr("Your settings already match “%1”").arg(p.name));
                return;
            }
            root.current = p;
            // Settings in page order (as Changed settings lists them), the ones Nexus has no row for last
            const order = Object.keys(Registry.entries);
            const rank = d => d.entryId ? order.indexOf(d.entryId) : order.length;
            root.changes = root.distinct(list.map(c => root.describe(c))).sort((a, b) => rank(a) - rank(b));
            applyDialog.open();
        });
    }

    // caelestia4: ProfileApply runs it, so its Undo still works once this page is closed
    function apply(p: var): void {
        ProfileApply.apply(p, false);
    }

    // {title, place, from, to} for one change: the registry setting whose id is the longest start of the path, else
    // the last key in words. null in the change is the default
    function describe(c: var): var {
        const store = c.path[0];
        const screen = store === "screens" ? c.path[1] : "";
        const keys = c.path.slice(store === "screens" ? 2 : 1);
        const prefix = store === "config" ? "e4:" : "c:";
        let entry = null;
        let n = keys.length;
        for (; n > 0 && !entry; n--)
            entry = Registry.entry(prefix + keys.slice(0, n).join("."));
        const exact = entry && n + 1 === keys.length;
        const placeParts = [];
        if (entry)
            placeParts.push(root.labels.routeLabels(entry.route).join(" › "));
        else
            placeParts.push(store === "config" ? Tr.tr("Other end-4 setting") : Tr.tr("Other Caelestia setting"));
        if (screen)
            // TRANSLATORS: a setting for one screen only; %1 is the screen's name (e.g. DP-1)
            placeParts.push(Tr.tr("Screen %1").arg(screen));
        return {
            sid: exact ? entry.id : "",
            entryId: entry?.id ?? "",
            title: entry ? Tr.tr(entry.title) : root.keyTitle(keys, 1),
            keys,
            place: placeParts.join(" · "),
            from: exact ? null : root.plain(c.old),
            to: exact ? null : root.plain(c.new),
            oldValue: c.old,
            newValue: c.new
        };
    }

    // caelestia4: a title from the last `depth` keys, for a setting with no registry entry. A last key that says little
    // on its own ("enable", "value") gives way to the one before it: transparency.enable → "Transparency"
    function keyTitle(keys: var, depth: int): string {
        const vague = ["enable", "enabled", "active", "show", "value", "mode", "type", "style", "list", "items"];
        let ks = keys.filter(k => typeof k === "string");
        if (ks.length > 1 && vague.includes(String(ks[ks.length - 1]).toLowerCase()))
            ks = ks.slice(0, -1);
        return ks.slice(-depth).map(k => root.words(k)).filter(w => w).join(" › ");
    }

    // caelestia4: rows with no registry entry that would show the same title take more of their keys until they differ
    function distinct(list: var): var {
        for (let depth = 2; depth <= 4; depth++) {
            const seen = {};
            for (const d of list)
                if (!d.entryId)
                    seen[d.title + "\n" + d.place] = (seen[d.title + "\n" + d.place] ?? 0) + 1;
            const dup = list.filter(d => !d.entryId && seen[d.title + "\n" + d.place] > 1);
            if (!dup.length)
                break;
            for (const d of dup)
                d.title = root.keyTitle(d.keys, depth);
        }
        return list;
    }

    // "weatherLocation" → "Weather location"
    function words(key: string): string {
        const w = String(key).replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[_-]+/g, " ").toLowerCase().trim();
        return w ? w[0].toUpperCase() + w.slice(1) : "";
    }

    // A value with no registry entry, short
    function plain(v: var): string {
        if (v === null || v === undefined)
            return Tr.trCtx("Default", "a setting's default value");
        if (typeof v === "boolean")
            return v ? Tr.tr("On") : Tr.tr("Off");
        if (Array.isArray(v)) {
            // caelestia4: a short list of words shows them ("kitty"), a longer one how many
            const shown = v.every(x => typeof x === "string" || typeof x === "number") ? v.join(", ") : "";
            if (v.length && shown.length && shown.length <= 40)
                return shown;
            return v.length ? Tr.trN("%n item", "%n items", v.length) : Tr.tr("Empty");
        }
        if (typeof v === "object")
            return Tr.tr("Edited");
        const t = String(v);
        if (!t.length)
            return Tr.tr("Empty");
        return t.length > 40 ? t.slice(0, 39) + "…" : t;
    }

    Component.onCompleted: root.refresh()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        RowGroup {
            Layout.fillWidth: true

            ActionRow {
                icon: "add"
                text: Tr.tr("Save current settings")
                subtext: Tr.tr("Keeps what you changed under a name, without passwords or keys")
                busy: root.busy
                onClicked: {
                    nameDialog.target = null;
                    nameDialog.open();
                }
            }
        }

        // Your profiles
        SectionHeader {
            text: Tr.tr("Your profiles")
        }

        RowGroup {
            Layout.fillWidth: true

            // Empty state
            ConnectedRect {
                Layout.fillWidth: true
                visible: root.loaded && root.saved.length === 0
                implicitHeight: empty.implicitHeight + Tokens.padding.extraLarge * 2

                ColumnLayout {
                    id: empty

                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.largeIncreased * 2
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "bookmarks"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Tr.tr("No profiles yet")
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Tr.tr("Save your settings to switch back to them later")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Repeater {
                model: root.saved

                ActionRow {
                    required property var modelData

                    icon: "bookmark"
                    text: modelData.name
                    // TRANSLATORS: a saved profile: how many settings it holds, then when it was saved
                    subtext: Tr.trN("%n setting", "%n settings", modelData.count) + " · " + root.when(modelData.created)
                    actionIcon: "edit"
                    actionText: Tr.tr("Rename")
                    action2Icon: "delete"
                    action2Text: Tr.trCtx("Delete", "button")
                    busy: root.busy
                    Accessible.description: Tr.tr("Apply this profile")
                    onClicked: root.preview(modelData)
                    onActionClicked: {
                        nameDialog.target = modelData;
                        nameDialog.open();
                    }
                    onAction2Clicked: {
                        root.current = modelData;
                        deleteConfirm.open();
                    }
                }
            }
        }

        // Backups: made by each apply
        SectionHeader {
            visible: root.backups.length > 0
            text: Tr.tr("Backups")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            visible: root.backups.length > 0
            text: Tr.tr("Your settings as they were before a profile was applied. The last 10 are kept.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        RowGroup {
            Layout.fillWidth: true
            visible: root.backups.length > 0

            Repeater {
                model: root.backups

                ActionRow {
                    required property var modelData

                    icon: "history"
                    text: modelData.name
                    subtext: Tr.trN("%n setting", "%n settings", modelData.count)
                    actionIcon: "bookmark_add"
                    actionText: Tr.tr("Keep as a profile")
                    action2Icon: "delete"
                    action2Text: Tr.trCtx("Delete", "button")
                    busy: root.busy
                    Accessible.description: Tr.tr("Apply this backup")
                    onClicked: root.preview(modelData)
                    onActionClicked: {
                        nameDialog.target = modelData;
                        nameDialog.open();
                    }
                    onAction2Clicked: {
                        root.current = modelData;
                        deleteConfirm.open();
                    }
                }
            }
        }

        // caelestia4: an apply (or its undo) done: the list has a new backup
        Connections {
            function onFinished(): void {
                root.refresh();
            }

            target: ProfileApply
        }

        Process {
            id: listProc

            command: [root.script, "list"]
            stdout: StdioCollector {
                id: listOut
            }
            onExited: code => {
                try {
                    root.profiles = code === 0 ? JSON.parse(listOut.text) : [];
                } catch (e) {
                    root.profiles = [];
                }
                root.loaded = true;
            }
        }

        Process {
            id: runner

            property var done: null

            stdout: StdioCollector {
                id: runOut
            }
            stderr: StdioCollector {
                id: runErr
            }
            onExited: code => {
                if (code !== 0)
                    console.warn(`Nexus: profiles: ${runner.command[1]} failed (${code}): ${runErr.text.trim()}`);
                const fn = runner.done;
                runner.done = null;
                fn?.(code, runOut.text);
            }
        }

        // Save (target null) or rename: the name
        NexusDialog {
            id: nameDialog

            property var target: null
            readonly property string name: nameField.text.trim()

            title: target ? (target.backup ? Tr.tr("Keep as a profile") : Tr.tr("Rename profile")) : Tr.tr("Save current settings")
            acceptText: Tr.trCtx("Save", "button")
            acceptEnabled: name.length > 0 && !root.nameTaken(name, target?.id ?? "") && !(target && !target.backup && name === target.name)
            initialFocus: nameField

            onOpenedChanged: {
                if (opened) {
                    nameField.text = target && !target.backup ? target.name : "";
                    nameField.selectAll();
                }
            }
            onAccepted: target ? root.rename(target, name) : root.save(name)

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Passwords and keys are never saved in a profile.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            StyledTextField {
                id: nameField

                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                placeholderText: Tr.tr("Name")
                // TRANSLATORS: a sample profile name
                supportingText: Tr.tr("e.g. Work, Gaming, Evening")
                errorText: root.nameOwner(nameDialog.name, nameDialog.target?.id ?? "")?.backup ? Tr.tr("A backup has that name") : Tr.tr("A profile with that name exists")
                isError: nameDialog.name.length > 0 && root.nameTaken(nameDialog.name, nameDialog.target?.id ?? "")
                maximumLength: 80
                onAccepted: nameDialog.accept()
            }
        }

        ConfirmDialog {
            id: deleteConfirm

            title: Tr.tr("Delete “%1”?").arg(root.current?.name ?? "")
            text: Tr.tr("The profile is deleted for good. Your settings now stay as they are.")
            confirmText: Tr.trCtx("Delete", "button")
            destructive: true
            onAccepted: root.remove(root.current)
        }

        // What applying changes, then Apply
        NexusDialog {
            id: applyDialog

            title: Tr.tr("Apply “%1”?").arg(root.current?.name ?? "")
            acceptText: Tr.trCtx("Apply", "button")
            tall: root.changes.length > 4
            onAccepted: root.apply(root.current)

            StyledText {
                Layout.fillWidth: true
                text: Tr.trN("%n setting changes. Your current settings are saved as a backup first, so you can undo this.", "%n settings change. Your current settings are saved as a backup first, so you can undo this.", root.changes.length)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledListView {
                id: changeList

                Layout.fillWidth: true
                Layout.fillHeight: applyDialog.tall
                Layout.preferredHeight: applyDialog.tall ? -1 : contentHeight
                Layout.topMargin: Tokens.spacing.small
                clip: true
                spacing: Tokens.spacing.small
                model: root.changes
                boundsBehavior: Flickable.StopAtBounds

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: changeList
                }

                delegate: ColumnLayout {
                    id: change

                    required property var modelData

                    readonly property RowSetting link: RowSetting {
                        sid: change.modelData.sid
                    }
                    // A null value is the setting's default
                    function text(v: var): string {
                        if (!change.modelData.sid)
                            return "";
                        const shown = link.format(v === null ? link.s.defaultValue : v);
                        return shown || Tr.trCtx("Default", "a setting's default value");
                    }

                    readonly property string fromText: modelData.sid ? text(modelData.oldValue) : modelData.from
                    readonly property string toText: modelData.sid ? text(modelData.newValue) : modelData.to

                    width: changeList.width - Tokens.padding.medium
                    spacing: 0

                    // The setting, then where it lives
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.maximumWidth: change.width * 0.6
                            text: change.modelData.title
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: change.modelData.place
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        // TRANSLATORS: a setting a profile changes: %1 its value now, %2 its value after (e.g. "Off → On")
                        text: change.fromText === change.toText ? Tr.tr("Edited: %1").arg(change.toText) : Tr.trCtx("%1 → %2", "value now → value after").arg(change.fromText).arg(change.toText)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
