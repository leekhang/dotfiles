# dotfiles

Personal dotfiles, agent skills, and configs for Claude Code, Hermes, and other tools.

## Quick Start

```sh
git clone https://github.com/leekhang/dotfiles
cd dotfiles
./bootstrap/setup.sh
```

`setup.sh` handles everything interactively — OS detection, chezmoi install, dotfile apply, and guided setup for each component.

## Structure

```
dotfiles/
  agent-tools.json          # Single source of truth: which skills/plugins each agent should have
  local-skills/              # Full copies of hand-authored skills with no external source
    clickable-brief/          # (agent-tools.json's install command copies these into place)
  bootstrap/
    setup.sh                # Main interactive setup (start here)
    aliases.sh              # Portable alias definitions
    sync-agent-tools.sh     # Reads agent-tools.json, installs what's missing per agent
    ensure-hermes-hooks.sh  # Wires the sync hooks into a local Hermes instance's config.yaml
    bootstrap-devtools.sh   # Install CLI tools (OS-aware) — gum, jq, eza, GWS CLI
  dot_claude/
    settings.json.tmpl      # Claude Code config (API key templated, sync hooks included)
    executable_statusline-command.sh.tmpl   # Claude Code statusline script
  dot_config/
    nvim/                   # Neovim config (lazy.nvim) — mason LSPs, herdr/tmux split nav
    herdr/
      config.toml           # Herdr theme + keybindings
  private_dot_tmux.conf     # Tmux config with Catppuccin theme
```

Neovim's `lua/plugins/herdr-splits.lua` and `lua/plugins/nvim-tmux-navigator.lua` are mutually exclusive via a `HERDR_ENV` check, so the same config works for either multiplexer without edits.

## Skills & plugins

`agent-tools.json` is the single source of truth for which skills, marketplaces, and plugins should be installed on which agent (currently `claude` and `hermes`; `pi` is a placeholder for a future agent). `bootstrap/sync-agent-tools.sh <agent> sync` reads it and installs anything missing — idempotent, safe to re-run, silent if nothing needs doing.

This is also wired into hooks, tracked in this repo so any agent on any machine can install them:
- **Claude Code**: a `SessionStart` hook re-syncs and reports anything installed that isn't in the manifest yet (drift), and a `PostToolUse` hook catches new installs as they happen and flags them for confirmation — both configured in `dot_claude/settings.json.tmpl`.
- **Hermes**: `bootstrap/ensure-hermes-hooks.sh` appends equivalent `on_session_start`/`post_tool_call` shell hooks to `~/.hermes/config.yaml` (run locally on whatever machine hosts the Hermes instance — it doesn't touch the rest of that file, which has its own live-tuned settings dotfiles doesn't manage).

In both cases the direction is: dotfiles → agent syncs automatically; agent → dotfiles (something new got installed) always asks before writing back to `agent-tools.json`.

`tutor@tutor-marketplace` and its marketplace are marked `"portable": false` in the manifest and intentionally skipped by `sync` on a fresh machine — that marketplace is a local directory path (`/Users/khang/repos/tutor`), not something a plain install can reproduce elsewhere.

Most manifest entries have an `install` command that pulls from a real external source (a repo, a tap, an installer) — never a local copy of those, so they can't go stale. The one exception is `local-skills/`: skills hand-authored directly through an agent session, with no external source at all. For those, the dotfiles copy *is* the source of truth, and `install` just copies it into place.

## Tools

### Figma
| Agent | How to connect |
|---|---|
| Claude Code | `/plugin install figma@claude-plugins-official` (run inside Claude Code) |
| Hermes | MCP server via `figma/mcp-server-guide` · skills via `sync-agent-tools.sh hermes sync` |

### Google Workspace
| Agent | How to connect |
|---|---|
| Claude Code | Skills via `sync-agent-tools.sh claude sync` |
| Hermes | Skills via `sync-agent-tools.sh hermes sync` |
| CLI | GWS CLI via `bootstrap-devtools.sh` |

## Secrets

On a new machine, create `~/.config/chezmoi/chezmoi.toml` with:

```toml
[data]
    skillsmp_api_key = "your-api-key-here"
    animationsdev_token = "your-animations.dev-license-token"
```

Get your SkillsMPC API key from the SkillsMPC dashboard, and your animations.dev token from your account there. Never put either directly in a tracked file — this repo is public, and `agent-tools.json` reads secrets like the animations.dev token at runtime via `chezmoi data`, never hardcoded.
