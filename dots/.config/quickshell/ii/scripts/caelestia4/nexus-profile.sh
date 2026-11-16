#!/usr/bin/env bash
# caelestia4: Nexus > About > Profiles. Named settings profiles in ${XDG_DATA_HOME:-~/.local/share}/caelestia4/profiles,
# one <id>.json each: what nexus-export.sh writes (the settings that differ from their defaults, secrets removed) plus
# "profile": {name, backup}. Secrets never land in a profile; applying one keeps the secrets you have now.
# Usage:
#   nexus-profile.sh list                 JSON list, newest first: [{id, name, created, count, backup}]
#   nexus-profile.sh save NAME [--backup] save the current settings; prints the id (exit 3: that name is taken)
#   nexus-profile.sh rename ID NAME       prints the new id (exit 3: that name is taken)
#   nexus-profile.sh delete ID
#   nexus-profile.sh diff ID              JSON {changes: [{path, old, new}]}: what apply would change (path as a list:
#                                         ["shell"|"config", keys...] or ["screens", screen, keys...]; null = default)
#   nexus-profile.sh apply ID BACKUPNAME  saves the current settings as a backup profile named BACKUPNAME, then writes
#                                         the profile's settings; prints the backup's id
# Exit 2: bad use or a missing profile; 4: nothing to apply.
set -euo pipefail
self=$(readlink -f "${BASH_SOURCE[0]}")
here=$(dirname "$self")
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
dir=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia4/profiles
export_sh="$here/nexus-export.sh"
defaults_js="$here/../../modules/caelestia/nexus/registry/E4Defaults.js"
keep_backups=10
command -v jq > /dev/null || { echo "nexus-profile: jq is missing" >&2; exit 2; }

