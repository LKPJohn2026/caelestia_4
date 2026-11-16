pragma Singleton

import QtQuick
import Quickshell

// caelestia4: small Nexus UI state kept while the shell runs (and over a shell reload): which "Advanced" sections are
// open, by "<page route>#<key>" (AdvancedSection). Not saved to disk
Singleton {
    id: root

    readonly property var advancedOpen: props.advancedOpen

    function isOpen(key: string): bool {
        return props.advancedOpen[key] === true;
    }

    function setOpen(key: string, open: bool): void {
        if (!key || isOpen(key) === open)
            return;
        const m = Object.assign({}, props.advancedOpen);
        if (open)
            m[key] = true;
        else
            delete m[key];
        props.advancedOpen = m;
    }

    PersistentProperties {
        id: props

        property var advancedOpen: ({})

        reloadableId: "caelestia4NexusMemory"
    }
}
