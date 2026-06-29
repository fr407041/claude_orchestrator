# Claude Router Orchestrator

This repository focuses only on the `Claude Code + router -> child Claude Code + router` orchestration pattern.

It is designed to reduce token overflow risk by forcing narrow child jobs, limiting child creation, and recovering from bad worker behavior without killing the main orchestrator.

Related design docs:
- `CLAUDE_ROUTER_PURE_MODE_SPEC.zh-TW.md`
- `COMPANY_TEST_MATRIX.zh-TW.md`
- `TEST_RESULTS_2026-06-27.zh-TW.md`
- `TEST_RESULTS_2026-06-27_STRESS.zh-TW.md`

Central limits file:
- `profiles/orchestrator-limits.env`
- `profiles/preset-conservative.env`
- `profiles/preset-fast.env`
- `profiles/preset-large-project-safe.env`
- `profiles/kimi-k2-router-production.env`
- `profiles/kimi-k2-router-ultra-safe.env`

## Scope

Included:
- main Claude/router planning and child dispatch
- child count cap
- safe cleanup that only targets `child_*` processes
- overflow retry with smaller file scope
- optional remote Raspberry Pi worker dispatch over SSH
- `NEEDS_REPLAN` recovery
- timeout recovery
- false-success blocking
- repeated-replan loop guard
- Linux one-click bundle installer
- fresh Ubuntu Docker image smoke test

Excluded on purpose:
- Claude Code installation flow
- Claude Code Router installation flow
- router model setting changes
- open-source model selection flow

## Core scripts

- `scripts/orchestrate_claude_to_claude.sh`
- `scripts/run_claude_guarded.sh`
- `scripts/worker_claude_router.sh`
- `scripts/worker_claude_router_managed_single_file.sh`
- `scripts/claude_router_common.sh`
- `scripts/cleanup_claude_children.sh`

## Failure handling

- Overflow on multi-file child jobs:
  split into smaller retry jobs
- Too many child processes:
  block new child creation with `CLAUDE_MAX_CHILDREN`
- Broken child cleanup:
  cleanup only targets `child_*` registry entries and skips the main process
- Child timeout:
  watchdog terminates the child and lets the main orchestrator rewrite or stop safely
- Child says `SUCCESS` but changed nothing:
  worker downgrades the result to `FAILED`
- Child keeps asking for replan:
  main triggers `replan_loop_guard_hit` instead of infinite redispatch
- Planner returns bad JSON:
  main falls back to deterministic small-batch planning

## Linux bundle install

Assumption:
- target machine already has `bash`, `python3`, `jq`, `claude`, and router startup support

Install:

```bash
bash ./scripts/install_claude_router_orchestrator_bundle.sh /opt/claude_orchestrator
```

Run a minimal edit flow:

```bash
cd /opt/claude_orchestrator
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the file minimal." \
  ./examples/hello-python
```

Package a publishable zip bundle:

```bash
bash ./scripts/package_publish_bundle.sh
```

Key Chinese docs for company rollout:
- `README.zh-TW.md`
- `COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md`
- `BUNDLE_INSTALL.zh-TW.md`
- `KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md`
- `PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md`
- `RLS_PRODUCTION_TEST_PLAN.zh-TW.md`

## Kimi K2 Ultra-Safe Mode

For `Kimi-K2.7-Code + Claude Code Router` environments that regularly hit context-window errors, use:

```bash
export ORCH_LIMITS_FILE="$(pwd)/profiles/kimi-k2-router-ultra-safe.env"
```

This forces single-file jobs, a smaller inventory, and narrower guarded reads. Pair it with a router-side `max_tokens` cap of `2048` or `4096`, not `32000`.

## Fresh-image smoke test

Build and validate the bundle in a fresh Ubuntu image:

```bash
bash ./scripts/smoke_bundle_in_fresh_image.sh
```

Run this from a Linux shell environment.
If you invoke this script directly from Windows PowerShell without a working local `bash` runtime, the host shell can fail before the Docker-based smoke test even starts.

The smoke test installs the bundle into a clean image and runs:
- single-file managed edit
- multi-round overflow recovery
- child limit protection
- fail-replan recovery
- timeout recovery
- bad planner fallback
- needs-replan recovery
- false-success blocking
- repeated-replan loop guard
- deep overflow chain
- mixed failure chain
- variant replan loop
- parallel isolation
- large complex multi-file workflow with mixed failure injection

## Real integration smoke test

Use this only on a Linux machine that already has a working `claude` CLI and an already-running Claude Code Router.

This test does not install Claude, does not install router, and does not rewrite router model settings.

```bash
bash ./scripts/smoke_real_claude_router_integration.sh
```

If your `claude` binary is not on `PATH`, point the script at your existing install without changing global settings:

```bash
CLAUDE_BIN=/absolute/path/to/claude bash ./scripts/smoke_real_claude_router_integration.sh
```

For a broader real task against the sample multi-file repo:

```bash
CLAUDE_BIN=/absolute/path/to/claude bash ./scripts/smoke_real_claude_router_large_task.sh
```

