#!/bin/bash

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

OS=$(detect_os)

echo "Detected OS: $OS"

# gum (required for setup.sh)
if ! command -v gum &>/dev/null; then
  echo "Installing gum..."
  case $OS in
    mac) brew install gum ;;
    linux)
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
      echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
      sudo apt update && sudo apt install -y gum ;;
    *) echo "Please install gum manually: https://github.com/charmbracelet/gum" ;;
  esac
fi

# eza
echo "Installing eza..."
case $OS in
  mac) brew install eza ;;
  linux) sudo apt install -y eza 2>/dev/null || cargo install eza ;;
  *) echo "Please install eza manually: https://github.com/eza-community/eza" ;;
esac

# Google Workspace CLI
echo "Installing Google Workspace CLI..."
case $OS in
  mac) brew install googleworkspace-cli ;;
  linux) npm install -g @googleworkspace/cli ;;
  *) echo "Please install GWS CLI manually: https://github.com/googleworkspace/cli" ;;
esac

echo "Done."
