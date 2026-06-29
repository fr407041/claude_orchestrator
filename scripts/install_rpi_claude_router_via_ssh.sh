#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rpi_ssh_common.sh"

WINDOWS_LLM_LAN_BASE_URL="${WINDOWS_LLM_LAN_BASE_URL:?WINDOWS_LLM_LAN_BASE_URL is required}"
WINDOWS_LLM_MODEL="${WINDOWS_LLM_MODEL:?WINDOWS_LLM_MODEL is required}"
NODE_MAJOR="${NODE_MAJOR:-20}"

bash "${SCRIPT_DIR}/preflight_rpi_ssh.sh" >/dev/null

rpi_ssh bash -s <<EOF
set -euo pipefail
SUDO=""
if command -v sudo >/dev/null 2>&1 && [[ \$(id -u) -ne 0 ]]; then
  SUDO="sudo"
fi

\${SUDO} apt-get update
\${SUDO} apt-get install -y \
  bash \
  ca-certificates \
  curl \
  git \
  jq \
  python3 \
  python3-pip \
  python3-venv \
  gnupg \
  openssh-client

\${SUDO} mkdir -p /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/nodesource.gpg ]]; then
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | \${SUDO} gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
fi

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | \${SUDO} tee /etc/apt/sources.list.d/nodesource.list >/dev/null

\${SUDO} apt-get update
\${SUDO} apt-get install -y nodejs

\${SUDO} npm install -g @anthropic-ai/claude-code @musistudio/claude-code-router
mkdir -p '${RPI_REMOTE_BASE_DIR}/config' '${RPI_REMOTE_BASE_DIR}/scripts' '${RPI_REMOTE_BASE_DIR}/jobs'
EOF

bash "${SCRIPT_DIR}/configure_rpi_router_to_windows_ollama.sh" >/dev/null
bash "${SCRIPT_DIR}/smoke_rpi_router_to_windows_llm.sh"
