# Product-Grade Adoption Checklist

這份文件的目的是把 `router + open-source LLM` 的驗證目標，從 demo 提升到公司可採用等級。

## Gate

- 必須觀察到 overflow recovery
- 必須觀察到 router recovery
- 必須觀察到 repeated failure / repeated replan stop guard
- 必須觀察到 false-success blocking
- 必須有可重跑的 matrix 結果

## 建議先跑的腳本

```bash
bash ./scripts/evaluate_claude_product_grade_matrix.sh
```

## 這份 checklist 不保證什麼

- 不保證你公司真實 router 參數一定一致
- 不保證任何大模型都會有相同行為
- 不保證你公司 monorepo 在零調參下就一定通過

## 它保證什麼

- orchestration 有明確的 failure handling 路徑
- token overflow 不會只停在單次失敗
- router empty / partial response 有 recovery 路徑
- repeated failure 不會無限 loop
