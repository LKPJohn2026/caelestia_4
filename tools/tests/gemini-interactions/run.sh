#!/usr/bin/env bash
# Tests for services/ai/interactions.js (the Gemini Interactions API's request and stream handling): test.js reads that
# file and replays SSE streams shaped like the API reference. Offline, nothing but node. Without node it's skipped with a
# note (CI=true: a failure, as with ci-lint's other tools).
# Usage: tools/tests/gemini-interactions/run.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v node >/dev/null; then
  if [[ ${CI:-} == true ]]; then
    echo "FAIL: node is not installed"
    echo "gemini-interactions tests: FAILED"
    exit 1
  fi
  echo "skip: node is not installed"
  echo "gemini-interactions tests: OK"
  exit 0
fi

node "$here/test.js"
echo "gemini-interactions tests: OK"
