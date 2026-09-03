# Hermes Plain Minimal — Display Patch Context

This directory pins the display fixes for the `plain` skin that cannot be
expressed as skin YAML alone. `~/.hermes/hermes-agent` is a git clone on
`origin/main` (`63279301` at time of writing). Any `hermes update` /
`git pull --ff-only origin main` on `gateway restart` resets in-tree files.
Skin YAML (`~/.hermes/skins/plain.yaml`, `~/.hermes/config.yaml` `display.skin`)
survives because it lives outside git; code patches do not.

## What plain already covers (durable, no patch needed)

`~/.hermes/skins/plain.yaml` (30 `colors`, `spinner: [""]`, `tool_emojis: " "`):
- all text on `--` `--` gray: `banner_title #e6edf3`, `banner_text #c9d1d9`, `banner_dim #768390`, borders `#30363d`, status `bg #1e293b`
- `banner_hero: " "` / `banner_logo: " "` (single space is truthy, so `banner.py` skips hardcoded gold `HERMES_CADUCEUS` / `HERMES_AGENT_LOGO`)
- `spinner.waiting_faces/thinking_faces: [""]`, `wings: [["",""]]` so `KawaiiSpinner` does not fall back to kawaii

## What plain YAML cannot reach (needs patch — what this dir does)

Hard-coded literals in the clone:
- `agent/display.py:_get_cute_tool_message` — 24 branches like `┊ 💻 $`, `┊ 📖 read`, `┊ 🔎 grep`, `┊ 🐍 exec`, `┊ 🌐 navigate` with emoji inline, verb column `:9` padded, and no `get_tool_emoji()` lookup. `plain`'s `tool_emojis` never consulted.
- `cli.py:_print_user_message_preview` + `cli.py:17125` — `ChatConsole().print(f"[{_accent_hex()}]─"*40)` + `●` bullet above/below every submitted prompt.
- `cli.py` / `hermes_cli/banner.py` — `status-bar-session-title` (`─ Note: model was just swi…` pill) and tool-availability `[yellow]/[red]` used literal gold.

Worst UX symptom that was not a color/emoji leak: **no hanging indent**.
Long tool lines (` • cat ... + 2 commands`) and multi-line prompts wrapped
at `shutil.get_terminal_size().columns` started at col 0 on line 2, breaking
readability. Also verb gap ` $         ` (9-pad) left double space when emoji
stripped by plain. Desired: Claude Code style `textwrap.fill(subsequent_indent="  ")`
recalculated at each print (resize-safe; prompt_toolkit invalidates on SIGWINCH).

## Patch file

- `private_dot_hermes_patches/plain-minimal.patch` (248 lines, chezmoi `private_` so 0700) — `git diff` of the 4 files:
  - `hermes_cli/skin_engine.py` — `status-bar-session-title: bg:selection_bg #c9d1d9 bold` (+ status warn/bad/critical already gray in plain)
  - `hermes_cli/banner.py` — `lazy_color = _skin_color("ui_warn")`, `error_color = _skin_color("ui_error")`, replaces `[yellow]/[red]` with skin colors so plain gray leaks are gone
  - `agent/display.py` — `_maybe_emoji` (plain returns `""`) + `_wrap` emoji regex strip + 11 explicit emoji branches patched + hanging-indent `textwrap.fill(width=cols-4, subsequent_indent="  ")` + verb-gap collapse
  - `cli.py` — `_print_user_message_preview` now `[on status_bar_bg status_bar_text] line [/]` single-space highlight (no `─`, no `●`) with same `textwrap.fill` hanging indent; turn-start `─*40` at 17125 removed

Generate/refresh: `git -C ~/.hermes/hermes-agent diff --no-color > private_dot_hermes_patches/plain-minimal.patch`

## How it survives updates (two re-apply paths)

```
chezmoi-managed copy                    hermes runtime self-heal
private_dot_hermes_patches/ ──chezmoi apply──> ~/.hermes_patches/ ─┐
                                                                   │
run_onchange_after_hermes-plain-patches.sh.tmpl  hooks.on_session_start in ~/.hermes/config.yaml
  (hash of patch) ── apply if clean          bash -c 'for p in ~/.hermes_patches/... ~/.local/share/dotfiles/private_dot_hermes_patches/...; do git apply --check && git apply …; done'
  cp SRC to ~/.hermes_patches/                already-applied -> reverse --check short-circuit (no-op)
                                               not-yet-applied after `git pull --ff-only` -> re-applied at next `hermes` session start
```

`~/.hermes/config.yaml` is NOT chezmoi-managed (live-tuned `model:`, `terminal:` keys). The hook there was appended directly by `cat >> ~/.hermes/config.yaml` alongside the chezmoi-managed patch source. `chezmoi data`/`.chezmoi.toml` is separate.

## How to iterate

1. Edit files in `~/.hermes/hermes-agent/` directly (e.g. adjust `width=cols-6` vs `cols-4`, `subsequent_indent` amount, keep duration `0.3s` suffix handling).
2. `python3 -m py_compile agent/display.py cli.py hermes_cli/skin_engine.py hermes_cli/banner.py` — must be 0.
3. Start a new `hermes` to verify: submitted prompts = gray pill no outlines; ` • cat ...` has no blank gap and wraps with 2-space indent; status pill `─ Note:` on right of status bar is gray not `#FFD700`; banner `Available Tools:` lazy set is gray.
4. `git -C ~/.hermes/hermes-agent diff > private_dot_hermes_patches/plain-minimal.patch` and copy to `~/.hermes_patches/plain-minimal.patch` (both must match). Next agent should re-run `git diff --check` to detect needed rebase after upstream changes.
5. Do not delete `agent/display.py` — `cli.py` and `agent/tool_executor.py` import it; deletion breaks every `hermes` invocation and is undone by next `git pull` anyway.

## History

Sep 2–3 2026: iterated from blue-all (`#8ea3ff` flood) to white/gray minimal via `hermes-mod` + manual gray `#e6edf3/#768390/#30363d`. Fixed gold leaks: `banner_hero "" -> " "` falsy->truthy so `HERMES_CADUCEUS` not taken, `status-bar-session-title` gold pill, banner `[yellow]/[red]`. Then addressed emoji stripping (`plain` `tool_emojis:" "` plus `display.py` hard-coded literals) and prompt highlight conversion; previous code patches were lost at `63279301` pull at `2026-09-03 07:19:50` because they were uncommitted in the clone — this patch dir is the fix.
