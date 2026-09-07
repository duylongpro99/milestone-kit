---
name: cx-session
description: Use when asked to start, stop, or close a Codex coding session under Herdr (e.g. "start a cx-session", "open a new codex session", "stop that cx-session", "close its pane"). Creates a Herdr pane running `codex`, by default in a new tab in the current workspace; can also stop the session and close its pane. Requires HERDR_ENV=1.
---

# cx-session

## Overview

Starts a new Codex session as a Herdr-managed pane in the current workspace, so it stays attached to and reachable from the active terminal. Run the bundled script instead of hand-rolling `herdr` calls — it encodes the exact `herdr` CLI shape this was verified against, which has drifted from the general `herdr` skill's own docs before.

Sibling skill `cc-session` does the same thing for Claude Code (`claude` instead of `codex`); the two share behavior and flags.

## When to Use

- Use when the user asks to start, open, or spin up a new Codex / "cx" session — optionally naming the pane, renaming the session itself, or choosing where it's placed (new tab vs. split in the active tab).
- Use when the user asks to stop, kill, or close a `cx-session` pane.

## Before running

Verify Herdr is active:

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, tell the user this isn't running inside Herdr and stop.

## Usage

```bash
scripts/create-session.sh [--p-name PANE_LABEL] [--s-name SESSION_NAME] [--split-r | --split-d]
```

Resolve the script path relative to this `SKILL.md`.

| Flag | Effect |
| --- | --- |
| *(none)* | Default: creates a new Herdr tab in the current workspace (`$HERDR_WORKSPACE_ID`) and starts `codex` in its pane, then focuses it. |
| `--split-r` | Splits the caller's current pane to the right in the active tab instead of creating a new tab, and starts `codex` there. |
| `--split-d` | Same as `--split-r`, but splits down. |
| `--p-name NAME` | Labels the new Herdr pane via `herdr pane rename` (a Herdr-level label, shown in sidebar/tab UI — separate from the agent's own session identity). |
| `--s-name NAME` | Once Codex reports idle, submits `/rename` then the name text as two separate inputs, since Codex's rename is a modal ("Type a name and press Enter"), not an inline `/rename NAME` argument. |

`--split-r` and `--split-d` are mutually exclusive; the script rejects both together.

`create-session.sh` prints the pane ID it started (e.g. `Started Codex in pane w8:p0 (tab w8:tE).`) — that pane ID is what `stop-session.sh` below takes.

### Stopping a session

```bash
scripts/stop-session.sh <pane_id>
```

Sends `/exit` into the pane so Codex quits on its own, then closes the pane regardless of whether that worked (`herdr pane close` also kills the process directly, so it's safe to run even if `/exit` didn't do anything, and a no-op if the pane is already gone).

## Notes

- The script waits (up to 30s) for the new pane to reach Herdr's `idle` agent status before applying `--p-name` / `--s-name`. A first-run Codex install with onboarding prompts (login, trust dialog) can delay this or intercept `--s-name`'s injected text — if that happens, resolve the prompt yourself, then send `/rename` and the name manually (see below).
- Codex has no CLI equivalent of Claude Code's `--name` startup flag, so `--s-name` can't be set at launch the way `cc-session` does it. It's applied post-launch via `/rename`, which in Codex opens a modal rather than accepting the name inline — the script sends `/rename`, waits briefly, then sends the name as a second input. This two-step flow hasn't been exercised against a live Herdr session; if `--s-name` silently doesn't apply, resolve it manually: send `/rename`, wait for the "Type a name and press Enter" prompt, then send the name.
- The create script prints the resulting pane and tab IDs on success. Use `herdr agent get <pane_id>`, `herdr pane read <pane_id> --source recent-unwrapped`, or the general `herdr` skill for anything beyond starting/naming/stopping the session.
- `stop-session.sh` closes whatever pane you point it at — it doesn't verify the pane is actually running Codex. Don't point it at a pane you didn't start with this skill unless the user clearly means that pane.
- Do not use this skill outside Herdr, and do not reimplement its steps by hand when the script covers them — the installed `herdr` binary's actual CLI surface has previously diverged from its own bundled documentation, and the script was written against and verified against the real installed behavior.
