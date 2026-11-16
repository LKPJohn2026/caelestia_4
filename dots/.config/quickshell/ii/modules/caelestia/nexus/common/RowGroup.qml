import QtQuick
import QtQuick.Layouts
import Caelestia.Config

// caelestia4: a column of Nexus rows that sets `first`/`last` on them itself, so the rounded corners stay right when
// rows are hidden or shown. A run of rows (items with both `first` and `last`: ConnectedRect rows, ToggleRow) is broken
// by anything else that takes space, e.g. a SectionHeader, which gets `first` when it is the column's first visible
// item. Rows a Repeater makes join the run around them. Rows' own `first:`/`last:` are overwritten here: leave them out
ColumnLayout {
    id: root

    spacing: Tokens.spacing.extraSmall / 2

    function relayout(): void {
        // Non-visual helpers (a Repeater, whose rows come right after it; an Instantiator's holder; a ConfirmDialog at
        // home) are visible but take no space: skip them, or they would split the run around a Repeater's rows
        const items = [];
        for (const c of root.children)
            if (c.visible && (("first" in c) || c.implicitHeight > 0 || c.height > 0))
                items.push(c);
        let runStart = -1;
        for (let i = 0; i <= items.length; i++) {
            const c = items[i];
            const isRow = !!c && "first" in c && "last" in c;
            if (isRow && runStart < 0)
                runStart = i;
            if (!isRow && runStart >= 0) {
                for (let j = runStart; j < i; j++) {
                    items[j].first = j === runStart;
                    items[j].last = j === i - 1;
                }
                runStart = -1;
            }
            if (c && !isRow && "first" in c)
                c.first = i === 0;
        }
    }

    property var _watched: []

    function _watch(): void {
        const watched = root._watched.filter(c => c && c.parent === root);
        for (const c of root.children) {
            if (watched.indexOf(c) < 0) {
                c.visibleChanged.connect(root._queue);
                // A helper that later takes space (a Loader that loads) starts breaking the run
                if (!("first" in c))
                    c.implicitHeightChanged.connect(root._queue);
                watched.push(c);
            }
        }
        root._watched = watched;
        root._queue();
    }

    property bool _pending

    // Children's signals stay connected to this (connect() below) and can fire while the page is torn down, after the
    // group is gone: `root` is null then
    function _queue(): void {
        if (!root || root._pending)
            return;
        root._pending = true;
        Qt.callLater(() => {
            // The group can be destroyed (page left) before this runs
            if (!root)
                return;
            root._pending = false;
            root.relayout();
        });
    }

    onChildrenChanged: _watch()
    Component.onCompleted: _watch()
    Component.onDestruction: {
        for (const c of root._watched) {
            if (!c)
                continue;
            c.visibleChanged.disconnect(root._queue);
            if (!("first" in c))
                c.implicitHeightChanged.disconnect(root._queue);
        }
    }
}
