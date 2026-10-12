#!/usr/bin/env bash
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    # caelestia4: entries like 'command -v btop && kitty -1 fish -c btop' carry their own check; run it here, then
    # launch only the part after &&. Otherwise the check below tested `command` (a builtin, always found) and, under
    # uwsm, `uwsm-app -- command …` failed because uwsm-app needs a real executable.
    if [[ "$cmd" == "command -v "*" && "* ]]; then
        eval "${cmd%% && *}" >/dev/null 2>&1 || continue
        cmd="${cmd#* && }"
    fi
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    # caelestia4: in the uwsm session each app gets its own systemd unit (named after the app, not this script)
    if [[ "$CAELESTIA4_UWSM" == 1 ]]; then
        eval "uwsm-app -- $cmd" &
    else
        eval "$cmd" &
    fi
    exit
done
