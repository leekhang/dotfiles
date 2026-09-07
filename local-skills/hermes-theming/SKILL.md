---
name: hermes-theming
description: "Use when theming Hermes display, skins, or banners."
version: 1.0.0
author: Hermes Agent + Teknium
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, skin, theming, display, banner, status-bar, cli, patch-durability, chezmoi]
    homepage: https://github.com/NousResearch/hermes-agent
---

# Hermes Theming — durable skins vs ephemeral display patches

One YAML file themes every surface (`~/.hermes/skins/*.yaml` via `hermes_cli/skin_engine.py`), but ~30% of what the user sees is **hard-coded literals** in `cli.py` / `agent/display.py` that skins cannot reach. This skill teaches which layer to touch and how to make code patches survive `git pull --ff-only origin main`.

## When to Use

- User says colors are leaking (mustard/gold `#FFD700/#CD7F32` after editing a skin via hermes-mod)
- User wants minimal/monochrome/plain skin, no kawaii spinner faces, no tool emojis
- Submitted prompts show `●` / `─*40` outlines and user wants a `status-bar` highlight instead
- Tool completion lines show `💻 📖 🔎 🐍 🌐` even though `plain.yaml tool_emojis: " "`
- Status bar right-side pill `─ Note: model was just…` is still gold
- Wrapped prompt / tool lines have no hanging indent (second line at col 0, hard to read)
- User asks to keep a display tweak across `hermes update` / `gateway restart`

## Two Layers (the durable vs ephemeral split)

```
Durable — outside git (survives pull)        Ephemeral — inside git clone (wiped on pull)
~/.hermes/skins/plain.yaml                     ~/.hermes/hermes-agent/
~/.hermes/config.yaml (display.skin)            cli.py
                                                agent/display.py
                                                hermes_cli/skin_engine.py
                                                hermes_cli/banner.py
                                                ^ also this VM's hermes-mod npx cache
```

```
 Skin path (what plain CAN control)          Hard-coded path (what plain CANNOT reach)
 ─────────────────────────                   ─────────────────────────────────────
 terminal tool → get_tool_emoji(             tool complete → display.py:_get_cute_tool_message
   "terminal")                               if tool=="terminal": return "┊ 💻 $ ..."
   plain tool_emojis:" " → " " invisible ✓    if tool=="read_file": return "┊ 📖 read ..."
   no override → registry emoji "💻" ✗        ... 24 branches with literal emoji — skins never consulted

 banner hero: banner.py:1017                  prompt outline: cli.py:8269 / 17125
  _hero = _bskin.banner_hero if … else         ChatConsole.print(f"[{_accent_hex()}]─"*40)
  HERMES_CADUCEUS  ← gold free-standing text    ChatConsole.print(f"[bold {_accent_hex()}]●[/]")
  plain "" is falsy → falls back gold ✗       plain has no key for this — literal string
  plain " " is truthy → blank ✓               patch to [on status_bar_bg status_bar_text] pill
```

## Quick Reference — labels to change

