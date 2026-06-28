#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${REPO_ROOT}/tmp/rls-production-matrix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

declare -a CASES=(
  "evaluate_claude_deep_overflow_chain.sh"
  "evaluate_claude_reasoning_pressure.sh"
  "evaluate_claude_large_file_guard.sh"
  "evaluate_claude_router_empty_response.sh"
  "evaluate_claude_router_partial_response.sh"
  "evaluate_claude_router_flapping.sh"
  "evaluate_claude_timeout_storm.sh"
  "evaluate_claude_interface_regression.sh"
  "evaluate_claude_same_failure_guard.sh"
  "evaluate_claude_large_complex_workflow.sh"
  "evaluate_claude_kimi_k2_conservative_single_file.sh"
  "evaluate_claude_kimi_k2_router_recovery_storm.sh"
  "evaluate_claude_kimi_k2_rls_complex_release.sh"
)

json_files=()

for case_name in "${CASES[@]}"; do
  case_stem="${case_name%.sh}"
  out_file="${OUT_DIR}/${case_stem}.json"
  set +e
  bash "${SCRIPT_DIR}/${case_name}" >"${out_file}"
  set -e
  json_files+=("$out_file")
done

python3 - "$OUT_DIR" "${json_files[@]}" <<'PY'
import json
import sys
from pathlib import Path

out_dir = Path(sys.argv[1])
json_paths = [Path(arg) for arg in sys.argv[2:]]

cases = []
for path in json_paths:
    data = json.loads(path.read_text(encoding="utf-8"))
    cases.append(
        {
            "scenario": data.get("scenario", path.stem.replace("evaluate_", "")),
            "pass": bool(data.get("pass", False)),
            "metrics": data.get("metrics", {}),
            "source_file": str(path),
        }
    )

pass_count = sum(1 for case in cases if case["pass"])
fail_count = sum(1 for case in cases if not case["pass"])
required_scenarios = {
    "deep_overflow_chain",
    "reasoning_pressure",
    "large_file_guard",
    "router_empty_response",
    "router_partial_response",
    "router_flapping",
    "timeout_storm",
    "interface_regression",
    "same_failure_guard",
    "large_complex_workflow",
    "kimi_k2_conservative_single_file",
    "kimi_k2_router_recovery_storm",
    "kimi_k2_rls_complex_release",
}
present = {case["scenario"] for case in cases}
missing = sorted(required_scenarios - present)

total_verified_changes = sum(case["metrics"].get("workers_with_verified_changes", 0) for case in cases)
max_same_failure_again = max((case["metrics"].get("same_failure_again", 0) for case in cases), default=0)
max_child_limit_hits = max((case["metrics"].get("child_invocation_limit_hit", 0) for case in cases), default=0)

gates = {
    "all_cases_passed": fail_count == 0,
    "no_required_case_missing": not missing,
    "router_recovery_present": any(case["metrics"].get("workers_router_errors", 0) >= 2 for case in cases),
    "overflow_split_present": any(case["metrics"].get("overflow_retries", 0) >= 2 for case in cases),
    "loop_stop_present": any(case["metrics"].get("replan_loop_guard_hit", 0) >= 1 for case in cases),
    "false_success_block_present": any(case["metrics"].get("workers_false_success_blocked", 0) >= 1 for case in cases),
    "single_file_overflow_recovery_present": any(
        case["metrics"].get("workers_overflowed", 0) >= 2 and case["metrics"].get("overflow_retries", 0) >= 2
        for case in cases
    ),
    "multi_router_recovery_depth_present": any(case["metrics"].get("router_replan_attempts", 0) >= 2 for case in cases),
    "verified_changes_floor_met": total_verified_changes >= 10,
    "no_child_limit_hits": max_child_limit_hits == 0,
    "same_failure_is_bounded": max_same_failure_again <= 1,
}

production_ready = all(gates.values())
summary = {
    "scenario": "rls_production_matrix",
    "pass": production_ready,
    "production_ready": production_ready,
    "pass_count": pass_count,
    "fail_count": fail_count,
    "missing_required_scenarios": missing,
    "aggregate_metrics": {
        "total_verified_changes": total_verified_changes,
        "max_same_failure_again": max_same_failure_again,
        "max_child_limit_hits": max_child_limit_hits,
    },
    "gates": gates,
    "cases": cases,
}
(out_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
if not production_ready:
    sys.exit(1)
PY
