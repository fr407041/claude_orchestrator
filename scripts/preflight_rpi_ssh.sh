#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rpi_ssh_common.sh"

RPI_PREFLIGHT_JSON="${RPI_PREFLIGHT_JSON:-0}"

remote_report="$ (
  rpi_ssh bash -lc "python3 - <<'PY'
import json
import os
import platform
import shutil
import subprocess
from pathlib import Path

def run(cmd):
    try:
        completed = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True)
    except Exception as exc:
        return {'ok': False, 'code': -1, 'stdout': '', 'stderr': str(exc)}
    return {'ok': completed.returncode == 0, 'code': completed.returncode, 'stdout': completed.stdout.strip(), 'stderr': completed.stderr.strip()}

os_release = {}
for line in Path('/etc/os-release').read_text(encoding='utf-8', errors='ignore').splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        os_release[key] = value.strip().strip('\"')

glibc = platform.libc_ver()
machine = platform.machine()
disk = shutil.disk_usage('/')
meminfo = {}
for line in Path('/proc/meminfo').read_text(encoding='utf-8', errors='ignore').splitlines():
    if ':' in line:
        key, value = line.split(':', 1)
        meminfo[key] = value.strip()

payload = {
    'host': os.uname().nodename,
    'os_release': os_release,
    'machine': machine,
    'is_64bit': machine in {'aarch64', 'x86_64'},
    'glibc': {'name': glibc[0], 'version': glibc[1]},
    'commands': {
        'node': run('node -v'),
        'npm': run('npm -v'),
        'python3': run('python3 --version'),
        'curl': run('curl --version | head -n 1'),
        'bash': run('bash --version | head -n 1'),
    },
    'disk': {
        'total_bytes': disk.total,
        'used_bytes': disk.used,
        'free_bytes': disk.free,
    },
    'memory': {
        'MemTotal': meminfo.get('MemTotal', ''),
        'MemAvailable': meminfo.get('MemAvailable', ''),
    },
}
print(json.dumps(payload))
PY"
)"

python3 - "$remote_report" "$RPI_PREFLIGHT_JSON" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
json_only = sys.argv[2] == "1"
errors = []

if not payload.get("is_64bit"):
    errors.append("raspberry_pi_is_not_64bit")

if payload["commands"]["python3"]["ok"] is False:
    errors.append("python3_missing")

payload["preflight_ok"] = not errors
payload["errors"] = errors

if json_only:
    print(json.dumps(payload, indent=2))
    sys.exit(0 if payload["preflight_ok"] else 1)

print(json.dumps(payload, indent=2))
sys.exit(0 if payload["preflight_ok"] else 1)
PY
