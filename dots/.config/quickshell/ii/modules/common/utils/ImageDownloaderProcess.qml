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
    
    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    function processSourceUrl() {
        return StringUtils.shellSingleQuoteEscape(sourceUrl);
    }

    function curlUserAgentArg() {
        if (!downloadUserAgent) {
            return "";
        }
        return ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(downloadUserAgent)}'`;
    }

    function curlRefererArg() {
        return referer ? ` -e '${StringUtils.shellSingleQuoteEscape(referer)}'` : "";
    }

    running: true
    // caelestia4: download to .part and keep it only if it is an image, so a blocked request (HTML page) is never cached
    command: ["bash", "-c", 
        `mkdir -p $(dirname '${processFilePath()}'); [ -f '${processFilePath()}' ] || { curl -fsSL '${processSourceUrl()}'${curlUserAgentArg()}${curlRefererArg()} -o '${processFilePath()}.part' && file -b --mime-type '${processFilePath()}.part' | grep -q '^image/' && mv '${processFilePath()}.part' '${processFilePath()}'; } && file '${processFilePath()}'`
    ]
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
