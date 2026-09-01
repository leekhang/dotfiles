#!/bin/bash
# Idempotent, additive-only patch to ~/.hermes/config.yaml: wires up the
# same skills/plugins sync hooks as Claude Code gets. Operates on LOCAL
# ~/.hermes wherever it's run -- no hostname/SSH baked in, so running this
# on any machine that hosts a Hermes instance (this Mac, the ZimaBoard, a
# future one) wires up the same hooks. That's the whole point: another
# agent, on another machine, can be asked to install these hooks.
#
# Not a chezmoi-templated full-file replacement -- config.yaml has ~30
# live-tuned keys (model routing, compression thresholds, terminal
# settings, etc.) dotfiles has no business overwriting wholesale.
set -u
CONFIG="$HOME/.hermes/config.yaml"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/sync-agent-tools.sh"

[ -f "$CONFIG" ] || { echo "ensure-hermes-hooks: $CONFIG not found -- run Hermes setup first"; exit 1; }

if grep -q '^hooks:' "$CONFIG"; then
  echo "ensure-hermes-hooks: 'hooks:' key already present in $CONFIG -- skipping (merge manually if it's missing our entries)."
else
  cat >> "$CONFIG" <<YAML

# added by leekhang/dotfiles: bootstrap/ensure-hermes-hooks.sh
hooks:
  on_session_start:
    - command: "$SCRIPT_PATH hermes session-start"
      timeout: 15
      fail_closed: false
  post_tool_call:
    - matcher: "terminal"
      command: "$SCRIPT_PATH hermes post-tool-use"
      timeout: 10
      fail_closed: false
YAML
  echo "ensure-hermes-hooks: added hooks: block to $CONFIG"
fi

# hooks_auto_accept: run hooks without a manual approval prompt each time --
# a SessionStart hook fires every session, so leaving this off means
# approving it by hand every time Hermes starts.
if grep -q '^hooks_auto_accept:' "$CONFIG"; then
  sed -i.bak 's/^hooks_auto_accept:.*/hooks_auto_accept: true/' "$CONFIG" && rm -f "$CONFIG.bak"
  echo "ensure-hermes-hooks: set hooks_auto_accept: true"
else
  echo "hooks_auto_accept: true" >> "$CONFIG"
  echo "ensure-hermes-hooks: added hooks_auto_accept: true"
fi
