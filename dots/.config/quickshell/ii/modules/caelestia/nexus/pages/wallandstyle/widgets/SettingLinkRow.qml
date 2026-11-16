import QtQuick
import Caelestia.I18n
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.registry

// caelestia4: a row that opens a setting kept on another page (its registry route#id), for an option a widget uses
// that is shared with other parts of the shell (weather location, default player...). Title from the entry; the
// description says which page it opens
NavRow {
    id: root

    required property var nState
    property string target
    readonly property var entry: Registry.entry(target)
    readonly property string pageLabel: {
        const route = entry?.route ?? "";
        return PageRegistry.pages[PageRegistry.indexOf(route.split("/")[0])]?.label ?? "";
    }

    visible: !!entry
    // caelestia4: no icon, so no gap for one: the text starts where setting rows' text does
    iconLabel.visible: false
    text: entry ? Tr.tr(entry.title) : ""
    // TRANSLATORS: %1 is a settings page, e.g. "Language & region"
    subtext: pageLabel ? Tr.tr("Set in %1").arg(pageLabel) : ""
    Accessible.name: text
    Accessible.description: subtext
    onClicked: {
        if (root.entry && root.nState)
            root.nState.navigate(root.entry.route + "#" + root.target);
    }
}
