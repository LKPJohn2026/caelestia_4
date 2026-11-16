pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a titled group of rows that opens and closes: a card with the title, a one-line summary (e.g. "Inter ·
// 15 pt · Medium") and a chevron (Enter or Space toggles it), over a RowGroup of its children. For a page made of
// several like parts (Type scale's text styles); a page's own "Advanced" part is an AdvancedSection. Works as
// AdvancedSection does: closed at first, remembered open per page route and `key` while the shell runs (NexusMemory),
// and a route's "#key" (or a reason link) that names a row inside opens it first: PageBase.land() looks for
// `nexusAdvancedSection` and calls reveal()
ColumnLayout {
    id: root

    property string title
    property string summary
    // Tells groups on one page apart in NexusMemory (default: the title)
    property string key
    property bool expanded
    // How many rows inside differ from their default, shown in the header while closed (rows with a setting)
    readonly property int modifiedCount: _modifiedCount
    // PageBase.land() opens any closed item with this flag around the row it lands on
    readonly property bool nexusAdvancedSection: true
    readonly property alias group: body

    default property alias content: body.data

    // Opens without animation (a route landing on a row inside)
    function reveal(): void {
        root._instant = true;
        root.expanded = true;
        root._instant = false;
    }

    function toggle(): void {
        root.expanded = !root.expanded;
    }

    property bool _instant: true
    property int _modifiedCount
    property Item _page
    // Not the same keys as AdvancedSection's, so a group and a section can't share one
    readonly property string _memoryKey: _page ? `${_page.pageRoute}#group:${key || title}` : ""

    function _findPage(): Item {
        let p = root.parent;
        while (p && !p.nexusPageBase)
            p = p.parent;
        return p;
    }

    function _countModified(): void {
        let n = 0;
        // Rows are the items with a `setting` and a `link` (their marks and notes hold the link too: not counted)
        const walk = item => {
            for (const c of item.children) {
                if (typeof c.setting === "string" && c.link?.sid !== undefined) {
                    if (c.link.modified)
                        n++;
                } else {
                    walk(c);
                }
            }
        };
        walk(body);
        root._modifiedCount = n;
    }

    onExpandedChanged: {
        if (root._memoryKey)
            NexusMemory.setOpen(root._memoryKey, root.expanded);
    }

    on_MemoryKeyChanged: {
        if (root._memoryKey && NexusMemory.isOpen(root._memoryKey))
            root.reveal();
    }

    Component.onCompleted: {
        root._page = root._findPage();
        Qt.callLater(() => {
            if (!root)
                return;
            root._instant = false;
            root._countModified();
        });
    }

    Layout.fillWidth: true
    spacing: 0

    Timer {
        interval: 1000
        repeat: true
        running: !root.expanded && root.visible
        onTriggered: root._countModified()
    }

    ConnectedRect {
        id: header

        first: true
        last: true
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Tokens.padding.medium * 2

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.title
        Accessible.description: [root.summary, root.expanded ? Tr.trCtx("Expanded", "a collapsible section") : Tr.trCtx("Collapsed", "a collapsible section")].filter(s => s).join(". ")
        Accessible.onPressAction: root.toggle()
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()
        onActiveFocusChanged: {
            if (!activeFocus)
                ring.pointerFocus = false;
        }

        StateLayer {
            onPressed: {
                if (header.activeFocus)
                    ring.pointerFocus = true;
            }
            onClicked: root.toggle()
        }

        RowLayout {
            id: headerRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            Column {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.title
                    font: Tokens.font.title.small
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: text
                    text: root.summary
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }
            }

            StyledText {
                visible: !root.expanded && root.modifiedCount > 0
                text: Tr.trN("%n changed", "%n changed", root.modifiedCount)
                color: Colours.palette.m3primary
                font: Tokens.font.label.small
            }

            MaterialIcon {
                text: "expand_more"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        FocusRing {
            id: ring

            focusItem: header
        }
    }

    Item {
        id: clipper

        property real progress: root.expanded ? 1 : 0

        Layout.fillWidth: true
        // The gap above the rows and below them (before the next group) opens with them
        implicitHeight: (body.implicitHeight + Tokens.spacing.medium + Tokens.spacing.large) * progress
        visible: progress > 0
        clip: progress < 1
        opacity: progress

        Behavior on progress {
            enabled: !root._instant

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        RowGroup {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Tokens.spacing.medium
        }
    }
}
