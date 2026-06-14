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

# Google Workspace CLI
echo "Installing Google Workspace CLI..."
case $OS in
  mac) brew install googleworkspace-cli ;;
  linux) npm install -g @googleworkspace/cli ;;
  *) echo "Unsupported OS: install GWS CLI manually from https://github.com/googleworkspace/cli" ;;
esac

echo "Done."
