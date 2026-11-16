pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: edits one shortcut (openFor) or makes a new one that runs a command (openNew). Keys a change brings back
// (new keys, turning it on, Reset to default) are checked against every working shortcut: a clash says which one and
// Save becomes "Replace", which turns that one off. One made outside Nexus can't be turned off, so its keys can't be
// taken. Nothing can be saved while changes don't take effect (model.canApply)
NexusDialog {
    id: root

    required property KeyNames names
    required property KeybindsModel model

    // The shortcut being edited (a nexus-keybinds.py list entry), null for a new one
    property var shortcut: null
    readonly property bool isNew: !shortcut
    readonly property bool isAdded: shortcut?.status === "added"
    // Read-only: made somewhere Nexus can't change (a plugin, another config file)
    readonly property bool readOnly: shortcut?.status === "other"
    property bool enabledShortcut: true
    readonly property string currentKeys: shortcut?.currentKeys ?? ""
    readonly property string newKeys: capture.keys !== currentKeys ? capture.keys : ""
    readonly property string submap: shortcut?.submap ?? ""
    readonly property bool universal: !!shortcut?.universal
    // Turned off now, switched back on in the dialog: its keys come back
    readonly property bool turningOn: !isNew && shortcut?.status === "disabled" && enabledShortcut && !newKeys
    readonly property string keysBack: newKeys || (turningOn ? currentKeys : "")
    readonly property var clash: keysBack ? model.conflict(keysBack, shortcut?.id ?? "", names, submap, universal) : null
    readonly property bool clashOutside: clash?.status === "other"
    // What Reset to default would clash with (its default keys back)
    readonly property bool canReset: !!shortcut && (shortcut.status === "changed" || shortcut.status === "disabled")
    readonly property var resetClash: canReset ? model.conflict(shortcut.keys, shortcut.id, names, submap, universal) : null
    // A shortcut inside a mode (such as virtual machine mode) keeps its keys: the mode's own messages name them
    readonly property bool inMode: submap !== ""
    readonly property bool canChangeKeys: shortcut?.source !== "other" && !(shortcut?.mouse ?? false) && !inMode

    function openFor(s: var): void {
        root.shortcut = s;
        root.enabledShortcut = s.status !== "disabled";
        capture.keys = s.currentKeys;
        root.open();
    }

    function openNew(): void {
        root.shortcut = null;
        root.enabledShortcut = true;
        capture.keys = "";
        nameField.text = "";
        commandField.text = "";
        root.open();
    }

    function _name(): string {
        return root.shortcut ? root.names.actionWords(root.shortcut) : nameField.text.trim();
    }

    title: isNew ? Tr.tr("New shortcut") : names.actionWords(shortcut ?? {})
    acceptText: clash ? Tr.trCtx("Replace", "button: give the keys to this shortcut") : Tr.trCtx("Save", "button")
    acceptEnabled: {
        if (readOnly || capture.capturing || !model.canApply || clashOutside)
            return false;
        if (isNew)
            return capture.keys.length > 0 && commandField.text.trim().length > 0 && nameField.text.trim().length > 0;
        return newKeys.length > 0 || enabledShortcut !== (shortcut?.status !== "disabled");
    }
    enterAccepts: !capture.activeFocus
    extraText: {
        if (!model.canApply)
            return "";
        if (isAdded)
            return Tr.trCtx("Remove", "button: delete this shortcut");
        if (canReset)
            return Tr.trCtx("Reset to default", "button");
        return "";
    }
    initialFocus: isNew ? nameField : capture

    onOpenedChanged: {
        if (!opened)
            capture.stop();
    }

    onExtraClicked: {
        const s = root.shortcut;
        root.close();
        if (root.isAdded)
            root.model.run(Tr.tr("Removed “%1”").arg(root._name()), ["remove", s.id]);
        else
            root.model.run(Tr.tr("Reset “%1”").arg(root._name()), ["reset", s.id, ...(root.resetClash && root.resetClash.status !== "other" ? ["--replace", root.resetClash.id] : [])]);
    }

    onAccepted: {
        const name = root._name();
        const replace = root.clash ? ["--replace", root.clash.id] : [];
        if (root.isNew) {
            root.model.run(Tr.tr("Added “%1”").arg(name), ["add", capture.keys, commandField.text.trim(), name, ...replace]);
            return;
        }
        const s = root.shortcut;
        if (!root.enabledShortcut) {
            root.model.run(Tr.tr("Turned off “%1”").arg(name), ["disable", s.id]);
            return;
        }
        if (root.newKeys) {
            root.model.run(Tr.tr("“%1” is now %2").arg(name).arg(root.names.label(root.newKeys)), ["remap", s.id, root.newKeys, ...replace]);
            return;
        }
        root.model.run(Tr.tr("Turned on “%1”").arg(name), ["enable", s.id, ...replace]);
    }

    // What it does and where it comes from
    StyledText {
        Layout.fillWidth: true
        visible: text.length > 0
        text: {
            const s = root.shortcut;
            if (!s)
                return Tr.tr("Runs a command or opens an app when you press the keys.");
            if (s.status === "other")
                return Tr.tr("Made outside Nexus (a plugin or another config file). It can't be changed here.");
            const parts = [];
            if (s.sameAs)
                parts.push(s.variant === "keypad" ? Tr.tr("The number pad twin of another shortcut.") : s.variant === "keycode" ? Tr.tr("Works on any keyboard layout, beside the shortcut with the same number.") : Tr.tr("A second shortcut for the same action."));
            if (s.status === "changed")
                parts.push(Tr.tr("Default: %1").arg(root.names.label(s.keys)));
            if (s.source === "custom")
                parts.push(Tr.tr("From your own shortcuts file."));
            if (s.status === "added")
                parts.push(Tr.tr("Added in Nexus."));
            if (s.mouse)
                parts.push(Tr.tr("A mouse shortcut: it can be turned off here, not moved."));
            else if (root.inMode)
                parts.push(Tr.tr("Part of a mode, such as virtual machine mode: it can be turned off here, not moved."));
            if (s.locked)
                parts.push(Tr.tr("Also works on the lock screen."));
            return parts.join(" ");
        }
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }

    StyledTextField {
        id: nameField

        visible: root.isNew
        Layout.fillWidth: true
        placeholderText: Tr.tr("Name")
        Accessible.name: placeholderText
    }

    StyledTextField {
        id: commandField

        visible: root.isNew
        Layout.fillWidth: true
        placeholderText: Tr.tr("Command or app to run")
        supportingText: Tr.tr("For example: firefox, or kitty -e btop")
        Accessible.name: placeholderText
    }

    KeyCapture {
        id: capture

        names: root.names
        model: root.model
        visible: root.canChangeKeys || root.isNew
        enabled: root.enabledShortcut && root.model.canApply
        opacity: enabled ? 1 : 0.5
    }

    // The keys as they are, for a shortcut whose keys can't change here
    StyledText {
        Layout.fillWidth: true
        visible: !capture.visible
        text: root.names.label(root.currentKeys)
        font: Tokens.font.title.small
        wrapMode: Text.WordWrap
    }

    // Clash with another working shortcut
    RowLayout {
        Layout.fillWidth: true
        visible: !!root.clash
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "warning"
            color: Colours.palette.m3error
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                if (!root.clash)
                    return "";
                const keys = root.names.label(root.keysBack);
                if (root.clashOutside)
                    return Tr.tr("%1 already does “%2”, made outside Nexus, which can't turn it off. Pick other keys.").arg(keys).arg(root.names.actionWords(root.clash));
                return Tr.tr("%1 already does “%2”. Replace turns that shortcut off; Cancel keeps both as they are.").arg(keys).arg(root.names.actionWords(root.clash));
            }
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }

    // Reset to default would bring back keys another shortcut has now
    RowLayout {
        Layout.fillWidth: true
        visible: !!root.resetClash && root.model.canApply && !root.clash
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "info"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                const c = root.resetClash;
                if (!c)
                    return "";
                const keys = root.names.label(root.shortcut?.keys ?? "");
                if (c.status === "other")
                    return Tr.tr("“%1” has %2 now, made outside Nexus: after Reset to default both run.").arg(root.names.actionWords(c)).arg(keys);
                return Tr.tr("“%1” has %2 now: Reset to default turns that shortcut off.").arg(root.names.actionWords(c)).arg(keys);
            }
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }

    // Changes don't take effect yet: nothing here can be saved
    StyledText {
        Layout.fillWidth: true
        visible: !root.model.canApply && !root.readOnly
        text: Tr.tr("Changes here don't work yet, so they can't be saved. Update the dotfiles first.")
        color: Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }

    // On / off (not for a new one, nor one made outside Nexus)
    RowLayout {
        Layout.fillWidth: true
        visible: !root.isNew && !root.readOnly && !root.isAdded && root.shortcut?.source !== "other"
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Shortcut on")
            font: Tokens.font.body.small
        }

        StyledSwitch {
            value: root.enabledShortcut
            Accessible.name: Tr.tr("Shortcut on")
            onToggled: root.enabledShortcut = checked
        }
    }
}
