pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.bar.components.status
import Quickshell.Services.Pipewire
import qs.services as E4 // caelestia4: keep

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // caelestia4: end-4 privacy indicators (computed here: end-4's Privacy service assigns lists to bools)
    readonly property bool micInUse: Pipewire.linkGroups.values.some(g => g.source?.type === PwNodeType.AudioSource && g.target?.type === PwNodeType.AudioInStream)
    readonly property bool screenCaptured: Pipewire.linkGroups.values.some(g => g.source?.type === PwNodeType.VideoSource)
    readonly property bool updatesPending: E4.Updates.available && E4.Updates.count > 0

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        if (entry.id === "privacy") // caelestia4
            return !root.micInUse && !root.screenCaptured;
        if (entry.id === "updates") // caelestia4
            return !root.updatesPending;
        return false;
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: iconColumn.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: iconColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.medium

        spacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                // caelestia4: privacy + updates are always offered (they collapse when idle) unless shell.json lists them
                values: {
                    const list = root.Config.bar.statusIcons.values;
                    const extras = ["privacy", "updates"].filter(id => !list.some(e => e.id === id)).map(id => ({
                                id: id,
                                enabled: true
                            }));
                    return [...extras, ...list].filter(e => e.enabled);
                }
            }

            DelegateChooser {
                role: "id"

                // caelestia4: privacy (mic / screen capture in use) and pending updates
                DelegateChoice {
                    roleValue: "privacy"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        Item {
                            clip: true
                            implicitWidth: privacyCol.implicitWidth
                            implicitHeight: (root.micInUse || root.screenCaptured) ? privacyCol.implicitHeight : 0

                            Column {
                                id: privacyCol
                                spacing: Tokens.spacing.extraSmall

                                MaterialIcon {
                                    visible: root.micInUse
                                    text: "mic"
                                    color: Colours.palette.m3error
                                    fontStyle: Tokens.font.icon.medium
                                    fill: 1
                                }

                                MaterialIcon {
                                    visible: root.screenCaptured
                                    text: "screen_record"
                                    color: Colours.palette.m3error
                                    fontStyle: Tokens.font.icon.medium
                                    fill: 1
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "updates"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        Item {
                            clip: true
                            implicitWidth: updCol.implicitWidth
                            implicitHeight: root.updatesPending ? updCol.implicitHeight : 0

                            Column {
                                id: updCol

                                MaterialIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    animate: true
                                    text: "system_update_alt"
                                    color: E4.Updates.updateStronglyAdvised ? Colours.palette.m3error : root.colour
                                    fontStyle: Tokens.font.icon.medium
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: E4.Updates.count
                                    color: root.colour
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: root.colour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        property real topGap: present && index !== root.firstPresent ? margin : 0
        property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()

        Layout.topMargin: Math.round(topGap)
        Layout.bottomMargin: Math.round(bottomGap)
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Behavior on topGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on bottomGap {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
