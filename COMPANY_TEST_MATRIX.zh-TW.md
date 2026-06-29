# Company Test Matrix

This document exists so the repository links remain complete on GitHub and so company users can quickly see which validation scripts matter most.

## Goal

Use these scripts to validate that `Claude Code + router -> child Claude Code + router` orchestration stays usable under real company failure modes such as token overflow, router instability, repeated replans, and false success.

## P0: Must Pass Before Company Rollout

- `scripts/evaluate_claude_deep_overflow_chain.sh`
- `scripts/evaluate_claude_false_success_guard.sh`
- `scripts/evaluate_claude_timeout_recovery.sh`
- `scripts/evaluate_claude_child_limits.sh`
- `scripts/evaluate_claude_parallel_isolation.sh`
- `scripts/evaluate_claude_router_instability.sh`
- `scripts/evaluate_claude_large_file_guard.sh`
- `scripts/evaluate_claude_same_failure_guard.sh`
- `scripts/evaluate_claude_reasoning_pressure.sh`
- `scripts/evaluate_claude_interface_regression.sh`

## P1: Strongly Recommended

- `scripts/evaluate_claude_mixed_failure_chain.sh`
- `scripts/evaluate_claude_variant_replan_loop.sh`
- `scripts/evaluate_claude_multi_round.sh`
- `scripts/evaluate_claude_fail_replan.sh`
- `scripts/evaluate_claude_needs_replan.sh`
- `scripts/evaluate_claude_replan_loop_guard.sh`
- `scripts/evaluate_claude_timeout_storm.sh`
- `scripts/evaluate_claude_large_complex_workflow.sh`

## P2: Product-Grade Full Matrix

- `scripts/evaluate_claude_product_grade_matrix.sh`
- `scripts/evaluate_claude_rls_production_matrix.sh`
- `scripts/evaluate_claude_kimi_k2_conservative_single_file.sh`
- `scripts/evaluate_claude_kimi_k2_router_recovery_storm.sh`
- `scripts/evaluate_claude_kimi_k2_rls_complex_release.sh`

## What To Check In Results

- `workers_overflowed`
- `overflow_retries`
- `workers_failed`
- `workers_timed_out`
- `workers_false_success_blocked`
- `replan_loop_guard_hit`
- `workers_with_verified_changes`
- `child_invocation_limit_hit`
- `run_id`

## Notes

- `tests/test_placeholder.py` style paths in examples are usually relative to the target example repo such as `./examples/hello-python`.
- Generated files such as `summary.json` and `dist/claude-router-orchestrator-bundle-<timestamp>.zip` are runtime outputs, not checked-in repository files.
- If the GitHub repository and the local working bundle diverge, prefer fixing the repository links or adding the missing file rather than leaving a dead reference in README files.
