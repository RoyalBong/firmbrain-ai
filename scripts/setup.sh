#!/usr/bin/env bash
# Idempotent Phase 1 setup: wait for native Ollama, pull models from models.txt.
# Does not install Ollama. Safe to re-run.
# Usage: ./scripts/setup.sh [--include-optional]
set -euo pipefail

INCLUDE_OPTIONAL=0
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
READY_TIMEOUT="${READY_TIMEOUT:-120}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-optional) INCLUDE_OPTIONAL=1; shift ;;
    --ollama-url) OLLAMA_URL="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_FILE="$REPO_ROOT/models.txt"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ERROR: ollama is not on PATH. Install Ollama, then re-run." >&2
  echo "  Linux: https://ollama.com/download" >&2
  exit 1
fi

if [[ ! -f "$MODELS_FILE" ]]; then
  echo "ERROR: models.txt not found at $MODELS_FILE" >&2
  exit 1
fi

echo "FirmBrain.AI Phase 1 setup"
echo "Repo: $REPO_ROOT"
echo "Ollama: $OLLAMA_URL"
echo

echo "Waiting for Ollama to become ready (timeout ${READY_TIMEOUT}s)..."
elapsed=0
until curl -sf "$OLLAMA_URL/api/tags" >/dev/null 2>&1; do
  if (( elapsed >= READY_TIMEOUT )); then
    echo "ERROR: Ollama did not respond at $OLLAMA_URL/api/tags. Start the Ollama service and retry." >&2
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
echo "Ollama is ready."
echo

model_installed() {
  local wanted="$1"
  local have
  have="$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')"
  grep -qxF "$wanted" <<<"$have" && return 0
  grep -qE "^${wanted}" <<<"$have" && return 0
  return 1
}

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  name="$(awk '{print $1}' <<<"$line")"
  tier="$(awk '{print $2}' <<<"$line" | tr '[:upper:]' '[:lower:]')"
  purpose="$(awk '{$1=$2=""; sub(/^ +/,""); print}' <<<"$line")"

  if [[ "$tier" != "required" ]]; then
    if [[ "$INCLUDE_OPTIONAL" -eq 1 && "$tier" == "optional" ]]; then
      :
    else
      continue
    fi
  fi

  if model_installed "$name"; then
    echo "Skip (already present): $name"
    continue
  fi

  echo "Pulling $name  ($purpose)"
  echo "WARNING: First pull needs internet. Slow disk load times after pull are expected."
  ollama pull "$name"
done < "$MODELS_FILE"

echo
echo "----- Next steps -----"
echo "Ollama API:              $OLLAMA_URL  (localhost only — do not set OLLAMA_HOST=0.0.0.0)"
echo "AnythingLLM:            Desktop app in Phase 1 (port 3001 is Phase 2 Docker)"
echo "Chat model:              qwen2.5:1.5b"
echo "Embedding model:        nomic-embed-text"
echo "Settings guide:         docs/anythingllm-settings.md"
echo
echo "WARNING: Do not enable Ollama on the LAN in Phase 1."
