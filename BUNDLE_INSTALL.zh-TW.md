# Claude Router Orchestrator 安裝說明

這份文件只說明如何把 orchestration bundle 安裝到目標 Linux 主機。

不處理：
- Claude Code 安裝
- Claude Code Router 安裝
- router model 設定
- 開源模型部署

## 前置條件

目標主機需要已經有：
- `bash`
- `python3`
- `jq`
- `claude`
- 已可工作的 Claude Code Router

## 一鍵安裝

```bash
bash ./scripts/install_claude_router_orchestrator_bundle.sh /opt/claude_orchestrator
```

安裝後會建立：
- `/opt/claude_orchestrator/scripts`
- `/opt/claude_orchestrator/profiles`
- `/opt/claude_orchestrator/examples`
- `/opt/claude_orchestrator/docker/claude-router-bundle-test`

## 最小驗證

```bash
cd /opt/claude_orchestrator
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the file minimal." \
  ./examples/hello-python
```

## Docker smoke test

如果你要先驗證 bundle 本身，而不是直接打真 router，先跑：

```bash
bash ./scripts/smoke_bundle_in_fresh_image.sh
```

這會在乾淨 Ubuntu image 裡驗證：
- install flow
- child 上限
- overflow recovery
- timeout recovery
- false-success guard
- replan loop guard

## 真實 router smoke test

如果目標機器上的 `claude` 與 router 已經可用，再跑：

```bash
bash ./scripts/smoke_real_claude_router_integration.sh
```

如果 `claude` 不在 `PATH`：

```bash
CLAUDE_BIN=/absolute/path/to/claude \
bash ./scripts/smoke_real_claude_router_integration.sh
```

## 公司建議驗證順序

1. `bash ./scripts/smoke_bundle_in_fresh_image.sh`
2. `bash ./scripts/smoke_real_claude_router_integration.sh`
3. `bash ./scripts/evaluate_claude_product_grade_matrix.sh`
4. `bash ./scripts/evaluate_claude_rls_production_matrix.sh`

## 交付給同事前建議

如果你要把這份 repo 打成 zip 再交給同事：

```bash
bash ./scripts/package_publish_bundle.sh
```

輸出位置：
- `dist/claude-router-orchestrator-bundle-<timestamp>.zip`
