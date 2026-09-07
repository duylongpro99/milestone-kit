# milestone-kit

Everything a repository needs to run roadmap milestones with Claude Code driver and worker sessions, in one place, so a new project is prepared by a script and a checklist instead of by hand.

| Part | What |
|---|---|
| `skills/bootstrapping-milestones/` | Prepares a repo from an idea or a PRD/architecture doc, stage by stage, until `scripts/bootstrap/check` prints `READY`. |
| `skills/driving-a-milestone/` | Drives one milestone: spawns one worker session per role (plan, execute, finish, probe, audit) in the milestone worktree, relays owner gates. Needs Herdr and `head-chief/skills/managed-session`. |
| `scripts/milestone/` | `claim spawn brief wait status exit-check scope log-decision next driver-state`, shared parsers in `lib.sh`, project settings in `config` (written per project). Tests in `tests/`. |
| `scripts/hooks/` | `guard-scope.sh` (write scope per worker session), `require-handoff.sh` (Stop hook), `guard-superpowers-paths.sh`. Wired by `templates/claude/settings.json`. |
| `scripts/sdd/` | Repo-local `sdd-workspace`, `task-brief`, `review-package` (superpowers subagent-driven-development, writing under `docs/sdd/`). |
| `scripts/bootstrap/` | `install <repo>` copies scripts and hooks, links skills, seeds templates; `check` prints per-stage `OK / MISSING / MALFORMED / PLACEHOLDER / OWNER / DRIFT / NOTE` lines and `READY` / `NOT READY`; `check --list` is the manifest. |
| `templates/` | `CLAUDE.md`, `docs/STATUS.md`, `docs/05-roadmap.md`, `docs/plans/README.md`, `docs/sdd/README.md`, `docs/adr/*`, `docs/spike-results.md`, `rules/component.md`, `claude/settings*.json`, `gitignore.block`, `milestone.config`. `{{TOKEN}}` placeholders are the content decisions the bootstrap fills. |

## Use

```bash
# new or existing repo
skills/milestone-kit/scripts/bootstrap/install ~/code/my-app
cd ~/code/my-app && scripts/bootstrap/check          # then: "bootstrap this repo for milestones" in Claude Code
# when check says READY: "run 0A" (driving-a-milestone)
```

Scripts and hooks are **copied** into the project (hooks must exist in every clone and worktree; CI too); skills are **symlinked** into `.claude/skills/`. `check` prints `DRIFT:` when a copy differs from the kit: fix the kit, re-run `install`.

## Contracts the documents must keep

`scripts/milestone/lib.sh` holds the only parsers for `docs/STATUS.md` rows, roadmap milestone rows, roadmap §8, the `### x.y Milestone` heading, and `.impl.md` task headings. `check` validates with them, so a document `check` accepts is a document `claim`, `next`, `brief`, `scope` can read. Formats a project must keep: `templates/docs/plans/README.md` (five questions, `## Status` with the blockquoted §8 row, `## Exit checks` table), the roadmap heading and cell names, the STATUS row shape, `**Files:**` blocks in `.impl.md`, the handoff format in `skills/driving-a-milestone/references/briefs.md`.

Origin: extracted from `duylongpro99/gesture2browse` after its Phase 0 (first run of the driver).
