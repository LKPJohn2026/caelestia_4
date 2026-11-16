#!/usr/bin/env bash
# caelestia4: Nexus > About > Copy diagnostics. Writes a text for a bug report: versions (caelestia4's git describe,
# Quickshell, Hyprland from `hyprctl version -j`, the Caelestia plugin build, Qt, the system), the changed settings
# (nexus-export.sh, secrets removed) and the last 100 lines of the shell's log (qs log, else the journal of
# caelestia4-shell.service). Everything is read-only; secret-looking text in the log is replaced and $HOME reads "~".
# Usage: nexus-diagnostics.sh [FILE]   default: /tmp/caelestia4-diagnostics-<date-time>.txt. Prints the path written.
set -uo pipefail
umask 077
self=$(readlink -f "${BASH_SOURCE[0]}")
here=$(dirname "$self")
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
out=${1:-/tmp/caelestia4-diagnostics-$(date +%Y%m%d-%H%M%S).txt}
# The shell that started this (Quickshell's Process runs the script directly)
shell_pid=${NEXUS_SHELL_PID:-$PPID}

have() { command -v "$1" > /dev/null; }
line() { printf '%-14s %s\n' "$1:" "${2:-unknown}"; }

caelestia4_version() {
    local repo
    repo=$(cat "$cfg/caelestia4/repo" 2> /dev/null) || return
    [[ -d $repo/.git ]] || return
    # describe only reads; no --dirty, which may refresh the index
    GIT_OPTIONAL_LOCKS=0 git -C "$repo" describe --tags --always 2> /dev/null
}

quickshell_version() { have qs && qs --version 2> /dev/null | head -1; }

hyprland_version() {
    have hyprctl && have jq || return
    hyprctl version -j 2> /dev/null | jq -r '"\(.tag // .version // "?") (\((.commit // "")[0:9]), \(.branch // "?"))"' 2> /dev/null
}

plugin_build() {
    local dir stamp
    for dir in ${QML_IMPORT_PATH:+${QML_IMPORT_PATH//:/ }} "$HOME/.local/lib/qt6/qml"; do
        stamp="$dir/Caelestia/caelestia4-build.json"
        if [[ -r $stamp ]]; then
            jq -r '"\(.version // "?") (\(.revision // "?")), built \(.built // "?") with Qt \(.qt // "?")"' "$stamp" 2> /dev/null
            return
        fi
    done
}

qt_version() { /usr/lib/qt6/bin/qtpaths6 --qt-version 2> /dev/null || { have qtpaths6 && qtpaths6 --qt-version 2> /dev/null; }; }

system_name() { (. /etc/os-release 2> /dev/null && printf '%s' "${PRETTY_NAME:-$NAME}"); }

shell_log() {
    local text=''
    if have qs; then
        text=$(qs log --pid "$shell_pid" -t 100 2> /dev/null) || text=''
        [[ -n $text ]] || text=$(qs log -c ii -t 100 2> /dev/null) || text=''
    fi
    if [[ -z $text ]] && have journalctl; then
        text=$(journalctl --user -u caelestia4-shell.service -n 100 -o cat --no-pager 2> /dev/null) || text=''
    fi
    printf '%s\n' "${text:-(no log found)}"
}

# Secret-looking text in the log: "Authorization: Basic …" (the scheme and the value), "Bearer …", "Basic" + base64,
# a secret-named "k=v" / "k: v" (also api_key=, X_API_KEY=, x-api-key:), "password …" / "token '…'" with no colon,
# user:pass@ in URLs, and key-like words. Some plain words after "token" or "password" go too: better safe.
redact() {
    local q="[\"']?" v="[^[:space:]\"',;}&]+"
    sed -E \
        -e "s/((proxy-)?authori[sz]ation${q}[[:space:]]*[:=][[:space:]]*$q)((basic|bearer|digest|token|negotiate)[[:space:]]+)?$v/\1<removed>/Ig" \
        -e "s/(bearer[[:space:]]+)$v/\1<removed>/Ig" \
        -e "s#\b([Bb]asic[[:space:]]+)[A-Za-z0-9+/]{8,}={0,2}#\1<removed>#g" \
        -e "s/([a-z0-9_-]*(key|token|secret|passw(or)?d|pwd|passphrase|auth|cookie|credentials?)${q}[[:space:]]*[:=][[:space:]]*$q)$v/\1<removed>/Ig" \
        -e "s/\b((passw(or)?d|passphrase|token|secret)s?[[:space:]]+(is[[:space:]]+)?$q)$v/\1<removed>/Ig" \
        -e "s#(://[^/[:space:]:@]+:)[^/[:space:]@]+@#\1<removed>@#g" \
        -e "s/\b(sk-|sk_|ghp_|gho_|ghs_|github_pat_|glpat-|xox[abprs]-|AIza)[A-Za-z0-9_-]+/<removed>/g" \
        -e "s#${HOME//#/\\#}#~#g"
}

{
    echo "caelestia4 diagnostics, $(date -Iseconds)"
    echo
    echo "== Versions"
    line caelestia4 "$(caelestia4_version)"
    line Quickshell "$(quickshell_version)"
    line Hyprland "$(hyprland_version)"
    line Plugin "$(plugin_build)"
    line Qt "$(qt_version)"
    line System "$(system_name)"
    line Kernel "$(uname -r)"
    echo
    echo "== Changed settings (secrets removed)"
    "$here/nexus-export.sh" --stdout 2>&1 || echo "(could not export)"
    echo
    echo "== Shell log, last 100 lines"
    shell_log
} | redact > "$out.tmp" && mv -- "$out.tmp" "$out" || { rm -f -- "$out.tmp"; exit 1; }
printf '%s\n' "$out"
