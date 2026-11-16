pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (HyprlandConfig: which Hyprland options the shell overrides)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.registry
import "../../navpane"

// caelestia4: About > Changed settings (route about/changed): every registry setting that differs from its default,
// grouped by the page it lives on (with its path), each with "default → now", a reset button (one undo step) and a
// click that opens its row. "Reset all" asks first and is one undo step. Live values come from one Setting per
// option, as the settings search's is:changed does: c: and e4: options always, h: ones only while the shell
// overrides them. x: ids are left out: their row shows a c:/e4: option, which is listed itself
PageBase {
    id: root

    title: Tr.tr("Changed settings")
    isSubPage: true

    // ---- live values

    property int _rev
    readonly property var _plainIds: Object.keys(Registry.entries).filter(id => id.startsWith("c:") || id.startsWith("e4:"))
    readonly property var _hyprIds: {
        E4.HyprlandConfig.overridesRevision; // dependency
        return Object.keys(Registry.entries).filter(id => id.startsWith("h:") && E4.HyprlandConfig.isOverridden(id.slice(2)));
    }

    readonly property Instantiator plainSettings: Instantiator {

        model: root._plainIds
        onObjectAdded: root._bump()
        onObjectRemoved: root._bump()

        Setting {
            required property string modelData

            sid: modelData
            onModifiedChanged: root._bump()
        }
    }

    readonly property Instantiator hyprSettings: Instantiator {

        model: root._hyprIds
        onObjectAdded: root._bump()
        onObjectRemoved: root._bump()

        Setting {
            required property string modelData

            sid: modelData
            onModifiedChanged: root._bump()
        }
    }

    // Many changes at once (a reset, the first build) count as one
    function _bump(): void {
        _bumpTimer.restart();
    }

    readonly property Timer _bumpTimer: Timer {
        interval: 0
        onTriggered: root._rev++
    }

    // The modified Settings
    readonly property var changed: {
        root._rev; // dependency
        const out = [];
        for (const inst of [root.plainSettings, root.hyprSettings])
            for (let i = 0; i < inst.count; i++) {
                const s = inst.objectAt(i);
                if (s?.modified && s.entry)
                    out.push(s);
            }
        return out;
    }

    // [{route, crumbs, ids}] in page order, then route, then registry order
    readonly property var groups: {
        const order = Object.keys(Registry.entries);
        const byRoute = {};
        for (const s of root.changed)
            (byRoute[s.entry.route] = byRoute[s.entry.route] ?? []).push(s.sid);
        const pageIdx = route => {
            const i = PageRegistry.indexOf(route.split("/")[0]);
            return i < 0 ? 999 : i;
        };
        return Object.keys(byRoute).sort((a, b) => pageIdx(a) - pageIdx(b) || a.localeCompare(b)).map(route => ({
                    route,
                    crumbs: root.labels.routeLabels(route).join(" › "),
                    ids: byRoute[route].sort((a, b) => order.indexOf(a) - order.indexOf(b))
                }));
    }

    // Route labels as search shows them (no live values: `active` stays false)
    readonly property SearchIndex labels: SearchIndex {}

    function open(sid: string): void {
        const e = Registry.entry(sid);
        if (!e)
            return;
        const key = e.noRow ? "" : (e.shownBy ?? sid);
        root.nState.navigate(key ? `${e.route}#${key}` : e.route);
    }

    // caelestia4: one short line per value: the first line of a long text, cut to 40 characters with "…"
    function short(t: string): string {
        const lines = t.split("\n").filter(l => l.trim());
        const first = (lines[0] ?? "").trim();
        if (first.length > 40)
            return first.slice(0, 39).replace(/\s+$/, "") + "…";
        return lines.length > 1 ? first + " …" : first;
    }

    function resetAll(): void {
        const list = root.changed.slice();
        if (!list.length)
            return;
        const label = Tr.trN("Reset %n setting", "Reset %n settings", list.length);
        const step = NexusActions.batch(label, () => {
            for (const s of list) {
                const sid = s.sid;
                const old = JSON.parse(JSON.stringify(s.value ?? null));
                s.reset();
                NexusActions.record(label, () => NexusActions.writeSetting(sid, old));
            }
        });
        NexusActions.message(label, step ? Tr.trCtx("Undo", "snackbar button") : "", step ? () => NexusActions.undoStep(step) : null);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Summary and Reset all
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            visible: root.changed.length > 0
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: Tr.trN("%n setting differs from its default.", "%n settings differ from their defaults.", root.changed.length)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            TextButton {
                id: resetAllBtn

                type: TextButton.Tonal
                horizontalPadding: Tokens.padding.largeIncreased
                verticalPadding: Tokens.padding.medium
                text: Tr.tr("Reset all")
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: text
                onClicked: resetConfirm.open()
                Keys.onReturnPressed: resetConfirm.open()
                Keys.onEnterPressed: resetConfirm.open()
                Keys.onSpacePressed: resetConfirm.open()

                FocusRing {
                    focusItem: resetAllBtn
                }
            }
        }

        // Empty state
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: root.changed.length === 0
            implicitHeight: empty.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: empty

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "check_circle"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Tr.tr("Nothing changed")
                    font: Tokens.font.body.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Tr.tr("Every setting is at its default.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }
            }
        }

        Repeater {
            model: root.groups

            RowGroup {
                id: group

                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.topMargin: index > 0 ? Tokens.spacing.largeIncreased : 0

                SectionHeader {
                    Layout.topMargin: 0
                    text: group.modelData.crumbs
                }

                Repeater {
                    model: group.modelData.ids

                    ActionRow {
                        id: changedRow

                        required property string modelData
                        readonly property RowSetting link: RowSetting {
                            sid: changedRow.modelData
                        }

                        readonly property string fromText: root.short(link.format(link.s.defaultValue)) || Tr.trCtx("Default", "a setting's default value")
                        readonly property string nowText: root.short(link.format(link.value)) || "…"

                        text: link.title
                        // A list edited in place reads the same both ways ("2 items → 2 items")
                        // TRANSLATORS: a changed setting: %1 its default value, %2 its value now (e.g. "Off → On")
                        subtext: fromText === nowText ? Tr.tr("Edited: %1").arg(nowText) : Tr.trCtx("%1 → %2", "default value → value now").arg(fromText).arg(nowText)
                        subtextLines: 2
                        trailingIcon: "chevron_right"
                        actionIcon: "restart_alt"
                        actionText: link.resetTip
                        Accessible.description: Tr.tr("Changed: %1").arg(subtext)
                        onClicked: root.open(modelData)
                        onActionClicked: link.reset()
                    }
                }
            }
        }

        ConfirmDialog {
            id: resetConfirm

            title: Tr.tr("Reset all settings?")
            text: Tr.trN("%n setting goes back to its default. You can undo this.", "%n settings go back to their defaults. You can undo this.", root.changed.length)
            confirmText: Tr.trCtx("Reset", "button")
            destructive: true
            onAccepted: root.resetAll()
        }
    }
}
