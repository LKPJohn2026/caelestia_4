pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Nexus > Updates (upstream has only a placeholder): pending Arch repo and AUR updates and new commits
// for this caelestia_4 clone, from SystemUpdates (shared with the bar's updates icon and popout). Updating runs in a
// terminal that answers everything itself (scripts/caelestia4/system-update.sh); a check follows when it closes.
PageBase {
    id: root

    // caelestia4: SystemUpdates is shared with the bar's updates icon and popout, so all three show the same check
    readonly property var data: SystemUpdates.data
    readonly property var repoPkgs: SystemUpdates.repoPackages
    readonly property var aurPkgs: SystemUpdates.aurPackages
    readonly property var c4: SystemUpdates.caelestia4
    readonly property int total: SystemUpdates.count
    readonly property bool checking: SystemUpdates.checking

    // caelestia4: system.py's errors (English, also for its command line) as a plain title, a hint and what can be
    // done about it: `retry` = try the check again, `install` = install the missing update checker, `net` = the
    // internet connection is the likely cause
    function problem(error: string): var {
        if (!error)
            return null;
        if (error === "checkupdates is not installed (pacman-contrib)")
            return {
                title: Tr.tr("The update checker isn't installed"),
                hint: Tr.tr("It comes with the pacman-contrib package"),
                install: true
            };
        if (error === "checkupdates failed (offline?)")
            return {
                title: Tr.tr("Couldn't reach the package servers"),
                hint: Tr.tr("Check the internet connection, then try again"),
                retry: true,
                net: true
            };
        if (/ -Qua failed \(offline\?\)$/.test(error))
            return {
                title: Tr.tr("Couldn't reach the AUR"),
                hint: Tr.tr("Check the internet connection, then try again"),
                retry: true,
                net: true
            };
        if (error.startsWith("clone not found"))
            return {
                title: Tr.tr("caelestia_4 source folder not found"),
                hint: Tr.tr("Updates look for the caelestia_4 folder you installed from. Run its installer once more so the shell knows where it is")
            };
        if (error === "the branch has no upstream")
            return {
                title: Tr.tr("This copy isn't linked to an online branch"),
                hint: Tr.tr("So new versions can't be checked for")
            };
        if (error.startsWith("git fetch failed"))
            return {
                title: Tr.tr("Couldn't reach the server"),
                hint: Tr.tr("Showing the last check. Check the internet connection, then try again"),
                retry: true,
                net: true
            };
        if (error.startsWith("The server asked for a sign-in"))
            return {
                title: Tr.tr("The server asked for a sign-in"),
                hint: Tr.tr("Often a short limit on automatic checks: try again later. Showing the last check"),
                retry: true
            };
        return {
            title: Tr.tr("Couldn't check"),
            hint: SystemUpdates.errorText(error) ?? "",
            retry: true
        };
    }

    readonly property var repoProblem: problem(data.repo?.error ?? "")
    readonly property var aurProblem: problem(data.aur?.error ?? "")
    readonly property var c4Problem: problem(c4.error ?? "")
    // caelestia4: a failed package check shows once, in the System summary (not again under Arch or AUR packages),
    // with one button: Check now. A second, different problem (repo and AUR) goes in its description
    readonly property var pkgProblem: repoProblem ?? aurProblem
    readonly property var pkgProblem2: repoProblem && aurProblem && aurProblem.title !== repoProblem.title ? aurProblem : null
    // caelestia4: the first check hasn't answered yet
    readonly property bool c4Loaded: !!c4.path || !!c4.error
    // caelestia4: an error that leaves nothing to show (no folder, no online branch); a failed fetch keeps the last check
    readonly property bool c4NoData: !!c4Problem && (!c4Problem.retry || !c4.path)
    // caelestia4: a failed caelestia_4 check is shown in its own row, except an offline one while the System summary
    // already shows an offline package check (one cause, shown once)
    readonly property bool c4ProblemShown: !c4NoData && !!c4Problem && !(c4Problem.net && pkgProblem?.net)

    title: Tr.tr("Updates")

    Component.onCompleted: SystemUpdates.checkPasswordless()

    // caelestia4: RowGroup sets the rows' first/last, the Repeaters' rows too
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("System")
        }

        InfoRow {
            icon: root.checking ? "sync" : root.total > 0 ? "system_update_alt" : SystemUpdates.error ? "error" : "check_circle"
            label: root.checking ? Tr.tr("Checking for updates…") : root.total > 0 ? Tr.trN("%n update available", "%n updates available", root.total) : root.pkgProblem ? root.pkgProblem.title : SystemUpdates.error ? Tr.tr("Couldn't check for updates") : Tr.tr("Up to date")
            subtext: [root.checking || !root.pkgProblem ? "" : root.total > 0 ? root.pkgProblem.title : root.pkgProblem.hint, root.checking ? "" : root.pkgProblem2?.title ?? "", SystemUpdates.since()].filter(s => s).join(" · ")
        }

        RowButton {
            icon: "refresh"
            // caelestia4: "Try again" only when trying again can help (not for a missing update checker)
            text: root.pkgProblem?.retry && !root.checking ? Tr.tr("Try again") : Tr.tr("Check now")
            disabled: root.checking
            onClicked: SystemUpdates.refresh()
        }

        RowButton {
            visible: !!root.repoProblem?.install
            icon: "download"
            text: Tr.tr("Install the update checker")
            subtext: Tr.tr("In a terminal; asks for the password")
            disabled: SystemUpdates.terminalOpen
            onClicked: SystemUpdates.runInTerminal("sudo pacman -S --needed pacman-contrib")
        }

        RowButton {
            icon: "download"
            text: Tr.tr("Update everything")
            subtext: SystemUpdates.terminalOpen ? Tr.tr("Running in a terminal…") : SystemUpdates.passwordlessWide ? Tr.tr("No questions; AUR build scripts aren't reviewed") : SystemUpdates.passwordlessUpdates ? Tr.tr("Repo packages with no password; AUR updates and rebuilds ask for it. AUR build scripts aren't reviewed") : Tr.tr("The password once, then no questions; AUR build scripts aren't reviewed")
            disabled: root.checking || root.total === 0 || SystemUpdates.terminalOpen
            onClicked: SystemUpdates.updatePackages()
        }

        // caelestia4: a sudoers rule, not a config option (x:updates.passwordless): the row shows whether the repo upgrade
        // runs with no password (and whether an older rule, or another file's, lets all of pacman) and turns the rule on
        // or off in a terminal. Turning it on asks first; turning it off doesn't
        ToggleRow {
            id: passwordlessRow

            // caelestia4: true while "Upgrade repo packages without a password?" asks, so the switch stays on meanwhile
            // (it would flip back after 2 s); `askStep` is the undo step the switch recorded, dropped again if the answer
            // is Cancel
            property bool asking
            property var askStep: null

            function endAsk(keepStep: bool): void {
                if (!keepStep && askStep)
                    NexusActions.steps = NexusActions.steps.filter(s => s !== askStep);
                askStep = null;
                asking = false;
            }

            setting: "x:updates.passwordless"
            // caelestia4: the rule's script is in the caelestia_4 folder; say why the switch is off-limits
            subtext: root.c4Loaded && !root.c4.path ? Tr.tr("Needs the caelestia_4 source folder, which wasn't found") : SystemUpdates.terminalOpen ? Tr.tr("Running in a terminal…") : SystemUpdates.passwordlessWideOther ? Tr.tr("On through another sudoers rule (%1) that lets any program under this account run pacman as root, or more. This switch can't change it").arg(SystemUpdates.passwordlessEntry || Tr.tr("file unknown")) : SystemUpdates.passwordlessWide ? Tr.tr("On, with an older rule that lets any program under this account run pacman as root. Turn this off and on again to narrow it") : SystemUpdates.passwordlessUnknown ? Tr.tr("Can't tell: this sudo doesn't say whether updates need the password, so they ask for it at the start") : SystemUpdates.passwordlessUpdates ? Tr.tr("On: repo upgrades ask nothing; AUR updates and shell rebuilds ask for the password") : Tr.tr("Off: updates ask for the password once, at the start")
            // (A rule from another sudoers file stays whatever this does: off would flip back on)
            disabled: !root.c4.path || SystemUpdates.terminalOpen || SystemUpdates.passwordlessWideOther
            link.s.customValue: SystemUpdates.passwordlessUpdates || passwordlessRow.asking
            link.s.customDefault: false

            Connections {
                // The switch is the only way in, but an undo or a reset comes here too: only act on a real change
                function onCustomSet(v: var): void {
                    if (!!v === SystemUpdates.passwordlessUpdates) {
                        // Undo of a turn-on that is still asking
                        if (passwordlessRow.asking) {
                            passwordlessConfirm.close();
                            passwordlessRow.endAsk(false);
                        }
                        return;
                    }
                    if (v) {
                        // RowSetting records the undo step right after this returns: catch it
                        const last = NexusActions.steps[NexusActions.steps.length - 1];
                        Qt.callLater(() => {
                            const top = NexusActions.steps[NexusActions.steps.length - 1];
                            passwordlessRow.askStep = top !== last ? top : null;
                        });
                        passwordlessRow.asking = true;
                        passwordlessConfirm.open();
                    } else {
                        SystemUpdates.setPasswordlessUpdates(false);
                    }
                }

                function onCustomReset(): void {
                    if (SystemUpdates.passwordlessUpdates)
                        SystemUpdates.setPasswordlessUpdates(false);
                }

                target: passwordlessRow.link.s
            }
        }

        ConfirmDialog {
            id: passwordlessConfirm

            title: Tr.tr("Upgrade repo packages without a password?")
            // caelestia4: no file names or commands here; docs/install.md has them
            text: Tr.tr("This adds a system rule that lets this account upgrade the packages from your repos, and their signing keys, with no password. Those are signed packages only, so nothing running under this account can become root through the rule. AUR updates and shell rebuilds still ask for the password.\n\nA terminal asks for your password once. To undo it, turn this off here.")
            confirmText: Tr.trCtx("Turn on", "button")
            onAccepted: {
                const go = !!root.c4.path && !SystemUpdates.terminalOpen && !SystemUpdates.passwordlessUpdates;
                if (go)
                    SystemUpdates.setPasswordlessUpdates(true);
                passwordlessRow.endAsk(go);
                passwordlessRow.rebind();
            }
            onRejected: {
                passwordlessRow.endAsk(false);
                passwordlessRow.rebind();
            }
        }

        // caelestia4: end-4's update check settings (SystemUpdates reads them)
        SectionHeader {
            text: Tr.tr("Automatic checks")
        }

        ToggleRow {
            setting: "e4:updates.enableCheck"
        }

        DurationRow {
            setting: "e4:updates.checkInterval"
        }

        SectionHeader {
            visible: root.repoPkgs.length > 0
            text: Tr.tr("Arch packages (%1)").arg(root.repoPkgs.length)
        }

        Repeater {
            model: root.repoPkgs

            InfoRow {
                required property var modelData
                required property int index

                label: modelData.name
                value: `${modelData.from} → ${modelData.to}`
            }
        }

        SectionHeader {
            visible: root.aurPkgs.length > 0
            text: Tr.tr("AUR packages (%1)").arg(root.aurPkgs.length)
        }

        Repeater {
            model: root.aurPkgs

            InfoRow {
                required property var modelData
                required property int index

                label: modelData.name
                value: `${modelData.from} → ${modelData.to}`
            }
        }

        SectionHeader {
            text: "caelestia_4"
        }

        InfoRow {
            icon: root.c4NoData ? "error" : !root.c4Loaded ? (root.checking ? "sync" : "schedule") : root.c4.diverged ? "warning" : (root.c4.behind ?? 0) > 0 ? "upgrade" : "check_circle"
            label: root.c4NoData ? root.c4Problem.title : !root.c4Loaded ? (root.checking ? Tr.tr("Checking…") : Tr.tr("Not checked yet")) : (root.c4.behind ?? 0) > 0 ? Tr.trN("%n new commit", "%n new commits", root.c4.behind) : Tr.tr("Up to date")
            // caelestia4: the branch, not the folder and remote (no paths in the page)
            subtext: !root.c4.path ? (root.c4Problem?.hint ?? "") : [root.c4NoData ? root.c4Problem.hint : "", root.c4Problem && !root.c4NoData && !root.c4ProblemShown ? Tr.tr("Showing the last check") : "", root.c4.branch ? Tr.tr("Branch %1").arg(root.c4.branch) : "", root.c4.dirty ? Tr.tr("Has local changes") : "", (root.c4.ahead ?? 0) > 0 ? Tr.trN("%n local commit not pushed", "%n local commits not pushed", root.c4.ahead) : ""].filter(s => s).join(" · ")
        }

        // caelestia4: a check of the folder that failed (offline, sign-in): the lists show the last one. Not when both
        // checks were offline: the System summary already says so, and the row above says the last check is shown
        InfoRow {
            visible: root.c4ProblemShown
            icon: "error"
            label: root.c4Problem?.title ?? ""
            subtext: root.c4Problem?.hint ?? ""
        }

        RowButton {
            // caelestia4: one "Try again" on the page: the System one also checks caelestia_4 again
            visible: !!root.c4Problem?.retry && !root.pkgProblem?.retry
            icon: "refresh"
            text: Tr.tr("Try again")
            disabled: root.checking
            onClicked: SystemUpdates.refresh()
        }

        Repeater {
            model: root.c4.commits ?? []

            InfoRow {
                required property var modelData

                label: modelData.subject
                value: modelData.hash
                subtext: Tr.formatDateTime(new Date(modelData.date), "ddd dd/MM hh:mm")
            }
        }

        RowButton {
            icon: "download"
            text: Tr.tr("Update caelestia_4")
            subtext: !root.c4Loaded ? (root.checking ? Tr.tr("Checking…") : Tr.tr("Not checked yet")) : !root.c4.path ? Tr.tr("Needs the caelestia_4 source folder") : root.c4NoData ? (root.c4.error === "the branch has no upstream" ? Tr.tr("Needs an online branch to update from") : Tr.tr("Couldn't check")) : root.c4.diverged ? Tr.tr("This copy has commits of its own, so it can't update by itself. See Updating in the install guide") : root.c4.dirty ? Tr.tr("Commit or set aside the local changes first") : (root.c4.behind ?? 0) === 0 ? Tr.tr("Nothing new to install") : Tr.tr("Downloads the new version and reinstalls it, in a terminal")
            disabled: root.checking || !root.c4.path || (root.c4.behind ?? 0) === 0 || root.c4.dirty || !!root.c4.diverged
            onClicked: SystemUpdates.updateCaelestia4()
        }

        // caelestia4: the last block of the page (it sat between the check settings and the package lists)
        AdvancedSection {
            StepperRow {
                setting: "e4:updates.adviseUpdateThreshold"
            }

            StepperRow {
                setting: "e4:updates.stronglyAdviseUpdateThreshold"
            }
        }
    }
}
