// caelestia4: the Caelestia-design panel family (see PLAN.md).
// Phase 2: no UI yet. Only the adapter self-test runs (Config.options.caelestia.debugProbe).
// Panels are added here phase by phase, each as a PanelLoader, like IllogicalImpulseFamily.qml.
import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.caelestia

Scope {
    PanelLoader {
        extraCondition: Config.options.caelestia.debugProbe
        component: AdapterProbe {}
    }
}
