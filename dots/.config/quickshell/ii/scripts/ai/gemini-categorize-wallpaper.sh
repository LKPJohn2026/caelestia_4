#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <image_path> [model] [prompt]"
    echo "Tip: set GEMINI_WALLPAPER_MODEL and/or GEMINI_WALLPAPER_PROMPT to provide defaults."
    exit 1
fi

# Variables
SOURCE_IMG_PATH="$1"
MODEL="${2:-${GEMINI_WALLPAPER_MODEL:-gemini-2.5-flash}}" # We use the flash variant so it's fast
WALLPAPER_NAME="$(basename "$SOURCE_IMG_PATH")"
PROMPT="${3:-${GEMINI_WALLPAPER_PROMPT:-Categorize the wallpaper. Its file name is $WALLPAPER_NAME}}"
RESIZED_IMG_PATH="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-temp/ai/wallpaper.jpg"

CATEGORIES='["abstract", "anime", "city", "minimalist", "landscape", "plants", "person", "space"]'

# caelestia4: this prints a category and nothing else; on any failure it prints nothing and exits non-zero, so the
# caller (switchwall.sh) keeps the category it had instead of writing "null" or an error page
fail() {
    echo "[gemini-categorize-wallpaper.sh] $1" >&2
    exit 1
}

# Resize image for speed
mkdir -p "$(dirname "$RESIZED_IMG_PATH")"
magick "$SOURCE_IMG_PATH" -resize 200x -quality 50 "$RESIZED_IMG_PATH" || fail "Couldn't read $SOURCE_IMG_PATH"

# Get API key
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' | jq -r '.apiKeys.gemini // empty' 2>/dev/null)
[[ -n "$API_KEY" ]] || fail "No Gemini API key in the keyring"

# Encode image to base64
if [[ "$(base64 --version 2>&1)" = *"FreeBSD"* ]]; then
    B64FLAGS="--input"
else
    B64FLAGS="-w0"
fi
B64DATA="$(base64 $B64FLAGS "$RESIZED_IMG_PATH")" || fail "Couldn't encode the image"
# echo $B64DATA

# Prepare request data
# caelestia4: built with jq, so a quote or backslash in the prompt (or the file name in it) stays valid JSON
payload=$(jq -n --arg data "$B64DATA" --arg prompt "$PROMPT" --argjson categories "$CATEGORIES" '{
    "contents": [{
        "parts":[
            {
                "inline_data": {
                "mime_type":"image/jpeg",
                "data": $data
                }
            },
            {"text": $prompt}
        ]
    }],
    "generationConfig": {
        "responseMimeType": "text/x.enum",
        "responseSchema": {
            "type": "string",
            "enum": $categories
        },
        "temperature": 0
    }
}') || fail "Couldn't build the request"
# echo "$payload" | jq

# Make the request
# caelestia4: the key goes in on stdin (-H @-) and the payload from a pipe, not as arguments, which any process can
# read in /proc while curl runs
response=$(printf 'x-goog-api-key: %s\n' "$API_KEY" | curl -fsS "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
-H @- \
-H 'Content-Type: application/json' \
-X POST \
--data-binary @<(printf '%s' "$payload") 2> /dev/null) || fail "The request to Gemini failed"
# echo "$response" | jq

# Write the result
category=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
jq -e --arg c "$category" 'index($c) != null' <<< "$CATEGORIES" >/dev/null || fail "Gemini gave no category"
echo "$category"
