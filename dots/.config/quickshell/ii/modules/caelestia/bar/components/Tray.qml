pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep (end-4 TrayService: pinned items)

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    // caelestia4: end-4's tray pinning (Config tray.pinnedItems / invertPinnedItems, TrayService). Pinned items are
    // always on the bar; the others sit behind the expand arrow, as in end-4's overflow (compact mode or not).
    // Middle-click an icon, or use the pin row on top of its menu, to pin / unpin it.
    readonly property var pinnedItems: E4.TrayService.pinnedItems.filter(i => root.shownInBar(i))
    readonly property var unpinnedItems: E4.TrayService.unpinnedItems.filter(i => root.shownInBar(i))
    readonly property var shownItems: expanded ? pinnedItems.concat(unpinnedItems) : pinnedItems

    function shownInBar(item: var): bool {
        return item.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(item.id);
    }

    readonly property real nonAnimHeight: {
        if (!Config.bar.tray.compact && !expandIcon.active)
            return layout.implicitHeight + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        const icon = expandIcon.active ? expandIcon.implicitHeight : 0;
        if (items.count > 0) // caelestia4: pinned items stay visible while collapsed
            return icon + layout.implicitHeight + (icon > 0 ? spacing : 0) + pad;
        return Math.max(Config.bar.tray.background ? width : 0, icon + pad);
    }

    clip: true
    visible: height > 0

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        spacing: Tokens.spacing.small


        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: root.shownItems
            }

            TrayItem {}
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.unpinnedItems.length > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
