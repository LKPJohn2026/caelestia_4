pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.utils
import qs.modules.common as E4C // caelestia4: keep

Searcher {
    id: root

    // caelestia4: named schemes come from caelestia-cli (not installed) -> empty list (the "Scheme" action is hidden).
    // The current variant mirrors end-4's palette type ("scheme-tonal-spot" -> "tonalspot", "auto" -> "auto").
    property string currentScheme
    readonly property string currentVariant: (E4C.Config.options.appearance.palette.type ?? "auto").replace(/^scheme-/, "").replace(/-/g, "")

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        Scheme {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            console.warn("[caelestia4] named schemes need caelestia-cli, not available");
        }
    }
}
