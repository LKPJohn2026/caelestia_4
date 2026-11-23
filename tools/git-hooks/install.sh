#!/usr/bin/env bash
# caelestia4: install this repo's git hook as a copy in the clone's own hooks folder (.git/hooks, shared by its
# worktrees), never run from the working tree.
#   tools/git-hooks/install.sh
# core.hooksPath pointing into the tree (tools/git-hooks) ran whatever hooks the checked-out commit had: a PR branch or
# an upstream pick adding post-checkout or pre-commit ran it on checkout, and one editing pre-push turned the denylist
# check off. A copy only changes when this is run again, so run it on purpose, after reading a change to the hook.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

top=$(git rev-parse --show-toplevel)
hooks=$(git rev-parse --path-format=absolute --git-common-dir)/hooks

# abs <path>: the path as git reads core.hooksPath (relative to the top of the tree; ~ expanded by --type=path), with
# links followed
abs() {
  local p="$1"
  [[ $p == /* ]] || p="$top/$p"
  realpath -m -- "$p"
}
gitdir=$(abs "$(git rev-parse --path-format=absolute --git-common-dir)")
# inside <path>: the path is in this working tree or another of the clone's worktrees (they share the setting); the
# clone's own git folder (.git/hooks, say) isn't, unless it is a link into one
inside() {
  local p w
  p=$(abs "$1")
  [[ $p == "$gitdir" || $p == "$gitdir/"* ]] && return 1
  while IFS= read -r w; do
    w=$(realpath -m -- "${w#worktree }")
    [[ $p == "$w" || $p == "$w/"* ]] && return 0
  done < <(git worktree list --porcelain | grep '^worktree ')
  return 1
}

if local_path=$(git config --local --type=path --get core.hooksPath); then
  if inside "$local_path"; then
    git config --local --unset core.hooksPath
    echo "core.hooksPath was $local_path, in the working tree: unset (the hook now runs from $hooks)"
  fi
fi
# Set anywhere else (global, worktree or included config) to another folder: left to its owner, and said where
if path=$(git config --type=path --get core.hooksPath) && [[ $(abs "$path") != "$(abs "$hooks")" ]]; then
  where=$(git config --show-origin --get core.hooksPath | cut -f1)
  if inside "$path"; then
    echo "core.hooksPath is $path ($where), in the working tree: git would run whatever hooks the checked-out" >&2
    echo "commit holds there. Unset it in that file (never copy a hook into the tree), then run this again." >&2
  else
    echo "core.hooksPath is $path ($where), so git doesn't read $hooks." >&2
    echo "Unset it there, or copy tools/git-hooks/pre-push to it yourself." >&2
  fi
  exit 1
fi
# The hooks folder itself must not be (or lead) into a working tree either
if inside "$hooks"; then
  echo "$hooks is in a working tree ($(abs "$hooks")): make it a folder of its own first" >&2
  exit 1
fi

# pre-push is the only hook here: a hook added to tools/git-hooks is installed only once this script names it
mkdir -p "$hooks"
src=tools/git-hooks/pre-push dst=$hooks/pre-push
[[ -f $src && ! -L $src ]] || { echo "$src isn't a file" >&2; exit 1; }
if [[ -e $dst || -L $dst ]] && ! cmp -s "$src" "$dst"; then
  # one kept copy per replaced hook, never written over
  old=$dst.old.$(date +%Y%m%d-%H%M%S)
  [[ -e $old || -L $old ]] && { echo "$old is already there: move it, then run this again" >&2; exit 1; }
  mv -- "$dst" "$old" && echo "kept the earlier pre-push as $old"
fi
tmp=$(mktemp "$hooks/.pre-push.XXXXXX")
cat "$src" > "$tmp"
chmod 0755 "$tmp"
mv -f -- "$tmp" "$dst"
echo "installed $dst ($(sha256sum "$dst" | cut -c1-12)); run this again after reading a change to $src"
