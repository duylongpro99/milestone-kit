# milestone-kit

Everything a repository needs to run roadmap milestones with a Claude Code **driver** session and **worker** sessions on Claude Code or Codex, in one place, so a new project is prepared by a script and a checklist instead of by hand.

Two skills, one loop. `bootstrapping-milestones` prepares a repo until `scripts/bootstrap/check` prints `READY`. `driving-a-milestone` then runs one milestone end to end: it spawns a worker session per role inside a git worktree, hands each one a self-contained brief, reads its handoff, and comes back to you only for decisions. Every step is gated by a script that parses documents, never by the agent's own judgment.

## Why

Running a multi-session agent project by hand has three failure modes:

- **The agent decides for you.** It invents product content, resolves a plan input by reading the roadmap, grades its own exit criteria, or merges. The kit turns each of these into an **owner gate**: the agent stops and asks, and the scripts refuse to proceed without your recorded answer.
- **Context grows until it collapses.** A driver that holds pane ids, session numbers and answers in chat loses them at compaction. The kit keeps driver memory on disk in `docs/sdd/<M>/driver.json`, so "resume 0A" in a fresh session continues where the last one stopped.
- **Workers wander.** A worker fixes a test in another component, or ends its turn without saying what happened. Hooks enforce a per-session write scope and refuse to let a worker stop without a handoff.

The fix in every case is the same: a document format the scripts can parse, a script that acts on it, and a hook that enforces it.

## How it works

```
 you (owner)                 driver session                  worker session (one per role)
 ─────────────               ───────────────────             ─────────────────────────────
 "run 0A"          ────►     claim ► spawn ► brief           reads docs/sdd/0A/session-N-brief.md
                             wait (background) ◄──────────── writes code, commits, writes handoff.md
 gate: approve /   ◄────     status ► exit-check
 answer / merge    ────►     answers to the same pane ─────► continues
                             next role, or stop
```

Three layers make this safe to hand to an agent:

| Layer | What it holds | Where |
|---|---|---|
| **Documents** | The project's intent: PRD, architecture, roadmap with milestone rows and §8 decisions, `docs/STATUS.md` claims, per-milestone plans with a frozen `## Exit checks` table | `docs/`, seeded from `templates/` |
| **Scripts** | The only readers and writers of those documents. `lib.sh` holds the one set of parsers; `check` validates with the same parsers `claim`, `next`, `brief`, `scope` use, so "check says OK" and "the scripts can read it" are one fact | `scripts/milestone/`, `scripts/bootstrap/` |
| **Hooks** | Enforcement inside every worker session: write scope, mandatory handoff, superpowers artifacts kept under `docs/` | `scripts/hooks/`, wired by `.claude/settings.json` (Claude Code) or `.codex/hooks.json` (Codex, `MS_AGENT=codex`) |

The driver's only repo writes are the STATUS claim, the post-finish §8 row (on your recorded "apply"), and the gitignored briefs and state under `docs/sdd/<M>/`. Workers write only the paths their role allows. You write `.claude/settings.local.json`, approve gates, and merge.

## Lifecycle

```
bootstrap   install ─► check ─► [0 intent] ─► [1 boundaries] ─► [2 roadmap] ─► [3 process docs] ─► [4 tooling] ─► [5 READY]
                                   gate           gate             gate                              owner items

drive       "run <M>" ─► claim ─► [plan] ─► [execute]* ─► [finish] ─► you merge
                                     └── NEEDS-OWNER: relay, answer, same pane ──┘

post-finish "merged" ─► next ─► log-decision --apply ─► READY: <next M>  ─► "run <next M>"
```

1. **Bootstrap** (`bootstrapping-milestones`). From an idea or an existing PRD and architecture doc, the agent works six stages in order, re-running `check` after each. Content stages end at a gate where you approve the goal and component list, the rule files, and the milestone list with its exit criteria. `check` refuses `READY` while any `{{TOKEN}}` remains.
2. **Drive** (`driving-a-milestone`). "run 0A" claims the STATUS row, creates `.worktrees/0A` on branch `0A`, and runs roles in order. Between roles the driver reads `status` and `exit-check`, and acts on their printed verdict lines only.
3. **Post-finish.** After the PR merges, `next` reports the drafted §8 decision and every unstarted milestone as `READY:` or `BLOCKED:` with the missing input named. `log-decision --apply` writes the §8 row and retires the STATUS row as one `[docs]` commit. You start the next milestone with "run <M>".

