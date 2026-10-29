#!/usr/bin/env bash
# caelestia4: run hyprlock, and start it again if it dies while the session is still locked. On resume the G95NC
# drops off and comes back (NVIDIA, DP 2.1); Hyprland then disconnects hyprlock with a protocol error ("error in
# client communication") and shows its "lock screen died" screen. misc.allow_session_lock_restore (on) lets a new
# hyprlock take the lock back. hyprlock exits 0 after a good password, so only a failed exit restarts it.
pidof hyprlock >/dev/null && exit 0
for attempt in 1 2 3 4 5; do
    hyprlock "$@" && exit 0
    echo "caelestia4: hyprlock exited with $?, starting it again ($attempt/5)" >&2
    sleep 1
done
exit 1
