pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

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
    
    function resetMany(keys: list<string>) {
        let args = []
        for (let i = 0; i < keys.length; i++) {
            args.push("--reset", String(keys[i]))
        }
        root.run(args)
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded()
            }
        }
    }
}
