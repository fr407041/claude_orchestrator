# Claude Router Orchestrator

This repository focuses on one scope only:
- `Claude Code + router -> child Claude Code + router` orchestration

It is intended to reduce rollout risk for company use by forcing narrower child jobs, limiting child creation, and recovering from common failure modes without killing the main orchestrator.

## Scope

Included:
- main Claude/router planning and child dispatch
- child count cap
- safe cleanup that only targets `child_*` processes
- overflow retry with smaller file scope
- `NEEDS_REPLAN` recovery
- timeout recovery
- false-success blocking
- repeated-replan loop guard
- Linux one-click bundle installer
- publishable zip bundle packaging
- fresh Ubuntu Docker image smoke test
- stricter release-style validation matrix

Excluded on purpose:
- Claude Code installation flow
- Claude Code Router installation flow
- router model setting changes
- open-source model selection flow

## Key docs

For company-facing onboarding and rollout:
- `README.zh-TW.md`
- `COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md`
- `BUNDLE_INSTALL.zh-TW.md`
- `PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md`
- `RLS_PRODUCTION_TEST_PLAN.zh-TW.md`
- `SAFE_PUBLISHING.md`

## Core scripts

- `scripts/orchestrate_claude_to_claude.sh`
- `scripts/run_claude_guarded.sh`
- `scripts/worker_claude_router.sh`
- `scripts/worker_claude_router_managed_single_file.sh`
- `scripts/install_claude_router_orchestrator_bundle.sh`
- `scripts/package_publish_bundle.sh`
- `scripts/smoke_bundle_in_fresh_image.sh`
- `scripts/smoke_real_claude_router_integration.sh`
- `scripts/evaluate_claude_product_grade_matrix.sh`
- `scripts/evaluate_claude_rls_production_matrix.sh`

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

## Package a publishable zip bundle

```bash
bash ./scripts/package_publish_bundle.sh
```

Output:
- `dist/claude-router-orchestrator-bundle-<timestamp>.zip`

## Validation order

1. `bash ./scripts/smoke_bundle_in_fresh_image.sh`
2. `bash ./scripts/smoke_real_claude_router_integration.sh`
3. `bash ./scripts/evaluate_claude_product_grade_matrix.sh`
4. `bash ./scripts/evaluate_claude_rls_production_matrix.sh`

## Positioning

This repository does not claim that every company router configuration will work unchanged.

What it does provide is:
- enforced narrow job planning
- bounded overflow recovery
- bounded router recovery
- loop-stop guards for repeated failures
- a Docker-runnable validation matrix that can be re-run before rollout