This script is also intended to be launched from Linux, or from inside a Linux container or VM that already has `bash`.

Optional:
- pass a custom project root as the first argument
- pass a custom task as the second argument
- set `CCR_HEALTH_URL` if your router health endpoint is not `http://127.0.0.1:3456/health`
- set `ALLOW_AUTOSTART=1` together with `START_CCR_BIN=/your/existing/router-start-command` if you explicitly want the script to start your already-configured router command

## Docker master + Raspberry Pi worker

This repository now also includes a `Docker master -> Raspberry Pi worker` path.

Use this when:
- the Ubuntu Docker container should be the main orchestrator
- the Raspberry Pi should run `claude` + `ccr`
- the Raspberry Pi should call a Windows-hosted Ollama-compatible API instead of running a local model

Required env vars:

```bash
export RPI_HOST=192.168.100.162
export RPI_USER=pi
export RPI_PASSWORD='your-password'
export WINDOWS_LLM_BASE_URL=http://host.docker.internal:11434
export WINDOWS_LLM_LAN_BASE_URL=http://<windows-lan-ip>:11434
export WINDOWS_LLM_MODEL=qwen3:4b
```

Preflight and install flow:

```bash
bash ./scripts/preflight_docker_host.sh
bash ./scripts/preflight_windows_host_llm.sh
bash ./scripts/preflight_rpi_ssh.sh
bash ./scripts/install_rpi_claude_router_via_ssh.sh
bash ./scripts/smoke_rpi_router_to_windows_llm.sh
```

To force the existing orchestrator to use the Raspberry Pi worker path:

```bash
export CLAUDE_REMOTE_DISPATCH=1
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the file minimal." \
  ./examples/hello-python
```

See also:
- `docs/RPI_DEPLOYMENT.zh-TW.md`

## Mock validation scripts

- `scripts/evaluate_claude_single_file.sh`
- `scripts/evaluate_claude_multi_round.sh`
- `scripts/evaluate_claude_child_limits.sh`
- `scripts/evaluate_claude_fail_replan.sh`
- `scripts/evaluate_claude_timeout_recovery.sh`
- `scripts/evaluate_claude_bad_planner.sh`
- `scripts/evaluate_claude_needs_replan.sh`
- `scripts/evaluate_claude_false_success_guard.sh`
- `scripts/evaluate_claude_large_file_guard.sh`
- `scripts/evaluate_claude_replan_loop_guard.sh`
- `scripts/evaluate_claude_reasoning_pressure.sh`
- `scripts/evaluate_claude_interface_regression.sh`
- `scripts/evaluate_claude_router_empty_response.sh`
- `scripts/evaluate_claude_router_flapping.sh`
- `scripts/evaluate_claude_router_instability.sh`
- `scripts/evaluate_claude_same_failure_guard.sh`
- `scripts/evaluate_claude_timeout_storm.sh`
- `scripts/evaluate_claude_large_complex_workflow.sh`
- `scripts/evaluate_claude_product_grade_matrix.sh`
- `scripts/evaluate_claude_kimi_k2_conservative_single_file.sh`
- `scripts/evaluate_claude_kimi_k2_router_recovery_storm.sh`
- `scripts/evaluate_claude_kimi_k2_rls_complex_release.sh`
- `scripts/evaluate_claude_rls_production_matrix.sh`

## Product-grade matrix

Run the highest-signal company adoption matrix for `router + open-source LLM` behavior:

```bash
bash ./scripts/evaluate_claude_product_grade_matrix.sh
```

This matrix is intended to catch the failure modes that usually break real company rollout:
- long reasoning before useful output
- router empty or partial responses
- overflow split-and-retry behavior
- false success with no verified change
- repeated failure and replan stopping
- mixed large-task recovery

## RLS production matrix

Run the stricter release-style matrix that uses a conservative Kimi-K2 proxy profile:

```bash
bash ./scripts/evaluate_claude_rls_production_matrix.sh
```

This adds:
- single-file overflow under conservative context budgeting
- repeated router recovery across partial and empty responses
- complex mixed-failure release flow under narrower job limits

See also:
- `RLS_PRODUCTION_TEST_PLAN.zh-TW.md`

## Verified on 2026-06-25

Fresh Ubuntu Docker image validation completed for the Linux bundle with:
- successful bundle install into a new path
- multi-round mock orchestration execution
- bounded child creation
- safe child cleanup without killing main
- recovery from overflow, timeout, failure, false success, and repeated replan cases

## Verified on 2026-06-27

Additional Docker reruns validated the complex scenarios after tightening the mock and run-id behavior:
- deep overflow chain now records `workers_overflowed=2`, `overflow_retries=1`, `workers_failed=0`
- mixed failure chain stays bounded with timeout, false-success, and replan pressure in one run
- variant replan loop stops with `replan_loop_guard_hit=1`
- parallel isolation now produces distinct `run_id` values for concurrent launches

See also:
- `TEST_RESULTS_2026-06-27.zh-TW.md`
