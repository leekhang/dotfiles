#!/bin/bash
# Single source-of-truth reconciler for "what skills/plugins should be
# installed on which AI agent", driven by agent-tools.json.
#
# Usage: sync-agent-tools.sh <agent> <mode>
#   agent: claude | hermes | pi
#   mode:
#     sync           dotfiles -> agent. Installs anything the manifest wants
#                     that isn't present. Idempotent, silent on success.
#     drift          agent -> dotfiles (read-only). Prints JSON of anything
#                     installed locally that ISN'T in the manifest. Prints
#                     nothing if there's no drift.
#     session-start  sync, then drift. For SessionStart hooks. Emits
#                     Claude-Code hookSpecificOutput JSON (agent=claude) or
#                     plain text (agent=hermes), only if drift was found.
#     post-tool-use  Reads a Claude Code PostToolUse hook payload on stdin,
#                     checks tool_input.command against known install-command
#                     patterns for BOTH agents, and if matched, re-runs drift
#                     for whichever agent's command pattern matched and (if
#                     non-empty) emits {"decision":"block","reason":...} so
#                     Claude sees it as feedback on the already-run command.
#
# Runs on whatever machine it's invoked on -- no hostname/SSH baked in.
# `npx skills` tracks state relative to cwd, so Claude-side detection always
# runs from $HOME regardless of where this script itself was invoked from.
set -u
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_DIR/agent-tools.json"
AGENT="${1:-}"; MODE="${2:-}"
log() { echo "[sync-agent-tools] $*" >&2; }

command -v jq >/dev/null 2>&1 || { log "jq is required (brew install jq)"; exit 1; }
[ -f "$MANIFEST" ] || { log "manifest not found: $MANIFEST"; exit 1; }

case "$AGENT" in
  claude|hermes) ;;
  pi) log "agent 'pi' is a placeholder -- no install mechanism yet"; exit 0 ;;
  *) log "unknown agent '$AGENT' (want: claude|hermes|pi)"; exit 1 ;;
esac

# ---- detection ----
claude_installed_skill_sources()     { (cd "$HOME" && npx skills list --json 2>/dev/null) | jq -r '[.[]|select(.source!=null)|.source]|unique|.[]'; }
# Skills with no npx-tracked source -- installed by dropping a SKILL.md
# directly (e.g. agent-reach's own installer), not via `npx skills add`.
# Tracked in the manifest by .name instead of .source.
claude_installed_local_skill_names() { (cd "$HOME" && npx skills list --json 2>/dev/null) | jq -r '.[]|select(.source==null)|.name'; }
claude_installed_plugin_ids()        { claude plugin list --json 2>/dev/null | jq -r '.[].id'; }
claude_installed_marketplace_names() { claude plugin marketplace list --json 2>/dev/null | jq -r '.[].name'; }

hermes_installed_tap_sources()  { jq -r '.taps[]? | (.repo // .source // .)' "$HOME/.hermes/skills/.hub/taps.json" 2>/dev/null; }
# `hermes plugins list --json` returns the entire bundled catalog (dozens of
# plugins that ship disabled by default), not just what's actually active --
# filter to genuinely enabled ones or every bundled plugin shows as "drift".
hermes_installed_plugin_names() { hermes plugins list --json 2>/dev/null | jq -r '.[] | select(.status!="not enabled") | .name'; }

# ---- sync: install what the manifest wants but isn't present ----
sync_claude() {
  local have
  have="$(claude_installed_skill_sources)"
  while IFS=$'\t' read -r source cmd; do
    [ -z "$source" ] && continue
    grep -qxF "$source" <<<"$have" || { log "installing Claude skill source: $source"; (cd "$HOME" && eval "$cmd") || log "FAILED: $cmd"; }
  done < <(jq -r '.agents.claude.skills[] | select(.source!=null) | [.source,.install] | @tsv' "$MANIFEST")

  have="$(claude_installed_local_skill_names)"
  while IFS=$'\t' read -r name cmd; do
    [ -z "$name" ] && continue
    if ! grep -qxF "$name" <<<"$have"; then
      if [ -z "$cmd" ]; then
        log "local Claude skill '$name' missing and has no install command (hand-authored, no reproducible source) -- skipping, add it by hand if needed"
      else
        log "installing local Claude skill: $name"
        eval "$cmd" || log "FAILED: $cmd"
      fi
    fi
  done < <(jq -r '.agents.claude.skills[] | select(.name!=null) | [.name,(.install//"")] | @tsv' "$MANIFEST")

  # Bundle entries: one install command produces several named skills at once
  # (e.g. a course installer). Run the command once if ANY name is missing.
  have="$(claude_installed_local_skill_names)"
  while IFS=$'\t' read -r names cmd; do
    [ -z "$names" ] && continue
    missing=0
    IFS=',' read -ra name_arr <<<"$names"
    for n in "${name_arr[@]}"; do
      grep -qxF "$n" <<<"$have" || missing=1
    done
    if [ "$missing" = 1 ]; then
      log "installing Claude skill bundle: $names"
      eval "$cmd" || log "FAILED: $cmd"
    fi
  done < <(jq -r '.agents.claude.skills[] | select(.names!=null) | [(.names|join(",")),.install] | @tsv' "$MANIFEST")

  have="$(claude_installed_marketplace_names)"
  while IFS=$'\t' read -r name source repo path; do
    [ -z "$name" ] && continue
    grep -qxF "$name" <<<"$have" && continue
    local target=""
    [ "$source" = github ] && target="$repo"
    [ "$source" = directory ] && target="$path"
    [ -n "$target" ] && { log "adding Claude marketplace: $name"; claude plugin marketplace add "$target" || log "FAILED: marketplace add $name"; }
  done < <(jq -r '.agents.claude.marketplaces[] | select(.builtin!=true) | [.name,.source,(.repo//""),(.path//"")] | @tsv' "$MANIFEST")

  have="$(claude_installed_plugin_ids)"
  while IFS=$'\t' read -r id portable; do
    [ -z "$id" ] && continue
    grep -qxF "$id" <<<"$have" && continue
    if [ "$portable" = "false" ]; then
      log "skipping non-portable plugin $id -- install manually if prerequisites exist here"
      continue
    fi
    log "installing Claude plugin: $id"
    claude plugin install "$id" || log "FAILED: claude plugin install $id"
  done < <(jq -r '.agents.claude.plugins[] | [.id,((.portable//true)|tostring)] | @tsv' "$MANIFEST")
}

