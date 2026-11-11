#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# caelestia4: the activate path quoted (a space in it split the word), and exec so the caller gets the script's exit
# status: a deactivate after it always returned 0, so a failure looked like empty output
source "$(eval echo "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")/bin/activate"
exec "$SCRIPT_DIR/token_from_key.py" "$@"
