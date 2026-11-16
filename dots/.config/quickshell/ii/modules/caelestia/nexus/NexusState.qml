import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    id: root

    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    // caelestia4: the search text, shared by the nav's search field and the rail's search overlay
    property string searchText
    // caelestia4: spaces alone are not a search
    readonly property bool searchOpen: searchText.trim().length > 0
    // Rail layout: the search field shows as an overlay over the content
    property bool searchOverlayOpen
    // Single-pane layout (narrow): the nav list is shown instead of the page
    property bool navShown

    // caelestia4: where Nexus is, as a route: the page id, then each open sub-page's name ("panels/taskbar/tray")
    readonly property string route: {
        const parts = [PageRegistry.pages[currentPageIdx]?.id ?? ""];
        for (const idx of subPageIdxStack)
            parts.push(PageRegistry.subPageName(currentPageIdx, idx) || String(idx));
        return parts.join("/");
    }
    // Set once, before the pages load: where the window opens (navigate())
    property string initialRoute
    // The setting a route's "#key" asked for: the page holding it scrolls to it and highlights it, then clears this
    property string focusKey

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed
    // The whole sub-page stack was replaced (navigate() on the current page): the StackPage rebuilds it without animation
    signal subPagesReset
    // Ctrl+F, "/": the layout in use moves focus to its search field
    signal searchFocusRequested

    // `target` is the sub-page's name in PageRegistry (`subPages`) or, the old way, its index
    function openSubPage(target: var): void {
        const idx = typeof target === "number" ? target : PageRegistry.subPageIndex(currentPageIdx, target);
        if (idx < 1) {
            console.warn(`Nexus: no sub-page "${target}" on page "${PageRegistry.pages[currentPageIdx]?.id}"`);
            return;
        }
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    // navigate("page/sub/sub#key"): opens the page, then each sub-page in turn (unknown names end the path there).
    // "search?q=text" fills the settings search instead (the page stays). Returns false when the page doesn't exist
    function navigate(target: string): bool {
        // caelestia4: search deep links ("search?q=blur", "search?q=is%3Achanged")
        if (target === "search" || target.startsWith("search?")) {
            const m = /[?&]q=([^&]*)/.exec(target);
            let q = m ? m[1].replace(/\+/g, " ") : "";
            try {
                q = decodeURIComponent(q);
            } catch (e) {}
            searchText = q;
            searchFocusRequested();
            return true;
        }
        const hash = target.indexOf("#");
        const path = hash < 0 ? target : target.slice(0, hash);
        const parts = path.split("/").filter(p => p.length > 0);
        const pageIdx = PageRegistry.indexOf(parts[0] ?? "");
        if (pageIdx < 0) {
            console.warn(`Nexus: no page "${parts[0] ?? ""}" (route "${target}")`);
            return false;
        }
        const stack = [];
        for (const name of parts.slice(1)) {
            const idx = PageRegistry.subPageIndex(pageIdx, name);
            if (idx < 1) {
                console.warn(`Nexus: no sub-page "${name}" on page "${parts[0]}" (route "${target}")`);
                break;
            }
            stack.push(idx);
        }
        focusKey = hash < 0 ? "" : target.slice(hash + 1);
        navShown = false; // single pane: show the page navigated to
        // caelestia4: a page link closes an open search, so the search doesn't cover the page (rail overlay)
        searchText = "";
        searchOverlayOpen = false;
        if (pageIdx !== currentPageIdx) {
            currentPageIdx = pageIdx; // clears the stack (below); the page is loaded after its fade-out, with this stack
            subPageIdxStack = stack;
        } else {
            subPageIdxStack = stack;
            subPagesReset();
        }
        return true;
    }

    // caelestia4: Ctrl+Tab and friends: the next (1) or previous (-1) page, wrapping around
    function stepPage(delta: int): void {
        const n = PageRegistry.pages.length;
        if (n > 0)
            currentPageIdx = ((currentPageIdx + delta) % n + n) % n;
    }

    // One step back: closes the top sub-page. False when on a page's main view
    function back(): bool {
        if (subPageIdxStack.length === 0)
            return false;
        closeSubPage();
        return true;
    }

    onCurrentPageIdxChanged: {
        subPageIdxStack.length = 0;
        navShown = false;
    }
}
