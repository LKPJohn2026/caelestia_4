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
    # caelestia4: '@term <command>' runs <command> in the default terminal (uwsm -T, ~/.config/xdg-terminals.list)
    term=""
    if [[ "$cmd" == "@term "* ]]; then
        cmd="${cmd#@term }"
        term="-T"
    fi
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    # caelestia4: each app gets its own systemd unit (named after the app, not this script)
    eval "uwsm-app $term -- $cmd" &
    exit
done
