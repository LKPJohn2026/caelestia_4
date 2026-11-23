pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Renders LaTeX snippets with MicroTeX.
 * For every request:
 *   1. Hash it
 *   2. Check if the hash is already processed
 *   3. If not, render it with MicroTeX and mark as processed
 */
Singleton {
    id: root

    readonly property var renderPadding: 4 // This is to prevent cutoff in the rendered images

    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    property string microtexBinaryDir: "/opt/MicroTeX"
    property string microtexBinaryName: "LaTeX"
    property string latexOutputPath: Directories.latexOutput
    readonly property int maxExpressionLength: 2000 // caelestia4: a longer "expression" isn't rendered

    signal renderFinished(string hash, string imagePath)

    // caelestia4: MicroTeX runs directly, with the expression as one argument (no shell, no QML source built from
    // the model's text), in its own folder, where it finds its fonts
    Component {
        id: microtexProcess
        Process {
            id: proc
            property string hash
            property string imagePath
            workingDirectory: root.microtexBinaryDir
            // stdout: SplitParser {
            //     onRead: data => { console.log("MicroTeX: " + data) }
            // }
            onExited: (exitCode, exitStatus) => {
                // console.log("[LatexRenderer] MicroTeX process exited with code: " + exitCode + ", status: " + exitStatus)
                if (exitCode === 0) {
                    root.renderedImagePaths[proc.hash] = proc.imagePath
                    root.renderFinished(proc.hash, proc.imagePath)
                }
                proc.destroy()
            }
        }
    }

    // caelestia4: the argument list MicroTeX gets (tools/tests/ai-safety checks it keeps the expression whole)
    function microtexCommand(expression, imagePath) {
        return [`${root.microtexBinaryDir}/${root.microtexBinaryName}`, "-headless",
            `-input=${expression}`,
            `-output=${imagePath}`,
            `-textsize=${Appearance.font.pixelSize.normal}`,
            `-padding=${root.renderPadding}`,
            // `-background=${Appearance.m3colors.m3tertiary}`,
            `-foreground=${Appearance.colors.colOnLayer1}`,
            "-maxwidth=0.85"]
    }

    /**
    * Requests rendering of a LaTeX expression.
    * Returns the [hash, isNew]
    */
    function requestRender(expression) {
        // 1. Hash it and initialize necessary variables
        const hash = Qt.md5(expression)
        const imagePath = `${latexOutputPath}/${hash}.svg`

        // 2. Check if the hash is already processed
        if (processedHashes.includes(hash)) {
            // console.log("Already processed: " + hash)
            if (root.renderedImagePaths[hash]) renderFinished(hash, imagePath) // caelestia4: only once it has rendered
            return [hash, false]
        } else {
            root.processedHashes.push(hash)
            root.processedExpressions[hash] = expression
            // console.log("Rendering expression: " + expression)
        }

        // 3. If not, render it with MicroTeX and mark as processed
        // console.log(`[LatexRenderer] Rendering expression: ${expression} with hash: ${hash}`)
        // console.log(`                to file: ${imagePath}`)
        if (expression.length > root.maxExpressionLength) return [hash, false]
        microtexProcess.createObject(root, {
            "hash": hash,
            "imagePath": imagePath,
            "command": root.microtexCommand(expression, imagePath),
            "running": true,
        })
        return [hash, true]
    }
}
