import QtQuick
import qs.modules.caelestia.adapters

// caelestia4: keyboard focus ring for Nexus rows: a 2px primary outline inset in its parent, following the parent's
// corner radii (a ConnectedRect). Shown only while `focusItem` has keyboard focus: a Control's focusReason must be
// Tab/Backtab; a plain item (no focusReason) only takes focus from Tab, unless the row sets `pointerFocus` when it
// takes focus for a click. When shown, the nearest Flickable scrolls so the row is in view
Rectangle {
    id: root

    property Item focusItem
    property bool pointerFocus
    readonly property bool show: {
        if (!focusItem?.activeFocus || pointerFocus)
            return false;
        const reason = focusItem.focusReason;
        return reason === undefined || reason === Qt.TabFocusReason || reason === Qt.BacktabFocusReason;
    }

    function ensureVisible(): void {
        const row = root.parent;
        let flick = row?.parent;
        while (flick && !("contentY" in flick && "flickableDirection" in flick))
            flick = flick.parent;
        if (!flick || !flick.contentItem)
            return;
        const y = row.mapToItem(flick.contentItem, 0, 0).y;
        const margin = 8;
        let target = flick.contentY;
        if (y - margin < flick.contentY)
            target = y - margin;
        else if (y + row.height + margin > flick.contentY + flick.height)
            target = y + row.height + margin - flick.height;
        const top = flick.originY ?? 0;
        target = Math.max(top, Math.min(target, top + flick.contentHeight - flick.height));
        if (Math.abs(target - flick.contentY) > 0.5)
            flick.contentY = target;
    }

    onShowChanged: {
        if (show)
            Qt.callLater(ensureVisible);
    }

    anchors.fill: parent
    z: 10
    visible: show
    color: "transparent"
    border.width: 2
    border.color: Colours.palette.m3primary

    // qmllint disable missing-property
    radius: parent?.radius ?? 0
    topLeftRadius: parent?.topLeftRadius ?? radius
    topRightRadius: parent?.topRightRadius ?? radius
    bottomLeftRadius: parent?.bottomLeftRadius ?? radius
    bottomRightRadius: parent?.bottomRightRadius ?? radius
    // qmllint enable missing-property
}
