pragma Singleton

import QtQuick

// caelestia4: every Nexus setting by id ("c:bar.tray.compact", "e4:lock.blur.radius", "h:decoration:rounding",
// "x:<name>"). The entries live in one Reg<Page>.qml per page (format: RegPanels.qml) so pages can be edited apart;
// they are merged here once. tools/nexus-coverage.py checks them against the config options.
QtObject {
    id: root

    // Same order as PageRegistry.pages. caelestia4: a page may have more than one file (P5: one per group working on it)
    readonly property list<QtObject> pages: [
        RegAppearance {},
        RegFonts {},
        RegWidgetsA {},
        RegWidgetsB {},
        RegDisplay {},
        RegNetwork {},
        RegBluetooth {},
        RegAudio {},
        RegPower {},
        RegLock {},
        RegUpdates {},
        RegPlugins {},
        RegHyprland {},
        RegPanels {},
        RegPanelsB {},
        RegApps {},
        RegServices {},
        RegLanguage {},
        RegAbout {}
    ]

    // caelestia4: what search needs to know about entries that have no row of their own (P4 review). `shownBy`: the x:
    // row that shows this option (search lists that row, not this one; is:changed counts it there). `noRow`: no row
    // anywhere (a list editor, a per-app toggle): search opens the route without a #key. A Reg file's own fields win,
    // so these can move into the Reg files later
    readonly property var rowInfo: ({
            "c:launcher.actionPrefix": {
                shownBy: "x:launcher.actionPrefix"
            },
            "c:session.commands.logout": {
                shownBy: "x:session.commands.logout"
            },
            "c:session.commands.hibernate": {
                shownBy: "x:session.commands.hibernate"
            },
            "c:session.commands.reboot": {
                shownBy: "x:session.commands.reboot"
            },
            "c:session.commands.shutdown": {
                shownBy: "x:session.commands.shutdown"
            },
            "e4:overview.scale": {
                shownBy: "x:overview.scalePercent"
            },
            "c:bar.entries": {
                noRow: true
            },
            "c:bar.statusIcons": {
                noRow: true
            },
            "c:utilities.quickToggles": {
                noRow: true
            },
            "e4:caelestia.quickToggles": {
                noRow: true
            },
            "x:apps.favourite": {
                noRow: true
            },
            "x:apps.hidden": {
                noRow: true
            }
        })

    // {id: entry}; each entry also gets its `id`
    readonly property var entries: {
        const out = {};
        for (const page of root.pages) {
            const src = page.entries;
            for (const id in src) {
                if (out[id])
                    console.warn(`Nexus registry: "${id}" is declared twice (route "${src[id].route}")`);
                if (!src[id].route || !src[id].title) {
                    // caelestia4: skipped, so one bad entry cannot break route lookup for every page
                    console.warn(`Nexus registry: "${id}" needs a route and a title (skipped)`);
                    continue;
                }
                out[id] = Object.assign({
                    id: id
                }, root.rowInfo[id] ?? {}, src[id]);
            }
        }
        return out;
    }

    // The entry for an id, or null
    function entry(id: string): var {
        return root.entries[id] ?? null;
    }

    // The ids whose rows live on a route or under it ("panels/taskbar" gives panels/taskbar/tray's too), in the
    // order the Reg files declare them
    function idsForRoute(route: string): list<string> {
        const ids = [];
        for (const id in root.entries) {
            const r = root.entries[id].route;
            if (r === route || (r ?? "").startsWith(route + "/"))
                ids.push(id);
        }
        return ids;
    }

    // The ids whose rows live on exactly this route (a page's own rows, not its sub-pages'), in declaration order
    function idsOnRoute(route: string): list<string> {
        return Object.keys(root.entries).filter(id => root.entries[id].route === route);
    }

    // Every entry, as a list
    function all(): list<var> {
        return Object.keys(root.entries).map(id => root.entries[id]);
    }
}
