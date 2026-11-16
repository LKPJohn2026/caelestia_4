#!/usr/bin/env bash
# caelestia4: Nexus > About > Export my changes. Writes the settings that differ from their defaults to one JSON file:
# Caelestia's shell.json (it only holds what was set) and its per-screen files, and the end-4 config.json keys whose
# value is not the default (defaults from nexus/registry/E4Defaults.js). Secrets are removed at any depth: an option
# whose name ends in a secret word (token, secret, password, pin, auth, an API or private key...; a bool stays), a
# string "cookie", and any string that holds a secret: an API-key-like word, a "Bearer"/"Basic" value, a password in a
# URL (user:pass@host), a secret-named k=v or k: v (also URL queries and env vars), or "password is ...". Objects
# emptied by this are left out. "removed" lists the paths taken out (names only, never values).
# Usage: nexus-export.sh [--stdout | FILE | DIR]   default: ~/caelestia4-settings-<date>.json (a second export that
# day adds the time, so the first is kept). Prints the path written.
set -euo pipefail
self=$(readlink -f "${BASH_SOURCE[0]}")
here=$(dirname "$self")
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
defaults_js="$here/../../modules/caelestia/nexus/registry/E4Defaults.js"
command -v jq > /dev/null || { echo "nexus-export: jq is missing" >&2; exit 2; }

target=${1:-$HOME}
if [[ $target != --stdout && -d $target ]]; then
    target="${target%/}/caelestia4-settings-$(date +%F).json"
    # Keep an earlier export of the same day
    [[ ! -e $target ]] || target="${target%.json}-$(date +%H%M%S).json"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Each input as JSON, {} when missing or unreadable
read_json() { if [[ -r $1 ]] && jq -e 'type == "object"' "$1" > /dev/null 2>&1; then jq -c . "$1"; else echo '{}'; fi; }

