pragma Singleton

import QtQuick
import Quickshell

// caelestia4: one place where the shell starts apps (Caelestia launcher, end-4 launcher search, docks).
// In the uwsm session (CAELESTIA4_UWSM=1, from ~/.config/uwsm/env-hyprland) the shell itself is a systemd unit
// (caelestia4-shell.service). Anything it starts directly would live in that unit's cgroup: listed under the shell,
// and killed when the shell restarts (Ctrl+Super+R, a crash + Restart=on-failure). Handing launches to uwsm gives
// each app its own unit in app-graphical.slice instead. Outside uwsm everything behaves as before.
Singleton {
    id: root

    readonly property bool uwsm: Quickshell.env("CAELESTIA4_UWSM") === "1"

    // A command that runs as its own unit under uwsm (unchanged otherwise). uwsm-app = uwsm's fast client.
    function wrap(command: var): var {
        return root.uwsm ? ["uwsm-app", "--", ...command] : command;
    }

    function exec(command: var, workingDirectory: string): void {
        Quickshell.execDetached({
            command: root.wrap(command),
            workingDirectory: workingDirectory ?? ""
        });
    }

    // Launch a desktop entry (Quickshell DesktopEntry: id, command, workingDirectory, execute()).
    function launch(entry: var): void {
        if (!root.uwsm) {
            entry.execute();
            return;
        }
        root.exec(entry.command, entry.workingDirectory);
    }

    // Launch one of an entry's actions (DesktopAction: id, command, execute()).
    function launchAction(entry: var, action: var): void {
        if (!root.uwsm) {
            action.execute();
            return;
        }
        // uwsm resolves "<entry id>.desktop:<action id>" like a desktop environment would
        root.exec([`${entry.id}.desktop:${action.id}`], entry.workingDirectory);
    }
}
