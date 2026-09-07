# Plain Minimal Patch — exact diff reference

Captured Sep 3 2026 from `git -C ~/.hermes/hermes-agent diff --no-color` (248 lines, 4 files). Stored durably as `~/.local/share/dotfiles/private_dot_hermes_patches/plain-minimal.patch` (chezmoi `private_` → 0700 at `~/.hermes_patches/plain-minimal.patch`). Re-applied via `run_onchange_after_hermes-plain-patches.sh.tmpl` on `chezmoi apply` and optionally a `hooks.on_session_start` shell hook for pure `hermes update`.

## Files

- `hermes_cli/skin_engine.py` — `status-bar-session-title`
- `hermes_cli/banner.py` — lazy/error colors
- `agent/display.py` — `_maybe_emoji` + hanging indent + verb gap
- `cli.py` — submitted prompt highlight + divider removal

## skin_engine.py

```py
# after menu_meta_current_bg
pill_bg = skin.get_color("selection_bg", menu_current_bg)
# in return dict
"status-bar-session-title": f"bg:{pill_bg} {status_text} bold",
```

Plain renders `bg:#30363d #c9d1d9 bold` (gray pill) not `bg:#FFD700 #1a1a2e bold` (gold).

## banner.py

```py
lazy_color = _skin_color("ui_warn", "#ffa726")
error_color = _skin_color("ui_error", "#ef5350")
# then [yellow] -> [{lazy_color}], [red] -> [{error_color}] for tool + mcp paths
```

## agent/display.py

```py
_skin = _get_skin()
_is_plain = bool(_skin and _skin.name == "plain")
def _maybe_emoji(name, fallback):
    if _is_plain:
        ov = _skin.tool_emojis.get(name) if _skin and _skin.tool_emojis else None
        if ov is not None: return "" if ov.strip()=="" else ov
        return ""
    return get_tool_emoji(name, default=fallback)
# _wrap: strip emoji codepoints for plain, collapse gaps, then hanging indent:
# textwrap.fill(width=cols-len(prefix), subsequent_indent="  ", break_long_words=False)
```

Patched ~11 emoji lines: web_search, web_extract, terminal, process, read_file, write_file, patch, browser_navigate, grep/find, fallback ⚡.

## cli.py

```py
# _print_user_message_preview: replace
ChatConsole().print(f"[{_accent_hex()}]─"*40)
ChatConsole().print(f"[bold {_accent_hex()}]●[/] ...")
# with
[on {status_bar_bg} {status_bar_text}] {text} [/]  # highlight
# plus textwrap hanging indent for single-line prompts
# and delete the turn-start divider at :17125 (keep print(flush=True))
```

## plain.yaml 28-key template (gray minimal)

```yaml
name: plain
description: Minimal skin — no tool emojis, no kawaii spinner faces.
colors:
  banner_border: "#30363d"
  banner_title: "#e6edf3"
  banner_accent: "#adbac7"
  banner_dim: "#768390"
  banner_text: "#c9d1d9"
  ui_accent: "#adbac7"
  ui_label: "#768390"
  ui_ok: "#768390"
  ui_error: "#768390"
  ui_warn: "#768390"
  prompt: "#e6edf3"
  input_rule: "#30363d"
  response_border: "#30363d"
  session_label: "#768390"
  session_border: "#444c56"
  status_bar_bg: "#1e293b"
  status_bar_text: "#c9d1d9"
  status_bar_strong: "#e6edf3"
  status_bar_dim: "#768390"
  status_bar_good: "#768390"
  status_bar_warn: "#768390"
  status_bar_bad: "#768390"
  status_bar_critical: "#768390"
  completion_menu_bg: "#1e293b"
  completion_menu_current_bg: "#30363d"
  completion_menu_meta_bg: "#1e293b"
  completion_menu_meta_current_bg: "#30363d"
  selection_bg: "#30363d"
  voice_status_bg: "#1e293b"
  shell_dollar: "#768390"
spinner:
  waiting_faces: [""]
  thinking_faces: [""]
  thinking_verbs: [working]
  wings: [["",""]]
tool_emojis: {todo: " ", read_file: " ", ... every tool: " "}
banner_logo: " "
banner_hero: " "
```
