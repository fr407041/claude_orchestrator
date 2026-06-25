# Claude Router Orchestrator 懶人包

這份懶人包只處理 `Claude Code + router -> child Claude Code + router` 的 orchestration 架構。

刻意不包含：
- Claude Code 安裝流程
- Claude Code Router 安裝流程
- 開源模型選擇流程
- router model 設定修改

## 前置假設

目標機器或目標 image 已經具備：
- `bash`
- `python3`
- `jq`
- `claude`
- `ccr` 或等價 router 啟動方式

如果只是先驗證 orchestration 邏輯，可直接使用內建 mock runner，不需要真實 Claude/router 服務。

## 一鍵安裝

```bash
bash ./scripts/install_claude_router_orchestrator_bundle.sh /opt/claude_orchestrator
```

安裝完成後，重點路徑如下：
- `/opt/claude_orchestrator/scripts`
- `/opt/claude_orchestrator/examples`
- `/opt/claude_orchestrator/docker/claude-router-bundle-test`

## 最小啟動

```bash
cd /opt/claude_orchestrator
bash ./scripts/orchestrate_claude_to_claude.sh \
  "Edit tests/test_placeholder.py so it contains a deterministic assertion assert 1 + 1 == 2 and keep the file minimal." \
  ./examples/hello-python
```

## 新 image smoke test

如果要在新的 Ubuntu Docker image 驗證整包可用：

```bash
cd /opt/codex-claude-server-playbook
bash ./scripts/smoke_bundle_in_fresh_image.sh
```

這個 smoke test 會：
1. 建立新的 Ubuntu image
2. 在 image 內安裝這份懶人包
3. 跑多輪與錯誤恢復測試
4. 確認 child cap、安全清理、timeout、overflow、replan loop guard 都能工作

## 建議公開內容

若要上傳到 GitHub，只公開：
- orchestration scripts
- mock 測試與 examples
- 本懶人包說明

不要公開：
- 個人 token
- 公司內部 router 設定
- 實際 model endpoint
