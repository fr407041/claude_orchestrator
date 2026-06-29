#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/rpi_ssh_common.sh"

WINDOWS_LLM_LAN_BASE_URL="${WINDOWS_LLM_LAN_BASE_URL:?WINDOWS_LLM_LAN_BASE_URL is required}"
WINDOWS_LLM_MODEL="${WINDOWS_LLM_MODEL:?WINDOWS_LLM_MODEL is required}"
REMOTE_CONFIG_DIR="${RPI_REMOTE_BASE_DIR}/config"
REMOTE_SCRIPT_DIR="${RPI_REMOTE_BASE_DIR}/scripts"
LOCAL_TEMPLATE="${REPO_ROOT}/configs/router/rpi-router-config.json.example"
LOCAL_TRANSFORMER="${REPO_ROOT}/strip-thinking-transformer.js"
TMP_DIR="${TMPDIR:-/tmp}/rpi-router-config.$$"

mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

rendered_config="${TMP_DIR}/config.json"
rendered_start="${TMP_DIR}/start-ccr-rpi.sh"

sed \
  -e "s|__WINDOWS_LLM_BASE_URL__|${WINDOWS_LLM_LAN_BASE_URL%/}|g" \
  -e "s|__WINDOWS_LLM_MODEL__|${WINDOWS_LLM_MODEL}|g" \
  -e "s|__TRANSFORMER_PATH__|${REMOTE_SCRIPT_DIR}/strip-thinking-transformer.js|g" \
  "$LOCAL_TEMPLATE" >"$rendered_config"

cat >"$rendered_start" <<EOF
#!/usr/bin/env bash
set -euo pipefail

CCR_HOME="\${HOME}/.claude-code-router"
TARGET_CONFIG="\${CCR_HOME}/config.json"
mkdir -p "\${CCR_HOME}"
cp "${REMOTE_CONFIG_DIR}/config.json" "\${TARGET_CONFIG}"
ccr restart >/tmp/ccr-restart.log 2>&1 || true

for _ in \$(seq 1 30); do
  if curl -fsS -H 'x-api-key: local-test-key' "${CCR_HEALTH_URL:-http://127.0.0.1:3456/health}" >/dev/null 2>&1; then
    echo "CCR started with config \${TARGET_CONFIG}"
    exit 0
  fi
  sleep 1
done

echo "CCR failed to become healthy" >&2
cat /tmp/ccr-restart.log >&2 || true
exit 1
EOF

rpi_ssh "mkdir -p '${REMOTE_CONFIG_DIR}' '${REMOTE_SCRIPT_DIR}'"
rpi_scp_to "$rendered_config" "${REMOTE_CONFIG_DIR}/config.json"
rpi_scp_to "$LOCAL_TRANSFORMER" "${REMOTE_SCRIPT_DIR}/strip-thinking-transformer.js"
rpi_scp_to "$rendered_start" "${REMOTE_SCRIPT_DIR}/start-ccr-rpi.sh"
rpi_ssh "chmod +x '${REMOTE_SCRIPT_DIR}/start-ccr-rpi.sh' '${REMOTE_SCRIPT_DIR}/strip-thinking-transformer.js'"

echo "${REMOTE_SCRIPT_DIR}/start-ccr-rpi.sh"
