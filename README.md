# dotfiles

Personal dotfiles, agent skills, and configs for Claude Code, Hermes, and other tools.

## Quick Start

```sh
# Clone and apply all dotfiles
chezmoi init https://github.com/leekhang/dotfiles
chezmoi apply

# Install skills for all agents
./bootstrap/bootstrap-skills.sh
```

## Structure

```
dotfiles/
  bootstrap/
    bootstrap-skills.sh     # Install skills for all agents
  dot_claude/
    settings.json.tmpl      # Claude Code config (API key templated)
    statusline-command.sh   # Claude Code statusline script
  dot_zshrc                 # Zsh config
  private_dot_tmux.conf     # Tmux config with Catppuccin theme
```

## Skills

### Claude Code
| Source | Install Command |
|---|---|
| Google Workspace | `npx skills add https://github.com/googleworkspace/cli` |
| Matt Pocock | `npx skills@latest add mattpocock/skills` |

### Hermes
| Source | Install Command |
|---|---|
| Google Workspace | `hermes skills tap add googleworkspace/cli` |
| Matt Pocock | `hermes skills tap add mattpocock/skills` |

## Secrets

On a new machine, create `~/.config/chezmoi/chezmoi.toml` with:

```toml
[data]
    skillsmp_api_key = "your-api-key-here"
```

Get your SkillsMPC API key from the SkillsMPC dashboard.

## Plugins

Figma plugin must be installed manually inside Claude Code:
```
/plugin install figma@claude-plugins-official
```