## Roles

Each role is one worker session with its own brief, scope, and handoff. `spawn` derives the write allowlist from the role and, for `execute`, from the next unfinished tasks' `**Files:**` blocks.

| Role | Produces | May write (besides the common paths) |
|---|---|---|
| `plan` | `docs/plans/<slug>.spec.md`, `.impl.md`, `.md` with the `## Exit checks` table, the consumer-side contract tests, the SDD workspace | `docs/**` and the contract-test globs (`MS_CONTRACT_GLOBS`) |
| `execute` | Advances the impl plan task by task with superpowers subagent-driven-development; repeats while `CONTINUE` | the `**Files:**` paths of the next ≤2 unfinished tasks, `docs/adr/**`, the lockfile; contract tests denied |
| `finish` | Verifies, finishes the branch, opens the PR to the base branch | nothing else: it cannot fix a failing check, and must not try |
| `probe` | Gate milestones only: short plan, spike, agent-side verification, results in `docs/spike-results.md` | the probe plan's `**Files:**` paths, `docs/spike-results.md`, `docs/adr/**`, the lockfile |
| `audit` | Owner-invoked only: an independent `exit-progress` grade against the frozen exit checks | `docs/sdd/<M>/handoff.md` only |

Common paths for every role are the session-end writes: the `docs/STATUS.md` row, `docs/journal/**`, `docs/sdd/<M>/**`, and the plan's `docs/plans/<slug>.md`. `.claude/scope.json`, `.claude/settings*.json`, `scripts/hooks/`, the spec and the impl plan are denied to every worker.

Every worker ends its turn by writing `docs/sdd/<M>/handoff.md`:

```
outcome: CONTINUE | NEEDS-OWNER | DONE | BLOCKED
phase: <role>
session: <N>
summary: one sentence
owner-questions: (NEEDS-OWNER only)
evidence: (DONE / BLOCKED only)
exit-progress: one line per exit criterion → met | not yet | at risk: why
next: what the next session does first
```

The driver joins `exit-progress` with the script's own run of each check and reports `AGREE` or `DISAGREE` per row. A `DISAGREE`, an `at risk`, a `TAMPERED` lock, or an out-of-scope path is never resolved by the driver: it becomes a question to you.

## What is in the kit

| Part | What |
|---|---|
| `skills/bootstrapping-milestones/` | Prepares a repo from an idea or a PRD/architecture doc, stage by stage, until `scripts/bootstrap/check` prints `READY`. |
| `skills/driving-a-milestone/` | Drives one milestone: spawns one worker session per role (plan, execute, finish, probe, audit) in the milestone worktree, relays owner gates. Needs Herdr and the kit's `cc-session` skill (linked into the project as `.claude/skills/cris-managed-session`). `references/briefs.md` holds the brief templates and the handoff format. |
| `scripts/milestone/` | `claim spawn brief wait status exit-check scope log-decision next driver-state`, shared parsers in `lib.sh`, project settings in `config` (written per project). Tests in `tests/`. |
| `scripts/hooks/` | `guard-scope.sh` (write scope per worker session), `require-handoff.sh` (Stop hook), `guard-superpowers-paths.sh`. Wired by `templates/claude/settings.json` or `templates/codex/hooks.json`; the same scripts serve both agents. |
| `scripts/sdd/` | Repo-local `sdd-workspace`, `task-brief`, `review-package` (superpowers subagent-driven-development, writing under `docs/sdd/`). |
| `scripts/bootstrap/` | `install <repo> [--agent claude\|codex]` copies scripts and hooks, links skills, seeds templates; `check` prints per-stage `OK / MISSING / MALFORMED / PLACEHOLDER / OWNER / DRIFT / NOTE` lines and `READY` / `NOT READY`; `check --list` is the manifest. |
| `templates/` | `CLAUDE.md`, `docs/STATUS.md`, `docs/05-roadmap.md`, `docs/plans/README.md`, `docs/sdd/README.md`, `docs/adr/*`, `docs/spike-results.md`, `rules/component.md`, `claude/settings*.json`, `codex/hooks.json`, `AGENTS.md` (Codex), `gitignore.block`, `milestone.config`. `{{TOKEN}}` placeholders are the content decisions the bootstrap fills. |

### Scripts at a glance

