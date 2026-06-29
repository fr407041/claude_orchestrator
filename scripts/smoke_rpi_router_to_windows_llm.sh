#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rpi_ssh_common.sh"

WINDOWS_LLM_LAN_BASE_URL="${WINDOWS_LLM_LAN_BASE_URL:?WINDOWS_LLM_LAN_BASE_URL is required}"
WINDOWS_LLM_MODEL="${WINDOWS_LLM_MODEL:?WINDOWS_LLM_MODEL is required}"
REMOTE_STARTER="${RPI_REMOTE_BASE_DIR}/scripts/start-ccr-rpi.sh"
REMOTE_JOB_DIR="${RPI_REMOTE_BASE_DIR}/smoke"

rpi_ssh "curl -fsS '${WINDOWS_LLM_LAN_BASE_URL%/}/api/tags' >/dev/null"
rpi_ssh "bash '${REMOTE_STARTER}' >/dev/null"

rpi_ssh bash -s <<EOF
set -euo pipefail
mkdir -p '${REMOTE_JOB_DIR}'
cd '${REMOTE_JOB_DIR}'
export ANTHROPIC_AUTH_TOKEN="\${ANTHROPIC_AUTH_TOKEN:-local-test-key}"
export ANTHROPIC_BASE_URL="\${ANTHROPIC_BASE_URL:-http://127.0.0.1:3456}"
export NO_PROXY="\${NO_PROXY:-127.0.0.1,localhost}"
export DISABLE_PROMPT_CACHING="\${DISABLE_PROMPT_CACHING:-1}"
export API_TIMEOUT_MS="\${API_TIMEOUT_MS:-600000}"

claude --bare -p --model "${CLAUDE_MODEL_ALIAS:-sonnet}" --permission-mode "${CLAUDE_PERMISSION_MODE:-bypassPermissions}" --output-format text \
  "Reply with exactly: rpi-router-ok model=${WINDOWS_LLM_MODEL}" \
  > '${REMOTE_JOB_DIR}/smoke-output.txt'

node -v
npm -v
claude --version
ccr version
cat '${REMOTE_JOB_DIR}/smoke-output.txt'
EOF
