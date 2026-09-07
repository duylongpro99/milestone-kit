# milestone-kit — usage

Two skills, one loop: **bootstrapping-milestones** prepares a repo; **driving-a-milestone** runs one milestone in it. Both are gated by scripts, never by the agent's own judgment. This page is the operator's guide; the skills' `SKILL.md` files are what the agent follows.

## 0. Requirements

| Need | Why |
|---|---|
| `git`, `jq`, `gh` on PATH | scripts; `gh` opens the PR in the finish role |
| [Herdr](https://github.com/herdrdev/herdr) with `HERDR_ENV=1` | the driver spawns worker panes through the kit's `cc-session` skill (linked into the project as `.claude/skills/cris-managed-session`) |
| this repo checked out (`milestone-kit`) with the `skills/superpowers` submodule initialised (`git submodule update --init`) | skills are symlinked from here |
| Claude Code | the driver session; the worker sessions by default |
| Codex ≥ 0.145 with `features.hooks` and `features.skills` on | optional: the worker sessions when `MS_AGENT=codex` (§8) |

## 1. New project from an idea or a PRD

```bash
mkdir my-app && cd my-app && git init -b main
# optional: drop your docs in first
mkdir -p docs && cp ~/prd.md docs/01-prd.md && cp ~/architecture.md docs/02-architecture.md

~/personal/agent/milestone-kit/milestone-kit/scripts/bootstrap/install .
scripts/bootstrap/check            # NOT READY, with the list of what is missing
```

Then open Claude Code in the repo and say:

> bootstrap this repo for milestones. Idea: <one paragraph>   (or: from docs/01-prd.md and docs/02-architecture.md)

The agent works stage by stage and stops at each gate:

| Stage | You approve |
|---|---|
| 0 intent | goal, component list, interface names in `docs/01-prd.md`, `docs/02-architecture.md` |
| 1 boundaries | `.claude/rules/<component>.md` (one per component) and the filled `CLAUDE.md` |
| 2 roadmap | milestone list, `0A` / `1A` exit criteria, pending §8 rows in `docs/05-roadmap.md` |
| 3 process docs | nothing (templates) |
| 4 tooling | you create `.claude/settings.local.json` from `.claude/settings.local.json.example` (your permission allowlist; the agent never writes it) |
| 5 ready | `check` prints `READY`; you say "commit" |

When `check` ends with `summary: … | READY` and `NEXT: READY: 0A`, the repo is prepared.

## 2. Existing project that already has docs and code

Same as above. `install` never overwrites an existing file: your `CLAUDE.md`, `docs/`, `.claude/settings.json` stay; `check` tells you which sections or rows are missing (`MALFORMED:` lines name the heading or cell). If `.claude/settings.json` already exists, `install` prints a `MANUAL:` line for each hook you have to merge from `templates/claude/settings.json`.

## 3. Feature idea on a prepared project

Once `check` says `READY`, a new feature does not go through bootstrap again. Open Claude Code on the base branch and say:

> add to the roadmap: <one paragraph about the feature>

The agent (`adding-a-milestone`) first asks which of three things it is:

| Outcome | You do |
|---|---|
| a **milestone** (crosses a component, adds or changes a shared interface, needs its own plan and exit criteria) | approve the PRD section (and an architecture delta if a component or interface changes), then the roadmap row: id, Plan inputs, Exit criteria, pending §8 rows |
| a **task in an active milestone** | add a task with a `**Files:**` block to that plan's `.impl.md` in its worktree; the next `execute` spawn picks it up |
| **not kit work** (one component, a couple of files) | a plain session on a branch |

For a milestone the agent appends to `docs/01-prd.md`, adds one `### x.y Milestone <M> — …` row to `docs/05-roadmap.md` (and the §2.2 phase-map entry), one `unclaimed` row to `docs/STATUS.md`, then runs `scripts/bootstrap/check --milestone <M>` and `scripts/milestone/next --inputs <M>`. It stops at the `READY: <M>` or `BLOCKED: <M>` line and commits only when you say "commit". Then "run <M>".

Ids: the next unused letter in the phase the feature extends (`1C`), a `.n` suffix for a slice of an unplanned milestone (`1D.1`), or a new phase digit (`2A`) in `## 5.`/`## 6.` of the roadmap. Plan inputs are read by `next` word by word: a milestone id resolves against merged branches, `G<n>` against §8, anything naming a doc as present, anything else as `(OWNER)`.

## 4. Running a milestone

Inside Herdr (`echo $HERDR_ENV` → `1`), open Claude Code in the repo root on the base branch with a clean tree, and say:

> run 0A

The driver (`driving-a-milestone`) claims the STATUS row, creates `.worktrees/0A` on branch `0A`, spawns worker sessions per role (plan → execute… → finish), and comes back to you only for gates: brainstorm questions, the frozen `## Exit checks` table, permission dialogs in a pane, `DISAGREE` lines, the PR merge, and the §8 row (`log-decision --apply` on your "apply"). Say "resume 0A" in a fresh session after a compaction or a restart; state is in `docs/sdd/0A/driver.json`.

After the PR merges: "merged" → the driver logs §8 and prints `READY:` / `BLOCKED:` for the next milestones. You start the next one with "run <M>".

## 5. Reading `check`

```
OK: <id> — …            done
MISSING: <id> — <path>  the artifact does not exist
MALFORMED: <id> — <why> exists but the parser cannot read it (heading, cell, row shape)
PLACEHOLDER: <file> — n {{…}} left   template tokens still to fill
OWNER: <id> — …         only you can supply it (settings.local.json, Herdr, a "(OWNER)" plan input); does not block READY
DRIFT: <path>           a script copy differs from the kit: fix the kit, re-run install
NOTE: <id> — …          advisory
NEXT: READY|BLOCKED: <M> — …   verbatim from scripts/milestone/next --inputs <M>
```

`check --list` prints the manifest (every check, its stage, who fills it). `check --milestone 1B` targets a later milestone. `check --no-tests` skips the kit's self-tests.

## 6. Updating the kit

Scripts and hooks are copies inside each project (hooks must exist in every clone, worktree and CI run). To ship a fix:

```bash
# edit milestone-kit/scripts/... in this repo, run its tests
milestone-kit/scripts/milestone/tests/guard-scope.sh
milestone-kit/scripts/milestone/tests/post-finish.sh
# then, per project
milestone-kit/scripts/bootstrap/install ~/code/my-app --no-templates
```

`config` (`scripts/milestone/config`) is the project's and is never overwritten. Skills are symlinks, so `SKILL.md` edits reach every project at once.

## 7. Formats the documents must keep

The scripts parse, they do not read. `templates/docs/plans/README.md` is the reference; the short list:

- `docs/STATUS.md`: `| **<M>** | unclaimed | <one sentence> | \`docs/plans/<slug>.md\` | <date> |`
- `docs/05-roadmap.md`: `### x.y Milestone <M> — …` followed by a two-column table with `| **Plan inputs** | … |` and `| **Exit** | … |` (or a table with `Plan inputs` / `Exit` / `Gate` columns and `| **<M>** |` rows); `## 8.` with `| Date | Decision | Input | Result |`; `## 9.` triggers. Ids `0A`, `1D.1`.
- `docs/plans/<slug>.md`: `## Exit checks` table `| E1 | <criterion> | clean-clone\|mechanical\|owner\|consumer:<M> | \`cmd\` |`; `## Status` with `**Proposed decision(s) for roadmap §8 …:**` then `> | date | decision | input | result |`.
- `docs/plans/<slug>.impl.md`: `### Task N: title` with a `**Files:**` block of `- Create:/Modify:/Test:` bullets and backticked paths.
- `docs/sdd/<M>/handoff.md`: the block in `skills/driving-a-milestone/references/briefs.md`.

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `claim` → `no STATUS row for 0A` | add the row (stage 3); `check` shows the exact shape |
| `next --inputs` → `BLOCKED … (OWNER)` | a Plan inputs item that is neither a milestone id, a `G<n>` gate, nor a doc: confirm it to the driver by hand |
| `brief` → `WARN=no roadmap heading names <M>` | the milestone has no `### x.y Milestone(s)` heading (or its range does not contain it) |
| `spawn` → `WARN=task N lists no … **Files:**` | the `.impl.md` task has no Files block; the worker cannot touch code for it |
| every worker commit asks for permission | `.claude/settings.local.json` missing in the root checkout |
| `lock: TAMPERED` | `## Exit checks` or a contract test changed after freeze: re-plan, or the owner says "accept" → `--refreeze` |

## 9. Workers on Codex

The driver is always a Claude Code session; the workers can be Codex. Everything the workers are held to (scope, handoff, superpowers paths) is enforced by the same three hook scripts, wired for Codex in `.codex/hooks.json` instead of `.claude/settings.json`.

```bash
~/personal/agent/milestone-kit/milestone-kit/scripts/bootstrap/install . --agent codex
scripts/bootstrap/check
```

What `--agent codex` changes, and nothing else:

| Item | Claude Code (`MS_AGENT=claude`) | Codex (`MS_AGENT=codex`) |
|---|---|---|
| Hooks | `.claude/settings.json` | `.codex/hooks.json` (`templates/codex/hooks.json`), same events, same deny JSON; file edits arrive as `apply_patch` and every path in the patch is checked |
| Rules file | `CLAUDE.md` | `CLAUDE.md` plus a seeded `AGENTS.md` that points Codex at it and tells it to read the `.claude/rules/<component>.md` whose `paths:` cover a file before editing (Codex has no path-scoped rules) |
| Skills | `.claude/skills/` | `.claude/skills/` (the scripts resolve there) and the same links under `.agents/skills/` (the only place Codex looks) |
| Session skill behind `.claude/skills/cris-managed-session` | `cc-session` (`claude --name`) | `cx-session` (`codex`, then `/rename` in two submits) |
| Permissions | `.claude/settings.local.json`, copied into each worktree | none; the owner's approval policy and sandbox in `~/.codex/config.toml` |
| Trust | Claude Code's trust dialog per new worktree | Codex's trust dialog per new worktree; project hooks load only after it, so the driver never proceeds past `RESULT=blocked` without the owner |

`MS_AGENT` is recorded in `scripts/milestone/config` by `install` and read by `check`, `spawn` and the skills; switching agents is `install . --agent <other>` (the session-skill link and the hooks file follow). Known gap: the briefs name superpowers skills as `obra-<name>` (the link name) while Codex lists them by their `SKILL.md` name; Codex still finds them by description, and `$brainstorming` works in a pane. OpenCode is not supported (no command hooks and no Stop hook to hold the handoff).
