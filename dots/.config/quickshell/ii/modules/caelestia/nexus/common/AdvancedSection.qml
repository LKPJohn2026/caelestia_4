pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a collapsible group of rows: a header ("Advanced" and a chevron; Enter or Space toggles it) over a
// RowGroup of its children. Closed at first; NexusMemory remembers it open per page route and `key` while the shell
// runs. A route's "#key" (or a reason link) that names a row inside opens it first: PageBase.land() calls reveal().
// Put it in a page's RowGroup like a SectionHeader; the rows inside get their corners from their own group
ColumnLayout {
    id: root

    property string title: Tr.tr("Advanced")
    // Tells sections on one page apart in NexusMemory (default: the title)
    property string key
    property bool expanded
    // How many rows inside differ from their default, shown in the header while closed (rows with a setting)
    readonly property int modifiedCount: _modifiedCount
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
    readonly property string _memoryKey: _page ? `${_page.pageRoute}#${key || title}` : ""

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
    Layout.topMargin: Tokens.spacing.medium
    spacing: Tokens.spacing.small

    Timer {
        interval: 1000
        repeat: true
        running: !root.expanded && root.visible
        onTriggered: root._countModified()
    }

    StyledRect {
        id: header

        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: "transparent"

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.title
        Accessible.description: root.expanded ? Tr.trCtx("Expanded", "a collapsible section") : Tr.trCtx("Collapsed", "a collapsible section")
        Accessible.onPressAction: root.toggle()
        Keys.onSpacePressed: root.toggle()
        Keys.onReturnPressed: root.toggle()
        Keys.onEnterPressed: root.toggle()
        onActiveFocusChanged: {
            if (!activeFocus)
                ring.pointerFocus = false;
        }

        StateLayer {
            radius: header.radius
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
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
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
        implicitHeight: body.implicitHeight * progress
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
        }
    }
}
