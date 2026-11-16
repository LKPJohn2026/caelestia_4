pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.registry

ColumnLayout {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    readonly property int cappedWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable

    default property Item contentChild

    // caelestia4: rows with a `setting` find their page by this (RowSetting walks up to it) and register here
    readonly property bool nexusPageBase: true
    // This page's own route: the first (stack index + 1) parts of nState.route ("panels/taskbar" for the Taskbar page
    // under "panels/taskbar/tray")
    readonly property string pageRoute: {
        const parts = (nState?.route ?? "").split("/");
        const idx = StackView.index;
        return idx < 0 ? (nState?.route ?? "") : parts.slice(0, idx + 1).join("/");
    }
    readonly property bool isCurrent: StackView.view ? StackView.status === StackView.Active : true
    // The registry settings on this page's route that differ from their default (the header's "Reset page")
    readonly property int modifiedCount: _modifiedCount

    // {settingId: RowSetting}: rows on this page with a setting
    property var _rows: ({})

    function registerRow(sid: string, link: var): void {
        root._rows[sid] = link;
        root._landSoon();
    }

    function unregisterRow(sid: string, link: var): void {
        if (root._rows[sid] === link)
            delete root._rows[sid];
    }

    // Scrolls the row of setting `sid` to a third from the top and pulses it. False if no row here has it
    function land(sid: string): bool {
        const link = root._rows[sid];
        const row = link?.row;
        if (!row || !flickable.contentItem)
            return false;
        // caelestia4: a row inside a closed AdvancedSection: open it, then scroll once the page has laid it out
        if (root._reveal(row)) {
            root._revealSid = sid;
            revealTimer.restart();
            return true;
        }
        return root._scrollTo(link);
    }

    // Opens the closed AdvancedSections around `row`; true when one was opened
    function _reveal(row: Item): bool {
        let opened = false;
        for (let p = row.parent; p && p !== root; p = p.parent) {
            if (p.nexusAdvancedSection && !p.expanded) {
                p.reveal();
                opened = true;
            }
        }
        return opened;
    }

    property string _revealSid

    Timer {
        id: revealTimer

        interval: 50
        onTriggered: {
            const link = root._rows[root._revealSid];
            if (link)
                root._scrollTo(link);
        }
    }

    function _scrollTo(link: var): bool {
        const row = link.row;
        const y = row.mapToItem(flickable.contentItem, 0, 0).y;
        const top = flickable.originY ?? 0;
        const max = top + Math.max(0, flickable.contentHeight + flickable.topMargin + flickable.bottomMargin - flickable.height) - flickable.topMargin;
        const target = Math.max(top - flickable.topMargin, Math.min(y - flickable.height / 3, max));
        scrollAnim.stop();
        scrollAnim.to = target;
        scrollAnim.start();
        link.pulse();
        return true;
    }

    // Resets every modified setting on this page's route, as one undo step, with Undo in the snackbar
    function resetPage(): void {
        const changed = [];
        for (let i = 0; i < pageSettings.count; i++) {
            const s = pageSettings.objectAt(i);
            if (s?.modified)
                changed.push(s);
        }
        if (!changed.length)
            return;
        const label = Tr.trN("Reset %n setting", "Reset %n settings", changed.length);
        const step = NexusActions.batch(label, () => {
            for (const s of changed) {
                const sid = s.sid;
                const old = JSON.parse(JSON.stringify(s.value ?? null));
                s.reset();
                NexusActions.record(label, () => NexusActions.writeSetting(sid, old));
            }
        });
        NexusActions.message(label, step ? Tr.trCtx("Undo", "snackbar button") : "", step ? () => NexusActions.undoStep(step) : null);
    }

    function _landSoon(): void {
        if (root.nState?.focusKey && root._rows[root.nState.focusKey])
            landTimer.restart();
    }

    function _tryLand(): void {
        const key = root.nState?.focusKey;
        if (!key || !root.isCurrent || !root._rows[key])
            return;
        if (root.land(key))
            root.nState.focusKey = "";
    }

    property int _modifiedCount
    // A string, so the Instantiator below is rebuilt only when the ids change (not on every route change)
    readonly property string _routeIds: Registry.idsOnRoute(pageRoute).filter(id => !id.startsWith("x:")).join("\n")

    function _recount(): void {
        let n = 0;
        for (let i = 0; i < pageSettings.count; i++)
            if (pageSettings.objectAt(i)?.modified)
                n++;
        root._modifiedCount = n;
    }

    onIsCurrentChanged: _landSoon()

    Connections {
        function onFocusKeyChanged(): void {
            root._landSoon();
        }

        target: root.nState
    }

    // After the page's push animation and layout
    Timer {
        id: landTimer

        interval: 350
        onTriggered: root._tryLand()
    }

    // One Setting per registry id on this route ("x:" ones need their row, so they are left out)
    Instantiator {
        id: pageSettings

        model: root._routeIds ? root._routeIds.split("\n") : []
        onObjectAdded: root._recount()
        onObjectRemoved: root._recount()

        Setting {
            required property string modelData

            sid: modelData
            screen: root.Config.screen
            onModifiedChanged: root._recount()
        }
    }

    spacing: Tokens.spacing.extraLargeIncreased

    MouseArea { // Prevent clicks from reaching flickable
        z: 1
        Layout.fillWidth: true
        implicitWidth: header.implicitWidth
        implicitHeight: header.implicitHeight - Layout.bottomMargin
        Layout.bottomMargin: -flickable.topMargin // Extra height to block clicks on flickable top margin
        onClicked: focus = true

        RowLayout {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.largeIncreased

            Loader {
                visible: active
                active: root.isSubPage
                asynchronous: true
                sourceComponent: IconButton {
                    icon: "arrow_back"
                    font: Tokens.font.icon.medium
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.nState.closeSubPage()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font: Tokens.font.title.large
                elide: Text.ElideRight
            }

            // caelestia4: "Reset page": shown while a setting on this page differs from its default
            IconButton {
                id: resetPageBtn

                visible: root.modifiedCount > 0
                icon: "restart_alt"
                font: Tokens.font.icon.medium
                type: IconButton.Text
                isRound: true
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                Accessible.name: Tr.tr("Reset page")
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: Tr.tr("Reset page")
                onClicked: {
                    resetConfirm.text = Tr.trN("%n setting on this page goes back to its default.", "%n settings on this page go back to their defaults.", root.modifiedCount);
                    resetConfirm.open();
                }
            }
        }
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        TapHandler {
            onTapped: flickable.focus = true
        }

        Anim {
            id: scrollAnim

            target: flickable
            property: "contentY"
            type: Anim.Emphasized
        }
    }

    ConfirmDialog {
        id: resetConfirm

        title: Tr.tr("Reset this page?")
        confirmText: Tr.trCtx("Reset", "button")
        destructive: true
        onAccepted: root.resetPage()
    }
}
