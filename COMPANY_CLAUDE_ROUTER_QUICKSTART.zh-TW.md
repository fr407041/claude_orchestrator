# 公司內部 Claude + Router 懶人包

這份文件給已經有 `Claude Code`、`Claude Code Router`、`bash`、`python3`、`jq` 的 Linux / Ubuntu 主機使用。

本 repo 不處理以下項目：
- Claude Code 安裝
- Claude Code Router 安裝
- router model 設定變更
- 開源模型安裝流程

## 你要拿這包做什麼

這包的目標只有一個：
- 讓 `main Claude + router` 把大任務拆成小任務
- 再把小任務派給 `child Claude + router`
- 用更嚴格的 worker 限制避免 token overflow、無限重試、router 空回應卡死

## 最短安裝流程

1. 把這個 repo 下載到 Linux 主機。
2. 執行一鍵安裝：

```bash
bash ./scripts/install_claude_router_orchestrator_bundle.sh /opt/claude_orchestrator
```

3. 進入目錄：

```bash
cd /opt/claude_orchestrator
```

4. 先跑最小 edit flow：

```bash
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the final file minimal." \
  ./examples/hello-python
```

Note: `tests/test_placeholder.py` is relative to the target repo root `./examples/hello-python`, not the top-level repository root.

## 建議驗證順序

1. `bash ./scripts/smoke_bundle_in_fresh_image.sh`
2. `bash ./scripts/smoke_real_claude_router_integration.sh`
3. `bash ./scripts/evaluate_claude_product_grade_matrix.sh`
4. `bash ./scripts/evaluate_claude_rls_production_matrix.sh`

## 你最常會調的參數

集中改這裡：
- `profiles/orchestrator-limits.env`
- `profiles/kimi-k2-router-production.env`

## 發佈給別人的懶人作法

```bash
bash ./scripts/package_publish_bundle.sh
```

輸出會放在：
- `dist/claude-router-orchestrator-bundle-<timestamp>.zip`

Note: `<timestamp>` is a generated runtime value, so this path is an output naming pattern rather than a checked-in repository file.
