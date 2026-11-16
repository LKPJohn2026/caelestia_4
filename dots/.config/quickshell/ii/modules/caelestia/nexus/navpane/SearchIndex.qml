pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (HyprlandConfig: which h: options the shell overrides)
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.registry
import "../../utils/scripts/fuzzysort.js" as Fuzzy

// caelestia4: Nexus settings search (proposal 4.2). One item per registry setting and per page and sub-page, matched
// on the translated and the English text with case and accents folded ("do trong suot" finds "Độ trong suốt").
// `query` is what the user typed; `results` is what to show. Filters in the text: "is:changed", "is:advanced".
// Not fzf.js: its Finder writes its options into a shared default object, which would change the launcher's.
QtObject {
    id: root

    property string query
    // How many results to show; `results.total` says how many matched
    property int limit: 50
    // Live values (the changed dots, the values, is:changed) need a Setting per option: made the first time this is
    // true, then kept
    property bool active
    // caelestia4: the screen whose c: values to show (as the pages' rows do: their Config.screen); empty: the global layer
    property string screen

    // Sub-page labels by route, as the sub-pages title themselves (same msgids, so the same translations). Routes left
    // out are detail pages that need a selection first (a network, a device, an app) and are not search results
    readonly property var subPages: ({
            "appearance/wallpapers": Tr.mark("Wallpapers"),
            "appearance/colours": Tr.mark("Colours"),
            "appearance/presets": Tr.mark("Presets"),
            "appearance/look": Tr.mark("Look & feel"),
            "appearance/sources": Tr.mark("Wallpaper options"),
            "appearance/desktop": Tr.mark("Desktop"),
            "network/add": Tr.mark("Add network"),
            "network/vpn": Tr.mark("Add VPN provider"),
            "network/all": Tr.mark("All networks"),
            "network/saved": Tr.mark("Saved networks"),
            "bluetooth/pairing": Tr.mark("Pair new device"),
            "audio/apps": Tr.mark("App volumes"),
            "hyprland/input": Tr.mark("Keyboard, mouse & touchpad"),
            "hyprland/windows": Tr.mark("Windows & effects"),
            "hyprland/rendering": Tr.mark("Rendering & games"),
            "panels/dashboard": Tr.mark("Dashboard"),
            "panels/taskbar": Tr.mark("Taskbar"),
            "panels/launcher": Tr.mark("Launcher"),
            "panels/sidebar": Tr.mark("Sidebar"),
            "panels/utilities": Tr.mark("Utilities"),
            "panels/taskbar/workspaces": Tr.mark("Workspaces"),
            "panels/taskbar/activeWindow": Tr.mark("Active window"),
            "panels/taskbar/tray": Tr.mark("Tray"),
            "panels/taskbar/statusIcons": Tr.mark("Status icons"),
            "panels/taskbar/clock": Tr.mark("Clock"),
            "panels/taskbar/barLayout": Tr.mark("Layout"),
            "panels/session": Tr.mark("Session menu"),
            "panels/osd": Tr.mark("On-screen display"),
            "panels/assistant": Tr.mark("Assistant"),
            "panels/overview": Tr.mark("Overview & overlay"),
            "panels/cheatsheet": Tr.mark("Keybind cheatsheet"),
            "apps/all": Tr.mark("All apps"),
            "services/notifications": Tr.mark("Notifications"),
            "services/polling": Tr.mark("Polling & tuning"),
            "services/media": Tr.mark("Media & music recognition"),
            "services/capture": Tr.mark("Screenshots & recording"),
            "services/advanced": Tr.mark("Advanced")
        })

    // The pages' labels in English (PageRegistry's are translated already), so English words find them in any language
    readonly property var pageLabels: ({
            appearance: Tr.mark("Wallpaper & style"),
            display: Tr.mark("Display"),
            network: Tr.mark("Network"),
            bluetooth: Tr.mark("Connected devices"),
            audio: Tr.mark("Audio"),
            power: Tr.mark("Power & idle"),
            updates: Tr.mark("Updates"),
            plugins: Tr.mark("Plugins"),
            hyprland: Tr.mark("Hyprland"),
            panels: Tr.mark("Panels"),
            apps: Tr.mark("Apps"),
            services: Tr.mark("Services"),
            language: Tr.mark("Language & region"),
            about: Tr.mark("About")
        })

    // ---- text helpers

    // Lowercase, accents off, đ to d: "Độ trong suốt" -> "do trong suot"
    function fold(s: string): string {
        if (!s)
            return "";
        return String(s).normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[đĐ]/g, "d").toLowerCase();
    }

    // A Tr.mark string's English text (the msgid); other strings as they are
    function english(s: var): string {
        if (!s)
            return "";
        s = String(s);
        if (s.charAt(0) !== "\x01")
            return s;
        let body = s.slice(1);
        const argEnd = body.lastIndexOf("\x02");
        if (argEnd >= 0)
            body = body.slice(argEnd + 1);
        const ctxEnd = body.indexOf("\x04");
        if (ctxEnd >= 0)
            body = body.slice(ctxEnd + 1);
        return body.split("\x03")[0];
    }

    function words(s: string): var {
        return s.split(/[^a-z0-9]+/).filter(w => w.length > 0);
    }

    // caelestia4: lowercase with the accents kept, for telling "mờ" from "mới" when the query has accents
    function lower(s: string): string {
        return s ? String(s).normalize("NFC").toLowerCase() : "";
    }

    function hasAccents(s: string): bool {
        return root.fold(s) !== root.lower(s);
    }

    // Whether `raw` starts with `rawQ` where `rawQ` has accents (a letter typed without them matches either way):
    // "lam mờ" agrees with "làm mờ", not with "làm mới". Both lowercase NFC: one character per letter, as fold() keeps
    function accentsAgree(raw: string, rawQ: string): bool {
        if (raw.length < rawQ.length || !root.fold(raw).startsWith(root.fold(rawQ)))
            return false;
        for (let i = 0; i < rawQ.length; i++) {
            const c = rawQ.charAt(i);
            if (root.fold(c) !== c && raw.charAt(i) !== c)
                return false;
        }
        return true;
    }

    // Split on spaces and punctuation, keeping letters with accents
    function rawWords(s: string): var {
        return s.split(/[\s,.;:!?()\[\]\/&›·“”"'-]+/).filter(w => w.length > 0);
    }

    // The label of each part of a route, translated: ["Panels", "Taskbar", "Tray"]
    function routeLabels(route: string): var {
        const parts = route.split("/");
        const page = PageRegistry.pages[PageRegistry.indexOf(parts[0])];
        const out = [page?.label ?? parts[0]];
        for (let i = 1; i < parts.length; i++) {
            const mark = root.subPageMark(parts.slice(0, i + 1).join("/"));
            out.push(mark ? Tr.tr(mark) : root.readableName(parts[i]));
        }
        return out;
    }

    function routeLabelsEn(route: string): var {
        const parts = route.split("/");
        const out = [root.english(root.pageLabels[parts[0]] ?? parts[0])];
        for (let i = 1; i < parts.length; i++)
            out.push(root.english(root.subPageMark(parts.slice(0, i + 1).join("/"))) || root.readableName(parts[i]));
        return out;
    }

    // caelestia4: a sub-page's label (a Tr.mark string): the table above, else its page's `subPageLabels` in
    // PageRegistry ({name: Tr.mark("Label")}, by the sub-page's name or its path under the page, e.g.
    // "desktop/widget.clock"), so new sub-pages need no line here. "" when neither has one
    function subPageMark(route: string): string {
        const known = root.subPages[route];
        if (known)
            return known;
        const parts = route.split("/");
        const labels = PageRegistry.pages[PageRegistry.indexOf(parts[0])]?.subPageLabels;
        if (!labels || parts.length < 2)
            return "";
        return labels[parts.slice(1).join("/")] ?? labels[parts[parts.length - 1]] ?? "";
    }

    // A sub-page name as words when nothing labels it: "widget.worldClock" -> "World clock", "tray" -> "Tray"
    function readableName(name: string): string {
        const n = String(name).replace(/^widget\./, "").replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[._-]+/g, " ").trim().toLowerCase();
        return n ? n.charAt(0).toUpperCase() + n.slice(1) : String(name);
    }

    // The sub-pages that are search results: the table above, the routes a page's `subPageLabels` names, and
    // desktop widget sub-pages ("widget.<w>") that registry entries live on. Detail pages without a label (a network,
    // a device) stay out
    function subPageRoutes(entries: var): var {
        const routes = Object.keys(root.subPages);
        const seen = new Set(routes);
        const push = route => {
            if (!seen.has(route)) {
                seen.add(route);
                routes.push(route);
            }
        };
        // Sub-page routes that registry entries live on (and their parents), by page
        const entryRoutes = new Set();
        for (const id in entries) {
            const parts = (entries[id].route ?? "").split("/");
            for (let i = 2; i <= parts.length; i++)
                entryRoutes.add(parts.slice(0, i).join("/"));
        }
        for (const page of PageRegistry.pages) {
            const labels = page.subPageLabels ?? {};
            for (const key in labels) {
                if (key.indexOf("/") >= 0) {
                    push(`${page.id}/${key}`);
                    continue;
                }
                // A bare name: where entries put it (it may sit under another sub-page), else right under the page
                let found = false;
                for (const r of entryRoutes) {
                    if (r.startsWith(page.id + "/") && r.split("/").pop() === key) {
                        push(r);
                        found = true;
                    }
                }
                if (!found)
                    push(`${page.id}/${key}`);
            }
        }
        for (const r of entryRoutes)
            if (r.split("/").pop().startsWith("widget."))
                push(r);
        return routes;
    }

    // Whether every part of a route names a page and sub-page that exist
    function routeExists(route: string): bool {
        const parts = route.split("/");
        const idx = PageRegistry.indexOf(parts[0]);
        if (idx < 0)
            return false;
        return parts.slice(1).every(p => PageRegistry.subPageIndex(idx, p) > 0);
    }

    // ---- the index

    // Rebuilt when the language changes (Tr.tr depends on it) or the registry does
    readonly property var items: {
        const out = [];
        const entries = Registry.entries;
        const sep = " › ";

        // caelestia4: `path` (where the item is: breadcrumb, section, route) and `extra` (keywords, the id) are kept
        // apart from each other, so a word in the path ranks above one in a description or keyword
        function add(it, titleMark, descMark, path, extra) {
            it.titleEn = root.english(titleMark);
            it.title = titleMark ? Tr.tr(titleMark) : it.titleEn;
            it.desc = descMark ? Tr.tr(descMark) : "";
            const descEn = root.english(descMark);
            it.fTitle = root.fold(it.title);
            it.fTitleEn = root.fold(it.titleEn);
            it.rTitle = root.lower(it.title);
            it.rTitleEn = root.lower(it.titleEn);
            it.rTitleWords = root.rawWords(it.rTitle);
            it.titleWords = root.words(it.fTitle + " " + it.fTitleEn);
            // The section and the last route label before the title ("keyboard layouts"), for queries that name both
            it.fPrefixed = (it.prefixes ?? []).map(p => root.fold(p));
            it.rPrefixed = (it.prefixes ?? []).map(p => root.lower(p));
            const pathText = [it.breadcrumb, ...path].join(" ");
            const fPath = root.fold(pathText);
            it.pathWords = root.words(fPath);
            it.rPathWords = root.rawWords(root.lower(pathText));
            const otherText = [it.desc, descEn, ...extra].join(" ");
            const other = root.fold(otherText);
            it.fOther = fPath + " " + other;
            it.otherWords = root.words(other);
            it.rOtherWords = root.rawWords(root.lower(otherText));
            it.prepTitle = Fuzzy.prepare(it.fTitle);
            it.prepTitleEn = it.fTitleEn === it.fTitle ? null : Fuzzy.prepare(it.fTitleEn);
            it.order = out.length;
            out.push(it);
        }

        // Pages, then their sub-pages
        for (const page of PageRegistry.pages) {
            add({
                kind: "page",
                id: page.id,
                route: page.id,
                icon: page.icon,
                breadcrumb: "",
                advanced: false,
                keywords: page.keywords ?? []
            }, root.pageLabels[page.id] ?? page.label, "", [], [page.description, ...(page.keywords ?? [])]);
            out[out.length - 1].desc = page.description;
        }
        for (const route of root.subPageRoutes(entries)) {
            if (!root.routeExists(route))
                continue;
            const labels = root.routeLabels(route);
            const labelsEn = root.routeLabelsEn(route);
            const page = PageRegistry.pages[PageRegistry.indexOf(route.split("/")[0])];
            add({
                kind: "page",
                id: route,
                route: route,
                icon: page?.icon ?? "settings",
                breadcrumb: labels.slice(0, -1).join(sep),
                advanced: false,
                keywords: []
            }, root.subPageMark(route) || labels[labels.length - 1], "", [labelsEn.slice(0, -1).join(" "), route.split("/").pop()], []);
        }

        // Settings
        for (const id in entries) {
            const e = entries[id];
            // A c: option that an x: row shows: the x: row is the result (registry `shownBy`, also from
            // Registry.rowInfo)
            if (e.shownBy && entries[e.shownBy])
                continue;
            if (!e.route || !root.routeExists(e.route))
                continue;
            const labels = root.routeLabels(e.route);
            const last = labels[labels.length - 1];
            const section = e.section ? Tr.tr(e.section) : "";
            // caelestia4: a section titled as its sub-page is not said twice
            if (section && root.fold(section) !== root.fold(last))
                labels.push(section);
            const prefixes = [];
            for (const p of [section, root.english(e.section), labels.length > 1 ? last : "", root.routeLabelsEn(e.route).slice(1).pop() ?? ""])
                if (p && !prefixes.includes(p))
                    prefixes.push(p);
            const page = PageRegistry.pages[PageRegistry.indexOf(e.route.split("/")[0])];
            const store = id.slice(0, id.indexOf(":"));
            // caelestia4: registry keywords are Tr.mark strings: match both the English word and its translation
            const kwEn = (e.keywords ?? []).map(k => root.english(k));
            const kwTr = (e.keywords ?? []).map(k => Tr.tr(k)).filter((k, i) => k !== kwEn[i]);
            add({
                kind: "setting",
                id: id,
                route: e.route,
                icon: page?.icon ?? "settings",
                store: store,
                key: id.slice(id.indexOf(":") + 1),
                breadcrumb: labels.join(sep),
                advanced: !!e.advanced,
                // No row shows it: opened without a #key (nothing to scroll to)
                noRow: !!e.noRow,
                keywords: kwEn,
                prefixes: prefixes
            }, e.title, e.desc, [root.english(e.section), root.routeLabelsEn(e.route).join(" ")], [...kwEn, ...kwTr, id]);
        }
        return out;
    }

    // ---- live values

    property bool _live: false
    onActiveChanged: {
        if (active)
            _live = true;
    }

    // caelestia4: the nav's changed dots want the live values too: made a moment after Nexus opens (so its first
    // frame is not slowed down by them), then kept
    property bool counts
    onCountsChanged: {
        if (counts && !_live)
            _countsTimer.restart();
    }
    Component.onCompleted: {
        if (counts && !_live)
            _countsTimer.restart();
    }

    readonly property Timer _countsTimer: Timer {
        interval: 400
        onTriggered: root._live = true
    }

    // caelestia4: {pageId: how many of its settings differ from their defaults}, as "is:changed" counts them (empty
    // until the live values are made)
    readonly property var changedByPage: {
        const out = {};
        if (!root._live)
            return out;
        root._settingsRevision; // dependency
        E4.HyprlandConfig.overridesRevision; // dependency
        for (const it of root.items) {
            if (it.kind !== "setting" || !root.modified(it))
                continue;
            const page = it.route.split("/")[0];
            out[page] = (out[page] ?? 0) + 1;
        }
        return out;
    }

    // c: and e4: ids that have rows (shown directly or through an x: row)
    readonly property var _liveIds: {
        if (!_live)
            return [];
        return Object.keys(Registry.entries).filter(id => id.startsWith("c:") || id.startsWith("e4:"));
    }
    // {id: Setting}
    property var _settings: ({})
    property int _settingsRevision: 0
    // x: id -> the c:/e4: ids it shows (registry `shownBy`)
    readonly property var _partners: {
        const out = {};
        const entries = Registry.entries;
        for (const id in entries) {
            const by = entries[id].shownBy;
            if (by)
                (out[by] = out[by] ?? []).push(id);
        }
        return out;
    }

    readonly property Instantiator _instantiator: Instantiator {
        model: root._liveIds

        delegate: Setting {
            required property string modelData

            sid: modelData
            screen: root.screen
        }

        onObjectAdded: (index, object) => {
            root._settings[object.sid] = object;
            root._bump();
        }
        onObjectRemoved: (index, object) => {
            if (root._settings[object.sid] === object)
                delete root._settings[object.sid];
            root._bump();
        }
    }

    // Many objects are added at once: count them as one change
    function _bump(): void {
        _bumpTimer.restart();
    }

    readonly property Timer _bumpTimer: Timer {
        interval: 0
        onTriggered: root._settingsRevision++
    }

    // Whether the item's setting differs from its default (false while not known)
    function modified(it: var): bool {
        if (it.kind !== "setting")
            return false;
        root._settingsRevision; // dependency
        switch (it.store) {
        case "c":
        case "e4":
            return root._settings[it.id]?.modified ?? false;
        case "h":
            return E4.HyprlandConfig.isOverridden(it.key);
        case "x":
            return (root._partners[it.id] ?? []).some(id => root._settings[id]?.modified ?? false);
        }
        return false;
    }

    // The item's value as the row says it ("On", "12 px", an option's label); "" when not known here
    function valueText(it: var): string {
        if (it.kind !== "setting")
            return "";
        root._settingsRevision; // dependency
        const e = Registry.entries[it.id];
        switch (it.store) {
        case "c":
        case "e4":
            {
                const s = root._settings[it.id];
                return s ? root.format(e, s.value, s) : "";
            }
        case "h":
            {
                if (!E4.HyprlandConfig.isOverridden(it.key))
                    return "";
                let v = E4.HyprlandConfig.overrideValue(it.key);
                if (v === "true" || v === "false")
                    v = v === "true";
                else if (typeof v === "string" && v.length && !isNaN(Number(v)))
                    v = Number(v);
                else if (typeof v === "string")
                    v = v.replace(/^"(.*)"$/, "$1");
                return root.format(e, v, null);
            }
        }
        return "";
    }

    // As RowSetting.format (same strings)
    function format(entry: var, v: var, s: var): string {
        if (v === undefined || v === null)
            return "";
        const same = (a, b) => s ? s.same(a, b) : String(a) === String(b);
        const opt = (entry?.options ?? []).find(o => same(o.value, v));
        if (opt)
            return Tr.tr(opt.label);
        if (typeof v === "boolean" || entry?.type === "bool")
            return v ? Tr.trCtx("On", "setting value") : Tr.trCtx("Off", "setting value");
        if (typeof v === "number") {
            const n = String(Math.round(v * (entry?.scale ?? 1) * 100) / 100);
            switch (entry?.unit) {
            case "ms":
                return Tr.tr("%1 ms").arg(n);
            case "s":
                return Tr.tr("%1 s").arg(n);
            case "min":
                return Tr.tr("%1 min").arg(n);
            case "%":
                return Tr.tr("%1 %").arg(n);
            case "px":
                return Tr.tr("%1 px").arg(n);
            case "K":
                return Tr.tr("%1 K").arg(n);
            case "pt":
                return Tr.tr("%1 pt").arg(n);
            case "°":
                return Tr.tr("%1°").arg(n);
            }
            return n;
        }
        if (typeof v === "string")
            return v.length ? "“" + v + "”" : Tr.trCtx("empty", "an empty text setting");
        if (Array.isArray(v))
            return v.length ? Tr.trN("%n item", "%n items", v.length) : Tr.trCtx("none", "an empty list setting");
        return "";
    }

    // ---- matching

    // The query split into filters and folded words
    readonly property var parsed: {
        const out = {
            changed: false,
            advanced: false,
            text: "",
            tokens: [],
            // caelestia4: the same words with their accents ("" for a word typed without any)
            rawText: "",
            rawTokens: []
        };
        const rest = [];
        const rawRest = [];
        for (const raw of root.query.trim().split(/\s+/)) {
            const w = root.fold(raw);
            if (w === "is:changed" || w === "is:modified")
                out.changed = true;
            else if (w === "is:advanced")
                out.advanced = true;
            else if (w.length) {
                rest.push(w);
                rawRest.push(root.hasAccents(raw) ? root.lower(raw) : "");
            }
        }
        out.text = rest.join(" ");
        out.tokens = rest;
        out.rawTokens = rawRest;
        out.rawText = rawRest.some(r => r.length) ? root.lower(root.query.trim().split(/\s+/).filter(r => !/^is:/i.test(r)).join(" ")) : "";
        return out;
    }

    // caelestia4: how well `t` starts with `q`; 0: not at all. A whole-word start (the next character ends the word, or
    // is a plural "s") ranks above one that stops inside a word ("lam mo" is "làm mờ ...", not "làm mới ..."); a shorter
    // rest of the title ranks higher
    function phraseScore(t: string, q: string): real {
        if (t === q)
            return 1000;
        if (!t.startsWith(q))
            return 0;
        const isWordChar = c => /[a-z0-9]/.test(c);
        const next = t.charAt(q.length);
        const whole = !isWordChar(next) || (next === "s" && !isWordChar(t.charAt(q.length + 1)));
        return (whole ? 920 : 860) - Math.min(50, t.length - q.length);
    }

    // How well one query word matches the item: 1 a whole title word, down to 0.2 inside some word; 0: nowhere. A
    // word typed with accents only matches words that have them ("bàn" is not "bảng")
    function tokenScore(it: var, tok: string, rawTok: string): real {
        const whole = w => w === tok || w === tok + "s";
        const agrees = rawWords => !rawTok || rawWords.some(w => root.accentsAgree(w, rawTok));
        const field = (words, rawWords, wholeScore, prefixScore) => {
            if (!agrees(rawWords))
                return 0;
            if (words.some(whole))
                return wholeScore;
            return words.some(w => w.startsWith(tok)) ? prefixScore : 0;
        };
        let best = Math.max(field(it.titleWords, it.rTitleWords, 1, 0.75), field(it.pathWords, it.rPathWords, 0.6, 0.45), field(it.otherWords, it.rOtherWords, 0.45, 0.35));
        if (best === 0 && !rawTok && tok.length >= 3 && (it.fTitle.includes(tok) || it.fTitleEn.includes(tok) || it.fOther.includes(tok)))
            best = 0.2;
        return best;
    }

    // Higher is better; 0: no match. Title exact (1000) > config key (950) > title starts with the query (920 whole
    // word, 860 inside one) > section or sub-page then title ("keyboard layouts", 5 less) > key part (650) > every word
    // somewhere (300-700: title words > path words > description and keywords) > fuzzy title (400-499, only when a word
    // matched nowhere). Typed accents count (see accents below)
    function score(it: var, q: string, tokens: var, rawQ: string, rawTokens: var): real {
        // Typed accents: 30 more when the title has them, 120 less when it has other ones
        const accents = (s, raw) => s <= 0 || !rawQ ? s : root.accentsAgree(raw, rawQ) ? s + 30 : s - 120;
        let best = Math.max(accents(root.phraseScore(it.fTitle, q), it.rTitle), accents(root.phraseScore(it.fTitleEn, q), it.rTitleEn));
        // The query names the section (or the sub-page) and then the title
        const prefixed = it.fPrefixed ?? [];
        for (let i = 0; i < prefixed.length; i++) {
            const p = prefixed[i];
            if (q.length <= p.length + 1 || !q.startsWith(p + " "))
                continue;
            const raw = it.rPrefixed[i] + " ";
            best = Math.max(best, accents(root.phraseScore(p + " " + it.fTitle, q), raw + it.rTitle) - 5, accents(root.phraseScore(p + " " + it.fTitleEn, q), raw + it.rTitleEn) - 5);
        }
        if (it.kind === "setting" && (q.includes(".") || q.includes(":"))) {
            const key = it.key.toLowerCase();
            if (key === q || it.id.toLowerCase() === q)
                best = Math.max(best, 950);
            else if (key.includes(q))
                best = Math.max(best, 650);
        }
        if (best > 0)
            return best;
        let sum = 0;
        for (let i = 0; i < tokens.length; i++) {
            const s = root.tokenScore(it, tokens[i], rawTokens[i] ?? "");
            if (s === 0) {
                sum = -1;
                break;
            }
            sum += s;
        }
        if (sum > 0)
            return 300 + Math.round(400 * sum / tokens.length) - Math.min(30, Math.round(it.fTitle.length / 6));
        // Fuzzy, on the title (each word must match): typos
        let fuzzy = 1;
        for (const tok of tokens) {
            if (tok.length < 2) {
                fuzzy = 0;
                break;
            }
            let s = Fuzzy.single(tok, it.prepTitle)?.score ?? 0;
            if (it.prepTitleEn)
                s = Math.max(s, Fuzzy.single(tok, it.prepTitleEn)?.score ?? 0);
            fuzzy = Math.min(fuzzy, s);
        }
        return fuzzy >= 0.5 ? 400 + Math.round(fuzzy * 99) : 0;
    }

    // {list: [items], total: int, filtered: bool}: what to show for `query`
    readonly property var results: {
        const p = root.parsed;
        const filtered = p.changed || p.advanced;
        if (!p.text && !filtered)
            return {
                list: [],
                total: 0,
                filtered: false
            };
        const found = [];
        for (const it of root.items) {
            if (filtered && it.kind !== "setting")
                continue;
            if (p.advanced && !it.advanced)
                continue;
            if (p.changed && !root.modified(it))
                continue;
            const s = p.text ? root.score(it, p.text, p.tokens, p.rawText, p.rawTokens) : 1;
            if (s > 0)
                found.push({
                    item: it,
                    score: s
                });
        }
        found.sort((a, b) => {
            if (a.score !== b.score)
                return b.score - a.score;
            if (a.item.kind !== b.item.kind)
                return a.item.kind === "page" ? -1 : 1;
            return a.item.order - b.item.order;
        });
        return {
            list: found.slice(0, root.limit).map(f => f.item),
            total: found.length,
            filtered: filtered
        };
    }
}
