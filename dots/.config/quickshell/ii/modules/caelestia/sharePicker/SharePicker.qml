pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: the screen-share picker (xdg-desktop-portal-hyprland's custom_picker_binary) in Caelestia style.
// scripts/caelestia4/share-picker.py is what XDPH runs: it writes what can be shared to <dir>/request.json, calls
// `sharePicker open <dir>` and waits for <dir>/reply.json, which it checks against the request before telling XDPH.
//  - Screens as a map of the monitor layout (a live capture of a screen would show this dialog over it), windows with
//    live previews, workspaces, and a region (drawn with slurp once the dialog has closed).
//  - "Remember this choice" lets the app keep a restore token and share the same thing next time without asking.
//  - Arrows move, Enter shares, Esc or a click outside cancels; a double-click shares at once.
// One request at a time: a new one cancels the one still open.
Scope {
    id: root

    property string dir // the request being answered, kept after the reply so `pending` still says yes
    property bool active: false
    property var req: null // { outputs: [{name, x, y, w, h}], windows: [{handle, class, title, address}], workspaces: [{id, name, outputs}], allowToken }
    property var items: [] // flat, in keyboard order: [{ kind, value, label, sub, ... }]
    property int sel: -1
    property bool token: false
    property string dialogScreen

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") ?? ""
    readonly property string dialogOn: {
        const names = Screens.real.map(s => s.name);
        if (names.includes(dialogScreen))
            return dialogScreen;
        const focused = Hypr.focusedMonitor?.name ?? "";
        return names.includes(focused) ? focused : (names[0] ?? "");
    }
    readonly property var selected: sel >= 0 && sel < items.length ? items[sel] : null

    // Only the bridge's own directories: <runtime>/caelestia4-share-<random>, nothing else is read or written
    function validDir(d: string): bool {
        if (!runtimeDir || !d.startsWith(runtimeDir + "/caelestia4-share-"))
            return false;
        const leaf = d.slice(runtimeDir.length + 1);
        return /^caelestia4-share-[A-Za-z0-9_]+$/.test(leaf);
    }

    function load(text: string): void {
        let r;
        try {
            r = JSON.parse(text);
        } catch (e) {
            respond({ kind: "cancel" });
            return;
        }
        const outputs = Array.isArray(r?.outputs) ? r.outputs : [];
        const windows = Array.isArray(r?.windows) ? r.windows : [];
        const workspaces = Array.isArray(r?.workspaces) ? r.workspaces : [];
        req = { outputs, windows, workspaces, allowToken: r?.allowToken === true };
        token = req.allowToken;

        const list = [];
        for (const o of outputs)
            list.push({ kind: "screen", value: o.name, label: o.name, sub: `${o.w} × ${o.h}`, output: o });
        for (const w of windows) {
            const hw = Hyprland.toplevels.values.find(t => w.address && t.address === w.address);
            list.push({
                kind: "window",
                value: w.handle,
                label: w.title || w.class,
                sub: w.class,
                toplevel: hw?.wayland ?? null,
                icon: Quickshell.iconPath(E4.AppSearch.guessIcon(w.class), "image-missing")
            });
        }
        for (const ws of workspaces)
            list.push({ kind: "workspace", value: ws.id, label: ws.name.replace(/^special:/, ""), sub: ws.outputs.join(", ") });
        items = list;

        // Start on the focused monitor
        const focused = Hypr.focusedMonitor?.name ?? "";
        const i = list.findIndex(it => it.kind === "screen" && it.value === focused);
        sel = i >= 0 ? i : (list.length > 0 ? 0 : -1);
        dialogScreen = focused;
        active = true;
    }

    function respond(obj: var): void {
        if (!dir)
            return;
        replyFile.setText(JSON.stringify(obj));
        active = false;
        items = [];
        sel = -1;
    }

    function share(): void {
        const it = selected;
        if (it)
            respond({ kind: it.kind, value: it.value, token: root.token });
    }

    function pickRegion(): void {
        respond({ kind: "pick-region", token: root.token });
    }

    function move(d: int): void {
        const n = items.length;
        if (n > 0)
            sel = sel < 0 ? 0 : ((sel + d) % n + n) % n;
    }

    FileView {
        id: requestFile

        path: root.dir ? `${root.dir}/request.json` : ""
        printErrors: false
        onLoaded: root.load(text())
        onLoadFailed: root.respond({ kind: "cancel" })
    }

    FileView {
        id: replyFile

        path: root.dir ? `${root.dir}/reply.json` : ""
        printErrors: false
        watchChanges: false
    }

    Loader {
        active: root.active

        sourceComponent: Variants {
            model: Screens.real

            StyledWindow {
                id: win

                required property ShellScreen modelData
                readonly property bool hasDialog: modelData.name === root.dialogOn

                screen: modelData
                name: "sharePicker"
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: hasDialog ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.palette.m3scrim, 0.5)
                    opacity: 0
                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                // A click outside cancels
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.respond({ kind: "cancel" })
                }

                Loader {
                    anchors.centerIn: parent
                    active: win.hasDialog
                    sourceComponent: dialogComp
                }
            }
        }
    }

    Component {
        id: dialogComp

        StyledRect {
            id: dialog

            readonly property int cardWidth: 260
            readonly property int thumbWidth: cardWidth - Tokens.padding.medium * 2
            readonly property int thumbHeight: Math.round(thumbWidth * 9 / 16)
            readonly property var screens: root.items.map((it, i) => ({ it, i })).filter(e => e.it.kind === "screen")
            readonly property var windows: root.items.map((it, i) => ({ it, i })).filter(e => e.it.kind === "window")
            readonly property var workspaces: root.items.map((it, i) => ({ it, i })).filter(e => e.it.kind === "workspace")

            implicitWidth: Math.max(560, Math.min(4, Math.max(1, windows.length)) * (cardWidth + Tokens.spacing.medium) - Tokens.spacing.medium) + Tokens.padding.extraLarge * 2
            implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surface
            focus: true

            scale: 0.92
            opacity: 0
            Component.onCompleted: {
                scale = 1;
                opacity = 1;
                forceActiveFocus();
            }

            Behavior on scale {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Right:
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    root.move(1);
                    break;
                case Qt.Key_Left:
                case Qt.Key_Up:
                case Qt.Key_Backtab:
                    root.move(-1);
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.share();
                    break;
                case Qt.Key_Escape:
                    root.respond({ kind: "cancel" });
                    break;
                default:
                    return;
                }
                event.accepted = true;
            }

            // Clicks inside the dialog don't cancel
            MouseArea {
                anchors.fill: parent
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: 3
            }

            ColumnLayout {
                id: layout

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraLarge
                spacing: Tokens.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "screen_share"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: Tr.tr("Share your screen")
                            font: Tokens.font.title.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("An app wants to see your screen. Choose what it can see.")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                StyledFlickable {
                    id: flick

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(sections.implicitHeight, (QsWindow.window?.height ?? 900) * 0.6)
                    contentHeight: sections.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: sections

                        width: flick.width
                        spacing: Tokens.spacing.large

                        // ---- screens: the monitor layout, to scale ----
                        SectionLabel {
                            visible: dialog.screens.length > 0
                            text: Tr.tr("Screens")
                        }

                        Item {
                            id: map

                            readonly property var outs: dialog.screens.map(e => e.it.output)
                            readonly property int minX: outs.length > 0 ? Math.min(...outs.map(o => o.x)) : 0
                            readonly property int minY: outs.length > 0 ? Math.min(...outs.map(o => o.y)) : 0
                            readonly property int spanW: outs.length > 0 ? Math.max(1, Math.max(...outs.map(o => o.x + o.w)) - minX) : 1
                            readonly property int spanH: outs.length > 0 ? Math.max(1, Math.max(...outs.map(o => o.y + o.h)) - minY) : 1
                            readonly property real k: Math.min(width / spanW, 140 / spanH)

                            visible: dialog.screens.length > 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(spanH * k)

                            Repeater {
                                model: dialog.screens

                                delegate: Choice {
                                    id: scard

                                    required property var modelData

                                    entry: modelData
                                    x: Math.round((map.width - map.spanW * map.k) / 2 + (modelData.it.output.x - map.minX) * map.k) + 2
                                    y: Math.round((modelData.it.output.y - map.minY) * map.k) + 2
                                    width: Math.round(modelData.it.output.w * map.k) - 4
                                    height: Math.round(modelData.it.output.h * map.k) - 4

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 0

                                        MaterialIcon {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "desktop_windows"
                                            color: scard.isSel ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.medium
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: scard.modelData.it.label
                                            color: scard.isSel ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            font: Tokens.font.label.medium
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: scard.modelData.it.sub
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.body.small
                                        }
                                    }
                                }
                            }
                        }

                        // ---- windows: live previews ----
                        SectionLabel {
                            visible: dialog.windows.length > 0
                            text: Tr.tr("Windows")
                        }

                        Grid {
                            visible: dialog.windows.length > 0
                            columns: Math.max(1, Math.floor((sections.width + Tokens.spacing.medium) / (dialog.cardWidth + Tokens.spacing.medium)))
                            spacing: Tokens.spacing.medium

                            Repeater {
                                model: dialog.windows

                                delegate: Choice {
                                    id: wcard

                                    required property var modelData

                                    entry: modelData
                                    implicitWidth: dialog.cardWidth
                                    implicitHeight: wcontent.implicitHeight + Tokens.padding.medium * 2

                                    ColumnLayout {
                                        id: wcontent

                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.medium
                                        spacing: Tokens.spacing.small

                                        ClipRect {
                                            Layout.preferredWidth: dialog.thumbWidth
                                            Layout.preferredHeight: dialog.thumbHeight
                                            radius: Tokens.rounding.medium
                                            color: Colours.tPalette.m3surfaceContainerHigh

                                            ScreencopyView {
                                                id: preview

                                                // Stop capturing when the window closes meanwhile: capturing a dead
                                                // toplevel crashes Quickshell (see windowSwitcher)
                                                readonly property var toplevel: wcard.modelData.it.toplevel
                                                readonly property bool alive: toplevel !== null && ToplevelManager.toplevels.values.indexOf(toplevel) >= 0
                                                readonly property real k: sourceSize.width > 0 && sourceSize.height > 0 ? Math.min(dialog.thumbWidth / sourceSize.width, dialog.thumbHeight / sourceSize.height) : 1

                                                anchors.centerIn: parent
                                                width: sourceSize.width > 0 ? sourceSize.width * k : dialog.thumbWidth
                                                height: sourceSize.height > 0 ? sourceSize.height * k : dialog.thumbHeight
                                                captureSource: root.active && alive ? toplevel : null
                                                live: true
                                                visible: alive && hasContent
                                            }

                                            IconImage {
                                                anchors.centerIn: parent
                                                visible: !preview.visible
                                                source: wcard.modelData.it.icon
                                                implicitSize: Math.round(dialog.thumbHeight * 0.4)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Tokens.spacing.small

                                            IconImage {
                                                source: wcard.modelData.it.icon
                                                implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: wcard.modelData.it.label
                                                color: wcard.isSel ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                elide: Text.ElideRight
                                                font: Tokens.font.label.medium
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---- workspaces ----
                        SectionLabel {
                            visible: dialog.workspaces.length > 0
                            text: Tr.tr("Workspaces")
                        }

                        Flow {
                            visible: dialog.workspaces.length > 0
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            Repeater {
                                model: dialog.workspaces

                                delegate: Choice {
                                    id: wschip

                                    required property var modelData

                                    entry: modelData
                                    radius: Tokens.rounding.full
                                    implicitWidth: wsRow.implicitWidth + Tokens.padding.large * 2
                                    implicitHeight: wsRow.implicitHeight + Tokens.padding.small * 2

                                    RowLayout {
                                        id: wsRow

                                        anchors.centerIn: parent
                                        spacing: Tokens.spacing.small

                                        MaterialIcon {
                                            text: "workspaces"
                                            color: wschip.isSel ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        StyledText {
                                            text: wschip.modelData.it.label
                                            color: wschip.isSel ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            font: Tokens.font.label.medium
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledSwitch {
                        id: remember

                        value: root.token
                        onToggled: root.token = checked
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Remember this choice for the app")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.token = !root.token
                        }
                    }

                    TextButton {
                        type: TextButton.Tonal
                        text: Tr.tr("Region…")
                        visible: dialog.screens.length > 0
                        onClicked: root.pickRegion()
                    }

                    TextButton {
                        type: TextButton.Text
                        text: Tr.tr("Cancel")
                        onClicked: root.respond({ kind: "cancel" })
                    }

                    TextButton {
                        type: TextButton.Filled
                        text: Tr.tr("Share")
                        disabled: !root.selected
                        onClicked: root.share()
                    }
                }
            }
        }
    }

    // A section heading inside the dialog
    component SectionLabel: StyledText {
        Layout.fillWidth: true
        color: Colours.palette.m3primary
        font: Tokens.font.label.large
    }

    // One thing that can be shared: selected with a click or the arrows, shared with a double-click
    component Choice: StyledRect {
        id: choice

        property var entry // { it, i }
        readonly property bool isSel: entry?.i === root.sel

        radius: Tokens.rounding.large
        color: isSel ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
        border.width: isSel ? 2 : 0
        border.color: Colours.palette.m3primary

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sel = choice.entry.i
            onDoubleClicked: {
                root.sel = choice.entry.i;
                root.share();
            }
        }
    }

    IpcHandler {
        target: "sharePicker"

        // Show the picker for the request in <dir>; "ok", or "invalid" for a directory that isn't the bridge's
        function open(dir: string): string {
            if (!root.validDir(dir))
                return "invalid";
            // One at a time: an older request still open is dropped, its bridge sees `pending` say no and cancels
            root.active = false;
            root.req = null;
            root.dir = dir;
            requestFile.reload();
            return "ok";
        }

        // "yes" while <dir> is the current request (answered or not), "no" once another one replaced it
        function pending(dir: string): string {
            return dir === root.dir ? "yes" : "no";
        }

        // The bridge gave up (timeout): close without answering
        function cancel(dir: string): void {
            if (dir === root.dir) {
                root.active = false;
                root.items = [];
                root.sel = -1;
                root.dir = "";
            }
        }
    }
}
