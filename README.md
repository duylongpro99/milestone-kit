# milestone-kit

Run a project as a sequence of roadmap milestones, each driven by a Claude Code **driver** session that spawns one **worker** session per role (plan, execute, finish, probe, audit) in a git worktree, hands it a brief, reads its handoff, and comes back to you only for decisions. Workers run on Claude Code or Codex. Every step is gated by a script that parses documents, never by the agent's own judgment.

This repository is the one clone a project needs: the kit itself, the two Herdr session skills the driver spawns workers through, and [obra/superpowers](https://github.com/obra/superpowers) as a submodule. Projects do not copy the skills; they symlink into this checkout, so an edit here reaches every project at once.

## Prerequisites

| Need | Why |
|---|---|
| this repo, cloned with `--recurse-submodules` (or `git submodule update --init`) | skills are symlinked from here; `skills/superpowers` must be present |
| [Herdr](https://github.com/herdrdev/herdr) running, `HERDR_ENV=1` | the driver spawns worker panes through `cc-session` or `cx-session` |
| `git`, `jq`, `gh` on PATH | the milestone scripts; `gh` opens the PR in the finish role |
| Claude Code | the driver session; the worker sessions by default |
| Codex CLI ≥ 0.145 with `features.hooks` and `features.skills` on | optional: the worker sessions when `install --agent codex` |

Herdr is a separate tool and is not vendored here.

```bash
git clone --recurse-submodules git@cris:duylongpro99/milestone-kit.git ~/personal/agent/milestone-kit
```

## Layout

```
milestone-kit/                       this repo
├── README.md                        this page
├── link-superpowers-skills.sh       links every superpowers skill into a project; called by install
├── milestone-kit/                   the kit (not a skill folder itself)
│   ├── README.md                    design, guarantees, roles, owner gates
│   ├── USAGE.md                     operator guide: bootstrap, drive, post-finish, Codex (§8)
│   ├── skills/{bootstrapping-milestones,adding-a-milestone,driving-a-milestone}/SKILL.md
│   ├── scripts/{bootstrap,milestone,hooks,sdd}/   copied into each project by install
│   └── templates/                   CLAUDE.md, AGENTS.md, settings, hooks.json, docs seeds
└── skills/                          one folder per skill
    ├── cc-session/                  start / stop a Claude Code session as a Herdr pane
    ├── cx-session/                  same for Codex
    └── superpowers/                 submodule: obra/superpowers (v6.3.0)
```

| Path | What | Linked into a project as |
|---|---|---|
| `milestone-kit/skills/bootstrapping-milestones/` | Prepares a repo from an idea or a PRD/architecture doc, stage by stage, until `scripts/bootstrap/check` prints `READY` | `.claude/skills/bootstrapping-milestones` |
| `milestone-kit/skills/adding-a-milestone/` | Turns a feature idea on a prepared repo into one roadmap milestone: triage, PRD and architecture deltas, one roadmap row, one STATUS row, verified by `check --milestone <M>` and `next --inputs <M>`. Never re-bootstraps, never starts the milestone | `.claude/skills/adding-a-milestone` |
| `milestone-kit/skills/driving-a-milestone/` | Drives one milestone: claims it, spawns a worker per role in the worktree, relays owner gates, logs the roadmap §8 row after merge | `.claude/skills/driving-a-milestone` |
| `milestone-kit/scripts/` | `bootstrap/{install,check}`, `milestone/{claim,spawn,brief,wait,status,exit-check,scope,next,log-decision,driver-state,lib.sh}`, `hooks/{guard-scope,require-handoff,guard-superpowers-paths}.sh`, `sdd/*` | copied to `scripts/` (hooks must exist in every clone and worktree) |
| `milestone-kit/templates/` | `CLAUDE.md`, `docs/*` seeds, `claude/settings*.json`, `codex/hooks.json`, `AGENTS.md`, `gitignore.block`, `milestone.config`; `{{TOKEN}}` placeholders are the content decisions the bootstrap fills | seeded once, never overwritten |
| `skills/cc-session/` | `create-session.sh [--p-name PANE] [--s-name NAME] [--split-r\|--split-d]`, `stop-session.sh`; `--s-name` is passed as `claude --name` | `.claude/skills/cris-managed-session` when `MS_AGENT=claude` (default) |
| `skills/cx-session/` | Same flags for `codex`; `--s-name` is applied through Codex's `/rename` after launch | `.claude/skills/cris-managed-session` when `install --agent codex` |
| `skills/superpowers/` | Agentic skill library: brainstorming, TDD, subagent-driven development, ... | `.claude/skills/obra-<name>` (and `.agents/skills/obra-<name>` for Codex) |

## Quick start

```bash
KIT=~/personal/agent/milestone-kit
$KIT/milestone-kit/scripts/bootstrap/install ~/code/my-app            # workers on Claude Code
$KIT/milestone-kit/scripts/bootstrap/install ~/code/my-app --agent codex   # workers on Codex
cd ~/code/my-app && scripts/bootstrap/check                          # NOT READY, with the list of what is missing
```

Then:

```text
in Claude Code:  "bootstrap this repo for milestones. Idea: <paragraph>"   until check prints READY
inside Herdr:    "run 0A"        driving-a-milestone claims, spawns plan -> execute -> finish, relays owner gates
after PR merge:  "merged"        logs the roadmap §8 row, prints READY: for the next milestones
new feature:     "add to the roadmap: <paragraph>"   adding-a-milestone: triage, PRD delta, one roadmap row, then "run <M>"
```

What `install <project> [--no-skills] [--no-templates] [--agent claude|codex]` does:

- Copies `scripts/{milestone,hooks,sdd,bootstrap}` into the project and refreshes them on every run; `check` prints `DRIFT:` when a copy differs from the kit.
- Links skills into `.claude/skills/`: `bootstrapping-milestones`, `adding-a-milestone`, `driving-a-milestone`, the session skill as `cris-managed-session`, and the superpowers skills as `obra-<name>` via `link-superpowers-skills.sh`.
- Seeds `.claude/settings.json` with the three hooks, appends the `.gitignore` block, seeds docs from `templates/`.
- With `--agent codex`: also seeds `.codex/hooks.json` and `AGENTS.md`, repeats the skill links under `.agents/skills/` (the only place Codex looks), links `cx-session` instead of `cc-session`, and records `MS_AGENT=codex` in `scripts/milestone/config`.
- Stamps `.milestone-kit` with the kit path and commit. Idempotent; never overwrites `scripts/milestone/config`, `.claude/settings.json`, `.claude/settings.local.json`, or an existing doc. Prints one line per action: `COPIED: KEPT: LINKED: SEEDED: MANUAL: CONFIG: STAMP:`.

You own `.claude/settings.local.json` (the permission allowlist for git, gh and the project's build and test tools); the agent never writes it. Full operator guide: [milestone-kit/USAGE.md](milestone-kit/USAGE.md). Design, roles, guarantees and owner gates: [milestone-kit/README.md](milestone-kit/README.md).

## Agent compatibility

| | Claude Code | Codex | OpenCode |
|---|---|---|---|
| Driver session | yes | no (always Claude Code) | no |
| Worker sessions | yes (default) | yes, `install --agent codex` | no |
| Skill discovery | `.claude/skills` | `.agents/skills` only | n/a |
| Hooks | `.claude/settings.json` | `.codex/hooks.json`, same three scripts and the same deny JSON | no command hooks, no `Stop` hook |

OpenCode is not supported: `require-handoff.sh` relies on a `Stop` hook to hold a worker until it has written its handoff, and OpenCode has no equivalent. Details on the Codex path: [milestone-kit/USAGE.md §8](milestone-kit/USAGE.md).

## Updating the kit

Edit under `milestone-kit/`, run its tests, then refresh each project:

```bash
milestone-kit/scripts/milestone/tests/guard-scope.sh
milestone-kit/scripts/milestone/tests/post-finish.sh
milestone-kit/scripts/bootstrap/install ~/code/my-app --no-templates
```

Skills are symlinks, so `SKILL.md` edits reach every project at once; scripts and hooks are copies and show as `DRIFT:` until refreshed. If the kit moves on disk, `check` prints a `NOTE: kit —` line for a stale `.milestone-kit` stamp; re-running `install` from the new location restamps it and refreshes the links.

The kit is developed in `duylongpro99/coding-agent-kit` (`general-cc-kit`) and synced here commit by commit; `skills/cc-session` and `skills/cx-session` are byte-identical copies from the same repo. Origin: extracted from `duylongpro99/gesture2browse` after its Phase 0.
