pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import Caelestia.I18n
import qs.modules.caelestia.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState
    // caelestia4: NavPane's mode: "full", "medium" (descriptions on the current and hovered items only), "rail"
    // (icons only, labels in tooltips) or "single"
    property string mode: "full"
    readonly property bool rail: mode === "rail"
    // The item Up/Down moved to (keyboard only; Enter opens it). -1: none
    property int keyIdx: -1
    // caelestia4: the settings search (set by Nexus.qml): its live values give each page's changed dot. Null: no dots
    property SearchIndex searchIndex

    function focusList(): void {
        keyIdx = nState.currentPageIdx;
        forceActiveFocus(Qt.TabFocusReason);
    }

    function moveKey(delta: int): void {
        const n = PageRegistry.pages.length;
        const from = keyIdx < 0 ? nState.currentPageIdx : keyIdx;
        keyIdx = Math.max(0, Math.min(n - 1, from + delta));
        ensureVisible(keyIdx);
    }

    function openKey(): void {
        if (keyIdx >= 0)
            open(keyIdx);
    }

    function open(idx: int): void {
        nState.currentPageIdx = idx;
        nState.navShown = false; // single-pane: show the page
    }

    // caelestia4: scrolls so the item at idx is fully in view (the current page was often below the fold)
    function ensureVisible(idx: int): void {
        const item = list.itemAt(idx);
        if (!item || height <= 0)
            return;
        // Clear of the edge fades, so the item is not shown faded
        const margin = Math.max(Tokens.spacing.medium, Math.min(height * fadeAmount, (height - item.height) / 2));
        let target = contentY;
        if (item.y - margin < contentY)
            target = item.y - margin;
        else if (item.y + item.height + margin > contentY + height)
            target = item.y + item.height + margin - height;
        target = Math.max(-topMargin, Math.min(target, contentHeight + bottomMargin - height));
        if (Math.abs(target - contentY) > 0.5) {
            scrollAnim.to = target;
            scrollAnim.restart();
        }
    }

    function ensureCurrentVisible(): void {
        ensureVisible(nState.currentPageIdx);
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.List
    Accessible.name: Tr.tr("Pages")

    onActiveFocusChanged: {
        if (!activeFocus)
            keyIdx = -1;
    }
    Keys.onUpPressed: moveKey(-1)
    Keys.onDownPressed: moveKey(1)
    Keys.onReturnPressed: openKey()
    Keys.onEnterPressed: openKey()
    Keys.onSpacePressed: openKey()

    onHeightChanged: Qt.callLater(ensureCurrentVisible)
    // caelestia4: medium mode: not while the pointer is over the list, as a hovered item grows (its description shows)
    // and scrolling back to the current page then would move the list under the mouse
    onContentHeightChanged: {
        if (mode !== "medium" || !listHover.hovered)
            Qt.callLater(ensureCurrentVisible);
    }
    Component.onCompleted: Qt.callLater(ensureCurrentVisible)

    HoverHandler {
        id: listHover
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            Qt.callLater(root.ensureCurrentVisible);
        }

        target: root.nState
    }

    Anim {
        id: scrollAnim

        target: root
        property: "contentY"
        type: Anim.DefaultEffects
    }

    TapHandler {
        onTapped: root.focus = true
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: list

            model: PageRegistry.pages

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: index === root.nState.currentPageIdx
                readonly property bool fullBadge: root.mode === "full" || root.mode === "single"
                readonly property bool isKeyItem: index === root.keyIdx && root.activeFocus
                // caelestia4: medium mode shows the description only on the current and hovered items
                readonly property bool showDesc: root.mode === "full" || root.mode === "single" || (root.mode === "medium" && (isCurrentPage || stateLayer.containsMouse || isKeyItem))
                readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1].category !== modelData.category
                readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1].category !== modelData.category
                // caelestia4: how many settings on this page differ from their defaults (the dot)
                readonly property int changedCount: root.searchIndex?.changedByPage[modelData.id] ?? 0
                readonly property string changedText: changedCount > 0 ? Tr.trN("%n changed setting", "%n changed settings", changedCount) : ""

                Layout.fillWidth: true
                Layout.topMargin: index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0
                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    return h % 2 === 0 ? h : h + 1;
                }

                color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                RadiusBehavior on topLeftRadius {}
                RadiusBehavior on topRightRadius {}
                RadiusBehavior on bottomLeftRadius {}
                RadiusBehavior on bottomRightRadius {}

                StateLayer {
                    id: stateLayer

                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    onClicked: root.open(item.index)
                }

                // caelestia4: Up/Down in the list moves this ring; Enter opens the item
                Rectangle {
                    anchors.fill: parent
                    z: 10
                    visible: item.isKeyItem
                    color: "transparent"
                    border.width: 2
                    border.color: Colours.palette.m3primary
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius
                }

                Accessible.role: Accessible.PageTab
                Accessible.name: item.modelData.label
                Accessible.description: item.changedText ? item.modelData.description + ". " + item.changedText : item.modelData.description
                Accessible.selected: item.isCurrentPage

                // caelestia4: the rail shows the label as a tooltip
                ToolTip.visible: root.rail && (stateLayer.containsMouse || item.isKeyItem)
                ToolTip.delay: stateLayer.containsMouse ? 300 : 0
                ToolTip.text: item.changedText ? item.modelData.label + "\n" + item.changedText : item.modelData.label

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: root.rail ? Tokens.padding.small : Tokens.padding.large
                    anchors.topMargin: root.mode === "medium" ? Tokens.padding.medium : anchors.margins
                    anchors.bottomMargin: root.mode === "medium" ? Tokens.padding.medium : anchors.margins
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        id: badge

                        // caelestia4: full mode: as high as the label and description; the other modes: a fixed size,
                        // as an item may have no description line
                        Layout.fillHeight: item.fullBadge
                        Layout.alignment: root.rail ? Qt.AlignHCenter : Qt.AlignVCenter
                        Layout.topMargin: item.fullBadge ? -1 : 0
                        Layout.bottomMargin: item.fullBadge ? -1 : 0
                        implicitWidth: item.fullBadge ? height : implicitHeight
                        implicitHeight: item.fullBadge ? 0 : badgeIcon.implicitHeight + (root.rail ? Tokens.padding.small : Tokens.padding.extraSmall) * 2

                        radius: Tokens.rounding.full
                        color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            id: badgeIcon

                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                            grade: 25
                            fill: item.modelData.noFill ? 0 : 1
                        }

                        // caelestia4: the rail's changed dot, on the badge's top right corner (ringed in the item's
                        // colour, so it shows on the current page's badge too)
                        Rectangle {
                            visible: root.rail && item.changedCount > 0
                            x: parent.width - width + 2
                            y: -2
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 5
                            color: Colours.palette.m3primary
                            border.width: 2
                            border.color: item.color
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !root.rail
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            font: Tokens.font.body.medium
                            wrapMode: Text.WordWrap // caelestia4: wrap, not elide, at narrow widths
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: item.showDesc
                            text: item.modelData.description
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    // caelestia4: the changed dot (as a row's modified dot), with its count as a tooltip
                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        visible: !root.rail && item.changedCount > 0
                        implicitWidth: 16
                        implicitHeight: 16

                        ToolTip.visible: dotHover.hovered
                        ToolTip.delay: 300
                        ToolTip.text: item.changedText

                        HoverHandler {
                            id: dotHover
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: Colours.palette.m3primary
                        }
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
