---
name: pullimg
description: Fetch a screenshot or image the user just dropped into their terminal message from their Mac onto this VM. Use whenever a message contains a Mac-style absolute path (starts with /Users/...) to an image file (.png, .jpg, .jpeg, .gif, .heic, etc.) that does not exist on this VM's filesystem — that's the signature of a drag-and-drop from Ghostty, which types the local Mac path as plain text instead of transferring the file.
---

# pullimg — pull a dropped Mac image onto this VM

## Background

The user SSHs into this VM (zima-ubuntu, Tailscale IP `100.78.227.16`) from
their Mac (Tailscale IP `100.84.236.108`, user `khang`) using Ghostty, inside
tmux. Ghostty has no native "upload over SSH" drag feature (unlike iTerm2),
so dragging a file into the pane just types the file's **local Mac path** as
plain text into whatever has focus — the actual image bytes never cross the
SSH connection. The path typically looks like:

    /Users/khang/Desktop/Screenshot 2026-08-27 at 10.30.15 AM.png

That path doesn't exist on this VM — it exists on the Mac's disk.

## What to do

1. Recognize a dropped path in the user's message: an absolute path starting
   with `/Users/` (or otherwise clearly Mac-side), usually with an image
   extension, that does not exist on this VM. Don't confuse this with a
   normal VM-local path (e.g. under `/home/khang/...`) — read those directly
   instead, no pull needed.
2. Run: `~/bin/pullimg "<the exact path from the message>"`
   - This scp's the file from the Mac (`khang@100.84.236.108`, passwordless
     key auth already trusted both directions) into `~/inbox` on this VM.
   - It strips surrounding quotes Ghostty sometimes adds, and avoids
     clobbering same-named files (timestamps the new one on collision).
   - It prints the resulting local path on stdout.
3. Pass the printed local path to vision_analyze to actually view the image.

## Failure handling

If `pullimg` fails (e.g. "No such file or directory", connection refused):
tell the user directly what failed — don't retry silently. Likely causes:
the path has a typo, the file was moved/renamed since being dropped, or the
Mac's SSH (Remote Login) got disabled. Ask them to re-drop the file rather
than guessing at the path yourself.

## Setup this depends on (already done, informational only)

- VM's SSH public key is in the Mac's `~/.ssh/authorized_keys` (one-time,
  done by the user).
- Mac's SSH host key is trusted in this VM's `~/.ssh/known_hosts`.
- `~/bin/pullimg` on this VM does the actual fetch; `~/inbox` is the landing
  directory.

If passwordless SSH ever stops working (prompts for a password / hangs),
that setup has drifted — don't try to work around it with a password; tell
the user to re-check Remote Login and `authorized_keys` on the Mac.
