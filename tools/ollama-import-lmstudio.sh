#!/usr/bin/env bash
# Import LM Studio's GGUF models into Ollama WITHOUT copying them.
# Ollama stores model files as blobs named sha256-<digest>. If a blob already exists, `ollama create` skips the
# upload/copy. So each GGUF is hashed and hard-linked into the blob store first (same filesystem required), and
# Ollama then uses LM Studio's file directly: same inode, no extra disk space.
#
# Usage: tools/ollama-import-lmstudio.sh [model-dir-name-filter]
#   LMSTUDIO_MODELS  (default: LM Studio's downloadsFolder from ~/.lmstudio/settings.json)
#   OLLAMA_MODELS    (default: the value in the ollama user service)
# Models are created as lmstudio/<repo-name-without--GGUF, lowercased>. Vision projectors (mmproj-*.gguf) are added
# as a second FROM. Split GGUFs (*-00001-of-0000N.gguf) are passed as one FROM per part.
set -euo pipefail

filter="${1:-}"
LMSTUDIO_MODELS="${LMSTUDIO_MODELS:-$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.lmstudio/settings.json'))).get('downloadsFolder',''))" 2>/dev/null)}"
LMSTUDIO_MODELS="${LMSTUDIO_MODELS:-$HOME/.lmstudio/models}"
OLLAMA_MODELS="${OLLAMA_MODELS:-$(systemctl --user show ollama.service -p Environment --value | tr ' ' '\n' | sed -n 's/^OLLAMA_MODELS=//p')}"
[[ -d "$LMSTUDIO_MODELS" ]] || { echo "LM Studio models not found: $LMSTUDIO_MODELS" >&2; exit 1; }
[[ -n "$OLLAMA_MODELS" ]] || { echo "OLLAMA_MODELS unknown (is the ollama user service set up?)" >&2; exit 1; }
blobs="$OLLAMA_MODELS/blobs"
mkdir -p "$blobs"
[[ "$(stat -c %d "$LMSTUDIO_MODELS")" == "$(stat -c %d "$blobs")" ]] || { echo "LM Studio models and Ollama blobs must be on the same filesystem (hard links)" >&2; exit 1; }

link_blob() { # link_blob <file>: hard-link into the blob store under its sha256 (hashing takes a while for big files)
  local f="$1" digest blob
  digest=$(sha256sum "$f" | cut -d' ' -f1)
  blob="$blobs/sha256-$digest"
  if [[ -e "$blob" ]]; then
    [[ "$(stat -c %i "$blob")" == "$(stat -c %i "$f")" ]] && echo "    = $(basename "$f") already linked" || echo "    ! $(basename "$f"): blob exists as a separate copy"
  else
    ln "$f" "$blob"
    echo "    + $(basename "$f") -> sha256-${digest:0:12}…"
  fi
}

shopt -s nullglob
for dir in "$LMSTUDIO_MODELS"/*/*/; do
  repo=$(basename "$dir")
  [[ -n "$filter" && "${repo,,}" != *"${filter,,}"* ]] && continue
  name="lmstudio/$(echo "${repo%-GGUF}" | tr '[:upper:]' '[:lower:]')"
  mapfile -t weights < <(find "$dir" -maxdepth 1 -name '*.gguf' ! -iname 'mmproj*' | sort)
  mapfile -t projectors < <(find "$dir" -maxdepth 1 -iname 'mmproj*.gguf' | sort)
  ((${#weights[@]})) || continue
  echo "== $name (${#weights[@]} weight file(s), ${#projectors[@]} projector(s))"
  for f in "${weights[@]}" "${projectors[@]}"; do link_blob "$f"; done
  modelfile=$(mktemp)
  { for f in "${weights[@]}" "${projectors[@]}"; do echo "FROM $f"; done; } > "$modelfile"
  if ollama create "$name" -f "$modelfile"; then echo "   created $name"; else echo "   FAILED $name" >&2; fi
  rm -f "$modelfile"
done
