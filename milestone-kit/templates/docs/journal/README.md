# Journal

One file per milestone, `docs/journal/<milestone slug>.md` (`0A-scaffold.md`), written on the milestone branch by `scripts/milestone/journal <M>` and merged with the PR. It is the milestone's durable record: what was implemented, how to verify it, who built it, what it decided. Nobody reads it at session start (`CLAUDE.md §0`); the owner reads it after the merge, and re-runs it.

| Section | Content | Written by |
|---|---|---|
| header | plan, branch and base, roadmap section, PR, last update | script |
| `## Verification` | the plan's frozen `## Exit checks` rows with a **Last result** column (result, date, commit, mode) | script, from `scripts/milestone/exit-check` |
| `### Owner steps` | one `**E3 — <criterion>**` block per `owner` row: the numbered steps the owner runs and an `Expected:` line | the worker that reaches the row; kept by the script |
| `### Runs` | one dated line per full exit-check run and per `--recheck` | script, appended |
| `## Implemented` | every commit on the branch grouped by its `[component] task N` body line, with files | script, from git |
| `## Sessions` | one row per worker session: role, outcome, summary | script, from the handoffs |
| `## Decisions` | the proposed roadmap §8 row, ADRs added on the branch | script, from the plan |
| `## Notes` | what git and the tables do not say | the worker; kept by the script |

**Re-verifying a merged milestone**, any time, without the worktree or the session that built it:

```bash
scripts/milestone/journal <M> --recheck     # from the repo root, on the base branch
```

It runs every command in the Verification table, prints PASS / FAIL per row, rewrites the Last result column and appends a Runs line; the `owner` rows are yours to walk through from Owner steps. Commit the journal to keep the run on record.

The Verification table is the plan's `## Exit checks`, frozen at plan time. A criterion that needs to change is a re-plan (roadmap §2.1, §7), never an edit here or in the plan.
