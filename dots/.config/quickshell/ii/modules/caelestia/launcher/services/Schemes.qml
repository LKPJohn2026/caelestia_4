pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.common as E4C // caelestia4: keep

Searcher {
    id: root

    // caelestia4: preset schemes come from utils/scripts/scheme.py via the Colours adapter (Caelestia asks
    // caelestia-cli). The current variant mirrors end-4's palette type ("scheme-tonal-spot" -> "tonalspot").
    readonly property string currentScheme: `${Colours.scheme} ${Colours.flavour}`
    readonly property string currentVariant: (E4C.Config.options.appearance.palette.type ?? "auto").replace(/^scheme-/, "").replace(/-/g, "")

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        Colours.reloadSchemes();
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        model: Colours.schemes

        Scheme {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        // Preview colours in the current light/dark mode when the scheme has it
        readonly property var colours: modelData.modes[Colours.light ? "light" : "dark"] ?? Object.values(modelData.modes)[0]

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Colours.setScheme(name, flavour);
        }
    }
}
