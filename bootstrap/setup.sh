#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP_DIR="$DOTFILES_DIR/bootstrap"

# ── OS Detection ───────────────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

OS=$(detect_os)

echo ""
echo "Welcome to leekhang/dotfiles setup!"
echo "──────────────────────────────────────"
echo "Detected OS: $OS"
read -p "Is this correct? [Y/n] " confirm_os
if [[ "$confirm_os" =~ ^[Nn]$ ]]; then
  echo "Select your OS:"
  select os_choice in "mac" "linux"; do
    OS=$os_choice; break
  done
fi

# ── Prerequisites ──────────────────────────────────────────────

# chezmoi
if ! command -v chezmoi &>/dev/null; then
  echo "chezmoi not found — installing..."
  case $OS in
    mac) brew install chezmoi ;;
    linux) sh -c "$(curl -fsLS get.chezmoi.io)" ;;
  esac
fi

echo "Applying dotfiles..."
chezmoi apply

# gum
if ! command -v gum &>/dev/null; then
  echo "Installing gum (required for setup UI)..."
  bash "$BOOTSTRAP_DIR/bootstrap-tools.sh"
fi

# ── Component Selection ────────────────────────────────────────

echo ""
COMPONENTS=$(gum choose --no-limit \
  --header "What would you like to set up? (space to select, enter to confirm)" \
  "Shell Environment" \
  "Agent Configs" \
  "Skills" \
  "Tools")

# ── Shell Environment ──────────────────────────────────────────

if echo "$COMPONENTS" | grep -q "Shell Environment"; then
  echo ""
  echo "── Shell Environment ──"

  # zsh
  if gum confirm "Install zsh?"; then
    case $OS in
      mac) brew install zsh ;;
      linux) sudo apt install -y zsh && chsh -s "$(which zsh)" ;;
    esac
  fi

  # oh-my-zsh
  if gum confirm "Install oh-my-zsh?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # Nerd Fonts
  check_nerd_font() {
    case $OS in
      mac) find ~/Library/Fonts /Library/Fonts -name "*NerdFont*" 2>/dev/null | grep -q . ;;
      linux) fc-list 2>/dev/null | grep -qi "nerd" ;;
    esac
  }

  if check_nerd_font; then
    echo "Nerd Font already installed — skipping."
  else
    if gum confirm "No Nerd Font detected. Install JetBrainsMono Nerd Font?"; then
      echo "Downloading JetBrainsMono Nerd Font..."
      curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/JetBrainsMono.zip
      case $OS in
        mac)
          unzip -o /tmp/JetBrainsMono.zip -d ~/Library/Fonts/ ;;
        linux)
          mkdir -p ~/.local/share/fonts
          unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/
          fc-cache -fv ;;
      esac
      rm /tmp/JetBrainsMono.zip
      echo "JetBrainsMono Nerd Font installed."
    fi
  fi

  # Aliases
  ALIASES=$(cat "$BOOTSTRAP_DIR/aliases.sh")
  if [ -f ~/.aliases ]; then
    if ! grep -q "dotfiles: portable aliases" ~/.aliases; then
      echo "" >> ~/.aliases
      echo "$ALIASES" >> ~/.aliases
      echo "Appended portable aliases to ~/.aliases"
    else
      echo "Aliases already present — skipping."
    fi
  else
    echo "$ALIASES" > ~/.aliases
    echo "Created ~/.aliases"
  fi

  if ! grep -q "source ~/.aliases" ~/.zshrc 2>/dev/null; then
    echo "\nsource ~/.aliases" >> ~/.zshrc
    echo "Added 'source ~/.aliases' to ~/.zshrc"
  fi

  # tmux
  if gum confirm "Set up tmux?"; then
    case $OS in
      mac) brew install tmux ;;
      linux) sudo apt install -y tmux ;;
    esac

    if [ ! -d ~/.tmux/plugins/tpm ]; then
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    if [ -f ~/.tmux.conf ]; then
      mv ~/.tmux.conf ~/.tmux.conf.bak
      echo "Backed up existing .tmux.conf to .tmux.conf.bak"
    fi

    chezmoi apply ~/.tmux.conf
    echo "Installed .tmux.conf — open tmux and press Ctrl+b I to install plugins."

    if gum confirm "Auto-start tmux on SSH login? (recommended for headless servers)"; then
      TMUX_BLOCK='
# dotfiles: tmux autostart
if [[ -z "$TMUX" ]]; then
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi'
      if ! grep -q "dotfiles: tmux autostart" ~/.zshrc 2>/dev/null; then
        echo "$TMUX_BLOCK" >> ~/.zshrc
        echo "Tmux autostart added to ~/.zshrc"
      fi
    fi
  fi
fi

# ── Agent Configs ──────────────────────────────────────────────

if echo "$COMPONENTS" | grep -q "Agent Configs"; then
  echo ""
  echo "── Agent Configs ──"

  if gum confirm "Set up Claude Code config?"; then
    chezmoi apply ~/.claude/settings.json
    chezmoi apply ~/.claude/statusline-command.sh
    echo "Claude Code config installed."
  fi
fi

# ── Skills ─────────────────────────────────────────────────────

if echo "$COMPONENTS" | grep -q "Skills"; then
  echo ""
  echo "── Skills ──"
  bash "$BOOTSTRAP_DIR/bootstrap-skills.sh"
fi

# ── Tools ──────────────────────────────────────────────────────

if echo "$COMPONENTS" | grep -q "Tools"; then
  echo ""
  echo "── Tools ──"
  bash "$BOOTSTRAP_DIR/bootstrap-tools.sh"
fi

echo ""
echo "Setup complete!"
