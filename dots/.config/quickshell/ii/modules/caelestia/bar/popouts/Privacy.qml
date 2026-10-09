pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: privacy popout (end-4 Privacy indicators): which apps are recording audio / capturing the screen.
// Computed from PipeWire link groups here (end-4's Privacy service assigns a list to a bool, which is always true).
ColumnLayout {
    id: root

    function appName(node: var): string {
        if (!node)
            return Tr.tr("Unknown app");
        const p = node.properties ?? {};
        return p["application.name"] || p["node.name"] || node.description || node.name || Tr.tr("Unknown app");
    }

    readonly property var micApps: [...new Set(Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.AudioSource && g.target?.type === PwNodeType.AudioInStream).map(g => appName(g.target)))]
    readonly property var screenApps: [...new Set(Pipewire.linkGroups.values.filter(g => g.source?.type === PwNodeType.VideoSource).map(g => appName(g.target)))]

    spacing: Tokens.spacing.small

    Row {
        visible: root.micApps.length > 0
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "mic"
            color: Colours.palette.m3error
        }

        StyledText {
            text: Tr.tr("Microphone in use: %1").arg(root.micApps.join(", "))
        }
    }

    Row {
        visible: root.screenApps.length > 0
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "screen_record"
            color: Colours.palette.m3error
        }

        StyledText {
            text: Tr.tr("Screen being captured: %1").arg(root.screenApps.join(", "))
        }
    }

    StyledText {
        visible: root.micApps.length === 0 && root.screenApps.length === 0
        text: Tr.tr("No app is using the microphone or capturing the screen")
        color: Colours.palette.m3onSurfaceVariant
    }
}
