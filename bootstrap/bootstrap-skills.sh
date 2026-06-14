#!/bin/bash

# Claude Code skills
echo "Installing Claude Code skills..."
npx skills add https://github.com/googleworkspace/cli
npx skills@latest add mattpocock/skills

# Hermes skills
echo "Installing Hermes skills..."
hermes skills tap add googleworkspace/cli
hermes skills tap add mattpocock/skills
hermes skills tap add figma/mcp-server-guide
