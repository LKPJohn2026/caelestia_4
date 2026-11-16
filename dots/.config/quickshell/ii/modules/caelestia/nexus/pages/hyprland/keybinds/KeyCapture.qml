pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: "press the new keys": click (or Enter) and the next key with its modifiers becomes `keys`. While it
// waits, Hyprland is in the empty "nexus-capture" submap (defined in custom/nexus-keybinds.lua), so shortcuts such as
// Super+Q reach this field instead of acting. Escape (Hyprland's own bind in that submap), a click elsewhere, closing
// the dialog or 10 s without a key cancel, and the submap is left
StyledRect {
    id: root

    required property KeyNames names
    required property KeybindsModel model
    // The keys chosen ("SUPER + SHIFT + W"), "" until one is pressed
    property string keys
    property string placeholder: Tr.tr("Click, then press the new keys")
    readonly property bool capturing: _capturing

    signal captured(keys: string)

    function start(): void {
        // caelestia4: without the submap the pressed keys would act on the desktop (Super+Q closing a window)
        if (root._capturing || !root.model.canApply)
            return;
        root._mods = "";
        root._capturing = true;
        root.forceActiveFocus();
        const fresh = !root.model.fileExists;
        root.model.ensureFile();
        // a new file: wait for Hyprland's reload to define the submap
        if (fresh)
            submapDelay.restart();
        else
            root._enterSubmap();
        timeout.restart();
    }

    function stop(): void {
        if (!root._capturing)
            return;
        root._capturing = false;
        root._mods = "";
        submapDelay.stop();
        timeout.stop();
        if (root._inSubmap) {
            root._inSubmap = false;
            Hypr.dispatch(`hl.dsp.submap("reset")`);
        }
    }

    function _enterSubmap(): void {
        if (!root._capturing)
            return;
        root._inSubmap = true;
        Hypr.dispatch(`hl.dsp.submap("nexus-capture")`);
    }

    property bool _capturing
    property bool _inSubmap
    // The modifiers held so far, shown while waiting ("Super + Shift + …")
    property string _mods

    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2
    Layout.fillWidth: true
    radius: Tokens.rounding.small
    color: root._capturing ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest
    border.width: root.activeFocus ? 2 : 1
    border.color: root._capturing || root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.keys ? Tr.tr("Keys: %1").arg(root.names.label(root.keys)) : root.placeholder
    Accessible.description: root._capturing ? Tr.tr("Waiting for keys") : ""

    onActiveFocusChanged: {
        if (!activeFocus)
            root.stop();
    }
    Component.onDestruction: root.stop()

    Keys.onPressed: event => {
        if (!root._capturing) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.start();
                event.accepted = true;
            }
            return;
        }
        event.accepted = true;
        // Escape alone cancels (outside Hyprland's submap, where Escape would not get here)
        if (event.key === Qt.Key_Escape && !(event.modifiers & (Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier))) {
            root.stop();
            return;
        }
        const k = root.names.fromEvent(event.key, event.modifiers, event.nativeScanCode);
        if (!k) {
            const mods = [];
            if (event.modifiers & Qt.MetaModifier || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)
                mods.push("SUPER");
            if (event.modifiers & Qt.ControlModifier || event.key === Qt.Key_Control)
                mods.push("CTRL");
            if (event.modifiers & Qt.AltModifier || event.key === Qt.Key_Alt)
                mods.push("ALT");
            if (event.modifiers & Qt.ShiftModifier || event.key === Qt.Key_Shift)
                mods.push("SHIFT");
            root._mods = mods.map(m => root.names.modNames[m]).join(" + ");
            timeout.restart();
            return;
        }
        root.keys = k;
        root.stop();
        root.captured(k);
    }
    Keys.onReleased: event => {
        if (root._capturing)
            event.accepted = true;
    }

    // Hyprland left the submap: Escape there (its bind), or anything else that reset it
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "submap" && event.data !== "nexus-capture" && root._inSubmap) {
                root._inSubmap = false;
                root.stop();
            }
        }

        target: Hyprland
    }

    Timer {
        id: submapDelay

        interval: 900
        onTriggered: root._enterSubmap()
    }

    Timer {
        id: timeout

        interval: 10000
        onTriggered: root.stop()
    }

    StateLayer {
        onClicked: root._capturing ? root.stop() : root.start()
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: root._capturing ? "radio_button_checked" : "keyboard"
            color: root._capturing ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                if (root._capturing)
                    return root._mods ? `${root._mods} + …` : Tr.tr("Press the new keys… (Esc cancels)");
                return root.keys ? root.names.label(root.keys) : root.placeholder;
            }
            color: root._capturing ? Colours.palette.m3onPrimaryContainer : (root.keys ? Colours.palette.m3onSurface : Colours.palette.m3outline)
            font: root.keys && !root._capturing ? Tokens.font.title.small : Tokens.font.body.small
            wrapMode: Text.WordWrap
        }
    }
}
