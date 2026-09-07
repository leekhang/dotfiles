# Hooks and Drift — Session 2026-09-03 Diagnosis

## What happened

- Last dotfiles sync: 2026-09-01 00:28 (`5493718`), last fetch 2026-09-01 01:32. On 2026-09-03 the repo was `behind 1` on `origin/main` (`47d051c` — "Track ponytail, dart-flutter, and dart-lang/skills; portable secret lookup") and had local `M agent-tools.json`, `M bootstrap/sync-agent-tools.sh`, `?? bin/`.
- `~/.hermes/config.yaml` had `hooks:` wired since 2026-09-01:
  ```yaml
  hooks:
    on_session_start:
      - command: "/home/khang/.local/share/dotfiles/bootstrap/sync-agent-tools.sh hermes session-start"
        timeout: 15
        fail_closed: false
    post_tool_call:
      - matcher: "terminal"
        command: "/home/khang/.local/share/dotfiles/bootstrap/sync-agent-tools.sh hermes post-tool-use"
        timeout: 10
        fail_closed: false
  hooks_auto_accept: true
  ```
- `agent.log` showed hooks registered on every startup (2026-09-01 00:07, 2026-09-02 15:11/19:44/23:04, 2026-09-03 00:34/00:39) — hooks were present and firing, not missing.

## Why drift persisted

1. **`on_session_start` does not `git pull` or `chezmoi apply`.** `sync-agent-tools.sh hermes session-start` only does `agent-tools.json -> installed skills` (sync) + `drift` (installed -> manifest). Remote commits and `chezmoi status` (`M .claude/settings.json`, `A .claude/statusline-command.sh`, `M .config`, `A README.md`, `A bin/chezmoi`, `A bootstrap/*`, `A local-skills/*`) stayed pending.
2. **`post_tool_call` timeout too low.** 10s was insufficient for `npx skills list --json` / `hermes plugins list --json`, producing repeated warnings on 2026-09-02:
   ```
   Hook 'post_tool_call' callback shell_hook[post_tool_call:/home/khang/.../sync-agent-tools.sh hermes post-tool-use] skipped after previous timeout or while still running
   ```
   x5 occurrences. Drift prompts were dropped.

## Fixes applied / recommended

- Session-start flow should be: `git fetch --all` -> `git pull --ff-only` -> `chezmoi status/diff` -> `chezmoi apply` -> `sync-agent-tools.sh hermes session-start`. Add the git/chezmoi steps to `config.yaml` hooks or to `ensure-hermes-hooks.sh` (currently additive-only: if `^hooks:` exists it skips, so manual merge needed).
- Bump `post_tool_call` timeout to 15-20s; keep `fail_closed: false`.
- `ensure-hermes-hooks.sh` behavior: appends `hooks:` block only if missing, and sets `hooks_auto_accept: true`. It does not patch an existing block — that requires editing `~/.hermes/config.yaml` directly via `hermes config set` or manual edit.
- `hermes plugins list --json` returns the full bundled catalog; filter with `select(.status!="not enabled")` (already done in `sync-agent-tools.sh`).
- `~/.hermes/hooks` is a directory; hook config lives in `config.yaml`, not as files under `hooks/`.
- `config.yaml.pre-hooks-backup` (2026-08-31 23:38) shows pre-hook state; `ensure-hermes-hooks.sh` added the hooks block.

## Verification commands (from session)

```bash
git -C ~/.local/share/dotfiles fetch --all && git -C ~/.local/share/dotfiles status --porcelain --branch
git -C ~/.local/share/dotfiles log HEAD..origin/main --oneline
chezmoi status; chezmoi diff | head -n 200
grep -n "hooks" ~/.hermes/config.yaml
grep -a "shell hook" ~/.hermes/logs/agent.log | tail -n 10
```