| Script | Called by | Prints |
|---|---|---|
| `claim <M>` | driver, once | `WORKTREE BRANCH BASE SLUG`; sets the STATUS owner cell to `drv-<M>`, creates the worktree, seeds `driver.json` |
| `spawn <M> <role>` | driver, per session | `PANE N BASE SCOPE`; archives the previous handoff, writes `.claude/scope.json`, records pane and session in `driver.json` |
| `brief <M>` | driver, per session | `docs/sdd/<M>/session-<N>-brief.md` from `briefs.md`, every `<…>` filled from `driver.json` and the roadmap |
| `wait <M> [--brief\|--answers\|--nudge\|--prompt]` | driver, in the background | one `RESULT=` line: `handoff blocked disconnect idle stalled gone deadline transport` |
| `status <M>` | driver, after `handoff` | a `VERDICT` block, the handoff verbatim, `OUT-OF-SCOPE:` / `COMMIT-CHECK:` / `HISTORY:` lines; the full dump goes to `status-<N>.txt` |
| `exit-check <M> [--fast\|--freeze\|--refreeze]` | driver and worker | per exit-check row: script result, worker grade, `AGREE` / `DISAGREE` / `AT-RISK` / `OWNER-CLAIM`; lock state `NONE` / `FROZEN` / `TAMPERED` |
| `scope <M> <role>` | `spawn` | the write allowlist as JSON |
| `next [<M>]` | driver, post-finish | `STATE:`, `PROPOSED-8:`, and `READY:` / `BLOCKED:` per unstarted milestone with each Plan input resolved |
| `log-decision <M> [--apply]` | driver, on your "apply" | dry run by default: `INSERT:` / `REPLACE:` / `KEEP:` / `STATUS-ROW:` and a `DIFF:` |
| `driver-state <M> get\|set\|add` | scripts and driver | the on-disk driver memory |

## Use

```bash
# new or existing repo
skills/milestone-kit/scripts/bootstrap/install ~/code/my-app
cd ~/code/my-app && scripts/bootstrap/check          # NOT READY, with the list of what is missing
# in Claude Code: "bootstrap this repo for milestones. Idea: <paragraph>"  (or: from docs/01-prd.md)
# when check says READY, inside Herdr: "run 0A"      (driving-a-milestone)
# after the PR merges: "merged"                        # logs §8, prints READY: for the next milestones
```

`install` is idempotent and never overwrites `scripts/milestone/config`, `.claude/settings.json`, `.claude/settings.local.json`, or any doc that already exists. It prints one line per action (`COPIED: KEPT: LINKED: SEEDED: MANUAL: STAMP:`) and stamps `.milestone-kit` with the kit path and commit so `check` can report drift.

Scripts and hooks are **copied** into the project (hooks must exist in every clone and worktree; CI too); skills are **symlinked** into `.claude/skills/` (`bootstrapping-milestones`, `driving-a-milestone`, `cris-managed-session`, and the superpowers skills as `obra-<name>`). `check` prints `DRIFT:` when a copy differs from the kit: fix the kit, re-run `install`.

### Requirements

- `git`, `jq`, `gh` on PATH.
- Herdr running with `HERDR_ENV=1`, for the driver to spawn worker panes.
- This repository (`milestone-kit`) checked out with the `skills/superpowers` submodule initialised (`git submodule update --init`), since skills are symlinked from here.
- Your own `.claude/settings.local.json` in the project root: the permission allowlist for git, gh, and the project's build and test tools. The agent never writes it; without it every worker commit is a permission dialog.
- Optional: Codex 0.145 or later with `features.hooks` and `features.skills` on, to run the workers on Codex (`install <repo> --agent codex`; `USAGE.md §8`). The driver is always Claude Code.

## Guarantees

What the kit makes true regardless of what the agent decides to do:

- **The check is the contract.** `check --list` is the manifest of every artifact the flow needs. Nothing is "done" on the agent's say-so; it is done when the line is `OK:`. Nothing outside the manifest gets created.
- **No invented product content.** PRD, components, interfaces, milestones and exit criteria come from your idea or docs. Where you have not decided, the doc carries a placeholder question, and `next` reports the item as `(OWNER)`.
- **The driver writes nothing by hand.** Briefs come from `brief`, state from `driver-state`, the §8 row from `log-decision --apply` on your recorded approval.
- **Scope is enforced, not requested.** `guard-scope.sh` denies every write outside `.claude/scope.json` and blocks after a Bash command that left out-of-scope changes. A legitimate extra path is a `NEEDS-OWNER` question; you widen the plan's `**Files:**` block, nobody widens a scope.
- **A worker cannot end without a handoff.** `require-handoff.sh` blocks the Stop until `docs/sdd/<M>/handoff.md` names this session. A cut connection ends at a handoff, not at you.
- **Intent is frozen before execution.** `exit-check --freeze` locks the `## Exit checks` table and contract tests after your approval. Any later change is `TAMPERED` and goes to you.
- **Driver memory survives the chat.** `driver.json` wins over anything the driver remembers. "resume <M>" continues from its `step`.

