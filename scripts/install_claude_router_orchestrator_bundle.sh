#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_ROOT="${1:-/opt/claude_orchestrator}"
TARGET_ROOT="$(python3 - "$TARGET_ROOT" <<'PY'
import os
import sys
print(os.path.abspath(sys.argv[1]))
PY
)"

mkdir -p "${TARGET_ROOT}/scripts" "${TARGET_ROOT}/profiles" "${TARGET_ROOT}/examples" "${TARGET_ROOT}/docker/claude-router-bundle-test"

copy_file() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

copy_optional_file() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  if [[ -f "$src" ]]; then
    copy_file "$src" "$dst"
  fi
}

copy_tree() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  mkdir -p "$dst"
  cp -R "${src}/." "$dst/"
}

copy_optional_tree() {
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  if [[ -d "$src" ]]; then
    copy_tree "$src" "$dst"
  fi
}

copy_file "${REPO_ROOT}/README.md" "${TARGET_ROOT}/README.md"
copy_optional_file "${REPO_ROOT}/README.zh-TW.md" "${TARGET_ROOT}/README.zh-TW.md"
copy_optional_file "${REPO_ROOT}/BUNDLE_INSTALL.zh-TW.md" "${TARGET_ROOT}/BUNDLE_INSTALL.zh-TW.md"
copy_optional_file "${REPO_ROOT}/COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md" "${TARGET_ROOT}/COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md"
copy_optional_file "${REPO_ROOT}/CLAUDE_ROUTER_PURE_MODE_SPEC.zh-TW.md" "${TARGET_ROOT}/CLAUDE_ROUTER_PURE_MODE_SPEC.zh-TW.md"
copy_optional_file "${REPO_ROOT}/COMPANY_TEST_MATRIX.zh-TW.md" "${TARGET_ROOT}/COMPANY_TEST_MATRIX.zh-TW.md"
copy_optional_file "${REPO_ROOT}/PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md" "${TARGET_ROOT}/PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md"
copy_optional_file "${REPO_ROOT}/RLS_PRODUCTION_TEST_PLAN.zh-TW.md" "${TARGET_ROOT}/RLS_PRODUCTION_TEST_PLAN.zh-TW.md"
copy_optional_file "${REPO_ROOT}/KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md" "${TARGET_ROOT}/KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md"
copy_optional_file "${REPO_ROOT}/TEST_RESULTS_2026-06-27.zh-TW.md" "${TARGET_ROOT}/TEST_RESULTS_2026-06-27.zh-TW.md"
copy_optional_file "${REPO_ROOT}/SAFE_PUBLISHING.md" "${TARGET_ROOT}/SAFE_PUBLISHING.md"
copy_optional_file "${REPO_ROOT}/profiles/orchestrator-limits.env" "${TARGET_ROOT}/profiles/orchestrator-limits.env"
copy_optional_file "${REPO_ROOT}/profiles/preset-conservative.env" "${TARGET_ROOT}/profiles/preset-conservative.env"
copy_optional_file "${REPO_ROOT}/profiles/preset-fast.env" "${TARGET_ROOT}/profiles/preset-fast.env"
copy_optional_file "${REPO_ROOT}/profiles/preset-large-project-safe.env" "${TARGET_ROOT}/profiles/preset-large-project-safe.env"
copy_optional_file "${REPO_ROOT}/profiles/kimi-k2-router-production.env" "${TARGET_ROOT}/profiles/kimi-k2-router-production.env"
copy_optional_file "${REPO_ROOT}/profiles/kimi-k2-router-ultra-safe.env" "${TARGET_ROOT}/profiles/kimi-k2-router-ultra-safe.env"

for file in \
  claude_router_common.sh \
  cleanup_claude_children.sh \
  evaluate_claude_bad_planner.sh \
  evaluate_claude_child_limits.sh \
  evaluate_claude_deep_overflow_chain.sh \
  evaluate_claude_fail_replan.sh \
  evaluate_claude_false_success_guard.sh \
  evaluate_claude_reasoning_pressure.sh \
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
  evaluate_claude_replan_loop_guard.sh \
  evaluate_claude_rls_production_matrix.sh \
  evaluate_claude_router_empty_response.sh \
  evaluate_claude_router_flapping.sh \
  evaluate_claude_router_instability.sh \
  evaluate_claude_router_partial_response.sh \
  evaluate_claude_same_failure_guard.sh \
  evaluate_claude_single_file.sh \
  evaluate_claude_timeout_storm.sh \
  evaluate_claude_timeout_recovery.sh \
  evaluate_claude_variant_replan_loop.sh \
  install_claude_router_orchestrator_bundle.sh \
  mock_claude_router_cli.py \
  orchestrator_limits.sh \
  orchestrate_claude_to_claude.sh \
  orchestrate_codex_to_claude.sh \
  package_publish_bundle.sh \
  run_claude_guarded.sh \
  smoke_real_claude_router_integration.sh \
  smoke_real_claude_router_large_task.sh \
  smoke_bundle_in_fresh_image.sh \
  worker_claude_router.sh \
  worker_claude_router_managed_single_file.sh
do
  copy_optional_file "${REPO_ROOT}/scripts/${file}" "${TARGET_ROOT}/scripts/${file}"
done

copy_optional_tree "${REPO_ROOT}/examples/hello-python" "${TARGET_ROOT}/examples/hello-python"
copy_optional_tree "${REPO_ROOT}/examples/multi-file-python" "${TARGET_ROOT}/examples/multi-file-python"
copy_optional_tree "${REPO_ROOT}/docker/claude-router-bundle-test" "${TARGET_ROOT}/docker/claude-router-bundle-test"

chmod +x "${TARGET_ROOT}/scripts/"*.sh

cat > "${TARGET_ROOT}/BUNDLE_MANIFEST.txt" <<EOF
Claude/router orchestration bundle installed at:
${TARGET_ROOT}

Included:
- main->child Claude/router orchestration scripts
- child process cap and safe cleanup helpers
- mock-based multi-round evaluation scripts
- centralized limits file at profiles/orchestrator-limits.env
- preset profiles for conservative, fast, large-project-safe, Kimi-K2 conservative, and Kimi-K2 ultra-safe modes
- fresh Docker image smoke test assets
- company-facing Chinese quickstart, ultra-safe guidance, and release test docs

Excluded on purpose:
- Claude Code installation flow
- Claude Code Router installation flow
- model selection or router model config changes
EOF

printf '%s\n' "${TARGET_ROOT}"
