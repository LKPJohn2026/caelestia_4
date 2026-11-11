#!/usr/bin/env bash
# caelestia4: run hyprlock, and start it again if it dies while the session is still locked. On resume a screen can
# drop off and come back (seen with NVIDIA on DP 2.1); Hyprland then disconnects hyprlock with a protocol error ("error in
# client communication") and shows its "lock screen died" screen. misc.allow_session_lock_restore (on) lets a new
# hyprlock take the lock back. hyprlock exits 0 after a good password, so only a failed exit restarts it.
# hyprlock's output and the exits go to the journal (journalctl -t hyprlock -t hyprlock-guard): started from the shell
# or hypridle, they were lost, and with them why it died.
# (this user's: another session's lock doesn't lock this one)
pgrep -u "$(id -u)" -x hyprlock >/dev/null && exit 0
"$(dirname "$(readlink -f "$0")")/hyprlock-strings.sh" 2>/dev/null
for attempt in 1 2 3 4 5; do
    # Each time: what drops a hyprlock is usually a screen coming and going
    "$(dirname "$(readlink -f "$0")")/hyprlock-layout.sh" 2>/dev/null
    systemd-cat -t hyprlock hyprlock "$@" && exit 0
    status=$?
    # Hyprland's log is in $XDG_RUNTIME_DIR, which a reboot (the usual way out of a dead lock) clears
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia4"
    # This Hyprland's log, not the newest one (another session's or a nested Hyprland's could be newer)
    saved="Hyprland's log not saved (couldn't copy $XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/hyprland.log)"
    cp "$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/hyprland.log" "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia4/hyprland-lockfail.log" 2>/dev/null &&
        saved="Hyprland's log saved to ${XDG_STATE_HOME:-$HOME/.local/state}/caelestia4/hyprland-lockfail.log"
    logger -t hyprlock-guard "hyprlock exited with $status, starting it again ($attempt/5); $saved"
    sleep 1
done
logger -t hyprlock-guard "hyprlock failed 5 times; recover from a TTY (docs/install.md, Lock screen)"
exit 1
