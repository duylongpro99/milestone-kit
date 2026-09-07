# Status

**Read this first every session. Rewrite your own lines, never append. Keep under 60 lines.**
History lives in `docs/journal/<milestone>.md` (one record per milestone: what was built, how to verify it); decisions live in `docs/05-roadmap.md §8`; per-milestone detail lives in `docs/plans/<milestone>.md ## Status`. This file is the index.

_Project section last updated: {{DATE}} (owner)_

## Project (owner or integration session only)

- **Phase:** 0 — {{PHASE0_TITLE}} (`docs/05-roadmap.md §3`).
- **Code:** nothing merged yet.
- **Blockers:** none.
- **Decisions pending** (inputs in roadmap §8): {{PENDING_DECISIONS}}.
- **Recently settled:** {{DATE}} roadmap v0.1 (§8).

## Active workstreams (one row per milestone; edit only your row)

| Milestone | Owner session | State (one sentence) | Plan | Updated |
|---|---|---|---|---|
| **{{FIRST_M}}** | unclaimed | {{FIRST_M_STATE}} | `docs/plans/{{FIRST_SLUG}}.md` | {{DATE}} |

Claiming a row: put a short session name in "Owner session" before starting. A row already claimed means another session is on it; pick a different milestone or stop and ask. Remove the row when the milestone exits; log the exit in roadmap §8 (owner).
