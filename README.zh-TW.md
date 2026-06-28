# Claude Router Orchestrator

這個 repo 只處理一件事：
- `Claude Code + router -> child Claude Code + router` 的 parent-child orchestration

目的不是安裝 Claude，也不是安裝 router，而是把已經能工作的 `Claude + router` 包成一套較穩定的協作框架，降低以下問題：
- token overflow
- router 空回應 / 半回應
- worker 無限重試
- child process 失控
- child 宣稱成功但實際沒改檔

## 這個 repo 包含什麼

- main planner 與 child worker orchestration
- child 數量限制
- safe cleanup，只清掉 `child_*`，不殺主控
- overflow 後自動縮小 scope 重試
- `NEEDS_REPLAN` recovery
- timeout recovery
- false-success blocking
- repeated-failure / repeated-replan loop guard
- Docker fresh image smoke test
- 公司導向的 release 級測試矩陣

## 這個 repo 不處理什麼

- Claude Code 安裝
- Claude Code Router 安裝
- router model 切換
- 開源模型安裝流程
- host 專用 Ollama / router 設定

## 最短使用方式

假設目標 Linux 機器已經有：
- `bash`
- `python3`
- `jq`
- `claude`
- 可用的 Claude Code Router

一鍵安裝：

```bash
bash ./scripts/install_claude_router_orchestrator_bundle.sh /opt/claude_orchestrator
```

跑最小 edit flow：

```bash
cd /opt/claude_orchestrator
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the file minimal." \
  ./examples/hello-python
```

## 先看哪份文件

如果你要快速交付給公司內部同事，先看：
- `COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md`

如果你要看 bundle 安裝：
- `BUNDLE_INSTALL.zh-TW.md`

如果你要看風險與可 publish 範圍：
- `SAFE_PUBLISHING.md`

如果你要看高標準測試：
- `PRODUCT_GRADE_ADOPTION_CHECKLIST.zh-TW.md`
- `RLS_PRODUCTION_TEST_PLAN.zh-TW.md`

## 一鍵打包 zip

```bash
bash ./scripts/package_publish_bundle.sh
```

輸出檔案位置：
- `dist/claude-router-orchestrator-bundle-<timestamp>.zip`

## 測試建議順序

1. `bash ./scripts/smoke_bundle_in_fresh_image.sh`
2. `bash ./scripts/smoke_real_claude_router_integration.sh`
3. `bash ./scripts/evaluate_claude_product_grade_matrix.sh`
4. `bash ./scripts/evaluate_claude_rls_production_matrix.sh`