## Owner gates

The agent stops and asks at each of these. It never proxies your answer.

| During bootstrap | During a milestone |
|---|---|
| goal and component list (stage 0) | a `BLOCKED` plan input from `next --inputs` |
| the `.claude/rules/*.md` files (stage 1) | brainstorm questions from a worker |
| milestone list, exit criteria, pending §8 rows (stage 2) | any agent dialog in a pane (trust, permissions) |
| every `MANUAL:` line from `install` | the `## Exit checks` table and contract tests before `--freeze` |
| `.claude/settings.local.json` | every `TAMPERED`, `DISAGREE`, `AT-RISK`, `OWNER-CLAIM`, `OUT-OF-SCOPE:` line |
| the bootstrap commit | the PR merge; the §8 row (`log-decision --apply`) |
| starting `driving-a-milestone` | spawning `audit`; starting the next `READY:` milestone |

## Contracts the documents must keep

`scripts/milestone/lib.sh` holds the only parsers for `docs/STATUS.md` rows, roadmap milestone rows, roadmap §8, the `### x.y Milestone` heading, and `.impl.md` task headings. `check` validates with them, so a document `check` accepts is a document `claim`, `next`, `brief`, `scope` can read. Formats a project must keep: `templates/docs/plans/README.md` (five questions, `## Status` with the blockquoted §8 row, `## Exit checks` table), the roadmap heading and cell names, the STATUS row shape, `**Files:**` blocks in `.impl.md`, the handoff format in `skills/driving-a-milestone/references/briefs.md`. The short list with examples is in `USAGE.md §6`.

## Project layout after bootstrap and a first milestone

```
my-app/
├── CLAUDE.md                          filled from templates/CLAUDE.md (§0–§6, cited by briefs)
├── .milestone-kit                     kit path + commit, for DRIFT detection
├── AGENTS.md                          Codex only: points at CLAUDE.md and the rule files
├── .codex/hooks.json                  Codex only: the three hooks
├── .agents/skills/                    Codex only: the same skill links
├── .claude/
│   ├── settings.json                  the three hooks (Claude Code)
│   ├── settings.local.json            yours, gitignored
│   ├── rules/<component>.md           one per architecture §3 component
│   ├── skills/                        symlinks into general-cc-kit
│   └── scope.json                     per-worktree, written by spawn, gitignored
├── scripts/{milestone,hooks,sdd,bootstrap}/   kit copies; config is the project's
├── docs/
│   ├── 01-prd.md  02-architecture.md  05-roadmap.md  STATUS.md
│   ├── plans/<slug>.md  .spec.md  .impl.md
│   ├── sdd/<M>/                       progress.md tracked; briefs, handoff, driver.json, status-N.txt gitignored
│   ├── adr/  journal/  spike-results.md
└── .worktrees/<M>/                    one per running milestone, branch <M>
```

## Where to read next

- `USAGE.md`: the operator's guide. Requirements, the two entry points, reading `check`, updating the kit, document formats, troubleshooting.
- `skills/bootstrapping-milestones/SKILL.md`: the stage table, the `{{TOKEN}}` sources, red flags. What the bootstrap agent follows.
- `skills/driving-a-milestone/SKILL.md`: preconditions, the loop, the `RESULT=` and `OUTCOME=` tables, Resume, Exit checks. What the driver follows.
- `skills/driving-a-milestone/references/briefs.md`: the brief templates and the handoff format. Read by `brief`, not by the driver.
- `scripts/bootstrap/check --list`: the manifest, one line per artifact with its stage and who fills it.
- Each script's header comment: its usage line and what it prints.

## Updating the kit

Edit under `skills/milestone-kit/` here, run `scripts/milestone/tests/*.sh`, then re-run `install <repo> --no-templates` per project. Skills are symlinks, so `SKILL.md` edits reach every project at once; scripts and hooks are copies and show as `DRIFT:` until refreshed. `scripts/milestone/config` is the project's and is never overwritten.

Origin: extracted from `duylongpro99/gesture2browse` after its Phase 0 (first run of the driver).
