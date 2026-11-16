pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.filedialog
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common

// caelestia4: a file or folder path: a text field (the home folder shows as "~") and a Browse button. `mode` "file"
// opens the shell's file dialog (components/filedialog, with `filters`: suffixes such as ["png", "jpg"], default any);
// "folder" opens FolderPickerDialog. Typed text saves on Enter or focus loss, with "~" written out as the home
// folder, only when the path exists (`mustExist`; "root:/…" shell assets are taken as they are); Esc puts the saved
// value back. A saved path that is gone gets a note. `thumbnail` shows a small preview of a picture. Entry fields
// read: `pathMode`, `filters`, `thumbnail`. Without `setting`, bind `value` and handle chosen(path)
SettingRow {
    id: root

    property string value: link.active ? String(link.value ?? "") : ""
    property string mode: link.entry?.pathMode ?? "file"
    property var filters: link.entry?.filters ?? ["*"]
    property string filterLabel: filters.indexOf("*") >= 0 ? Tr.tr("All files") : Tr.tr("Matching files")
    property bool mustExist: true
    property bool allowEmpty: true
    property bool thumbnail: link.entry?.thumbnail ?? false
    // caelestia4: an empty field says so in the placeholder style ("A file" read like a value)
    property string hint: mode === "folder" ? Tr.tr("No folder chosen") : Tr.tr("No file chosen")
    readonly property alias field: field
    readonly property bool missing: _missing && value.length > 0

    signal chosen(path: string)

    // "~/x" -> "/home/me/x"
    function expand(path: string): string {
        return String(path ?? "").trim().replace(/^~(?=\/|$)/, Paths.home);
    }

    // "/home/me/x" -> "~/x"
    function shorten(path: string): string {
        const p = String(path ?? "");
        return p === Paths.home ? "~" : p.startsWith(Paths.home + "/") ? "~" + p.slice(Paths.home.length) : p;
    }

    // Saves `path` (typed or picked) when it exists; else the field shows the error
    function commitPath(path: string): void {
        const p = root.expand(path);
        if (!p) {
            if (root.allowEmpty)
                root._write("");
            else
                field.fail();
            return;
        }
        if (!root.mustExist || p.startsWith("root:") || p.startsWith("qrc:")) {
            root._write(p);
            return;
        }
        root._pendingPath = p;
        commitCheck.command = root.mode === "folder" ? ["test", "-d", p] : ["test", "-e", p];
        commitCheck.running = true;
    }

    function browse(): void {
        if (root.link.blocked) {
            root.link.followReason();
            return;
        }
        const p = root.expand(root.value);
        if (root.mode === "folder") {
            // A folder that is gone opens the home folder instead
            folderDialog.openAt(p && !root.missing ? p : Paths.home);
            return;
        }
        // The file dialog's folder, as its parts ("Home" for the home folder)
        const dir = p.includes("/") ? p.slice(0, p.lastIndexOf("/")) : "";
        if (dir === Paths.home || dir.startsWith(Paths.home + "/"))
            fileDialog.cwd = ["Home", ...dir.slice(Paths.home.length).split("/").filter(s => s)];
        else if (dir.startsWith("/"))
            fileDialog.cwd = ["", ...dir.split("/").filter(s => s)];
        else
            fileDialog.cwd = ["Home"];
        fileDialog.open();
    }

    property string _pendingPath
    property bool _missing

    function _write(p: string): void {
        _errorShown = false;
        if (p !== root.value) {
            if (root.link.active)
                root.link.set(p);
            root.chosen(p);
        }
        field.settle();
    }

    property bool _errorShown

    function _checkValue(): void {
        const p = root.expand(root.value);
        if (!p || !root.mustExist || p.startsWith("root:") || p.startsWith("qrc:")) {
            root._missing = false;
            return;
        }
        valueCheck.command = ["test", "-e", p];
        valueCheck.running = true;
    }

    onValueChanged: _checkValue()
    Component.onCompleted: _checkValue()

    errorText: {
        if (root._errorShown)
            return root.mode === "folder" ? Tr.tr("There is no such folder") : Tr.tr("There is no such file");
        if (root.missing)
            return root.mode === "folder" ? Tr.tr("This folder doesn't exist any more") : Tr.tr("This file doesn't exist any more");
        return "";
    }
    focusItem: field

    Process {
        id: commitCheck

        onExited: code => {
            if (code === 0) {
                root._write(root._pendingPath);
            } else {
                root._errorShown = true;
                field.fail();
            }
        }
    }

    Process {
        id: valueCheck

        onExited: code => root._missing = code !== 0
    }

    Image {
        visible: root.thumbnail && !root.missing && status === Image.Ready
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        source: root.thumbnail && root.value ? (root.value.startsWith("/") ? "file://" + root.value : root.value) : ""
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    RowTextField {
        id: field

        Layout.fillWidth: root.controlBelow
        Layout.preferredWidth: root.controlBelow ? -1 : Tokens.sizes.nexus.textFieldWidth
        Layout.maximumWidth: root.controlBelow ? Number.POSITIVE_INFINITY : root.width / 2
        savedText: root.shorten(root.value)
        hint: root.hint
        Accessible.name: root.label
        Accessible.description: root.accessibleDescription
        onTextEdited: root._errorShown = false
        onCommit: text => root.commitPath(text)
    }

    IconButton {
        icon: root.mode === "folder" ? "folder_open" : "attach_file"
        type: IconButton.Tonal
        Accessible.name: Tr.tr("Browse")
        onClicked: root.browse()
    }

    FileDialog {
        id: fileDialog

        title: root.label || Tr.tr("Select a file")
        filters: root.filters
        filterLabel: root.filterLabel
        onAccepted: path => root.commitPath(path)
    }

    FolderPickerDialog {
        id: folderDialog

        title: root.label || Tr.tr("Choose a folder")
        onPicked: path => root.commitPath(path)
    }
}
