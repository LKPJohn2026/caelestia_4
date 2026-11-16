import "navpane"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus

ColumnLayout {
    id: root

    required property NexusState nState
    // caelestia4: "full" (descriptions on every item), "medium" (descriptions on the current and hovered items),
    // "rail" (icons only, search as an overlay) or "single" (the nav is its own page). Set by Nexus.qml
    property string mode: "full"
    readonly property bool rail: mode === "rail"
    readonly property alias list: locations
    // caelestia4: the settings search (made by Nexus.qml, shared with the rail's overlay)
    required property SearchIndex searchIndex
    // While the search has text, its results replace the nav list (not in the rail: its overlay shows them)
    readonly property bool showResults: root.nState.searchOpen && !root.rail

    // A search result was opened (the window moves focus to the page)
    signal resultOpened

    // caelestia4: `selectAll` false keeps the cursor where it is (a layout change while typing)
    function focusSearch(selectAll = true): void {
        searchField.forceActiveFocus();
        if (selectAll)
            searchField.selectAll();
    }

    function focusList(): void {
        if (root.showResults)
            results.focusResults();
        else
            locations.focusList();
    }

    // Up/Down from the window's key handler: in the results while searching, else in the nav list
    function moveKey(delta: int): void {
        if (root.showResults)
            results.moveKey(delta);
        else
            locations.moveKey(delta);
    }

    spacing: Tokens.spacing.large

    SearchBar {
        id: searchField

        Layout.fillWidth: true
        visible: !root.rail

        placeholderText: Tr.tr("Search settings")
        font: Tokens.font.body.large
        // caelestia4: SearchBar draws its own placeholder, so screen readers need the name
        Accessible.name: Tr.tr("Search settings")

        bg.color: Colours.tPalette.m3surfaceContainerLowest
        bg.border.color: Colours.palette.m3outlineVariant
        searchIcon.fontStyle: Tokens.font.icon.medium
        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
        clearIcon.font: Tokens.font.icon.medium
        clearIcon.padding: Tokens.padding.extraSmall

        // caelestia4: the text lives in nState.searchText, shared with the rail's search overlay
        onTextChanged: root.nState.searchText = text
        Keys.onDownPressed: {
            root.focusList();
            if (root.showResults)
                results.moveKey(1);
        }
        // caelestia4: Enter opens the first (or selected) result
        Keys.onReturnPressed: results.openKey()
        Keys.onEnterPressed: results.openKey()

        Connections {
            function onSearchTextChanged(): void {
                if (searchField.text !== root.nState.searchText)
                    searchField.text = root.nState.searchText;
            }

            target: root.nState
        }

        Behavior on bg.border.color {
            CAnim {}
        }
    }

    // caelestia4: rail layout: a search button in place of the field; it opens the search over the content
    IconButton {
        Layout.alignment: Qt.AlignHCenter
        visible: root.rail
        icon: "search"
        type: IconButton.Tonal
        isRound: true
        font: Tokens.font.icon.medium
        Accessible.name: Tr.tr("Search settings")
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: Tr.tr("Search settings")
        onClicked: {
            root.nState.searchOverlayOpen = true;
            root.nState.searchFocusRequested();
        }
    }

    NavLocations {
        id: locations

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.showResults
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
        mode: root.mode
    }

    SearchResults {
        id: results

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.showResults
        nState: root.nState
        searchIndex: root.searchIndex
        fieldFocused: searchField.activeFocus
        onBackToField: searchField.forceActiveFocus()
        onOpened: root.resultOpened()
    }
}
