pragma Singleton

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.navpane

// caelestia4: the launcher's settings search (">settings tray"): the same index and ranking as Nexus's own search
// (SearchIndex, which needs no Nexus window), made the first time the prefix is typed. Each result is a launcher action
// ({name, desc, icon, onClicked(list)}, shown by ActionItem); opening one opens Nexus on that page, at that row
QtObject {
    id: root

    // The launcher's text, set by AppList while it is in the "settings" state
    property string text
    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}settings `
    readonly property string query: text.startsWith(prefix) ? text.slice(prefix.length) : ""

    property SearchIndex index: null

    onTextChanged: {
        if (!index && text.startsWith(prefix))
            index = _indexComp.createObject(root);
    }

    readonly property Component _indexComp: Component {
        SearchIndex {
            id: idx

            query: root.query
            limit: 30
            // "is:changed" needs the live values (the global layer's, as no screen is asked for)
            active: idx.parsed.changed
        }
    }

    readonly property var results: {
        if (!index)
            return [];
        if (!query.trim())
            return [_openNexus];
        return index.results.list.map(it => ({
                    name: it.title,
                    desc: it.kind === "setting" ? it.breadcrumb : (it.breadcrumb || it.desc || ""),
                    icon: it.icon || "settings",
                    onClicked: list => root.open(it, list)
                }));
    }

    // With nothing typed yet: Enter opens Nexus where it was
    readonly property var _openNexus: ({
            name: Tr.tr("Open settings"),
            desc: Tr.tr("Or type to find a setting"),
            icon: "settings",
            onClicked: list => {
                list.screenState.launcher = false;
                WindowFactory.create();
            }
        })

    // As Nexus's search opens a result: a setting at its row (unless no row shows it), a page at its top
    function open(it: var, list: var): void {
        if (list?.screenState)
            list.screenState.launcher = false;
        WindowFactory.openAt(it.kind === "setting" && !it.noRow ? `${it.route}#${it.id}` : it.route);
    }
}
