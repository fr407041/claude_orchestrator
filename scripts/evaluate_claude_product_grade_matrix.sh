#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${REPO_ROOT}/tmp/product-grade-matrix-$(date +%Y%m%d-%H%M%S)"
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
    scenario = data.get("scenario", path.stem.replace("evaluate_", ""))
    case_pass = bool(data.get("pass", data.get("integration_ok", False)))
    metrics = data.get("metrics", {})
    cases.append(
        {
            "scenario": scenario,
            "pass": case_pass,
            "metrics": metrics,
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
}
present = {case["scenario"] for case in cases}
missing = sorted(required_scenarios - present)

gates = {
    "all_cases_passed": fail_count == 0,
    "no_required_case_missing": not missing,
    "router_recovery_present": any(
        case["metrics"].get("workers_router_errors", 0) >= 1 for case in cases
    ),
    "overflow_split_present": any(
        case["metrics"].get("overflow_retries", 0) >= 1 for case in cases
    ),
    "loop_stop_present": any(
        case["metrics"].get("replan_loop_guard_hit", 0) >= 1 for case in cases
    ),
    "false_success_block_present": any(
        case["metrics"].get("workers_false_success_blocked", 0) >= 1 for case in cases
    ),
}

product_ready = all(gates.values())
summary = {
    "scenario": "product_grade_matrix",
    "pass": product_ready,
    "product_ready": product_ready,
    "pass_count": pass_count,
    "fail_count": fail_count,
    "missing_required_scenarios": missing,
    "gates": gates,
    "cases": cases,
}
(out_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
if not product_ready:
    sys.exit(1)
PY
