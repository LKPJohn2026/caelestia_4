import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4 config.json)
import qs.modules.common.models.hyprland as E4H // caelestia4: keep
import qs.services as E4 // caelestia4: keep (HyprlandConfig)
import qs.modules.caelestia.nexus.registry
import "../registry/E4Defaults.js" as E4Defaults

// caelestia4: one setting, by registry id (registry/Registry.qml): its live value, default and whether it differs,
// for any store. "c:<path>" Caelestia shell.json (GlobalConfig), "e4:<path>" end-4 config.json, "h:<option>" a Hyprland
// option saved to end-4's shell overrides file, "x:<name>" a value the page provides (customValue / customDefault,
// customSet / customReset). Rows use it; writes are not debounced here (sliders and steppers do that).
QtObject {
    id: root

    property string sid
    // c: the screen whose value to show (a row binds its own Config.screen). Empty: the global layer. Writes and
    // resets always go to the global layer, as the pages do.
    property string screen

    // x: the page binds these and acts on the signals
    property var customValue
    property var customDefault
    signal customSet(var v)
    signal customReset

    // After set() or reset(), with the value before and the value written
    signal changedByUser(var oldValue, var newValue)

    readonly property var entry: Registry.entries[sid] ?? null
    readonly property string store: {
        const i = sid.indexOf(":");
        return i > 0 ? sid.slice(0, i) : "";
    }
    readonly property string key: sid.slice(sid.indexOf(":") + 1)

    readonly property var value: {
        switch (store) {
        case "c":
            return _cValue();
        case "e4":
            return _e4Node ? _norm(_e4Node[_leaf]) : undefined;
        case "h":
            // Hyprland reports an empty string option as "[[EMPTY]]"
            return _hOpt?.value === "[[EMPTY]]" ? "" : _hOpt?.value;
        case "x":
            return customValue;
        }
        return undefined;
    }

    readonly property var defaultValue: {
        if (entry && entry.default !== undefined)
            return entry.default;
        switch (store) {
        case "c":
            return _cNode ? _norm(_cNode.descriptorFor(_leaf).defaultValue) : undefined;
        case "e4":
            return E4Defaults.defaults[key];
        case "x":
            return customDefault;
        }
        return undefined;
    }

    readonly property bool modified: {
        if (store === "h") {
            E4.HyprlandConfig.overridesRevision;
            return E4.HyprlandConfig.isOverridden(key);
        }
        if (defaultValue === undefined || value === undefined)
            return false;
        return !_same(value, defaultValue);
    }

    // The registry's `requires` ({id, value}): false while that setting does not hold that value
    // caelestia4: the whole chain must hold: a row whose parent is itself blocked (Dashboard off → Performance off →
    // its rows) is blocked too, and names the first setting up the chain that is off
    readonly property bool enabledByParent: !_parent || (_parent.enabledByParent && _same(_parent.value, entry.requires.value))
    // The setting to change first: the parent, or the parent's own blocker further up
    readonly property string blockerId: enabledByParent ? "" : (_parent.enabledByParent ? entry.requires.id : _parent.blockerId)
    readonly property string disabledReason: {
        if (enabledByParent)
            return "";
        if (!_parent.enabledByParent)
            return _parent.disabledReason;
        const title = _parent.entry ? Tr.tr(_parent.entry.title) : _parent.sid;
        if (entry.requires.value === true)
            return Tr.tr("Turn on “%1” first").arg(title);
        if (entry.requires.value === false)
            return Tr.tr("Turn off “%1” first").arg(title);
        const opt = (_parent.entry?.options ?? []).find(o => _same(o.value, entry.requires.value));
        return Tr.tr("Needs “%1” set to %2").arg(title).arg(opt ? Tr.tr(opt.label) : String(entry.requires.value));
    }

    function set(v: var): void {
        const old = root.value;
        switch (store) {
        case "c":
            if (!_cNode)
                return _warn("no such Caelestia option");
            if (_isList(_cNode[_leaf])) {
                const list = _cNode[_leaf];
                list.clear();
                for (const item of v ?? [])
                    list.insert(item);
            } else {
                _cNode[_leaf] = v;
            }
            break;
        case "e4":
            if (!_e4Node)
                return _warn("no such end-4 option");
            _e4Node[_leaf] = v;
            break;
        case "h":
            E4.HyprlandConfig.set(key, typeof v === "boolean" ? (v ? "true" : "false") : String(v));
            break;
        case "x":
            root.customSet(v);
            break;
        default:
            return _warn("unknown store");
        }
        root.changedByUser(old, v);
    }

    function reset(): void {
        const old = root.value;
        switch (store) {
        case "c":
            if (!_cNode)
                return _warn("no such Caelestia option");
            _cNode.resetOption(_leaf);
            break;
        case "e4":
            if (defaultValue === undefined)
                return _warn("no default");
            set(JSON.parse(JSON.stringify(defaultValue)));
            return;
        case "h":
            E4.HyprlandConfig.reset(key);
            break;
        case "x":
            root.customReset();
            break;
        default:
            return _warn("unknown store");
        }
        root.changedByUser(old, root.defaultValue);
    }

    // Whether two values of this setting are the same (numbers within 1e-9, lists and objects by content, Hyprland's
    // 0/1 against bools)
    function same(a: var, b: var): bool {
        return _same(a, b);
    }

    // ---- internals

    readonly property var _parts: store === "c" || store === "e4" ? key.split(".") : []
    readonly property string _leaf: _parts.length ? _parts[_parts.length - 1] : ""
    readonly property var _cNode: store === "c" ? _walk(GlobalConfig, _parts) : null
    // caelestia4: global-only options (their own flag or a global-only parent node) must be read from the global
    // layer, or the plugin warns "Global option … was read from an overlay layer"
    readonly property bool _cGlobalOnly: {
        if (store !== "c")
            return false;
        let node = GlobalConfig;
        for (const p of _parts) {
            if (!node || typeof node.descriptorFor !== "function")
                return false;
            if (node.descriptorFor(p).globalOnly)
                return true;
            node = node[p];
        }
        return false;
    }
    readonly property var _cReadNode: {
        if (!_cNode || !screen || _cGlobalOnly)
            return _cNode;
        const layer = GlobalConfig.forScreen(screen);
        return layer ? (_walk(layer, _parts) ?? _cNode) : _cNode;
    }
    readonly property var _e4Node: store === "e4" ? _walk(E4C.Config.options, _parts) : null

    property var _hOpt: null
    property var _parent: null

    readonly property Component _hOptComp: Component {
        E4H.HyprlandConfigOption {}
    }

    function _walk(rootNode: var, parts: var): var {
        let node = rootNode;
        for (let i = 0; i < parts.length - 1 && node; i++)
            node = node[parts[i]];
        if (!node || !(parts[parts.length - 1] in node)) {
            _warn("no such option");
            return null;
        }
        return node;
    }

    function _cValue(): var {
        if (!_cReadNode)
            return undefined;
        const v = _cReadNode[_leaf];
        return _isList(v) ? Array.from(v.values, _plain) : _norm(v);
    }

    // A list element node ({id, enabled} etc.) as a plain object, without QObject's objectName
    function _plain(node: var): var {
        const o = JSON.parse(JSON.stringify(node));
        delete o.objectName;
        return o;
    }

    function _isList(v: var): bool {
        return !!v && typeof v === "object" && v.values !== undefined && typeof v.clear === "function";
    }

    // QML lists and value types as plain JS values, so they compare and stringify
    function _norm(v: var): var {
        if (v === null || v === undefined || typeof v !== "object")
            return v;
        if (Array.isArray(v) || v.length !== undefined)
            return Array.from(v, x => _norm(x));
        return v;
    }

    function _same(a: var, b: var): bool {
        if (typeof a === "number" && typeof b === "number")
            return Math.abs(a - b) < 1e-9;
        if (typeof a === "object" || typeof b === "object")
            return _canon(a) === _canon(b);
        // Hyprland gives bools as 0/1
        if (typeof a === "boolean" || typeof b === "boolean")
            return Boolean(a) === Boolean(b);
        return a === b;
    }

    // JSON with object keys sorted: list elements from a node and from a default map list their keys in other orders
    function _canon(v: var): string {
        return JSON.stringify(v, (k, x) => x && typeof x === "object" && !Array.isArray(x) ? Object.keys(x).sort().reduce((o, key) => {
                    o[key] = x[key];
                    return o;
                }, {}) : x);
    }

    function _warn(what: string): void {
        console.warn(`Nexus Setting "${sid}": ${what}`);
    }

    property bool _ready: false

    function _setup(): void {
        if (!_ready)
            return;
        _hOpt?.destroy();
        _hOpt = store === "h" ? _hOptComp.createObject(root, {
            key: key
        }) : null;
        _parent?.destroy();
        const req = entry?.requires;
        _parent = req?.id ? Qt.createComponent("Setting.qml").createObject(root, {
            sid: req.id
        }) : null;
    }

    onSidChanged: _setup()
    Component.onCompleted: {
        _ready = true;
        _setup();
    }
}