sync_hermes() {
  local have
  have="$(hermes_installed_tap_sources)"
  while IFS=$'\t' read -r source cmd; do
    [ -z "$source" ] && continue
    grep -qxF "$source" <<<"$have" || { log "installing Hermes tap: $source"; eval "$cmd" || log "FAILED: $cmd"; }
  done < <(jq -r '.agents.hermes.skills[] | [.source,.install] | @tsv' "$MANIFEST")

  have="$(hermes_installed_plugin_names)"
  while IFS=$'\t' read -r name cmd; do
    [ -z "$name" ] && continue
    grep -qxF "$name" <<<"$have" || { log "installing Hermes plugin: $name"; eval "$cmd" && hermes plugins enable "$name" 2>/dev/null; }
  done < <(jq -r '.agents.hermes.plugins[]? | [.name,.install] | @tsv' "$MANIFEST")
}

# ---- drift: what's installed that the manifest doesn't know about ----
drift_claude() {
  local es el ep
  es="$(comm -23 <(claude_installed_skill_sources|LC_ALL=C sort -u) <(jq -r '.agents.claude.skills[]|select(.source!=null)|.source' "$MANIFEST"|LC_ALL=C sort -u))"
  el="$(comm -23 <(claude_installed_local_skill_names|LC_ALL=C sort -u) <(jq -r '.agents.claude.skills[] | ((.name // empty), (.names[]? // empty))' "$MANIFEST"|LC_ALL=C sort -u))"
  ep="$(comm -23 <(claude_installed_plugin_ids|LC_ALL=C sort -u) <(jq -r '.agents.claude.plugins[].id' "$MANIFEST"|LC_ALL=C sort -u))"
  jq -n --arg s "$es" --arg l "$el" --arg p "$ep" \
    '{skill_sources:($s|split("\n")|map(select(length>0))), local_skills:($l|split("\n")|map(select(length>0))), plugins:($p|split("\n")|map(select(length>0)))}'
}
drift_hermes() {
  local et ep
  et="$(comm -23 <(hermes_installed_tap_sources|LC_ALL=C sort -u) <(jq -r '.agents.hermes.skills[].source' "$MANIFEST"|LC_ALL=C sort -u))"
  ep="$(comm -23 <(hermes_installed_plugin_names|LC_ALL=C sort -u) <(jq -r '.agents.hermes.plugins[]?.name' "$MANIFEST"|LC_ALL=C sort -u))"
  jq -n --arg t "$et" --arg p "$ep" '{skill_taps:($t|split("\n")|map(select(length>0))), plugins:($p|split("\n")|map(select(length>0)))}'
}

drift_empty() { jq -e '((.skill_sources//.skill_taps//[])+(.local_skills//[])+.plugins|length)==0' <<<"$1" >/dev/null; }

# ---- modes ----
case "$MODE" in
  sync)
    if [ "$AGENT" = claude ]; then sync_claude; else sync_hermes; fi
    exit 0
    ;;
  drift)
    if [ "$AGENT" = claude ]; then drift_claude; else drift_hermes; fi
    exit 0
    ;;
  session-start)
    if [ "$AGENT" = claude ]; then sync_claude; else sync_hermes; fi
    if [ "$AGENT" = claude ]; then result="$(drift_claude)"; else result="$(drift_hermes)"; fi
    if ! drift_empty "$result"; then
      msg="Dotfiles drift for $AGENT: installed locally but not in agent-tools.json: $(jq -c . <<<"$result"). Ask the user whether to add these to agent-tools.json in $REPO_DIR, and if yes, edit it and offer to commit."
      if [ "$AGENT" = claude ]; then
        jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
      else
        echo "$msg"
      fi
    fi
    exit 0
    ;;
  post-tool-use)
    payload="$(cat)"
    cmd="$(jq -r '.tool_input.command // empty' <<<"$payload" 2>/dev/null)"
    [ -z "$cmd" ] && exit 0
    target=""
    grep -Eq 'npx +skills(@[^ ]*)? +add |claude +plugin +(install|i) |claude +plugin +marketplace +add ' <<<"$cmd" && target=claude
    grep -Eq 'hermes +skills +(install|tap +add) |hermes +plugins +install ' <<<"$cmd" && target=hermes
    [ -z "$target" ] && exit 0
    if [ "$target" = claude ]; then result="$(drift_claude)"; else result="$(drift_hermes)"; fi
    if ! drift_empty "$result"; then
      jq -n --arg r "That command may have installed something not tracked in dotfiles ($target): $(jq -c . <<<"$result"). Ask the user if we should add it to agent-tools.json." \
        '{decision:"block", reason:$r}'
    fi
    exit 0
    ;;
  *) log "unknown mode '$MODE' (want: sync|drift|session-start|post-tool-use)"; exit 1 ;;
esac
