pragma Singleton

import QtQuick
import Quickshell

// caelestia4: one place where the shell starts apps (Caelestia launcher, end-4 launcher search, docks, run commands).
// uwsm-only (the plain Hyprland session is no longer supported): every launch goes through uwsm-app, so each app gets
// its own systemd unit in app-graphical.slice instead of living in the shell's unit (where a shell restart would kill
// it). Terminal apps also go through uwsm: it reads Terminal=true from the desktop entry and starts the default
// terminal from ~/.config/xdg-terminals.list (Settings > Apps > Terminal) - one terminal choice for everything.
Singleton {
    id: root

    // workingDirectory is optional and typed var on purpose: a missing argument to a `string` parameter arrives as
    // the text "undefined", execDetached then can't enter that directory and silently starts nothing.

    // Run a command as its own unit
    function exec(command: var, workingDirectory: var): void {
        Quickshell.execDetached({
            command: ["uwsm-app", "--", ...command],
            workingDirectory: workingDirectory ?? ""
        });
    }

    // Run a command inside the default terminal (uwsm-app -T: terminal from xdg-terminals.list)
    function execInTerminal(command: var, workingDirectory: var): void {
        Quickshell.execDetached({
            command: ["uwsm-app", "-T", "--", ...command],
            workingDirectory: workingDirectory ?? ""
        });
    }

    // Launch a desktop entry by its id: uwsm handles Terminal=true, field codes and Path= itself
    // (Quickshell's DesktopEntry.execute() ignores Terminal=true and field codes)
    function launch(entry: var): void {
        root.exec([`${entry.id}.desktop`], entry.workingDirectory);
    }

    // Launch one of an entry's actions: uwsm resolves "<entry id>.desktop:<action id>"
    function launchAction(entry: var, action: var): void {
        root.exec([`${entry.id}.desktop:${action.id}`], entry.workingDirectory);
    }
}
