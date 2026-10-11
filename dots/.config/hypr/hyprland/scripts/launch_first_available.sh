#!/usr/bin/env bash
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    # caelestia4: in the uwsm session each app gets its own systemd unit (named after the app, not this script)
    if [[ "$CAELESTIA4_UWSM" == 1 ]]; then
        eval "uwsm-app -- $cmd" &
    else
        eval "$cmd" &
    fi
    exit
done
