---
name: dotfiles-sync
description: "Sync dotfiles and agent skills across machines and agents."
version: 0.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [dotfiles, chezmoi, agent-tools, sync, hooks]
    related_skills: [hermes-agent, tmux]
---

# Dotfiles Sync

Keep `leekhang/dotfiles` (chezmoi) and cross-agent skills/plugins (`agent-tools.json`) consistent across machines (ZimaBoard, Mac) and agents (Hermes, Claude) via `bootstrap/sync-agent-tools.sh` and Hermes `hooks:` in `~/.hermes/config.yaml`.

## When to Use

- Session starts and dotfiles are behind `origin/main` (`git status` shows `behind 1`, last fetch >24h)
- `chezmoi status` / `chezmoi diff` shows drift (local files differ from repo)
- Installing or detecting a new skill/plugin (`npx skills add`, `hermes skills tap add`, `claude plugin install`)
- User asks "have you synced dotfiles?", "are hooks wired?", or "should we update agent-tools.json?"
- Diagnosing why `on_session_start` or `post_tool_call` did not fire or was skipped

Don't use for: one-off file edits unrelated to dotfiles or agent tool manifests.

## Prerequisites

- `jq` installed (required by `sync-agent-tools.sh`)
- Dotfiles at `~/.local/share/dotfiles` symlinked to `~/.local/share/chezmoi` (`ln -s ~/.local/share/dotfiles ~/.local/share/chezmoi`)
- `~/.config/chezmoi/chezmoi.toml` exists with `[data]` templated keys (e.g. `skillsmp_api_key`)
- `agent-tools.json` is the single source of truth: top-level `.skills` (shared) + `.agents.<agent>.skills` (per-agent extras); `.install` may be string or `{claude, hermes}` object
- Hermes `~/.hermes/config.yaml` has `hooks:` block (see Quick Reference); `hooks_auto_accept: true` so `on_session_start` does not require manual approval each launch

## How to Run

All commands via `terminal` tool. Quote paths to handle spaces.

```bash
# Full session-start sync (what hooks SHOULD do — pull + apply + skill sync)
git -C ~/.local/share/dotfiles fetch --all && git -C ~/.local/share/dotfiles status --porcelain --branch
git -C ~/.local/share/dotfiles pull --ff-only
chezmoi status; chezmoi diff | head -n 200
chezmoi apply ~/.config/herdr/config.toml ~/.config/nvim ~/.tmux.conf  # or `chezmoi apply` for full
~/.local/share/dotfiles/bootstrap/sync-agent-tools.sh hermes session-start
~/.local/share/dotfiles/bootstrap/sync-agent-tools.sh hermes drift | jq .

# Drift check only (read-only, no installs)
~/.local/share/dotfiles/bootstrap/sync-agent-tools.sh hermes drift
~/.local/share/dotfiles/bootstrap/sync-agent-tools.sh claude drift

# Wire hooks idempotently (additive, never overwrites existing config.yaml keys)
~/.local/share/dotfiles/bootstrap/ensure-hermes-hooks.sh
hermes config get hooks  # or grep -A 10 "^hooks:" ~/.hermes/config.yaml
```

## Quick Reference

| Command | Purpose |
|---|---|
| `git -C ~/.local/share/dotfiles fetch --all` | Update `origin/main` without merging |
| `git -C ~/.local/share/dotfiles log HEAD..origin/main --oneline` | What remote adds |
| `git -C ~/.local/share/dotfiles pull --ff-only` | Fast-forward local `main` |
| `chezmoi status` | Files differing from repo |
| `chezmoi diff` | Unified diff of those files |
| `chezmoi apply` | Write repo state to home |
| `sync-agent-tools.sh hermes sync` | Install missing skills/plugins (dotfiles -> agent) |
| `sync-agent-tools.sh hermes drift` | List installed-but-untracked (agent -> dotfiles) |
| `sync-agent-tools.sh hermes session-start` | `sync` then `drift`; emits prompt if drift non-empty |
| `sync-agent-tools.sh hermes post-tool-use` | Reads PostToolUse payload on stdin; blocks with `ask to update agent-tools.json` if new install detected |
| `grep -n "hooks" ~/.hermes/config.yaml` | Verify hooks wired |
| `grep -a "shell hook" ~/.hermes/logs/agent.log | tail` | Verify hooks registered/ran |

## Procedure

### 1. Session-start full sync (expected every new session)

