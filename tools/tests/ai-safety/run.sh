#!/usr/bin/env bash
# caelestia4: what the AI chat shows, runs and sends. Offline, in a temporary directory with an isolated HOME and stub
# commands (curl, secret-tool, notify-send only log); never the network, the keyring or the desktop.
#   1. checks.js (node): the approval box, set_shell_config and run_shell_command approval, LaTeX to MicroTeX as one
#      argument (stub binary), the Markdown sanitiser and link schemes, /key get kept out of saved chats, static checks
#   2. the header option the AI strategies write into request.sh, run by bash against a stub curl: the key reaches curl
#      as a header, never in its arguments
#   3. scripts/ai/gemini-translate.sh against stubs: the same, and no request without a key
# Usage: tools/tests/ai-safety/run.sh (from the repo root)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."

if ! command -v node >/dev/null; then
  if [[ "${CI:-}" == true ]]; then echo "FAIL: node is not installed"; exit 1; fi
  echo "skip: node is not installed"; echo "ai-safety tests: OK"; exit 0
fi

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
mkdir -p "$HOME" "$T/bin"

node tools/tests/ai-safety/checks.js "$T"

# A curl that logs its arguments, and the headers it is given from files or stdin (-H @file / -H @-)
cat > "$T/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$STUB_LOG/curl.argv"
prev=""
for a in "$@"; do
  if [[ "$prev" == -H && "$a" == @* ]]; then
    if [[ "$a" == @- ]]; then cat >> "$STUB_LOG/curl.headers"; else cat -- "${a#@}" >> "$STUB_LOG/curl.headers"; fi
  fi
  if [[ "$prev" == --data-binary && "$a" == @* && "$a" != @- ]]; then cat -- "${a#@}" > /dev/null; fi
  prev="$a"
done
printf '%s\n' '{"candidates":[{"content":{"parts":[{"text":"{\"k\": \"v\"}"}]}}]}'
EOF
cat > "$T/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG/notify"
EOF
cat > "$T/bin/secret-tool" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$STUB_KEYRING"
EOF
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH" STUB_LOG="$T/log"
key=FAKEKEY123-not-a-real-key

fresh_log() { rm -rf "$STUB_LOG"; mkdir -p "$STUB_LOG"; touch "$STUB_LOG/curl.argv" "$STUB_LOG/curl.headers"; }
no_key_in_argv() {
  if grep -qF -- "$key" "$STUB_LOG/curl.argv"; then echo "FAIL: $1: the key is in curl's arguments"; exit 1; fi
}

# 2. request.sh's header option, as the strategies build it
while IFS= read -r header; do
  fresh_log
  printf '#!/usr/bin/env bash\ncurl --no-buffer "http://127.0.0.1:9/v1" -H '"'"'Content-Type: application/json'"'"' %s --data '"'"'{}'"'"' > /dev/null\n' "$header" > "$T/request.sh"
  API_KEY="$key" bash "$T/request.sh"
  no_key_in_argv "request.sh ($header)"
  grep -qE "^(Authorization: Bearer |x-goog-api-key: )$key\$" "$STUB_LOG/curl.headers" ||
    { echo "FAIL: request.sh ($header): the key didn't reach curl as a header"; exit 1; }
done < "$T/headers.txt"
echo "ok: request.sh sends the key as a header, not an argument"

# 3. gemini-translate.sh, in a copy of its folders (its translation tool stubbed)
ii="$T/ii"
mkdir -p "$ii/scripts/ai" "$ii/translations/tools" "$HOME/.config/illogical-impulse"
cp dots/.config/quickshell/ii/scripts/ai/gemini-translate.sh "$ii/scripts/ai/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ii/translations/tools/manage-translations.sh"
chmod +x "$ii/translations/tools/manage-translations.sh"
printf '{"Hello": "Hello"}\n' > "$ii/translations/en_US.json"
printf '{"language": {"ui": "auto"}}\n' > "$HOME/.config/illogical-impulse/config.json"

fresh_log
STUB_KEYRING="{\"apiKeys\":{\"gemini\":\"$key\"}}" XDG_CONFIG_HOME="$HOME/.config" bash "$ii/scripts/ai/gemini-translate.sh" xx_XX > /dev/null
no_key_in_argv gemini-translate.sh
grep -qxF "x-goog-api-key: $key" "$STUB_LOG/curl.headers" || { echo "FAIL: gemini-translate.sh: no key header"; exit 1; }
[[ "$(jq -r .k "$HOME/.config/illogical-impulse/translations/xx_XX.json")" == v ]] || { echo "FAIL: gemini-translate.sh: no translation written"; exit 1; }

fresh_log
if STUB_KEYRING='{"apiKeys":{}}' XDG_CONFIG_HOME="$HOME/.config" bash "$ii/scripts/ai/gemini-translate.sh" xx_XX > /dev/null 2>&1; then
  echo "FAIL: gemini-translate.sh ran with no key"; exit 1
fi
[[ ! -s "$STUB_LOG/curl.argv" ]] || { echo "FAIL: gemini-translate.sh sent a request with no key"; exit 1; }
echo "ok: gemini-translate.sh sends the key as a header, and nothing without one"

echo "ai-safety tests: OK"
