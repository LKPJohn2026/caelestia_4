import QtQuick
import Caelestia.I18n
import qs.modules.caelestia.nexus.registry

// caelestia4: what a Nexus row does with its `setting` id (registry/Registry.qml). Every row type holds one:
//   readonly property RowSetting link: RowSetting { sid: root.setting; row: root; screen: root.Config.screen }
// It gives the row its registry title/description, the value, modified/default, the applies chip text, the "turn on X
// first" reason, and writes that record an undo step (set, setLater for steppers and sliders, reset with a snackbar).
// It registers the row with its PageBase, which scrolls to it and pulses it when the route's "#key" names it.
// With an empty sid it does nothing (`active` false): rows without a setting work as before.
QtObject {
    id: root

    property string sid
    property Item row
    // c: the screen whose value to show (the row's Config.screen)
    property string screen
    // setLater(): how long the value must stay put before it is written
    property int debounce: 300

    readonly property bool active: sid.length > 0
    readonly property Setting s: Setting {
        sid: root.sid
        screen: root.screen
    }
    readonly property var entry: active ? s.entry : null

    readonly property string title: entry?.title ? Tr.tr(entry.title) : ""
    readonly property string desc: entry?.desc ? Tr.tr(entry.desc) : ""
    readonly property var value: s.value
    // The value to show: a pending setLater() value until it is written and read back
    readonly property var shownValue: _holding ? _pending : s.value
    readonly property bool modified: active && s.modified
    readonly property bool blocked: active && !s.enabledByParent
    readonly property string disabledReason: blocked ? s.disabledReason : ""
    readonly property string appliesText: {
        switch (entry?.applies ?? "now") {
        case "nextLock":
            return Tr.tr("Applies at next lock");
        case "appRestart":
            return Tr.tr("After restarting apps");
        case "relogin":
            return Tr.tr("After logging in again");
        case "rebuild":
            return Tr.tr("After a rebuild");
        }
        return "";
    }
    readonly property string resetTip: {
        const d = format(s.defaultValue);
        return d ? Tr.tr("Reset to %1").arg(d) : Tr.tr("Reset to default");
    }

    // The PageBase holding the row (found by walking up from `row`), or null
    property Item page: null

    // The page asks for this when the route's "#key" is this setting, or the reason link of a row below points here
    signal pulse

    // Writes v now and records an undo step
    function set(v: var): void {
        if (!active)
            return;
        _debounceTimer.stop();
        _write(v);
    }

    // Shows v now and writes it once it stays put for `debounce` ms (steppers, sliders)
    function setLater(v: var): void {
        if (!active)
            return;
        root._pending = v;
        root._holding = true;
        _debounceTimer.restart();
    }

    // Writes a pending setLater() value now
    function flush(): void {
        if (_debounceTimer.running) {
            _debounceTimer.stop();
            _commit();
        }
    }

    // Back to the default, with an Undo in the snackbar
    function reset(): void {
        if (!active)
            return;
        flush();
        const old = s.value;
        s.reset();
        const step = NexusActions.record(Tr.tr("Reset “%1”").arg(title), _undoFn(old));
        NexusActions.message(Tr.tr("Reset “%1”").arg(title), step ? Tr.trCtx("Undo", "snackbar button") : "", step ? () => NexusActions.undoStep(step) : null);
    }

    // The row's reason link: go to the setting this one needs, on its page, or pulse it when it is on this one
    function followReason(): void {
        const pid = root.s.blockerId || entry?.requires?.id;
        const pe = pid ? Registry.entry(pid) : null;
        if (!pe)
            return;
        const page = root.page ?? _findPage();
        if (page && pe.route === page.pageRoute)
            page.land(pid);
        else if (page?.nState)
            page.nState.navigate(pe.route + "#" + pid);
    }

    // A value as the UI says it: option labels, On/Off, units ("12 px"), quoted text
    function format(v: var): string {
        if (v === undefined || v === null)
            return "";
        const opt = (entry?.options ?? []).find(o => s.same(o.value, v));
        if (opt)
            return Tr.tr(opt.label);
        if (typeof v === "boolean" || entry?.type === "bool")
            return v ? Tr.trCtx("On", "setting value") : Tr.trCtx("Off", "setting value");
        // caelestia4: a duration in its best unit ("300" s reads "5 min")
        if (typeof v === "number" && entry?.type === "duration")
            return formatDuration(v, entry?.unit ?? "ms");
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

    // caelestia4: durations (DurationRow). Milliseconds in each unit; the largest unit, not below `unit`, that
    // holds `v` (in `unit`) a whole number of times
    readonly property var durationUnits: ({
            ms: 1,
            s: 1000,
            min: 60000,
            h: 3600000
        })

    function bestDurationUnit(v: real, unit: string): string {
        const ms = v * (durationUnits[unit] ?? 1);
        const order = ["h", "min", "s", "ms"];
        for (const u of order) {
            if (durationUnits[u] < (durationUnits[unit] ?? 1))
                break;
            if (ms !== 0 && Math.abs(ms) >= durationUnits[u] && Math.abs(ms % durationUnits[u]) < 1e-6)
                return u;
        }
        return unit;
    }

    function durationUnitText(u: string): string {
        switch (u) {
        case "ms":
            return Tr.trCtx("ms", "unit after a number");
        case "s":
            return Tr.trCtx("s", "unit after a number");
        case "min":
            return Tr.trCtx("min", "unit after a number");
        case "h":
            return Tr.trCtx("h", "unit after a number");
        }
        return u;
    }

    function formatDuration(v: real, unit: string): string {
        const u = bestDurationUnit(v, unit);
        const n = Math.round(v * (durationUnits[unit] ?? 1) / durationUnits[u] * 100) / 100;
        // TRANSLATORS: a duration, e.g. "5 min": %1 the number, %2 the unit
        return Tr.trCtx("%1 %2", "a duration").arg(n).arg(durationUnitText(u));
    }

    // ---- internals

    property bool _holding
    property var _pending

    readonly property Timer _debounceTimer: Timer {
        interval: root.debounce
        onTriggered: root._commit()
    }

    // After a write, the shown value waits for the store to report it (Hyprland options take a moment), up to 2 s
    readonly property Timer _holdTimer: Timer {
        interval: 2000
        onTriggered: root._holding = false
    }

    readonly property Connections _valueWatch: Connections {
        function onValueChanged(): void {
            if (root._holding && !root._debounceTimer.running && root.s.same(root.s.value, root._pending)) {
                root._holding = false;
                root._holdTimer.stop();
            }
        }

        target: root.s
    }

    readonly property Connections _rowWatch: Connections {
        function onParentChanged(): void {
            Qt.callLater(root._attach);
        }

        target: root.row
    }

    function _commit(): void {
        _write(root._pending);
        if (s.same(s.value, root._pending))
            root._holding = false;
        else
            _holdTimer.restart();
    }

    function _write(v: var): void {
        const old = s.value;
        if (s.same(old, v))
            return;
        s.set(v);
        NexusActions.record(Tr.tr("Change “%1”").arg(title), _undoFn(old));
    }

    function _undoFn(old: var): var {
        const sid = root.sid;
        const setting = root.s;
        const copy = old === undefined ? undefined : JSON.parse(JSON.stringify(old));
        return () => {
            // The row may be gone (its page closed): write by id then. x: ids need their row
            let done = false;
            try {
                if (setting && setting.sid === sid) {
                    setting.set(copy);
                    done = true;
                }
            } catch (e) {}
            if (!done && !sid.startsWith("x:"))
                NexusActions.writeSetting(sid, copy);
        };
    }

    function _findPage(): Item {
        let p = root.row?.parent ?? null;
        while (p && !p.nexusPageBase)
            p = p.parent;
        return p;
    }

    property Item _registeredWith: null
    property string _registeredSid

    function _attach(): void {
        const page = _findPage();
        if (root._registeredWith && (root._registeredWith !== page || root._registeredSid !== root.sid))
            root._registeredWith.unregisterRow(root._registeredSid, root);
        root.page = page;
        if (page && root.active && (root._registeredWith !== page || root._registeredSid !== root.sid)) {
            page.registerRow(root.sid, root);
            root._registeredWith = page;
            root._registeredSid = root.sid;
        } else if (!page || !root.active) {
            root._registeredWith = null;
        }
    }

    onSidChanged: Qt.callLater(_attach)
    Component.onCompleted: Qt.callLater(_attach)
    Component.onDestruction: {
        flush();
        try {
            root._registeredWith?.unregisterRow(root._registeredSid, root);
        } catch (e) {}
    }
}
