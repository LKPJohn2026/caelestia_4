import QtQuick
import qs.modules.caelestia.nexus.common

// caelestia4: a Caelestia option shown scaled behind an x: row (a 0.05 fraction as 5 %, 15000 ms as 15 s), until the
// registry can scale a c: row itself. Reads and writes the global layer, as the pages did before the registry.
// Not an item: bind `link` to the row's RowSetting. The c: option has its own registry entry (`shownBy` the x: id),
// which gives coverage and "Reset page"
QtObject {
    id: opt

    required property RowSetting link
    // The GlobalConfig node holding the option (GlobalConfig.services) and its key there
    required property QtObject node
    required property string key
    // shown = stored * factor
    property real factor: 1
    // Write whole numbers (ms) instead of fractions
    property bool storeInt: false

    function _shown(v: real): real {
        // Two decimals: 0.05 * 100 must show 5, not 5.000000000000001
        return Math.round(v * opt.factor * 100) / 100;
    }

    readonly property Binding _value: Binding {
        target: opt.link.s
        property: "customValue"
        value: opt._shown(opt.node[opt.key])
    }

    readonly property Binding _default: Binding {
        target: opt.link.s
        property: "customDefault"
        value: opt._shown(opt.node.descriptorFor(opt.key).defaultValue)
    }

    readonly property Connections _writes: Connections {
        function onCustomSet(v: var): void {
            const stored = Number(v) / opt.factor;
            opt.node[opt.key] = opt.storeInt ? Math.round(stored) : stored;
        }

        function onCustomReset(): void {
            opt.node.resetOption(opt.key);
        }

        target: opt.link.s
    }
}
