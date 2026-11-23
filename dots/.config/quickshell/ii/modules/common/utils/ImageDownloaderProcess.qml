import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    property string referer: "" // caelestia4: for hotlink-protected hosts (Gelbooru's CDN redirects to HTML without one)
    
    // caelestia4: the user agent and referer as curl arguments (never shell code)
    function curlExtraArgs() {
        return (downloadUserAgent ? ["-H", `User-Agent: ${downloadUserAgent}`] : []).concat(referer ? ["-e", referer] : []);
    }

    running: true
    // caelestia4: download to .part and keep it only if it is an image, so a blocked request (HTML page) is never cached.
    // The path ($1), URL ($2) and curl arguments go in as arguments, never into the shell code, and "--" keeps a URL
    // that starts with "-" from being read as a curl option.
    command: ["bash", "-c",
        'mkdir -p -- "$(dirname -- "$1")"; [ -f "$1" ] || { curl -fsSL "${@:3}" -o "$1.part" -- "$2" && file -b --mime-type -- "$1.part" | grep -q "^image/" && mv -- "$1.part" "$1"; } && file -- "$1"',
        "bash", FileUtils.trimFileProtocol(filePath), sourceUrl].concat(curlExtraArgs())
    stdout: StdioCollector {
        id: imageSizeOutputCollector
        onStreamFinished: {
            const output = imageSizeOutputCollector.text.trim();
            const match = output.match(/(\d+)\s*x\s*(\d+)/);

            if (match) {
                const width = Number(match[1]);
                const height = Number(match[2]);
                root.done(root.filePath, width, height);
            }
        }
    }
}