1. `git -C ~/.local/share/dotfiles fetch --all`; check `git status --porcelain --branch` for `behind` and `M`/`??` lines.
2. If behind: `git pull --ff-only` (if local `M` blocks it, `git stash` or `git diff` then pull).
3. `chezmoi status` and `chezmoi diff | head -n 200` to see pending applies.
4. `chezmoi apply` (or targeted `chezmoi apply <path>` to avoid templating unrelated files).
5. `sync-agent-tools.sh hermes session-start` — installs missing shared+per-agent skills, then prints drift if any local install is not in `agent-tools.json`.
6. If drift JSON non-empty: ask user "Add these to agent-tools.json in ~/.local/share/dotfiles/agent-tools.json?" — on yes, edit `agent-tools.json`, offer to commit.

Completion: `git status` shows `## main...origin/main` (not behind), `chezmoi status` empty, `drift` is `{"skill_taps":[],"local_skills":[],"plugins":[]}` or user explicitly deferred.

### 2. After a skill/plugin install (post_tool_call path)

1. `sync-agent-tools.sh` `post-tool-use` mode is wired as `post_tool_call` matcher `terminal` (timeout 10-15s). It inspects `tool_input.command` for patterns `npx skills add`, `claude plugin install`, `hermes skills tap add`, etc.
2. If matched, it re-runs `drift` for that agent and returns `{decision:"block", reason:"...ask to update agent-tools.json"}` so the agent surfaces the prompt.
3. Same ask as above — do NOT silently edit the manifest; user approves.

Completion: manifest updated or drift acknowledged; next `drift` call empty for that source.

### 3. Verify hooks are wired

1. `grep -A 12 "^hooks:" ~/.hermes/config.yaml` shows `on_session_start` and `post_tool_call` entries pointing to `sync-agent-tools.sh` with `timeout` and `fail_closed: false`.
2. `grep -a "shell hook registered" ~/.hermes/logs/agent.log | tail -n 5` shows both hooks registered at last startup.
3. If missing: run `ensure-hermes-hooks.sh` (idempotent; skips if `^hooks:` already present, else appends block and sets `hooks_auto_accept: true`).

## Pitfalls

- **Hooks do NOT git pull or chezmoi apply.** `on_session_start` only does `agent-tools.json -> installed skills` + drift check. Without a separate `git pull --ff-only` + `chezmoi apply`, the repo stays `behind origin/main` indefinitely. Add those steps to the session-start flow; patch `ensure-hermes-hooks.sh` and `config.yaml` if you want them automatic.
- **`post_tool_call` timeout is tight (10s).** Drift detection runs `npx skills list --json` / `hermes plugins list --json`, which can exceed 10s and cause `skipped after previous timeout or while still running` (seen 2026-09-02). Bump to 15-20s and keep `fail_closed: false` so a slow check never blocks the tool.
- **`hermes plugins list --json` lists the bundled catalog.** Filter with `select(.status!="not enabled")` or every bundled plugin looks like drift. `sync-agent-tools.sh` already does this — don't replace with unfiltered list.
- **`~/.hermes/hooks` is a directory, not a file.** `read_file` on it errors with "not a regular file" — list with `ls -la ~/.hermes/hooks/`; real hook config lives in `~/.hermes/config.yaml` under `hooks:`.
- **Local `M`/`??` blocks pull.** `agent-tools.json` and `bootstrap/sync-agent-tools.sh` often show `M` when hooks or manual edits touched them; `bin/` may show `??`. Stash/commit or resolve before `pull --ff-only`, or `git fetch` will succeed but `pull` will stall.
- **`ensure-hermes-hooks.sh` is additive-only and skips if `^hooks:` exists.** It will not inject a new `git pull` step into an existing hooks block — merge manually in `config.yaml`.
- **`write_file` follows symlinks.** `~/.local/share/chezmoi` is a symlink to `dotfiles`; writing via the symlink overwrites the source. Use `terminal` heredoc (`cat >`) when the target is a symlinked path (see Memory).

## Verification

- `git -C ~/.local/share/dotfiles status --porcelain --branch` shows no `behind`, no `M` unless intentional
- `chezmoi status` empty (or only expected `M`/`A` user is tracking)
- `sync-agent-tools.sh hermes drift` returns empty arrays; `sync-agent-tools.sh claude drift` likewise if Claude present
- `grep -a "shell hook registered" ~/.hermes/logs/agent.log` shows both hooks at last startup; no `skipped after previous timeout` in last 10 lines
- `agent-tools.json` validates: `jq empty agent-tools.json` and `jq -r '((.skills//[])+(.agents.hermes.skills//[]))[] | .source // .name // .names[0]' agent-tools.json | head`

## References

- `references/hooks-and-drift.md` — session 2026-09-03 diagnosis: stale 2-day fetch, missing pull/apply in hooks, post_tool_call timeouts, and the patched wiring.
