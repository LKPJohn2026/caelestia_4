import QtQuick
import qs.modules.caelestia.nexus.common

// caelestia4: a PathRow for an option whose default is a shell asset ("root:/assets/dino.png"): the field shows the
// asset's file name ("dino.png"), not the raw "root:/…" path. A typed path saves as usual; an unchanged field saves
// nothing, so the asset stays
PathRow {
    id: root

    field.savedText: root.value.startsWith("root:/") ? root.value.slice(root.value.lastIndexOf("/") + 1) : root.shorten(root.value)
}
