# RLS Production Test Plan

這份計畫的目的不是宣稱「本機小模型完全等價於公司大模型」，而是用更保守的代理條件，驗證 orchestration 架構在 release 前是否具備足夠韌性。

## 目標

- 模擬 reasoning-heavy model 先吐很長內容，導致 output pressure 或 overflow
- 模擬 router 連續回 partial / empty response
- 模擬單檔任務在極窄 scope 下仍 overflow，需要二次縮限重試
- 模擬複合型故障鏈，避免主控與子任務無限 loop

## 保守代理設定

- 載入 `profiles/kimi-k2-router-production.env`
- 使用更窄的 job 切分與更高 recovery 預算

## 核心腳本

- `scripts/evaluate_claude_kimi_k2_conservative_single_file.sh`
- `scripts/evaluate_claude_kimi_k2_router_recovery_storm.sh`
- `scripts/evaluate_claude_kimi_k2_rls_complex_release.sh`
- `scripts/evaluate_claude_rls_production_matrix.sh`
