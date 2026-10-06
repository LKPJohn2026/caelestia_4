pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.models.quickToggles as E4QT // caelestia4: keep
import qs.modules.caelestia.nexus
import qs.modules.caelestia.bar.popouts as BarPopouts

// caelestia4: Caelestia's quick toggles + every end-4 quick toggle (driven by end-4's toggle models),
// with tooltips, right-click actions, an edit mode (click = show/hide, scroll = move; saved to
// caelestia.quickToggles in the end-4 config) and an "Eye protection" panel (right-click night light /
// anti-flashbang) that replaces end-4's night light dialog.
StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    property bool editMode: false
    property bool eyeProtectionOpen: false
    property bool warpAvailable: false

    readonly property int maxPerRow: 6

    // Every toggle this machine can show, in default order
    readonly property list<string> availableIds: {
        const ids = [];
        for (const item of Config.utilities.quickToggles.values) {
            if (ids.includes(item.id))
                continue;
            if (item.id === "vpn" && GlobalConfig.utilities.vpn.selectedProvider.length === 0)
                continue;
            ids.push(item.id);
        }
        const extras = ["nightLight", "easyEffects", "darkMode", "powerProfile", "idleInhibitor", "antiFlashbang", "musicRecognition", "onScreenKeyboard", "screenSnip", "colorPicker", "backgroundMute", "cloudflareWarp"];
        for (const id of extras) {
            if (id === "easyEffects" && !E4.EasyEffects.available)
                continue;
            if (id === "cloudflareWarp" && !root.warpAvailable)
                continue;
            if (!ids.includes(id))
                ids.push(id);
        }
        return ids;
    }

    // Saved order/visibility (end-4 config) merged with what is available; toggles not saved yet are appended.
    // Without a saved list, Caelestia's own toggles follow Caelestia's enabled flags and the end-4 extras are shown.
    readonly property var entries: {
        const saved = E4C.Config.options.caelestia.quickToggles ?? [];
        const caelestiaItems = Config.utilities.quickToggles.values;
        const out = [];
        for (const s of saved) {
            if (root.availableIds.includes(s.id) && !out.some(o => o.id === s.id))
                out.push({
                    id: s.id,
                    enabled: s.enabled !== false
                });
        }
        for (const id of root.availableIds) {
            if (out.some(o => o.id === id))
                continue;
            const caelestiaItem = caelestiaItems.find(i => i.id === id);
            out.push({
                id: id,
                enabled: saved.length > 0 || !caelestiaItem || caelestiaItem.enabled
            });
        }
        return out;
    }

    readonly property var shown: editMode ? entries : entries.filter(e => e.enabled)
    readonly property int rowCount: Math.max(1, Math.ceil(shown.length / maxPerRow))
    readonly property int perRow: Math.max(1, Math.ceil(shown.length / rowCount))

    function rowItems(row: int): var {
        const items = shown.slice(row * perRow, (row + 1) * perRow);
        // Pad short rows with invisible spacers so every button keeps the same width
        while (items.length > 0 && items.length < perRow)
            items.push({
                id: "_spacer",
                enabled: false
            });
        return items;
    }

    function save(list: var): void {
        E4C.Config.options.caelestia.quickToggles = list.map(e => ({
                    id: e.id,
                    enabled: e.enabled
                }));
    }

    function toggleShown(id: string): void {
        save(entries.map(e => e.id === id ? {
                id: e.id,
                enabled: !e.enabled
            } : e));
    }

    function move(id: string, delta: int): void {
        const list = entries.slice();
        const i = list.findIndex(e => e.id === id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= list.length)
            return;
        const tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
        save(list);
    }

    Component.onCompleted: {
        E4.EasyEffects.fetchAvailability(); // caelestia4: end-4 only fetches this from its own toggle
        E4.Hyprsunset.fetchState();
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v warp-cli"]
        onExited: code => root.warpAvailable = code === 0
    }

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.editMode ? Tr.tr("Click to show/hide · scroll to move") : Tr.tr("Quick toggles")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            IconButton {
                type: IconButton.Text
                icon: root.editMode ? "check" : "edit"
                onClicked: root.editMode = !root.editMode
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: root.editMode ? Tr.tr("Done") : Tr.tr("Edit quick toggles")
            }
        }

        Repeater {
            model: root.rowCount

            QuickToggleRow {
                required property int index

                items: root.rowItems(index)
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.eyeProtectionOpen
            visible: active

            sourceComponent: EyeProtection {
                onCloseRequested: root.eyeProtectionOpen = false
            }
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias items: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "_spacer"
                    delegate: Toggle {
                        disabled: true
                        icon: "check_box_outline_blank"
                    }
                }
                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        tip: Tr.tr("Wi-Fi")
                        checked: Nmcli.wifiEnabled
                        onActivated: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        tip: Tr.tr("Bluetooth")
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onActivated: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        tip: Tr.tr("Microphone")
                        checked: !Audio.sourceMuted
                        onActivated: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        tip: Tr.tr("Caelestia settings")
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onActivated: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        tip: Tr.tr("Game mode")
                        checked: GameMode.enabled
                        onActivated: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        tip: Tr.tr("Do not disturb")
                        checked: Notifs.dnd
                        onActivated: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        tip: Tr.tr("VPN")
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onActivated: VPN.toggle()
                    }
                }
                // ---- end-4 toggles, driven by end-4's QuickToggleModel objects
                DelegateChoice {
                    roleValue: "nightLight"
                    delegate: ModelToggle {
                        toggleModel: E4QT.NightLightToggle {}
                        tip: Tr.tr("Night light · right-click for eye protection settings")
                        secondaryAction: () => root.eyeProtectionOpen = !root.eyeProtectionOpen
                    }
                }
                DelegateChoice {
                    roleValue: "easyEffects"
                    delegate: ModelToggle {
                        toggleModel: E4QT.EasyEffectsToggle {}
                    }
                }
                DelegateChoice {
                    roleValue: "darkMode"
                    delegate: ModelToggle {
                        toggleModel: E4QT.DarkModeToggle {}
                    }
                }
                DelegateChoice {
                    roleValue: "powerProfile"
                    delegate: ModelToggle {
                        toggleModel: E4QT.PowerProfilesToggle {}
                        tip: Tr.tr("Power profile: %1 · click to cycle").arg(toggleModel.statusText)
                    }
                }
                DelegateChoice {
                    roleValue: "idleInhibitor"
                    delegate: ModelToggle {
                        toggleModel: E4QT.IdleInhibitorToggle {}
                    }
                }
                DelegateChoice {
                    roleValue: "antiFlashbang"
                    delegate: ModelToggle {
                        toggleModel: E4QT.AntiFlashbangToggle {}
                        tip: Tr.tr("%1 · click to cycle, right-click for settings").arg(toggleModel.tooltipText)
                        secondaryAction: () => root.eyeProtectionOpen = !root.eyeProtectionOpen
                    }
                }
                DelegateChoice {
                    roleValue: "musicRecognition"
                    delegate: ModelToggle {
                        toggleModel: E4QT.MusicRecognitionToggle {}
                        tip: Tr.tr("Identify music (%1) · right-click to switch source").arg(toggleModel.statusText)
                    }
                }
                DelegateChoice {
                    roleValue: "onScreenKeyboard"
                    delegate: ModelToggle {
                        toggleModel: E4QT.OnScreenKeyboardToggle {}
                    }
                }
                DelegateChoice {
                    roleValue: "screenSnip"
                    delegate: ModelToggle {
                        toggleModel: E4QT.ScreenSnipToggle {}
                        isToggle: false
                        closesDrawer: true
                    }
                }
                DelegateChoice {
                    roleValue: "colorPicker"
                    delegate: ModelToggle {
                        toggleModel: E4QT.ColorPickerToggle {}
                        isToggle: false
                        closesDrawer: true
                    }
                }
                DelegateChoice {
                    roleValue: "backgroundMute"
                    delegate: Toggle {
                        icon: "sports_esports"
                        tip: Tr.tr("Mute games in background")
                        checked: E4C.Config.options.caelestia.backgroundMute.enable
                        onActivated: E4C.Config.options.caelestia.backgroundMute.enable = !E4C.Config.options.caelestia.backgroundMute.enable
                    }
                }
                DelegateChoice {
                    roleValue: "cloudflareWarp"
                    delegate: ModelToggle {
                        toggleModel: E4QT.CloudflareWarpToggle {}
                    }
                }
            }
        }
    }

    // A toggle button: click = action (edit mode: show/hide), right-click = secondary, scroll in edit mode = move
    component Toggle: IconButton {
        id: toggle

        required property var modelData
        property string tip
        readonly property bool isSpacer: modelData.id === "_spacer"

        signal activated
        signal secondary

        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        inactiveOnColour: Colours.palette.m3onSurfaceVariant // also for one-shot buttons (default would be onPrimary)
        fillWidth: true
        isToggle: !root.editMode
        isRound: true
        shapeMorph: true
        opacity: isSpacer ? 0 : root.editMode && !modelData.enabled ? 0.35 : 1

        onClicked: {
            if (root.editMode)
                root.toggleShown(modelData.id);
            else
                activated();
        }

        ToolTip.visible: hovered && tip.length > 0 && !isSpacer
        ToolTip.delay: 500
        ToolTip.text: root.editMode ? Tr.tr("%1 · scroll to move").arg(tip) : tip

        TapHandler {
            acceptedButtons: Qt.RightButton
            enabled: !root.editMode && !toggle.isSpacer
            onTapped: toggle.secondary()
        }

        WheelHandler {
            enabled: root.editMode && !toggle.isSpacer
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.move(toggle.modelData.id, event.angleDelta.y > 0 || event.angleDelta.x > 0 ? -1 : 1)
        }
    }

    component ModelToggle: Toggle {
        id: modelToggle

        required property QtObject toggleModel // end-4 QuickToggleModel
        property bool closesDrawer: false // momentary actions that need the drawer out of the way (snip, colour picker)
        property var secondaryAction: toggleModel.altAction

        icon: toggleModel.icon
        tip: toggleModel.tooltipText.length > 0 ? toggleModel.tooltipText : toggleModel.name
        checked: toggleModel.toggled

        onActivated: {
            if (closesDrawer)
                root.screenState.utilities = false;
            toggleModel.mainAction();
        }
        onSecondary: {
            if (secondaryAction)
                secondaryAction();
        }
    }
}
