import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import "../functions/untrusted.js" as Untrusted

IconImage {
    id: root
    property string url
    property string displayText

    property real size: 32
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    property string faviconDownloadPath: Directories.favicons
    // caelestia4: a plain host name or nothing (the citation's URL and title come from search results)
    property string domainName: Untrusted.hostName(url.includes("vertexaisearch") ? displayText : Untrusted.urlHost(url))
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${encodeURIComponent(domainName)}&sz=32`
    property string fileName: `${domainName}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`
    property string urlToLoad

    Process {
        id: faviconDownloadProcess
        running: false
        // caelestia4: the values go in as arguments ($1 to $3), never into the shell code; the URL after curl's --
        command: ["bash", "-c", '[ -f "$1" ] || curl -s -o "$1" -L -H "User-Agent: $3" -- "$2"', "favicon",
            root.faviconFilePath, root.faviconUrl, root.downloadUserAgent]
        onExited: (exitCode, exitStatus) => {
            root.urlToLoad = root.faviconFilePath
        }
    }

    Component.onCompleted: {
        if (root.domainName.length === 0) return; // caelestia4: no good host name, no favicon
        faviconDownloadProcess.running = true
    }

    source: Qt.resolvedUrl(root.urlToLoad)
    implicitSize: root.size

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.implicitSize
            height: root.implicitSize
            radius: Appearance.rounding.full
        }
    }
}