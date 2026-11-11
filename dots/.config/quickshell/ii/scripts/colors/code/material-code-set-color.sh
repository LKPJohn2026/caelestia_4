#!/usr/bin/env bash
COLOR_FILE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt"

# Define an array of possible VSCode settings file paths for various forks
settings_paths=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - OSS/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Antigravity/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Windsurf/User/settings.json"
    
    # Add more paths as needed for other forks
)

new_color=$(cat "$COLOR_FILE_PATH" 2>/dev/null)
# caelestia4: no colour yet (or a broken file) would write an empty or garbled value into every editor's settings
new_color=${new_color//[[:space:]]/}
if [[ ! "$new_color" =~ ^#?[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$ ]]; then
    echo "[material-code-set-color.sh] No colour in $COLOR_FILE_PATH, leaving the editors alone" >&2
    exit 0
fi

# Loop through each settings file path
for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        # Try to update the key if it exists
        if grep -q '"material-code.primaryColor"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-code.primaryColor\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
                "$CODE_SETTINGS_PATH"
        # caelestia4: if the key is not already there, add it with jq: the sed that did this turned {} into {,...}.
        # VS Code allows comments and trailing commas, which jq can't read, so such a file is left alone. Written in
        # place (not moved) so a symlinked settings.json stays a symlink.
        elif jq -e 'type == "object"' "$CODE_SETTINGS_PATH" >/dev/null 2>&1; then
            if updated=$(jq --indent 4 --arg c "$new_color" '.["material-code.primaryColor"] = $c' "$CODE_SETTINGS_PATH"); then
                printf '%s\n' "$updated" > "$CODE_SETTINGS_PATH"
            fi
        else
            echo "[material-code-set-color.sh] $CODE_SETTINGS_PATH isn't plain JSON (comments?), not adding the colour" >&2
        fi
    fi
done
