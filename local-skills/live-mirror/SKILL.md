---
name: live-mirror
description: Use when live-syncing a repo between local and remote.
---

# Live Mirror — Remote ↔ Local Live Dev Sync

Mirrors a repo between a local Mac (for iOS Simulator / hot reload) and a remote Linux server (where the agent works) via Mutagen over Tailscale SSH. Generic — not Zima-specific.

## When to use
- User says "sync this repo", "mirror to server", "live sync for hot reload", "work on server but run on Mac"
- Setting up a new repo for agent + local dev
- `mutagen sync list` shows Paused / No sessions

## Checks (run on local Mac first, then remote)

```bash
# Local Mac
tailscale status | grep -E "zima|remote"
ssh <alias> "echo ok && whoami"  # must be passwordless — if it asks, run ssh-copy-id
mutagen version  # 0.18.1+
brew list mutagen 2>&1 | head -1 || echo "install mutagen"
ls -ld ~/repos/<repo>  # local path

# Remote (via ssh <alias>)
mutagen version
tailscale status
ls -ld ~/repos/<repo>  # remote path
```

## Create the sync (run FROM local Mac — local is alpha)

Pick ignores by repo type:
- Flutter: --ignore=".dart_tool" --ignore="build" --ignore=".hermes"
- Node/Expo: --ignore="node_modules" --ignore=".expo" --ignore="build" --ignore=".hermes"
- Generic: --ignore-vcs always

```bash
mutagen sync create --name=<repo> --sync-mode=two-way-resolved \
  --ignore-vcs --ignore=".dart_tool" --ignore="build" --ignore=".hermes" \
  ~/repos/<repo> <alias>:/home/<user>/repos/<repo>

mutagen sync list          # → Watching for changes
mutagen sync monitor <repo>  # live events (Ctrl+C to exit monitor, sync keeps running)
```

## Verify (both directions)
```bash
# Remote → Local (while monitor is open)
echo "probe $(date -u +%FT%TZ)" > /home/<user>/repos/<repo>/.mutagen-probe && ls -lh ~/repos/<repo>/.mutagen-probe
# Local → Remote
rm ~/repos/<repo>/.mutagen-probe  # delete on one side, `ls` on the other should show gone in <2s
```

## Pause / resume / kill
```bash
mutagen sync list              # Watching? Paused?
mutagen sync pause <repo>      # pause — stops syncing, keeps session
mutagen sync resume <repo>     # resume
mutagen sync flush <repo>      # force push now
mutagen sync terminate <repo>  # kill session (need create again)
mutagen daemon stop; mutagen daemon start  # restart daemon
```

Leave it Watching when idle — low overhead (~10-30MB RAM, no CPU until save). Pause only for battery or big rebases.

## Troubleshooting
- `Permission denied` → wrong SSH user (check `whoami` on remote is `khang` not `leekhang`) or missing `ssh-copy-id`
- `Scan problems: N` → usually ignored `build/.dart_tool` perms — check `mutagen sync list -v`
- `No sessions found` on remote → normal when session was created from local — check `mutagen sync list` on local instead
- Fast `create` exit → normal — daemon stays backgrounded, use `list`/`monitor` to see it
