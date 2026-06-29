# Reference Integrity Report

Scan date: `2026-06-30`

Scope:
- published GitHub-facing playbook documents
- Markdown reference integrity for `.md`, `.sh`, `.py`, `.env`, `.json`, `.toml`, `.yaml`, `.yml`, `.ps1`, `.cmd`

## Result Summary

- Confirmed broken or misleading references fixed: `6`
- Confirmed missing GitHub file restored: `1`
- References intentionally left unchanged because they are examples, runtime output names, or post-install absolute paths: `multiple`

## Fixed In This Pass

1. `COMPANY_TEST_MATRIX.zh-TW.md`
   - Restored as a repository file so README links are no longer broken on GitHub.

2. `KIMI_K2_ULTRA_SAFE_USAGE.zh-TW.md`
   - Replaced ambiguous `kimi-k2-router-ultra-safe.env`
   - New target: `profiles/kimi-k2-router-ultra-safe.env`

3. `README.zh-TW.md`
   - Clarified that `tests/test_placeholder.py` is relative to `./examples/hello-python`
   - Clarified that `dist/claude-router-orchestrator-bundle-<timestamp>.zip` is a generated output pattern

4. `BUNDLE_INSTALL.zh-TW.md`
   - Clarified that `tests/test_placeholder.py` is relative to `./examples/hello-python`
   - Clarified that `dist/claude-router-orchestrator-bundle-<timestamp>.zip` is a generated output pattern

5. `COMPANY_CLAUDE_ROUTER_QUICKSTART.zh-TW.md`
   - Clarified that `tests/test_placeholder.py` is relative to `./examples/hello-python`
   - Clarified that `dist/claude-router-orchestrator-bundle-<timestamp>.zip` is a generated output pattern

## Reviewed And Intentionally Not Counted As Broken

1. Prompt strings such as `Edit tests/test_placeholder.py ...`
   - These are task payload examples.
   - They are valid because the orchestrator command passes `./examples/hello-python` as the repo root.

2. Output artifact names such as `summary.json`
   - These refer to runtime-generated files, not checked-in repository files.

3. Installed-host absolute paths such as `/opt/codex-claude-server-playbook/...`
   - These are valid post-install paths in deployment docs.
   - They should not be interpreted as repository-root relative links on GitHub.

4. Example placeholder paths such as `/path/to/job.json` and `/tmp/job.raw.txt`
   - These are operator-supplied paths in command examples.

## Recommended Next Pass

1. Re-scan every published `.md` after major doc edits.
2. Prefer explicit `scripts/...`, `profiles/...`, and `examples/...` prefixes when the text is claiming a repository path.
3. When a path is only valid inside a target example repo, say that explicitly near the command block.
