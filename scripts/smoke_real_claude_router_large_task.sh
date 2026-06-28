#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="${1:-${REPO_ROOT}/examples/multi-file-python}"
TASK="${2:-Update src/math_utils.py, src/io_helpers.py, tests/test_math_utils.py, and README.md so the repo has deterministic helper behavior, matching tests, and concise documentation. Keep every file minimal.}"
RUN_ROOT="${ORCH_RUN_ROOT:-${REPO_ROOT}/orchestrator-claude}"
BASE_URL="${ANTHROPIC_BASE_URL:-http://127.0.0.1:3456}"
HEALTH_URL="${CCR_HEALTH_URL:-${BASE_URL%/}/health}"
ALLOW_AUTOSTART="${ALLOW_AUTOSTART:-0}"
MAX_CHILDREN="${CLAUDE_MAX_CHILDREN:-4}"
MAX_CHILD_INVOCATIONS="${ORCH_MAX_CHILD_INVOCATIONS:-8}"
CLAUDE_BIN_CANDIDATE="${CLAUDE_BIN:-claude}"

need_cmd() {
  local name="${1:?name required}"
  command -v "$name" >/dev/null 2>&1 || {
    echo "missing required command: $name" >&2
    exit 1
  }
}

need_cmd bash
need_cmd python3
need_cmd jq
need_cmd curl

if [[ "$CLAUDE_BIN_CANDIDATE" = */* ]]; then
  if [[ ! -x "$CLAUDE_BIN_CANDIDATE" ]]; then
    echo "configured CLAUDE_BIN is not executable: $CLAUDE_BIN_CANDIDATE" >&2
    exit 1
  fi
else
  need_cmd "$CLAUDE_BIN_CANDIDATE"
fi

if [[ "$ALLOW_AUTOSTART" = "1" ]]; then
  if [[ -n "${START_CCR_BIN:-}" ]]; then
    "${START_CCR_BIN}" >/dev/null 2>&1 || true
  else
    echo "ALLOW_AUTOSTART=1 was set, but START_CCR_BIN was not provided." >&2
    echo "Refusing to guess a router startup command because this smoke test must not modify your router settings." >&2
    exit 1
  fi
fi

if ! curl -fsS -H "x-api-key: ${ANTHROPIC_AUTH_TOKEN:-local-test-key}" "$HEALTH_URL" >/dev/null 2>&1; then
  echo "Router health check failed at: $HEALTH_URL" >&2
  echo "Start your existing Claude Code Router first, or rerun with ALLOW_AUTOSTART=1 and START_CCR_BIN=/path/to/your/start-command." >&2
  exit 1
fi

export CLAUDE_BIN="$CLAUDE_BIN_CANDIDATE"
export CCR_AUTOSTART=0
export CLAUDE_MAX_CHILDREN="$MAX_CHILDREN"
export ORCH_MAX_CHILD_INVOCATIONS="$MAX_CHILD_INVOCATIONS"

cat > "${PROJECT_ROOT}/src/math_utils.py" <<'EOF'
def add(a, b):
    return a + b
EOF

cat > "${PROJECT_ROOT}/src/io_helpers.py" <<'EOF'
def render_number(value):
    return f"value={value}"
EOF

cat > "${PROJECT_ROOT}/tests/test_math_utils.py" <<'EOF'
from src.math_utils import add


def test_add():
    assert add(1, 1) == 2
EOF

cat > "${PROJECT_ROOT}/README.md" <<'EOF'
# multi-file-python

Small multi-file repo for Claude Code + router orchestration tests.
EOF

bash "${SCRIPT_DIR}/orchestrate_claude_to_claude.sh" \
  "$TASK" \
  "$PROJECT_ROOT"

LATEST_RUN="$(find "$RUN_ROOT" -maxdepth 1 -type d -name 'run-*' | sort | tail -n 1)"
SUMMARY_FILE="${LATEST_RUN}/summary.json"

python3 - "$SUMMARY_FILE" "$PROJECT_ROOT" "$CLAUDE_BIN_CANDIDATE" <<'PY'
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
project_root = Path(sys.argv[2])
claude_bin = sys.argv[3]
metrics = summary.get("metrics", {})

math_text = (project_root / "src/math_utils.py").read_text(encoding="utf-8")
io_text = (project_root / "src/io_helpers.py").read_text(encoding="utf-8")
test_text = (project_root / "tests/test_math_utils.py").read_text(encoding="utf-8")
readme_text = (project_root / "README.md").read_text(encoding="utf-8")

reasons = []
if metrics.get("workers_run", 0) < 2:
    reasons.append("expected at least two child jobs for the larger task")
if metrics.get("workers_with_verified_changes", 0) < 2:
    reasons.append("expected at least two verified child changes")
if "return a + b" not in math_text:
    reasons.append("math helper was not normalized")
if 'return f"number={value}"' not in io_text:
    reasons.append("io helper was not normalized")
if 'assert render_number(2) == "number=2"' not in test_text:
    reasons.append("test file does not validate render_number")
if "render_number(value)" not in readme_text:
    reasons.append("README was not updated")

result = {
    "integration_ok": not reasons,
    "reasons": reasons,
    "run_id": summary.get("run_id"),
    "scope_path": summary.get("scope_path"),
    "strategy": summary.get("strategy"),
    "claude_bin": claude_bin,
    "metrics": metrics,
}
print(json.dumps(result, indent=2))
if reasons:
    sys.exit(1)
PY
