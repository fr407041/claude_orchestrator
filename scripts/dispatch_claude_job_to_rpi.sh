#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rpi_ssh_common.sh"

JOB_FILE="${1:?Usage: dispatch_claude_job_to_rpi.sh <job.json> <raw_output_file>}"
RAW_OUTPUT_FILE="${2:?Usage: dispatch_claude_job_to_rpi.sh <job.json> <raw_output_file>}"
REMOTE_ROOT="${RPI_REMOTE_BASE_DIR}/jobs"
TMP_DIR="${TMPDIR:-/tmp}/rpi-dispatch.$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

JOB_META="$(python3 - "$JOB_FILE" <<'PY'
import json
import sys
from pathlib import Path

job = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(json.dumps({
    "id": job["id"],
    "scope_path": job.get("scope_path", "."),
    "files": job.get("files", []),
    "instruction": job.get("instruction", ""),
}))
PY
)"

JOB_ID="$(python3 - "$JOB_META" <<'PY'
import json, sys
print(json.loads(sys.argv[1])["id"])
PY
)"
SCOPE_PATH="$(python3 - "$JOB_META" <<'PY'
import json, sys
print(json.loads(sys.argv[1])["scope_path"])
PY
)"
REMOTE_JOB_DIR="${REMOTE_ROOT}/${JOB_ID}"
REMOTE_WORKDIR="${REMOTE_JOB_DIR}/work"
REMOTE_RAW_FILE="${REMOTE_JOB_DIR}/raw.txt"

rpi_ssh "rm -rf '${REMOTE_JOB_DIR}' && mkdir -p '${REMOTE_WORKDIR}'"

python3 - "$JOB_META" "$TMP_DIR" "$SCOPE_PATH" <<'PY'
import json
import sys
from pathlib import Path

meta = json.loads(sys.argv[1])
tmp_dir = Path(sys.argv[2])
scope_path = Path(sys.argv[3])

for rel in meta["files"]:
    src = scope_path / rel
    dst = tmp_dir / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.exists():
        dst.write_bytes(src.read_bytes())
PY

while IFS= read -r file_path; do
  rel_path="${file_path#${TMP_DIR}/}"
  remote_dir="$(dirname "${REMOTE_WORKDIR}/${rel_path}")"
  rpi_ssh "mkdir -p '${remote_dir}'"
  rpi_scp_to "$file_path" "${REMOTE_WORKDIR}/${rel_path}"
done < <(find "$TMP_DIR" -type f | sort)

rpi_ssh "mkdir -p '${REMOTE_JOB_DIR}'"
rpi_scp_to "$JOB_FILE" "${REMOTE_JOB_DIR}/job.json"

rpi_ssh bash -s <<EOF
set -euo pipefail
cd '${REMOTE_WORKDIR}'
bash '${RPI_REMOTE_BASE_DIR}/scripts/start-ccr-rpi.sh' >/dev/null
export ANTHROPIC_AUTH_TOKEN="\${ANTHROPIC_AUTH_TOKEN:-local-test-key}"
export ANTHROPIC_BASE_URL="\${ANTHROPIC_BASE_URL:-http://127.0.0.1:3456}"
export NO_PROXY="\${NO_PROXY:-127.0.0.1,localhost}"
export DISABLE_PROMPT_CACHING="\${DISABLE_PROMPT_CACHING:-1}"
export API_TIMEOUT_MS="\${API_TIMEOUT_MS:-600000}"
PROMPT=\$(python3 - '${REMOTE_JOB_DIR}/job.json' <<'PY'
import json
import sys
from pathlib import Path

job = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
files = '\n'.join(job.get('files', []))
print(f'''You are the remote Raspberry Pi Claude worker.

Task:
{job.get("instruction", "")}

Allowed files:
{files}

Return format:
STATUS: <SUCCESS|NEEDS_REPLAN|OVERFLOW_DETECTED|ROUTER_ERROR|FAILED>
FILES: <comma-separated paths>
TESTS: not-run
SUMMARY: <one short paragraph>
''')
PY
)
claude --bare -p --model "${CLAUDE_MODEL_ALIAS:-sonnet}" --permission-mode "${CLAUDE_PERMISSION_MODE:-bypassPermissions}" --output-format text "\${PROMPT}" > '${REMOTE_RAW_FILE}' 2>&1
EOF

rpi_scp_from "${REMOTE_RAW_FILE}" "$RAW_OUTPUT_FILE"

python3 - "$JOB_META" "$TMP_DIR" <<'PY'
import json
import sys
from pathlib import Path

meta = json.loads(sys.argv[1])
tmp_dir = Path(sys.argv[2])
for rel in meta["files"]:
    local_marker = tmp_dir / rel
    if not local_marker.parent.exists():
        local_marker.parent.mkdir(parents=True, exist_ok=True)
PY

python3 - "$JOB_META" "$TMP_DIR" <<'PY' >"${TMP_DIR}/files.txt"
import json
import sys
from pathlib import Path

meta = json.loads(sys.argv[1])
tmp_dir = Path(sys.argv[2])
for rel in meta["files"]:
    print(str(tmp_dir / rel))
PY

while IFS= read -r local_file; do
  rel_path="${local_file#${TMP_DIR}/}"
  if rpi_scp_from "${REMOTE_WORKDIR}/${rel_path}" "$local_file" 2>/dev/null; then
    local_target="${SCOPE_PATH}/${rel_path}"
    mkdir -p "$(dirname "$local_target")"
    cp "$local_file" "$local_target"
  fi
done < "${TMP_DIR}/files.txt"
