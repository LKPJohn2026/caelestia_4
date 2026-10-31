#!/usr/bin/env bash
# caelestia4: run hyprlock, and start it again if it dies while the session is still locked. On resume the G95NC
# drops off and comes back (NVIDIA, DP 2.1); Hyprland then disconnects hyprlock with a protocol error ("error in
# client communication") and shows its "lock screen died" screen. misc.allow_session_lock_restore (on) lets a new
# hyprlock take the lock back. hyprlock exits 0 after a good password, so only a failed exit restarts it.
# hyprlock's output and the exits go to the journal (journalctl -t hyprlock -t hyprlock-guard): started from the shell
# or hypridle, they were lost, and with them why it died.
pidof hyprlock >/dev/null && exit 0
for attempt in 1 2 3 4 5; do
    systemd-cat -t hyprlock hyprlock "$@" && exit 0
    logger -t hyprlock-guard "hyprlock exited with $?, starting it again ($attempt/5)"
    sleep 1
done
logger -t hyprlock-guard "hyprlock failed 5 times; recover from a TTY (docs/install.md, Lock screen)"
exit 1
