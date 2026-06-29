#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/docker-preflight.$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

version_log="${TMP_DIR}/docker-version.txt"
compose_log="${TMP_DIR}/docker-compose.txt"

docker_ok=0
compose_ok=0

if docker version >"$version_log" 2>&1; then
  docker_ok=1
fi

if docker compose version >"$compose_log" 2>&1; then
  compose_ok=1
fi

python3 - "$version_log" "$compose_log" "$docker_ok" "$compose_ok" <<'PY'
import json
import sys
from pathlib import Path

version_log = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
compose_log = Path(sys.argv[2]).read_text(encoding="utf-8", errors="ignore")
docker_ok = sys.argv[3] == "1"
compose_ok = sys.argv[4] == "1"

payload = {
    "docker_ok": docker_ok,
    "docker_compose_ok": compose_ok,
    "docker_version_output": version_log.strip(),
    "docker_compose_output": compose_log.strip(),
    "likely_docker_config_permission_issue": "config.json: Access is denied" in version_log or "config.json: Access is denied" in compose_log,
}
print(json.dumps(payload, indent=2))
PY
