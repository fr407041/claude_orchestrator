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
copy_file "${REPO_ROOT}/CLAUDE_ROUTER_PURE_MODE_SPEC.zh-TW.md" "${BUNDLE_ROOT}/CLAUDE_ROUTER_PURE_MODE_SPEC.zh-TW.md"
copy_file "${REPO_ROOT}/COMPANY_TEST_MATRIX.zh-TW.md" "${BUNDLE_ROOT}/COMPANY_TEST_MATRIX.zh-TW.md"
copy_file "${REPO_ROOT}/KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md" "${BUNDLE_ROOT}/KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md"
copy_file "${REPO_ROOT}/SAFE_PUBLISHING.md" "${BUNDLE_ROOT}/SAFE_PUBLISHING.md"
copy_file "${REPO_ROOT}/PUBLISH_TARGET.txt" "${BUNDLE_ROOT}/PUBLISH_TARGET.txt"
copy_file "${REPO_ROOT}/.gitignore" "${BUNDLE_ROOT}/.gitignore"

copy_tree "${REPO_ROOT}/profiles" "${BUNDLE_ROOT}/profiles"
copy_tree "${REPO_ROOT}/docker/claude-router-bundle-test" "${BUNDLE_ROOT}/docker/claude-router-bundle-test"
copy_tree "${REPO_ROOT}/examples/hello-python" "${BUNDLE_ROOT}/examples/hello-python"
copy_tree "${REPO_ROOT}/examples/multi-file-python" "${BUNDLE_ROOT}/examples/multi-file-python"

for file in \
  claude_router_common.sh \
  cleanup_claude_children.sh \
  evaluate_claude_bad_planner.sh \
  evaluate_claude_child_limits.sh \
  evaluate_claude_deep_overflow_chain.sh \
  evaluate_claude_fail_replan.sh \
  evaluate_claude_false_success_guard.sh \
  evaluate_claude_interface_regression.sh \
  evaluate_claude_kimi_k2_conservative_single_file.sh \
  evaluate_claude_kimi_k2_rls_complex_release.sh \
  evaluate_claude_kimi_k2_router_recovery_storm.sh \
  evaluate_claude_large_complex_workflow.sh \
  evaluate_claude_large_file_guard.sh \
  evaluate_claude_mixed_failure_chain.sh \
  evaluate_claude_multi_round.sh \
  evaluate_claude_needs_replan.sh \
  evaluate_claude_parallel_isolation.sh \
  evaluate_claude_product_grade_matrix.sh \
  evaluate_claude_reasoning_pressure.sh \
  evaluate_claude_replan_loop_guard.sh \
  evaluate_claude_rls_production_matrix.sh \
  evaluate_claude_router_empty_response.sh \
  evaluate_claude_router_flapping.sh \
  evaluate_claude_router_instability.sh \
  evaluate_claude_router_partial_response.sh \
  evaluate_claude_same_failure_guard.sh \
  evaluate_claude_single_file.sh \
  evaluate_claude_timeout_recovery.sh \
  evaluate_claude_timeout_storm.sh \
  evaluate_claude_variant_replan_loop.sh \
  install_claude_router_orchestrator_bundle.sh \
  mock_claude_router_cli.py \
  orchestrator_limits.sh \
  orchestrate_claude_to_claude.sh \
  orchestrate_codex_to_claude.sh \
  package_publish_bundle.sh \
  run_claude_guarded.sh \
  smoke_bundle_in_fresh_image.sh \
  smoke_real_claude_router_integration.sh \
  smoke_real_claude_router_large_task.sh \
  worker_claude_router.sh \
  worker_claude_router_managed_single_file.sh
do
  copy_file "${REPO_ROOT}/scripts/${file}" "${BUNDLE_ROOT}/scripts/${file}"
done

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
