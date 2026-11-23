pragma Singleton

// caelestia4 ADAPTER: SystemUpdates
// One source for every updates UI: the bar's updates icon and popout and Nexus > Updates. Data comes from
// utils/scripts/system.py (`updates`: Arch repo via checkupdates, AUR via yay/paru, new commits for this caelestia_4
// clone; `cached`: the last result). Replaces end-4's Updates service (repo packages only) for the Caelestia panels.
// end-4's settings still apply: updates.enableCheck, updates.checkInterval (minutes) and the advise thresholds.

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4's updates.* settings)

Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("modules/caelestia/utils/scripts/system.py")

    property var data: ({})
    readonly property bool checking: checkProc.running
    readonly property bool terminalOpen: terminalProc.running
    property bool passwordlessChecked
    // The repo upgrade runs with no password (the rule of tools/update-sudo-rule.sh, or another); with the wide one any
    // pacman command does (that tool's older rule, or one from another sudoers file, passwordlessEntry, which that tool
    // can't change), else AUR updates and rebuilds still ask. Unknown: sudo doesn't say (taken as off)
    property bool passwordlessUpdates
    property bool passwordlessWide
    property bool passwordlessWideOther
    property bool passwordlessUnknown
    property string passwordlessEntry
    readonly property string checked: data.checked ?? ""
    readonly property var repoPackages: data.repo?.packages ?? []
    readonly property var aurPackages: data.aur?.packages ?? []
    readonly property string aurHelper: data.aur?.helper ?? ""
    readonly property var caelestia4: data.caelestia4 ?? ({})
    readonly property int caelestia4Behind: caelestia4.behind ?? 0
    // Packages waiting (repo + AUR); the bar shows this number
    readonly property int count: repoPackages.length + aurPackages.length
    readonly property bool pending: count > 0 || caelestia4Behind > 0
    // The last check failed (offline, or checkupdates / the AUR helper erred): its empty lists don't mean up to date
    readonly property string error: data.repo?.error || data.aur?.error || ""
    readonly property bool updateAdvised: count > (E4C.Config.options.updates.adviseUpdateThreshold ?? 75)
    readonly property bool updateStronglyAdvised: count > (E4C.Config.options.updates.stronglyAdviseUpdateThreshold ?? 200)

    // system.py's errors are English (also for its CLI use); these are the ones it can return, translated. An empty or
    // missing error comes back as it is
    function errorText(error: var): var {
        if (!error)
            return error;
        const aur = /^(\S+) -Qua failed \(offline\?\)$/.exec(error);
        if (aur)
            return Tr.tr("%1 -Qua failed (offline?)").arg(aur[1]);
        return {
            "checkupdates is not installed (pacman-contrib)": Tr.tr("checkupdates is not installed (pacman-contrib)"),
            "checkupdates failed (offline?)": Tr.tr("checkupdates failed (offline?)"),
            "clone not found (run tools/install-main.sh once)": Tr.tr("clone not found (run tools/install-main.sh once)"),
            "the branch has no upstream": Tr.tr("the branch has no upstream"),
            "git fetch failed (offline?): showing the last fetch": Tr.tr("git fetch failed (offline?): showing the last fetch"),
            "The server asked for a sign-in, often a temporary limit on bots: try again later, and if it lasts check the clone's remote. Showing the last fetch": Tr.tr("The server asked for a sign-in, often a temporary limit on bots: try again later, and if it lasts check the clone's remote. Showing the last fetch")
        }[error] ?? error;
    }

    function refresh(): void {
        checkProc.running = true;
    }

    // In the default terminal (uwsm -T), kept open at the end; a check follows once it's closed. Text (translations) is
    // never part of the command: it comes in as bash's $1 ("Done...") and $2, $3, ... (`texts`), so a quote or $(...)
    // in a translation stays text
    function runInTerminal(command: string, texts: var): void {
        if (terminalProc.running) // (the Process would queue it, and run it when that terminal closes)
            return;
        terminalProc.command = ["uwsm-app", "-T", "--", "bash", "-c", `${command}; echo; read -rp "$1"`, "bash", Tr.tr("Done. Press Enter to close."), ...(texts ?? [])];
        terminalProc.running = true;
    }

    // Asks only for the password, where sudo needs it (scripts/caelestia4/system-update.sh), and closes by itself unless
    // something failed
    function updatePackages(): void {
        if (terminalProc.running)
            return;
        terminalProc.command = ["uwsm-app", "-T", "--", Quickshell.shellPath("scripts/caelestia4/system-update.sh")];
        terminalProc.running = true;
    }

    // tools/update-sudo-rule.sh, which has to ask for the password to give up asking for it
    function setPasswordlessUpdates(on: bool): void {
        if (caelestia4.path)
            runInTerminal(`sudo '${caelestia4.path}/tools/update-sudo-rule.sh' ${on ? "enable" : "disable"}`);
    }

    function updateCaelestia4(): void {
        if (caelestia4.path)
            runInTerminal(`cd '${caelestia4.path}' && { git pull --ff-only || { printf '%s\\n' "$2"; false; }; } && tools/install-main.sh`, [Tr.tr("git pull failed. If the server asked for a sign-in, try again later: see Updating in docs/install.md")]);
    }

    // Asked of sudo itself (scripts/caelestia4/update-sudo-state.sh, which runs nothing as root), only where it's shown:
    // when a password is needed, every try is an alert in sudo's log
    function checkPasswordless(): void {
        passwordlessProc.running = true;
    }

    function since(): string {
        if (!checked)
            return Tr.tr("Never checked");
        const mins = Math.round((Date.now() - new Date(checked).getTime()) / 60000);
        if (mins < 1)
            return Tr.tr("Checked just now");
        if (mins < 60)
            return Tr.tr("Checked %1 min ago").arg(mins);
        return Tr.tr("Checked %1").arg(Tr.formatDateTime(new Date(checked), "ddd hh:mm"));
    }

    // The last result right away; a fresh check when it's older than the check interval
    Process {
        running: true
        command: [root.script, "cached"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(text);
                } catch (e) {
                    root.data = {};
                }
                const interval = (E4C.Config.options.updates.checkInterval ?? 120) * 60000;
                if (!root.checked || root.error || Date.now() - new Date(root.checked).getTime() > interval)
                    root.refresh();
            }
        }
    }

    Process {
        id: checkProc

        command: [root.script, "updates"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: terminalProc

        // uwsm-app -T returns when the terminal window closes
        onExited: {
            root.refresh();
            if (root.passwordlessChecked)
                root.checkPasswordless();
        }
    }

    Process {
        id: passwordlessProc

        command: ["bash", Quickshell.shellPath("scripts/caelestia4/update-sudo-state.sh")]
        stdout: StdioCollector {
            id: passwordlessOut
        }
        stderr: StdioCollector {}
        onExited: code => {
            // The state (split, wide own, wide other, off, off unlisted or unknown), then the deciding sudoers file
            const lines = code === 0 ? passwordlessOut.text.split("\n") : [];
            const words = (lines[0] ?? "off").trim().split(" ");
            const state = words[0] || "off";
            root.passwordlessUpdates = state === "split" || state === "wide";
            root.passwordlessWide = state === "wide";
            root.passwordlessWideOther = state === "wide" && words[1] !== "own";
            root.passwordlessUnknown = state === "unknown";
            root.passwordlessEntry = (lines[1] ?? "").trim();
            root.passwordlessChecked = true;
        }
    }

    // A failed check (e.g. the network not back yet after waking) is tried again in 5 minutes, not at the next interval
    Timer {
        interval: 5 * 60000
        running: !!root.error && !root.checking
        onTriggered: root.refresh()
    }

    Timer {
        interval: Math.max(5, E4C.Config.options.updates.checkInterval ?? 120) * 60000
        repeat: true
        running: E4C.Config.ready && (E4C.Config.options.updates.enableCheck ?? true)
        onTriggered: root.refresh()
    }
}
