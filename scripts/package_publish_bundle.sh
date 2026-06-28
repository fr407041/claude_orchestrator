#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
STAMP="$(date +%Y%m%d-%H%M%S)"
BUNDLE_ROOT="${DIST_DIR}/claude-router-orchestrator-bundle-${STAMP}"
ZIP_PATH="${DIST_DIR}/claude-router-orchestrator-bundle-${STAMP}.zip"

mkdir -p "${DIST_DIR}"
rm -rf "${BUNDLE_ROOT}"
mkdir -p "${BUNDLE_ROOT}"

copy_file() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
}

copy_tree() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  mkdir -p "${dst}"
  cp -R "${src}/." "${dst}/"
}

copy_file "${REPO_ROOT}/README.md" "${BUNDLE_ROOT}/README.md"
copy_file "${REPO_ROOT}/README.zh-TW.md" "${BUNDLE_ROOT}/README.zh-TW.md"
copy_file "${REPO_ROOT}/BUNDLE_INSTALL.zh-TW.md" "${BUNDLE_ROOT}/BUNDLE_INSTALL.zh-TW.md"
copy_file "${REPO_ROOT}/COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md" "${BUNDLE_ROOT}/COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md"
copy_file "${REPO_ROOT}/PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md" "${BUNDLE_ROOT}/PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md"
copy_file "${REPO_ROOT}/RLS_PRODUCTION_TEST_PLAN.zh-TW.md" "${BUNDLE_ROOT}/RLS_PRODUCTION_TEST_PLAN.zh-TW.md"
copy_file "${REPO_ROOT}/SAFE_PUBLISHING.md" "${BUNDLE_ROOT}/SAFE_PUBLISHING.md"
copy_tree "${REPO_ROOT}/profiles" "${BUNDLE_ROOT}/profiles"
copy_tree "${REPO_ROOT}/docker/claude-router-bundle-test" "${BUNDLE_ROOT}/docker/claude-router-bundle-test"
copy_tree "${REPO_ROOT}/examples/hello-python" "${BUNDLE_ROOT}/examples/hello-python"
copy_tree "${REPO_ROOT}/examples/multi-file-python" "${BUNDLE_ROOT}/examples/multi-file-python"
copy_tree "${REPO_ROOT}/scripts" "${BUNDLE_ROOT}/scripts"

chmod +x "${BUNDLE_ROOT}/scripts/"*.sh

python3 - "${BUNDLE_ROOT}" "${ZIP_PATH}" <<'PY'
import sys
import zipfile
from pathlib import Path

bundle_root = Path(sys.argv[1])
zip_path = Path(sys.argv[2])

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(bundle_root.rglob("*")):
        if path.is_file():
            zf.write(path, path.relative_to(bundle_root))

print(zip_path)
PY
