#!/usr/bin/env bash
set -euo pipefail

orchestrator_load_limits() {
  local script_dir repo_root default_limits_file limits_file
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "${script_dir}/.." && pwd)"
  default_limits_file="${repo_root}/profiles/orchestrator-limits.env"
  limits_file="${ORCH_LIMITS_FILE:-${default_limits_file}}"

  if [[ -f "$limits_file" ]]; then
    # shellcheck disable=SC1090
    source "$limits_file"
  fi

  export CCR_AUTOSTART="${CCR_AUTOSTART:-1}"
  export CLAUDE_MODEL_ALIAS="${CLAUDE_MODEL_ALIAS:-sonnet}"
  export CLAUDE_PERMISSION_MODE="${CLAUDE_PERMISSION_MODE:-bypassPermissions}"
  export CLAUDE_MAX_CHILDREN="${CLAUDE_MAX_CHILDREN:-2}"
  export CLAUDE_CHILD_TIMEOUT_SEC="${CLAUDE_CHILD_TIMEOUT_SEC:-600}"

  export ORCH_MAX_FILES_PER_JOB="${ORCH_MAX_FILES_PER_JOB:-2}"
  export ORCH_MAX_JOBS="${ORCH_MAX_JOBS:-3}"
  export ORCH_INVENTORY_LIMIT="${ORCH_INVENTORY_LIMIT:-12}"
  export ORCH_EXECUTE_WORKERS="${ORCH_EXECUTE_WORKERS:-1}"
  export ORCH_WORKER_MODE="${ORCH_WORKER_MODE:-auto}"
  export ORCH_MAX_CHILD_INVOCATIONS="${ORCH_MAX_CHILD_INVOCATIONS:-6}"
  export ORCH_MAX_RETRIES_PER_JOB="${ORCH_MAX_RETRIES_PER_JOB:-2}"
  export ORCH_MAX_FAIL_REPLANS_PER_JOB="${ORCH_MAX_FAIL_REPLANS_PER_JOB:-1}"
  export ORCH_MAX_ROUTER_RECOVERY_REPLANS="${ORCH_MAX_ROUTER_RECOVERY_REPLANS:-1}"
  export ORCH_MAX_FILE_LINES="${ORCH_MAX_FILE_LINES:-4000}"
}

orchestrator_load_limits