| Visible artifact | Key or code location | Fix |
|---|---|---|
| Status bar mustard `status_bar_strong/warn` | `colors.status_bar_*` 28 keys | Set all 28 in plain.yaml (hermes-mod only writes 15 `COLOR_KEYS`) |
| Session title pill `─ Note:` still gold | `skin_engine.py:get_prompt_toolkit_style_overrides` `status-bar-session-title` | Add `"status-bar-session-title": f"bg:{pill_bg} {status_text} bold"` where `pill_bg=selection_bg` |
| Caduceus / HERMES logo gold | `hermes_cli/banner.py` `HERMES_CADUCEUS` / `HERMES_AGENT_LOGO` (`#CD7F32/#FFBF00/#FFD700`) | `plain.yaml banner_hero: " "` + `banner_logo: " "` (single space truthy; `""` falsy → fallback) |
| Lazy tools `browser_back` yellow / `computer_use` yellow | `hermes_cli/banner.py:1094 [yellow]/[red]` hardcoded | Replace with `lazy_color=_skin_color("ui_warn")` / `error_color=_skin_color("ui_error")` |
| `●` + `─*40` above/below prompts | `cli.py:_print_user_message_preview` + `cli.py:17125` | Replace with `[on {status_bar_bg} {status_bar_text}] {text} [/]` highlight; delete the `─*40` divider; add `textwrap.fill(subsequent_indent="  ")` |
| `💻 📖 🔎` on quiet-mode completions | `agent/display.py:_get_cute_tool_message` 24 branches | Add `_is_plain` + `_maybe_emoji(name, fallback)` + `_wrap` regex strip `r'[\U0001F300-\U0001FAFF\u2600-\u27BF]+\s*'` for plain; use `get_tool_emoji` otherwise |
| No hanging indent on wrap | Both `display.py:_wrap` and `cli.py:_print_user_message_preview` | `textwrap.fill(width=cols-len(prefix), initial_indent="", subsequent_indent="  ", break_long_words=False)` where `cols=shutil.get_terminal_size().columns` queried at each print (like Claude Code's resize-aware `process.stdout.columns`) |
| Huge gap `💻 $         ` | `display.py` verb field `{verb:9}` 9-pad | For plain collapse to `' $ '` + collapse `\s{2,}` after emoji strip |

## Procedure

1. Write `~/.hermes/skins/plain.yaml` with **all 28 `colors`** (not just hermes-mod's 15). Use `references/plain-patch.md` for the full list. Set dark surfaces `status_bar_bg:#1e293b`, `completion_menu_bg:#1e293b`, `selection_bg:#30363d`; text `banner_title:#e6edf3`, `banner_text:#c9d1d9`, `banner_dim:#768390`, `status_bar_text:#c9d1d9` (or `#8ea3ff` if you keep blue). Set `spinner: waiting_faces:[""] thinking_faces:[""] wings:[["",""]]` and every `tool_emojis: " "` (including aliases `read`, `grep`, `write` if you use them). Set `banner_logo: " "` `banner_hero: " "`.
2. `hermes config set display.skin plain` (never hand-edit `config.yaml` indentation) and start a new `hermes` — gateway's watcher repaints live but banner prints only at startup.
3. For hard-coded literals (emojis, `●`/`─`, pill, wrap), patch the `.py` files listed above (see `references/plain-patch.md` for the exact diff). `python3 -m py_compile` each file; verify no mustard `bg:#FFD700` or `[yellow]` remains.
4. Make it durable (otherwise `git -C ~/.hermes/hermes-agent pull --ff-only origin main` on `gateway restart` wipes step 3):
   - `git -C ~/.hermes/hermes-agent diff --no-color > ~/.local/share/dotfiles/private_dot_hermes_patches/plain-minimal.patch` (`private_` → chezmoi 0700)
   - Add `run_onchange_after_hermes-plain-patches.sh.tmpl` that `include "private_dot_hermes_patches/plain-minimal.patch" | sha256sum` → `git apply` / `--3way` / no-op if already applied
   - Optionally add a Hermes `hooks.on_session_start` shell hook: `git -C ~/.hermes/hermes-agent apply --check ~/.hermes_patches/plain-minimal.patch && git apply … || true` so a pure `hermes update` without `chezmoi apply` also self-heals. `~/.hermes/config.yaml` has no `hooks:` block by default — append additively.
   - `chezmoi apply` on the host that runs the gateway (ZimaBoard); `hermes gateway restart` alone does not run chezmoi.

## Explaining This Class of Work

When the user says "I'm confused", "I don't get it", or "you're just spitting paragraphs", **stop using paragraph-only explanations**. The durable fix is diagrams:

- Layer diagram (durable vs ephemeral)
- Path diagram (which code path a skin can vs cannot reach)
- Before/after terminal mock with `subsequent_indent` arrows
- Timeline diagram (patch at T0 → `pull --ff-only` at T1 → wipe)

Embed one small ASCII diagram per section. Prefer a 10-line diagram over a 40-line paragraph. See `references/explaining-with-diagrams.md` for templates.

## Pitfalls

- **15 vs 28 colors**: hermes-mod `COLOR_KEYS` at `server.js:302` historically only persisted 15; `skin_engine.py:_BUILTIN_SKINS["default"]["colors"]` has 28. Missing keys `status_bar_*`, `completion_menu_*`, `selection_bg`, `voice_status_bg`, `shell_dollar` fall back via `colors.update()` → gold bleed. Patch the npx-cached `server.js` or write the yaml directly.
- **`filter(Boolean)` strips the plain hack**: hermes-mod `normalizeSkin` did `spinner.waiting_faces.map(String).filter(Boolean)` — strips `""` to `[]` → `display.py:1116 if faces:` fails → `KAWAII_WAITING`. Fixed upstream to preserve `""`.
- **`""` vs `" "`**: `""` is falsy for both `banner.py` fallback and `get_tool_emoji`'s `if override:` — use single space `" "` as the invisible-but-truthy override.
- **`on_session_start` is not `hermes update`**: `sync-agent-tools.sh hermes session-start` only syncs `~/.hermes/skills/.hub/taps.json` + `hermes plugins` — it never touches `~/.hermes/hermes-agent/*.py`. The wipe is `git pull`, not dotfiles sync. Don't blame the skills hook.
- **Chezmoi source = dotfiles**: `~/.local/share/chezmoi -> dotfiles` (symlink). `private_dot_*` files land as `~/.hermes_patches/` with 600. `run_onchange_*` only fires on `chezmoi apply`.
- **Gateway survives CLI exit**: `hermes` exit does not restart gateway (systemd `hermes-gateway`). Code patches in the gateway process need `hermes gateway restart` + re-apply; new CLI alone only verifies local banner.

## Verification

- `python3 -m py_compile ~/.hermes/hermes-agent/cli.py hermes_cli/skin_engine.py hermes_cli/banner.py agent/display.py`
- `python3 -c "from hermes_cli.skin_engine import set_active_skin; set_active_skin('plain'); from agent.display import get_cute_tool_message; print(repr(get_cute_tool_message('terminal',{'command':'ls'},0.1)))"` → `"┊ $  ls  0.1s"` (no emoji, single gap)
- Fresh `hermes` → banner caduceus blank, Available Tools all same gray/blue (no yellow `browser_back`), submitted prompt as `[on status_bar_bg]` pill with hanging indent on resize.

## References

- `references/plain-patch.md` — exact 4-file diff and `plain.yaml` 28-key template
- `references/explaining-with-diagrams.md` — diagram templates for the two-layer model
