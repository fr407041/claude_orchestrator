# Kimi K2 Ultra-Safe 用法

這份設定是給 `Kimi-K2.7-Code + Claude Code Router` 用的保守模式。

適用情境：
- 公司 repo 偏大
- 常出現 `maximum context length`
- 常看到 `you request 32000 output tokens`
- subagent 跑到後面 transcript 越積越大

## 目標

優先避免 context overflow，而不是追求一次處理很多檔案。

這份 profile 會強制：
- 每個 job 只碰 `1` 個檔案
- planner inventory 只看很小範圍
- worker 預設走 `managed_single_file`
- child 並行數降到 `1`
- 單檔首輪可讀行數降到 `1200`

## 啟用方式

在 Linux / Ubuntu shell：

```bash
cd /opt/claude_orchestrator
export ORCH_LIMITS_FILE="$(pwd)/profiles/kimi-k2-router-ultra-safe.env"
```

之後再執行：

```bash
bash ./scripts/orchestrate_claude_to_claude.sh \
  "你的任務描述" \
  /path/to/repo
```

## 建議一起做

除了套用這份 profile，router 端也建議一起收緊：

```json
"max_tokens": 2048
```

如果不能降到 `2048`，至少要先降到：

```json
"max_tokens": 4096
```

不建議再讓 `Kimi-K2.7-Code` 保留 `32000` output tokens，因為大 repo 很容易和輸入 token 相加後直接撞上 `131072` 上限。

## 推薦操作順序

1. 先套用 `kimi-k2-router-ultra-safe.env`
2. 再把 router 的 `max_tokens` 降到 `2048` 或 `4096`
3. 每跑完一批 repo，就重新開新 session
4. 不要讓 subagent 自由讀整個資料夾

## 如果還是 overflow

再往下收：

```bash
export ORCH_MAX_FILE_LINES=800
export ORCH_INVENTORY_LIMIT=4
export ORCH_MAX_JOBS=2
```

如果這樣還爆，通常就不是 orchestration 參數太鬆，而是：
- router 沒真的套用較小的 `max_tokens`
- 上游 client 還在硬送 `32000`
- 同一個 session 累積太多舊 transcript
