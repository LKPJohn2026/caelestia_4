pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus

// caelestia4: the settings search's results (SearchIndex), shown in place of the nav list while the search has text
// (and under the rail's search overlay). Up/Down move, Enter or a click opens; opening clears the search
ColumnLayout {
    id: root

    required property NexusState nState
    required property SearchIndex searchIndex
    readonly property var results: searchIndex.results
    readonly property int count: results.list.length
    // The result Up/Down moved to; Enter opens it (or the first result when none)
    property int keyIdx: -1
    // The list's content height (for a container that sizes itself to the results)
    readonly property real listContentHeight: list.visible ? list.contentHeight : 0
    // caelestia4: the layout's search field has focus: the result Enter opens there is marked (the first, until Up/Down)
    property bool fieldFocused

    // After a result was opened (the layout moves focus away)
    signal opened

    // Focus moves to the list; the selection stays (none until Up/Down)
    function focusResults(): void {
        if (count === 0)
            return;
        if (keyIdx >= count)
            keyIdx = count - 1;
        list.forceActiveFocus(Qt.TabFocusReason);
    }

    // From no selection, either key selects the first result
    function moveKey(delta: int): void {
        if (count === 0)
            return;
        if (!list.activeFocus)
            focusResults();
        keyIdx = keyIdx < 0 ? 0 : Math.max(0, Math.min(count - 1, keyIdx + delta));
        list.positionViewAtIndex(keyIdx, ListView.Contain);
    }

    // Enter in the field or the list: the selected result, else the first
    function openKey(): void {
        if (count > 0)
            open(results.list[keyIdx >= 0 && keyIdx < count ? keyIdx : 0]);
    }

    function open(it: var): void {
        if (!it)
            return;
        // caelestia4: an option no row shows opens its page at the top (no #key left set with nothing to land on)
        if (it.kind === "setting" && !it.noRow)
            nState.navigate(it.route + "#" + it.id);
        else
            nState.navigate(it.route);
        nState.searchText = "";
        nState.searchOverlayOpen = false;
        nState.navShown = false;
        keyIdx = -1;
        opened();
    }

    spacing: Tokens.spacing.small

    onResultsChanged: keyIdx = -1

    // caelestia4: screen readers hear the count (or "no results") once typing pauses
    Timer {
        id: announceTimer

        interval: 700
        onTriggered: {
            if (root.visible && root.nState.searchOpen)
                countText.Accessible.announce(root.count > 0 ? countText.text : emptyTitle.text);
        }
    }

    onCountChanged: announceTimer.restart()
    Connections {
        function onSearchTextChanged(): void {
            announceTimer.restart();
        }

        target: root.nState
    }

    // The count
    StyledText {
        id: countText

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        visible: root.count > 0
        text: {
            const r = root.results;
            if (r.total > r.list.length)
                return Tr.tr("%1 of %2 results").arg(r.list.length).arg(r.total);
            return Tr.trN("%n result", "%n results", r.total);
        }
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.medium
        wrapMode: Text.WordWrap

        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }

    // Nothing found
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.large
        Layout.leftMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.small
        visible: root.count === 0
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "search_off"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.large
        }

        // caelestia4: a filter alone ("is:changed") says what it found none of; the hint never suggests what was typed
        StyledText {
            id: emptyTitle

            readonly property var parsed: root.searchIndex.parsed

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (parsed.text.length)
                    return Tr.tr("No settings match “%1”").arg(root.nState.searchText.trim());
                if (parsed.changed)
                    return Tr.tr("No settings are changed from their defaults");
                return parsed.advanced ? Tr.tr("No advanced settings") : "";
            }
            font: Tokens.font.body.medium
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: emptyTitle.parsed.text.length > 0
            text: emptyTitle.parsed.changed || emptyTitle.parsed.advanced ? Tr.tr("Try fewer words, or no filter") : Tr.tr("Try fewer words, or is:changed")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            wrapMode: Text.WordWrap
        }
    }

    // Keeps the empty state at the top
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count === 0
    }

    VerticalFadeListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count > 0
        clip: true
        spacing: Tokens.spacing.extraSmall
        model: root.results.list
        boundsBehavior: Flickable.StopAtBounds

        activeFocusOnTab: root.count > 0
        Accessible.role: Accessible.List
        Accessible.name: Tr.tr("Search results")

        Keys.onUpPressed: {
            if (root.keyIdx <= 0) {
                root.keyIdx = -1;
                root.backToField();
            } else {
                root.moveKey(-1);
            }
        }
        Keys.onDownPressed: root.moveKey(1)
        Keys.onReturnPressed: root.openKey()
        Keys.onEnterPressed: root.openKey()
        Keys.onSpacePressed: root.openKey()

        delegate: StyledRect {
            id: item

            required property var modelData
            required property int index

            readonly property bool isKeyItem: index === root.keyIdx && list.activeFocus
            // caelestia4: what Enter in the search field opens
            readonly property bool isDefault: root.fieldFocused && index === (root.keyIdx >= 0 ? root.keyIdx : 0)
            readonly property bool changed: root.searchIndex.modified(modelData)
            readonly property string value: root.searchIndex.valueText(modelData)
            readonly property bool isPage: modelData.kind === "page"

            width: list.width
            implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.medium
            color: isKeyItem || isDefault ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

            Accessible.role: Accessible.ListItem
            Accessible.name: {
                const parts = [modelData.title];
                if (modelData.breadcrumb)
                    parts.push(modelData.breadcrumb);
                if (value)
                    parts.push(value);
                if (changed)
                    parts.push(Tr.tr("Changed"));
                if (modelData.advanced)
                    parts.push(Tr.tr("Advanced"));
                return parts.join(", ");
            }
            Accessible.selected: isKeyItem || isDefault
            Accessible.onPressAction: root.open(modelData)

            StateLayer {
                anchors.fill: parent
                radius: parent.radius
                onClicked: root.open(item.modelData)
            }

            Rectangle {
                anchors.fill: parent
                z: 10
                visible: item.isKeyItem
                color: "transparent"
                border.width: 2
                border.color: Colours.palette.m3primary
                radius: parent.radius
            }

            RowLayout {
                id: layout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.large
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: item.isPage ? item.modelData.icon : "tune"
                    color: item.isPage ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: item.isPage ? 1 : 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.title
                            font: Tokens.font.body.medium
                            wrapMode: Text.WordWrap
                        }

                        StyledRect {
                            Layout.alignment: Qt.AlignVCenter
                            visible: item.modelData.advanced
                            implicitWidth: advText.implicitWidth + Tokens.padding.small * 2
                            implicitHeight: advText.implicitHeight + Tokens.padding.extraSmall
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3tertiaryContainer

                            StyledText {
                                id: advText

                                anchors.centerIn: parent
                                text: Tr.tr("Advanced")
                                color: Colours.palette.m3onTertiaryContainer
                                font: Tokens.font.label.small
                            }
                        }
                        // Changed from the default
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            visible: item.changed
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: Colours.palette.m3primary
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: item.modelData.breadcrumb
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: item.value.length > 0
                        Layout.topMargin: Tokens.spacing.extraSmall
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            visible: item.value.length > 0
                            text: item.value
                            color: item.changed ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                            elide: Text.ElideRight
                        }

                    }
                }
            }
        }
    }

    // Up from the first result: the layout moves focus back to its search field
    signal backToField
}
