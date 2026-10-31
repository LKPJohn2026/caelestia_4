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

    function refresh(): void {
        checkProc.running = true;
    }

    // In the default terminal (uwsm -T), kept open at the end; a check follows once it's closed
    function runInTerminal(command: string): void {
        terminalProc.command = ["uwsm-app", "-T", "--", "bash", "-c", `${command}; echo; read -rp "${Tr.tr("Done. Press Enter to close.")}"`];
        terminalProc.running = true;
    }

    function updatePackages(): void {
        runInTerminal(aurHelper || "sudo pacman -Syu");
    }

    function updateCaelestia4(): void {
        if (caelestia4.path)
            runInTerminal(`cd '${caelestia4.path}' && git pull --ff-only && tools/install-main.sh`);
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
        onExited: root.refresh()
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