read_json "$cfg/caelestia/shell.json" > "$tmp/shell.json"
read_json "$cfg/illogical-impulse/config.json" > "$tmp/config.json"
{
    echo '{'
    first=1
    for f in "$cfg"/caelestia/monitors/*/shell.json; do
        [[ -e $f ]] || continue
        screen=$(basename "$(dirname "$f")")
        ((first)) || echo ','
        first=0
        jq -n --arg s "$screen" '$s'
        echo ':'
        read_json "$f"
    done
    echo '}'
} | jq -c . > "$tmp/screens.json"
# E4Defaults.js: a header, then `var defaults = {...};`
if [[ -r $defaults_js ]]; then
    sed -n '/^var defaults = /,$p' "$defaults_js" | sed '1s/^var defaults = //; $s/;[[:space:]]*$//' | jq -c . > "$tmp/defaults.json" 2> /dev/null || echo '{}' > "$tmp/defaults.json"
else
    echo '{}' > "$tmp/defaults.json"
fi

jq -n --slurpfile shell "$tmp/shell.json" --slurpfile config "$tmp/config.json" --slurpfile screens "$tmp/screens.json" \
    --slurpfile defaults "$tmp/defaults.json" --arg created "$(date -Iseconds)" '
    # A name as lower-case words: "OPENAI_API_KEY", "apiKey" and "api-key" all give [..., "api", "key"]
    def words: gsub("(?<a>[a-z0-9])(?<b>[A-Z])"; "\(.a) \(.b)") | ascii_downcase | [splits("[^a-z0-9]+")] | map(select(length > 0));
    def secretword: IN("token", "tokens", "secret", "secrets", "password", "passwd", "pwd", "passphrase", "apikey",
        "credential", "credentials", "creds", "authorization", "authorisation", "auth", "pin", "privatekey");
    # The option holds the secret itself: its last word is a secret word ("key" only alone or after api, private,
    # access...), or token_value, password_hash... (key_id is the name of a key, kept). Names that start with a verb
    # (changePassword, hidePasswordAfter) are settings about a secret, not the secret.
    def secretname: words as $w | ($w | length) > 0
        and (($w[0] | IN("change", "reset", "hide", "show", "require", "ask", "unlock", "toggle", "use", "prompt",
            "remember", "allow", "enable", "disable")) | not)
        and ($w[-1] as $l | ($l | secretword)
            or ($l == "key" and (($w | length) == 1 or ($w[-2] | IN("api", "private", "access", "secret", "client",
                "auth", "license", "licence", "session", "encryption", "signing"))))
            or (($l | IN("value", "hash", "data")) and ($w | length) >= 2 and ($w[-2] | (secretword or . == "key"))));
    # "cookie" is also the end-4 clock style (an object): only a string cookie is a secret
    def weakname: words | (length > 0 and (.[-1] | IN("cookie", "cookies")));
    def secretvalue: type == "string" and (
        test("\\b(sk-|sk_|ghp_|gho_|ghs_|github_pat_|glpat-|xox[abprs]-|AIza)[A-Za-z0-9_-]{6,}")
        or test("\\bbearer\\s+[A-Za-z0-9+/._~-]{8,}"; "i")
        # "Basic" + base64 (a digit, + / =, or a capital past the first letter: not "basic questions")
        or test("\\b[Bb]asic\\s+(?=[A-Za-z0-9+/]*[0-9+/=]|[A-Za-z0-9+/][A-Za-z0-9+/]*[A-Z])[A-Za-z0-9+/]{8,}")
        or test("[a-z][a-z0-9+.-]*://[^/\\s:@]+:[^/\\s@]+@"; "i")
        or test("[a-z0-9_-]*(key|token|secret|passw(or)?d|pwd|passphrase|auth|authori[sz]ation|credentials?)[\"'\'']?\\s*[:=]\\s*[\"'\'']?[^\\s\"'\'',;&}]+"; "i")
        or test("\\b(passw(or)?d|passphrase)\\s+is\\s+[^\\s]"; "i"));
    def keptundersecret: type == "boolean" or type == "null" or type == "object"
        or (type == "array" and all(.[]; type == "boolean" or type == "null"));
    def drop(k; v): ((k | secretname) and (v | keptundersecret | not))
        or ((k | weakname) and (v | type) == "string") or (v | secretvalue);
    # Under a secret-named object everything goes but bools (and objects, walked the same way)
    def allsecret(p): reduce to_entries[] as $e ({v: {}, r: []};
        if ($e.value | type) == "object" then ($e.value | allsecret(p + [$e.key])) as $s
            | (if ($s.v | length) == 0 and ($e.value | length) > 0 then . else .v[$e.key] = $s.v end) | .r += $s.r
        elif ($e.value | keptundersecret) then .v[$e.key] = $e.value
        else .r += [p + [$e.key]] end);
    # {v: the value without secrets, r: the paths removed}; an object or list emptied by removals is left out
    def emptied(orig): (type == "object" or type == "array") and length == 0 and (orig | length) > 0;
    def scrubv(p):
        if type == "array" then
            . as $a | reduce range($a | length) as $i ({v: [], r: []};
                if ($a[$i] | secretvalue) then .r += [p + [$i]]
                else ($a[$i] | scrubv(p + [$i])) as $s | (if ($s.v | emptied($a[$i])) then . else .v += [$s.v] end) | .r += $s.r end)
        elif type == "object" then
            reduce to_entries[] as $e ({v: {}, r: []};
                if drop($e.key; $e.value) then .r += [p + [$e.key]]
                else ($e.value | if ($e.key | secretname) and type == "object" then allsecret(p + [$e.key]) else scrubv(p + [$e.key]) end) as $s
                    | (if ($s.v | emptied($e.value)) then . else .v[$e.key] = $s.v end) | .r += $s.r end)
        elif secretvalue then {v: null, r: [p]}
        else {v: ., r: []} end;
    def leaves(p): if type == "object" and length > 0 then to_entries[] as $e | $e.value | leaves(p + [$e.key]) else {p: p, v: .} end;
    ($defaults[0]) as $d | ($config[0]) as $c
    # end-4: options whose value differs from the default
    | ([$d | to_entries[] | (.key | split(".")) as $p | .value as $dv
        | ($c | getpath($p)) as $v | select($v != null and $v != $dv) | {p: $p, v: $v}]) as $changed
    # and keys config.json has that no default covers (older or newer options)
    | ([$c | leaves([])] | map(select(.p as $p | [range(1; ($p | length) + 1) as $n | $p[:$n] | join(".")]
        | any(.[]; . as $k | $d | has($k)) | not))) as $extra
    | (reduce ($changed + $extra)[] as $x ({}; setpath($x.p; $x.v))) as $e4
    | ({shell: $shell[0], screens: $screens[0], config: $e4} | scrubv([])) as $s
    | {format: "caelestia4-settings", version: 1, created: $created} + $s.v
      + {removed: [$s.r[] | map(tostring) | join(".")]}
' > "$tmp/out.json"

if [[ $target == --stdout ]]; then
    cat "$tmp/out.json"
else
    mkdir -p -- "$(dirname -- "$target")"
    install -m 600 -- "$tmp/out.json" "$target"
    printf '%s\n' "$target"
fi
