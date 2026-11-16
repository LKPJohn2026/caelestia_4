pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import "navpane"

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }
    property color blobColour: Colours.tPalette.m3surfaceContainerLow
    // caelestia4: the settings search (index, matching, results), shared by the nav pane and the rail's overlay
    readonly property SearchIndex searchIndex: SearchIndex {
        query: nState.searchText
        active: nState.searchOpen
        counts: true // caelestia4: the nav's changed dots
        screen: root.Config.screen // caelestia4: the values the pages' rows show
    }

    // caelestia4: layout by window size (proposal section 7): "full" >= 1100 px wide; "medium" 800-1100 (nav 280 px,
    // descriptions on the current and hovered items); "rail" < 800 wide or < 560 high (72 px icons, search as an
    // overlay); "single" < 640 wide (the nav is a page of its own)
    readonly property string layoutMode: {
        if (width <= 0)
            return "full";
        if (width < 640)
            return "single";
        if (width < 800 || height < 560)
            return "rail";
        return width < 1100 ? "medium" : "full";
    }
    readonly property bool single: layoutMode === "single"
    readonly property bool rail: layoutMode === "rail"
    readonly property bool navVisible: !single || nState.navShown
    readonly property int navMargin: rail ? Tokens.padding.small : Tokens.padding.large
    readonly property int navWidth: {
        if (single)
            return nState.navShown ? width - navMargin * 2 : 0;
        if (rail)
            return 72 - navMargin * 2;
        if (layoutMode === "medium")
            return 280;
        return Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(width / 3));
    }
    // Where the content area (the hole in the blob frame) starts
    readonly property int contentLeft: single ? Tokens.padding.medium : navWidth + navMargin * 2

    signal close

    // caelestia4: one key handler for the whole of Nexus (proposal section 8). Keys the focused control uses itself
    // (typing in fields, a row's own Esc/Enter/arrows, open dialogs) are accepted there and never reach this
    function isTextInput(item: Item): bool {
        return !!item && "cursorPosition" in item && "selectByMouse" in item;
    }

    function isInside(item: Item, container: Item): bool {
        for (; item; item = item.parent)
            if (item === container)
                return true;
        return false;
    }

    // Up/Down move in the nav list only when nothing on the page has focus (rows use the arrows themselves)
    function navKeysFree(): bool {
        const item = root.Window.activeFocusItem;
        return !item || item === root || isInside(item, navPane);
    }

    function focusSearch(): void {
        if (single)
            nState.navShown = true;
        else if (rail)
            nState.searchOverlayOpen = true;
        nState.searchFocusRequested();
    }

    // Not named "escape": a QML method by that name (a JS global) crashes Qt 6.12's type loader
    function escapeStep(): bool {
        const focused = root.Window.activeFocusItem;
        const inSearch = isInside(focused, navPane) || isInside(focused, overlay);
        // caelestia4: a page's text field is left first; the search is cleared only from the search, the nav or no focus
        if (focused && focused !== root && !inSearch && isTextInput(focused)) {
            root.forceActiveFocus(); // leave the field first
            return true;
        }
        const onPage = focused && focused !== root && !inSearch;
        if (nState.searchText.length > 0 && !onPage) {
            nState.searchText = "";
            // caelestia4: focus in the results (now hidden) goes back to the search field, so typing and the arrows
            // work again and the rail's overlay closes on the next Esc or when focus leaves it
            if (inSearch && !isTextInput(focused))
                nState.searchFocusRequested();
            return true;
        }
        if (nState.searchOverlayOpen) {
            nState.searchOverlayOpen = false;
            root.forceActiveFocus();
            return true;
        }
        if (nState.back())
            return true;
        if (single && !nState.navShown) {
            nState.navShown = true;
            return true;
        }
        if (nState.isWindow) {
            root.close();
            return true;
        }
        return false; // the popout closes as it did before
    }

    function goBack(): bool {
        if (nState.back())
            return true;
        if (single && !nState.navShown) {
            nState.navShown = true;
            return true;
        }
        return false;
    }

    function handleKey(event: KeyEvent): void {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const alt = (event.modifiers & Qt.AltModifier) !== 0;
        const inText = isTextInput(root.Window.activeFocusItem);
        const key = event.key;
        let done = true;

        // caelestia4: the first-run welcome (navpane/Welcome.qml) is up: Esc skips it, Ctrl+F (which it suggests) ends
        // it and opens the search; the other Nexus keys wait
        if (welcome.shown) {
            // caelestia4: Tab and Shift+Tab move only between the card's own items (the page behind it can't take focus)
            const tab = !ctrl && !alt && (key === Qt.Key_Tab || key === Qt.Key_Backtab);
            if (key === Qt.Key_Escape)
                welcome.finish();
            else if (ctrl && key === Qt.Key_F) {
                welcome.finish();
                focusSearch();
            } else if (tab)
                welcome.moveFocus(key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier));
            event.accepted = key === Qt.Key_Escape || (ctrl && key === Qt.Key_F) || tab;
            return;
        }

        // caelestia4: while a page dialog is open, the dialog handles its own keys; the Nexus keys (page switch,
        // search, undo, close) do nothing. Esc that got here (focus left the dialog, e.g. by a click on the nav)
        // closes the dialog
        const dialog = pages.openDialog();
        if (dialog) {
            if (key === Qt.Key_Escape)
                pages.closeDialog(dialog);
            event.accepted = key === Qt.Key_Escape;
            return;
        }

        if (ctrl && key === Qt.Key_F)
            focusSearch();
        else if (key === Qt.Key_Slash && !ctrl && !alt && !inText)
            focusSearch();
        else if (key === Qt.Key_Escape)
            done = escapeStep();
        else if ((alt && key === Qt.Key_Left) || key === Qt.Key_Back)
            done = goBack();
        else if (ctrl && key === Qt.Key_Backtab)
            nState.stepPage(-1);
        else if (ctrl && key === Qt.Key_Tab)
            nState.stepPage((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
        else if (ctrl && key === Qt.Key_PageDown)
            nState.stepPage(1);
        else if (ctrl && key === Qt.Key_PageUp)
            nState.stepPage(-1);
        else if (ctrl && key === Qt.Key_Z && !inText)
            NexusActions.undo();
        else if (ctrl && key === Qt.Key_W && nState.isWindow)
            root.close();
        else if ((key === Qt.Key_Up || key === Qt.Key_Down) && !ctrl && !alt && navVisible && navKeysFree()) {
            navPane.focusList();
            navPane.moveKey(key === Qt.Key_Up ? -1 : 1);
        } else
            done = false;

        event.accepted = done;
    }

    implicitWidth: Math.round(implicitHeight * Tokens.sizes.nexus.ratio)
    implicitHeight: Math.round((nState.screen?.height ?? 0) * Tokens.sizes.nexus.heightMult)

    focus: true
    Keys.onPressed: event => root.handleKey(event)

    // caelestia4: leaving the rail closes its search overlay (the nav's own field shows the text)
    // Tests layoutMode itself: `rail` and `single` may not have updated yet when this runs
    onLayoutModeChanged: {
        if (layoutMode !== "rail")
            nState.searchOverlayOpen = false;
        // caelestia4: a search in progress stays in view in the new layout
        if (nState.searchOpen && layoutMode === "single")
            nState.navShown = true;
        else if (nState.searchOpen && layoutMode === "rail")
            nState.searchOverlayOpen = true;
        // caelestia4: typing goes on in the new layout's field (the old one may be hidden now)
        const focused = root.Window.activeFocusItem;
        if (nState.searchOpen && isTextInput(focused) && (isInside(focused, navPane) || isInside(focused, overlay)))
            Qt.callLater(() => root.rail ? overlaySearch.forceActiveFocus() : navPane.focusSearch(false));
    }
    // caelestia4: search text set from outside the field ("search?q=" routes): show where the results are
    Connections {
        function onSearchTextChanged(): void {
            if (!root.nState.searchOpen)
                return;
            if (root.single)
                root.nState.navShown = true;
            else if (root.rail)
                root.nState.searchOverlayOpen = true;
        }

        target: root.nState
    }

    // A window opened without a route starts on the nav list when it is narrow (single pane; no effect otherwise)
    Component.onCompleted: {
        if (nState.isWindow && !nState.initialRoute)
            nState.navShown = true;
    }

    Behavior on blobColour {
        CAnim {}
    }

    TapHandler {
        onTapped: root.focus = true
    }

    // Mouse back button: one step back (Alt+Left's job)
    TapHandler {
        acceptedButtons: Qt.BackButton
        onTapped: root.goBack()
    }

    Connections {
        function onSearchFocusRequested(): void {
            if (root.rail)
                Qt.callLater(() => overlaySearch.forceActiveFocus());
            else
                Qt.callLater(() => navPane.focusSearch());
        }

        target: root.nState
    }

    Connections {
        function onMessage(text: string, actionLabel: string, actionFn: var): void {
            snackbar.show(text, actionLabel, actionFn);
        }

        target: NexusActions
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.large
        visible: !root.single || !root.nState.navShown

        borderLeft: root.contentLeft
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    // Single-pane layout with the nav shown: the whole window is the nav's surface
    StyledRect {
        anchors.fill: parent
        visible: root.single && root.nState.navShown
        color: root.blobColour
        radius: Tokens.rounding.large
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.nState.isWindow ? 0 : Tokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
        implicitHeight: windowBtn.implicitHeight + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small)
    }

    IconButton {
        id: windowBtn

        z: 2
        anchors.centerIn: windowBtnRect
        icon: nState.isWindow ? "close" : "pip"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? nState.isWindow ? Colours.palette.m3error : Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        Accessible.name: nState.isWindow ? Tr.tr("Close") : Tr.tr("Open in a window")
        onClicked: {
            if (!nState.isWindow)
                WindowFactory.openAt(nState.route); // caelestia4: the window opens where the popout was
            root.close();
        }

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: root.navMargin
        anchors.topMargin: root.single ? Tokens.padding.large + windowBtnRect.height : root.navMargin

        visible: root.navVisible
        nState: nState
        searchIndex: root.searchIndex
        mode: root.layoutMode
        width: root.navWidth
        onResultOpened: root.forceActiveFocus()

        // caelestia4: the nav list's changed dots (full list and rail) count from the search's live values
        Binding {
            target: navPane.list
            property: "searchIndex"
            value: root.searchIndex
        }
    }

    // caelestia4: single-pane layout: the way back from a page to the nav ("Nexus" is the root of the trail)
    RowLayout {
        id: singleHeader

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Tokens.padding.large
        anchors.topMargin: Tokens.padding.large
        visible: root.single && !root.nState.navShown && root.nState.subPageIdxStack.length === 0
        spacing: Tokens.spacing.small

        IconButton {
            icon: "arrow_back"
            type: IconButton.Tonal
            isRound: true
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            Accessible.name: Tr.tr("All settings")
            onClicked: root.nState.navShown = true
        }

        StyledText {
            text: "Nexus"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.title.small
        }
    }

    Item {
        id: contentArea

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.contentLeft
        anchors.rightMargin: Tokens.padding.medium
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        visible: !root.single || !root.nState.navShown

        Pages {
            id: pages

            anchors.fill: parent
            anchors.margins: root.single ? Tokens.padding.large : Tokens.padding.extraLarge - Tokens.padding.medium
            anchors.leftMargin: root.single ? Tokens.padding.large : Tokens.padding.extraLarge
            anchors.topMargin: (root.single ? Tokens.padding.large : Tokens.padding.extraLarge - Tokens.padding.medium) + (singleHeader.visible ? singleHeader.height + Tokens.spacing.medium : 0)

            nState: nState
        }

        // caelestia4: rail layout: the search field over the top of the content, its results under it
        ColumnLayout {
            id: overlay

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            z: 5
            visible: root.rail && root.nState.searchOverlayOpen
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: overlaySearch.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                SearchBar {
                    id: overlaySearch

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small

                    placeholderText: Tr.tr("Search settings")
                    font: Tokens.font.body.large
                    Accessible.name: Tr.tr("Search settings")
                    bg.color: Colours.tPalette.m3surfaceContainerLowest
                    bg.border.color: Colours.palette.m3outlineVariant
                    searchIcon.fontStyle: Tokens.font.icon.medium
                    clearIcon.font: Tokens.font.icon.medium
                    clearIcon.padding: Tokens.padding.extraSmall

                    onTextChanged: root.nState.searchText = text
                    onActiveFocusChanged: {
                        if (!activeFocus && text.length === 0)
                            root.nState.searchOverlayOpen = false;
                    }
                    Keys.onDownPressed: overlayResults.moveKey(1)
                    Keys.onReturnPressed: overlayResults.openKey()
                    Keys.onEnterPressed: overlayResults.openKey()

                    Connections {
                        function onSearchTextChanged(): void {
                            if (overlaySearch.text !== root.nState.searchText)
                                overlaySearch.text = root.nState.searchText;
                        }

                        target: root.nState
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                visible: root.nState.searchOpen
                // As high as the results, up to the bottom of the content area
                implicitHeight: Math.min(overlayResults.implicitHeight + overlayResults.listContentHeight + Tokens.padding.medium * 2, contentArea.height - Tokens.padding.large * 2 - overlaySearch.implicitHeight - Tokens.padding.small * 2 - overlay.spacing)
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer

                SearchResults {
                    id: overlayResults

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    nState: root.nState
                    searchIndex: root.searchIndex
                    fieldFocused: overlaySearch.activeFocus
                    onBackToField: overlaySearch.forceActiveFocus()
                    onOpened: root.forceActiveFocus()
                }
            }
        }
    }

    // caelestia4: the first-run welcome, over the whole window (also the single-pane nav)
    Welcome {
        id: welcome

        anchors.fill: parent
        z: 9
        nState: root.nState
    }

    // caelestia4: outside contentArea, so it also shows over the single-pane nav (contentArea is hidden then)
    Snackbar {
        id: snackbar

        readonly property Item surface: contentArea.visible ? contentArea : root

        anchors.horizontalCenter: surface.horizontalCenter
        anchors.bottom: surface.bottom
        anchors.bottomMargin: Tokens.padding.large
        z: 10
        width: Math.min(implicitWidth, surface.width - Tokens.padding.large * 2)
    }
}
