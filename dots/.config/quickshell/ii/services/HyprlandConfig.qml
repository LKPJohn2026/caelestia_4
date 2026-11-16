pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Hyprland
 */
Singleton {
    id: root
    
    signal reloaded()

    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/hyprconfigurator.py")
    readonly property string shellOverridesPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/main.lua`)

    // caelestia4: the arguments as a list, not a bash -c line. Values come from text fields (keyboard options, a
    // shader path): a quote ended the bash string early, and $(...) or a backtick in one ran as a command.
    function run(args: var) {
        Quickshell.execDetached([root.configuratorScriptPath, "--file", root.shellOverridesPath].concat(args))
        overridesReloadTimer.restart() // caelestia4: the file may not exist yet, so nothing watches it
    }

    function set(key: string, value: var) {
        root.run(["--set", String(key), String(value)])
    }
    
    function setMany(entries: var) {
        let args = []
        for (let key in entries) {
            args.push("--set", String(key), String(entries[key]))
        }
        root.run(args)
    }
    
    function reset(key: string) {
        root.run(["--reset", String(key)])
    }
    
    // caelestia4: the keys the shell overrides file sets ("decoration:rounding": its Lua value as a string), read
    // back from what hyprconfigurator.py writes: one `hl.config({decoration={rounding=10}})` per line.
    // overridesRevision goes up at each re-read, so bindings that call isOverridden() can depend on it.
    property var overrides: ({})
    property int overridesRevision: 0

    function isOverridden(key: string): bool {
        root.overridesRevision // dependency
        return Object.prototype.hasOwnProperty.call(root.overrides, String(key))
    }

    function overrideValue(key: string): var {
        root.overridesRevision // dependency
        return root.isOverridden(key) ? root.overrides[String(key)] : undefined
    }

    function parseOverrides(text: string) {
        let result = {}
        const lines = (text ?? "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const entry = root.parseOverrideLine(lines[i])
            if (entry)
                result[entry.key] = entry.value
        }
        root.overrides = result
        root.overridesRevision++
    }

    // `hl.config({a={b=VALUE}})` -> { key: "a:b", value: "VALUE" (strings unquoted) }, null for any other line
    function parseOverrideLine(line: string): var {
        const m = line.match(/^\s*hl\.config\(\{(.*)\}\)\s*$/)
        if (!m)
            return null
        let rest = m[1]
        let parts = []
        while (true) {
            const k = rest.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*/)
            if (!k)
                return null
            parts.push(k[1])
            rest = rest.slice(k[0].length)
            if (rest.startsWith("{")) {
                rest = rest.slice(1).replace(/\}\s*$/, "")
                continue
            }
            return { key: parts.join(":"), value: root.luaValue(rest.trim()) }
        }
    }

    // The inverse of hyprconfigurator.py's lua_string(); numbers and booleans stay as written
    function luaValue(text: string): string {
        if (!(text.startsWith("\"") && text.endsWith("\"") && text.length >= 2))
            return text
        return text.slice(1, -1).replace(/\\(\d{3}|n|.)/g, (all, c) => {
            if (c === "n")
                return "\n"
            if (c.length === 3)
                return String.fromCharCode(parseInt(c, 10))
            return c
        })
    }

    function resetMany(keys: list<string>) {
        let args = []
        for (let i = 0; i < keys.length; i++) {
            args.push("--reset", String(keys[i]))
        }
        root.run(args)
    }

    Timer {
        id: overridesReloadTimer
        interval: 400
        onTriggered: overridesFile.reload()
    }

    FileView {
        id: overridesFile
        path: root.shellOverridesPath
        watchChanges: true
        printErrors: false // no file until something is overridden
        onFileChanged: reload()
        onLoaded: root.parseOverrides(text())
        onLoadFailed: root.parseOverrides("")
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                overridesFile.reload() // caelestia4: Hyprland reloads when the overrides file changes
                root.reloaded()
            }
        }
    }
}