die() { echo "nexus-profile: $1" >&2; exit "${2:-2}"; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A file id from a name: no slashes, quotes, control characters or leading dots; at most 80 characters
id_for() {
    local id
    id=$(printf '%s' "$1" | tr -d '\000-\037/\\:*?"<>|' | sed 's/^[. ]*//; s/[ .]*$//')
    id=${id:0:80}
    printf '%s' "${id:-profile}"
}
need_profile() {
    [[ -n $1 && $1 != */* && $1 != .* && -f $dir/$1.json ]] || die "no profile '$1'"
}
# {name: ...} already taken by another profile (case is ignored)
name_taken() {
    local f
    for f in "$dir"/*.json; do
        [[ -e $f && $(basename "$f" .json) != "${2:-}" ]] || continue
        jq -e --arg n "$1" '(.profile.name // "" | ascii_downcase) == ($n | ascii_downcase)' "$f" > /dev/null 2>&1 && return 0
    done
    return 1
}

save() { # NAME BACKUP(0|1) -> prints the id
    local name=$1 backup=$2 id n=2
    [[ -n ${name//[[:space:]]/} ]] || die "empty name"
    mkdir -p -- "$dir"
    chmod 700 -- "$dir"
    id=$(id_for "$name")
    if ((backup)); then
        while [[ -e $dir/$id.json ]]; do id="$(id_for "$name") $n"; n=$((n + 1)); done
    else
        name_taken "$name" && die "a profile named '$name' exists" 3
        while [[ -e $dir/$id.json ]]; do id="$(id_for "$name") $n"; n=$((n + 1)); done
    fi
    "$export_sh" --stdout > "$tmp/export.json"
    jq --arg name "$name" --argjson backup "$( ((backup)) && echo true || echo false)" \
        '.format = "caelestia4-profile" | .profile = {name: $name, backup: $backup} | del(.removed)' \
        "$tmp/export.json" > "$tmp/profile.json"
    install -m 600 -- "$tmp/profile.json" "$dir/$id.json"
    printf '%s\n' "$id"
}

# The newest $keep_backups backups stay
prune_backups() {
    local f
    for f in "$dir"/*.json; do
        [[ -e $f ]] || continue
        jq -r 'select(.profile.backup == true) | "\(.created // "")\t\(input_filename)"' "$f" 2> /dev/null || true
    done | sort -r | tail -n +$((keep_backups + 1)) | cut -f2- | while IFS= read -r f; do rm -f -- "$f"; done
}

# Each input as JSON, {} when missing or unreadable (as nexus-export.sh reads them)
read_json() { if [[ -r $1 ]] && jq -e 'type == "object"' "$1" > /dev/null 2>&1; then jq -c . "$1"; else echo '{}'; fi; }

# The files the profile $1 gives, in $tmp/new (same layout as ~/.config), and the current ones in $tmp/cur.json
build() {
    local profile=$1 s
    "$export_sh" --stdout > "$tmp/curexport.json"
    {
        printf '{"shell":'
        read_json "$cfg/caelestia/shell.json"
        printf ',"config":'
        read_json "$cfg/illogical-impulse/config.json"
        printf ',"screens":{'
        local first=1
        for s in "$cfg"/caelestia/monitors/*/shell.json; do
            [[ -e $s ]] || continue
            ((first)) || printf ','
            first=0
            jq -n --arg s "$(basename "$(dirname "$s")")" '$s'
            printf ':'
            read_json "$s"
        done
        printf '}}'
    } | jq -c . > "$tmp/cur.json"
    if [[ -r $defaults_js ]]; then
        sed -n '/^var defaults = /,$p' "$defaults_js" | sed '1s/^var defaults = //; $s/;[[:space:]]*$//' | jq -c . > "$tmp/defaults.json" 2> /dev/null || echo '{}' > "$tmp/defaults.json"
    else
        echo '{}' > "$tmp/defaults.json"
    fi
    jq -n --slurpfile cur "$tmp/cur.json" --slurpfile ce "$tmp/curexport.json" --slurpfile p "$profile" \
        --slurpfile d "$tmp/defaults.json" '
        ($cur[0]) as $c | ($ce[0]) as $x | ($p[0]) as $p | ($d[0]) as $d
        | def leaves(q): if type == "object" and length > 0 then to_entries[] as $e | $e.value | leaves(q + [$e.key]) else {p: q, v: .} end;
        # "a.b.c" from the export back to a path in $c: a key may hold dots itself (the longest key that exists wins),
        # a list index is a number
        def resolve($segs; $node; $acc):
            if ($segs | length) == 0 then $acc
            elif ($node | type) == "array" then ($segs[0] | tonumber? // null) as $i
                | if $i == null then null else resolve($segs[1:]; $node[$i]; $acc + [$i]) end
            elif ($node | type) == "object" then
                first((range($segs | length; 0; -1) as $n | ($segs[:$n] | join(".")) as $k
                    | select($node | has($k)) | resolve($segs[$n:]; $node[$k]; $acc + [$k])) | select(. != null)) // null
            else null end;
        # Settings: the shell.json and screen files of the profile as they are; config.json: the current one with every
        # option that has a default put back to it, then the profile values on top
        ($p.config // {}) as $pc
        | (reduce ($d | to_entries[]) as $e ($c.config; ($e.key | split(".")) as $k
            | if getpath($k) != null and getpath($k) != $e.value then setpath($k; $e.value) else . end)) as $cfg0
        | (reduce ($pc | leaves([]))  as $l ($cfg0; setpath($l.p; $l.v))) as $cfg1
        | {shell: ($p.shell // {}), config: $cfg1,
           screens: (reduce ((($c.screens // {}) + ($p.screens // {})) | keys[]) as $s ({}; .[$s] = ($p.screens[$s] // {})))}
        # Secrets kept: each path the export took out of the current files is set back from them. Under a list, the
        # whole list comes back when the profile has the same list (secrets aside), else the item that holds it when
        # the profile has the same item at that place; else the profile list stays
        | reduce ($x.removed // [])[] as $r (.; resolve($r | split("."); $c; []) as $rp
            | if $rp == null then .
              else (first(range(0; $rp | length) as $i | select(($rp[$i] | type) == "number") | $i) // null) as $i
                | if $i == null then setpath($rp; $c | getpath($rp))
                  elif getpath($rp[:$i]) == ($x | getpath($rp[:$i])) then setpath($rp[:$i]; $c | getpath($rp[:$i]))
                  elif $i + 1 < ($rp | length) and getpath($rp[:$i + 1]) != null
                      and getpath($rp[:$i + 1]) == ($x | getpath($rp[:$i + 1])) then setpath($rp[:$i + 1]; $c | getpath($rp[:$i + 1]))
                  else . end
              end)
    ' > "$tmp/new.json"
    mkdir -p "$tmp/new/caelestia" "$tmp/new/illogical-impulse"
    jq '.shell' "$tmp/new.json" > "$tmp/new/caelestia/shell.json"
    jq '.config' "$tmp/new.json" > "$tmp/new/illogical-impulse/config.json"
    jq -r '.screens | keys[]' "$tmp/new.json" | while IFS= read -r s; do
        [[ $s != */* && $s != .* && -n $s ]] || continue
        mkdir -p "$tmp/new/caelestia/monitors/$s"
        jq --arg s "$s" '.screens[$s]' "$tmp/new.json" > "$tmp/new/caelestia/monitors/$s/shell.json"
    done
}

# What changes, from the export of the current files to the export of the new ones
diff_json() {
    XDG_CONFIG_HOME="$tmp/new" "$export_sh" --stdout > "$tmp/newexport.json"
    jq -n --slurpfile a "$tmp/curexport.json" --slurpfile b "$tmp/newexport.json" '
        def leaves(q): if type == "object" and length > 0 then to_entries[] as $e | $e.value | leaves(q + [$e.key]) else {p: q, v: .} end;
        def flat(o): reduce ({shell: o.shell, screens: o.screens, config: o.config} | leaves([]))
            as $l ({}; .[$l.p | tojson] = $l);
        flat($a[0]) as $old | flat($b[0]) as $new
        | {changes: [(($old + $new) | keys[]) as $k | select($old[$k].v != $new[$k].v)
            | {path: ($old[$k].p // $new[$k].p), old: $old[$k].v, new: $new[$k].v}
            # an empty object on one side is no setting
            | select(((.old | type) == "object" and (.old | length) == 0 and .new == null) or ((.new | type) == "object" and (.new | length) == 0 and .old == null) | not)]}'
}

# In place, so the shell's file watchers see the change; a file that would not change is left alone
write_file() { # NEW TARGET
    [[ -e $2 ]] || ! jq -e '. == {}' "$1" > /dev/null || return 0
    if [[ -e $2 ]] && jq -e --slurpfile a "$1" '. == $a[0]' "$2" > /dev/null 2>&1; then return 0; fi
    mkdir -p -- "$(dirname -- "$2")"
    jq --indent 4 . "$1" > "$tmp/write.json"
    cat -- "$tmp/write.json" > "$2"
}

cmd=${1:-}
shift || true
case $cmd in
    list)
        out='[]'
        for f in "$dir"/*.json; do
            [[ -e $f ]] || continue
            out=$(jq -c --arg id "$(basename "$f" .json)" --argjson acc "$out" '
                def leaves: if type == "object" then .[] | leaves else . end;
                $acc + [{id: $id, name: (.profile.name // $id), created: (.created // ""), backup: (.profile.backup == true),
                    count: ([(.shell // {}), (.screens // {} | .[]), (.config // {})] | map([leaves] | length) | add // 0)}]' \
                "$f" 2> /dev/null) || continue
        done
        jq -c 'sort_by(.created) | reverse' <<< "$out"
        ;;
    save)
        [[ $# -ge 1 ]] || die "save NAME [--backup]"
        save "$1" "$([[ ${2:-} == --backup ]] && echo 1 || echo 0)"
        ;;
    rename)
        [[ $# -eq 2 ]] || die "rename ID NAME"
        need_profile "$1"
        [[ -n ${2//[[:space:]]/} ]] || die "empty name"
        name_taken "$2" "$1" && die "a profile named '$2' exists" 3
        new=$(id_for "$2")
        if [[ $new != "$1" ]]; then
            n=2
            while [[ -e $dir/$new.json ]]; do new="$(id_for "$2") $n"; n=$((n + 1)); done
        fi
        jq --arg n "$2" '.profile.name = $n | .profile.backup = false' "$dir/$1.json" > "$tmp/r.json"
        install -m 600 -- "$tmp/r.json" "$dir/$new.json"
        [[ $new == "$1" ]] || rm -f -- "$dir/$1.json"
        printf '%s\n' "$new"
        ;;
    delete)
        [[ $# -eq 1 ]] || die "delete ID"
        need_profile "$1"
        rm -f -- "$dir/$1.json"
        ;;
    diff)
        [[ $# -eq 1 ]] || die "diff ID"
        need_profile "$1"
        build "$dir/$1.json"
        diff_json
        ;;
    apply)
        [[ $# -eq 2 ]] || die "apply ID BACKUPNAME"
        need_profile "$1"
        cp -- "$dir/$1.json" "$tmp/apply.json"
        build "$tmp/apply.json"
        [[ $(diff_json | jq '.changes | length') -gt 0 ]] || die "nothing to apply" 4
        backup=$(save "$2" 1)
        write_file "$tmp/new/caelestia/shell.json" "$cfg/caelestia/shell.json"
        write_file "$tmp/new/illogical-impulse/config.json" "$cfg/illogical-impulse/config.json"
        for f in "$tmp"/new/caelestia/monitors/*/shell.json; do
            [[ -e $f ]] || continue
            write_file "$f" "$cfg/caelestia/monitors/$(basename "$(dirname "$f")")/shell.json"
        done
        prune_backups
        printf '%s\n' "$backup"
        ;;
    *) die "usage: nexus-profile.sh list | save NAME [--backup] | rename ID NAME | delete ID | diff ID | apply ID BACKUPNAME" ;;
esac
