pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// Add or edit a VPN provider. editingVpnIndex (-1 = add) is read from NexusState.
PageBase {
    id: root

    readonly property int editIndex: nState.editingVpnIndex
    readonly property bool editing: editIndex >= 0
    readonly property var existing: editing ? (VPN.providers[editIndex] ?? null) : null

    function splitCmd(arr: var): string {
        return arr?.join(" ") ?? "";
    }

    function joinCmd(str: string): var {
        const t = str.trim();
        return t.length > 0 ? t.split(/\s+/) : [];
    }

    function arrEq(a: var, b: var): bool {
        return a.length === b.length && a.every((x, i) => x === b[i]);
    }

    function submit(): void {
        const name = nameField.text.trim();
        if (name.length === 0) {
            nameField.isError = true;
            nameField.forceActiveFocus();
            return;
        }

        const data = {
            name: name,
            displayName: displayField.text.trim() || name,
            interface: interfaceField.text.trim(),
            connectCmd: joinCmd(connectField.text),
            disconnectCmd: joinCmd(disconnectField.text)
        };

        if (editing) {
            const needsReload = existing.id === VPN.selectedProvider && VPN.connected && (existing.name !== name || existing.interface !== data.interface || !arrEq(existing.connectCmd, data.connectCmd) || !arrEq(existing.disconnectCmd, data.disconnectCmd));
            if (needsReload)
                VPN.disconnect();
            VPN.updateProvider(editIndex, data);
            if (needsReload) {
                if (!VPN.connecting && !VPN.disconnecting) {
                    VPN.connect();
                } else if (VPN.disconnecting) {
                    let onConnChanged = () => {
                        if (onConnChanged && !VPN.disconnecting) {
                            VPN.disconnectingChanged.disconnect(onConnChanged);
                            onConnChanged = null;
                            if (!VPN.connected)
                                VPN.connect();
                        }
                    };
                    VPN.disconnectingChanged.connect(onConnChanged);
                }
            }
        } else {
            VPN.addProvider(data);
        }

        nState.closeSubPage();
    }

    title: editing ? Tr.tr("Edit VPN provider") : Tr.tr("Add VPN provider")
    isSubPage: true

    Component.onCompleted: {
        if (existing) {
            nameField.text = existing.name;
            displayField.text = existing.displayName;
            interfaceField.text = existing.interface;
            connectField.text = splitCmd(existing.connectCmd);
            disconnectField.text = splitCmd(existing.disconnectCmd);
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            // caelestia4: plain words for users; the four names are what nameField matches (adapters VPN). WireGuard has
            // no default interface (wireguardAdapter sets none), so it needs the Interface field
            // TRANSLATORS: product names; the lower-case ones are what the user types (exact match), leave them untranslated. wg0 is an example name
            text: Tr.tr("WARP, Tailscale and NetBird need no setup: name the provider warp, tailscale or netbird. For WireGuard, name it wireguard and enter its connection name, such as wg0, under Interface. For any other VPN, add the commands that turn it on and off.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: nameField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            placeholderText: Tr.tr("Provider name")
            leadingIcon: "vpn_key"
            // TRANSLATORS: "tailscale" is a product name typed as-is, leave it untranslated
            supportingText: Tr.tr("For example tailscale, or any name for another VPN")
            errorText: Tr.tr("Provider name is required")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: displayField.forceActiveFocus()
        }

        StyledTextField {
            id: displayField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Display name")
            // TRANSLATORS: the name shown in the VPN provider list on the network page
            supportingText: Tr.tr("Shown in the list")
            leadingIcon: "label"
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: interfaceField.forceActiveFocus()
        }

        StyledTextField {
            id: interfaceField

            Layout.fillWidth: true
            placeholderText: Tr.trCtx("Interface", "network interface")
            leadingIcon: "lan"
            // caelestia4: plain words; wg0 is the usual WireGuard name
            // TRANSLATORS: wg0 is an example name, leave it untranslated
            supportingText: Tr.tr("The connection's name on this computer, such as wg0. WireGuard needs it")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: connectField.forceActiveFocus()
        }

        SectionHeader {
            text: Tr.tr("Custom commands (optional)")
        }

        StyledTextField {
            id: connectField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Connect command")
            leadingIcon: "play_arrow"
            supportingText: Tr.tr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: disconnectField.forceActiveFocus()
        }

        StyledTextField {
            id: disconnectField

            Layout.fillWidth: true
            placeholderText: Tr.tr("Disconnect command")
            leadingIcon: "stop"
            supportingText: Tr.tr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: root.submit()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: (root.editing ? Tokens.spacing.medium : Tokens.spacing.extraSmall) - parent.spacing
            spacing: Tokens.spacing.small

            IconTextButton {
                visible: root.editing
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer
                iconLabel.fill: 1
                iconLabel.grade: 25
                icon: "delete_forever"
                text: Tr.tr("Delete")
                onClicked: {
                    if (root.existing.id === VPN.selectedProvider && VPN.connected)
                        VPN.disconnect();
                    VPN.deleteProvider(root.editIndex);
                    root.nState.closeSubPage();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ButtonRow {
                spacing: parent.spacing

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    type: TextButton.Tonal
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: root.nState.closeSubPage()
                }

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    text: root.editing ? Tr.trCtx("Save", "button") : Tr.trCtx("Add", "button")
                    disabled: !nameField.text.trim()
                    onClicked: root.submit()
                }
            }
        }
    }
}
