# caelestia4: translations for shell scripts, from the shell's own catalogue (translations/<lang>.json, English keys).
# Source it, then: tr_ "Saved to %1" "$path". The language is the shell's (language.ui), else the locale's, read at the
# first string, so a script that prints nothing costs nothing. tools/i18n-missing.py checks the strings.
_tr_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../translations"

_tr_catalogue() {
    [[ -n "${_tr_file+x}" ]] && return
    local lang
    lang=$(jq -r '.language.ui // "auto"' "${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json" 2>/dev/null)
    if [[ -z "$lang" || "$lang" == auto ]]; then
        lang=${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}
        lang=${lang%%.*}
    fi
    _tr_file="$_tr_dir/$lang.json"
    [[ -n "$lang" && -f "$_tr_file" ]] || _tr_file=""
}

tr_() {
    _tr_catalogue
    local text=$1 n=0 arg
    if [[ -n "$_tr_file" ]]; then
        text=$(jq -r --arg k "$1" '(.[$k] // $k) | sub(" */\\*keep\\*/$"; "")' "$_tr_file" 2>/dev/null) || text=$1
    fi
    shift
    for arg in "$@"; do
        n=$((n + 1))
        text=${text//%$n/"$arg"}
    done
    printf '%s' "$text"
}

# A label and the spaces up to a column (characters, whatever the locale's charset)
tr_pad() {
    local LC_ALL=C.UTF-8
    local pad=$(($2 - ${#1}))
    ((pad < 1)) && pad=1
    printf '%s%*s' "$1" "$pad" ''
}
