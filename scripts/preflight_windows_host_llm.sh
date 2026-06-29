#!/usr/bin/env bash
set -euo pipefail

WINDOWS_LLM_BASE_URL="${WINDOWS_LLM_BASE_URL:-http://host.docker.internal:11434}"
WINDOWS_LLM_LAN_BASE_URL="${WINDOWS_LLM_LAN_BASE_URL:-}"
WINDOWS_LLM_MODEL="${WINDOWS_LLM_MODEL:-}"

check_tags() {
  local base_url="${1:?base_url required}"
  curl -fsS "${base_url%/}/api/tags"
}

primary_json="$(check_tags "$WINDOWS_LLM_BASE_URL")"
primary_models="$(python3 - "$primary_json" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
models = [item.get("name", "") for item in data.get("models", []) if item.get("name")]
print("\n".join(models))
PY
)"

if [[ -z "$WINDOWS_LLM_MODEL" ]]; then
  WINDOWS_LLM_MODEL="$(printf '%s\n' "$primary_models" | head -n 1)"
fi

lan_ok=0
lan_models=""
lan_error=""
if [[ -n "$WINDOWS_LLM_LAN_BASE_URL" ]]; then
  if lan_json="$(check_tags "$WINDOWS_LLM_LAN_BASE_URL" 2>&1)"; then
    lan_models="$(python3 - "$lan_json" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
models = [item.get("name", "") for item in data.get("models", []) if item.get("name")]
print("\n".join(models))
PY
)"
    lan_ok=1
  else
    lan_error="$lan_json"
  fi
fi

python3 - "$WINDOWS_LLM_BASE_URL" "$WINDOWS_LLM_LAN_BASE_URL" "$WINDOWS_LLM_MODEL" "$lan_ok" "$primary_models" "$lan_models" "$lan_error" <<'PY'
import json
import sys

base_url, lan_url, model, lan_ok, primary_models, lan_models, lan_error = sys.argv[1:8]
likely_localhost_bind_only = bool(lan_url) and lan_ok != "1"
payload = {
    "windows_llm_base_url": base_url,
    "windows_llm_lan_base_url": lan_url,
    "windows_llm_model": model,
    "primary_models": [line for line in primary_models.splitlines() if line],
    "lan_models": [line for line in lan_models.splitlines() if line],
    "lan_check_enabled": bool(lan_url),
    "lan_check_ok": lan_ok == "1",
    "lan_error": lan_error,
    "likely_localhost_bind_only": likely_localhost_bind_only,
}
print(json.dumps(payload, indent=2))
PY

if [[ -n "$WINDOWS_LLM_LAN_BASE_URL" && "$lan_ok" != "1" ]]; then
  >&2 echo "LAN endpoint check failed for $WINDOWS_LLM_LAN_BASE_URL"
  >&2 echo "Likely cause: the Windows-hosted LLM service is only listening on localhost."
  >&2 echo "Confirm the host service is bound to a LAN-reachable address before provisioning Raspberry Pi workers."
  exit 2
fi
