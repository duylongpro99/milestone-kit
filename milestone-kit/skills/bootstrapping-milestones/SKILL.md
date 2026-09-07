---
name: bootstrapping-milestones
description: Use when the owner has an idea, or a PRD and/or architecture doc, and wants the repo prepared so `driving-a-milestone` can run ("bootstrap this repo for milestones", "prepare the project from my prd.md", "set up the milestone flow"). Stage-gated; ends when `scripts/bootstrap/check` prints READY.
---

# Bootstrapping milestones

## Overview

This session prepares a repository for `driving-a-milestone`. It never writes product code. It works in six stages; each stage produces one kind of artifact, is verified by `scripts/bootstrap/check`, and, where content is involved, ends at an owner gate. The session stops when `check` prints `READY` and the owner has the line `READY: <M>` for the first milestone.

Two rules make this safe to hand to an agent:

- **The check is the contract.** `scripts/bootstrap/check --list` is the manifest of every artifact the milestone flow needs, and `check` validates each one with the same parsers `claim`, `next`, `brief`, `scope` will use (`scripts/milestone/lib.sh`). Nothing in this skill is "done" on your say-so: it is done when the line is `OK:`. Nothing outside the manifest gets created.
- **No invented product content.** PRD, components, interfaces, milestones and exit criteria come from the owner's idea or docs. Where the owner has not decided, the doc carries a placeholder question and the roadmap's Plan inputs cell names the item in plain words, which `next` reports as `(OWNER)`. Brainstorming is bounded to what the templates need (`obra-brainstorming`, questions batched, one round per stage).

## Preconditions

1. `git rev-parse --is-inside-work-tree` succeeds in the target repo; the owner names the base branch (default: the current one).
2. The kit is reachable: `scripts/bootstrap/install` exists in the `milestone-kit/` directory of this repo. If the project already has `.milestone-kit`, this is a re-run: skip to **Loop** and start from the first non-OK line.
3. The owner has given at least one of: an idea (a paragraph), `prd.md`, `architecture.md`. With none, stop and ask for the idea.

## Loop

```
install ─► check ─► [stage 0 intent] ─► [1 boundaries] ─► [2 roadmap] ─► [3 process docs] ─► [4 tooling] ─► [5 ready] ─► owner: "run <M>"
                        gate                gate            gate                                 owner items
```

1. **Install.** `scripts/bootstrap/install <repo>` from the kit (or `scripts/bootstrap/install .` after a first run). Relay every `MANUAL:` line to the owner verbatim; do not work around one.
2. **Check.** `scripts/bootstrap/check` from the repo root. Work the **first non-OK line of the lowest stage**; never a later stage first (stage 2 depends on stage 0's component list, stage 3 on stage 2's first milestone id).
3. **Do the stage** (table below), run `check` again, repeat until the stage's lines are all `OK:` / `NOTE:` / `OWNER:`.
4. **Gate** where the table says so: show the owner the artifact (or its `git diff --stat` plus the sections that matter), ask an owner question (`AskUserQuestion` on Claude Code, a plain numbered question on Codex): approve, or change. A change is applied and the stage is re-checked; the gate is not skipped because the second version "only fixed typos".
5. Stage 5 `READY` → report the `NEXT: READY: <M>` line, the `OWNER:` lines still open, and stop. The owner runs `driving-a-milestone` with "run <M>". Never start it yourself.

| Stage | Input | You produce | How | Gate |
|---|---|---|---|---|
| 0 intent | idea, or existing prd/arch | `docs/01-prd.md` with a Goals section; `docs/02-architecture.md` with `## 1.` principles, `## 3.` one `### 3.x` per component, `## 6.` interfaces (canonical names), `## 10.` layout; `## 7.` security and `## 8.` performance when the PRD has such requirements | Existing docs: copy in, add only the missing sections, never rewrite the owner's text. Idea only: one bounded brainstorm (goal, users, non-goals, components, interfaces, what is owner-only work), then draft | Owner approves goal + component list + interface names |
| 1 boundaries | arch §3, §10 | `CLAUDE.md` from the template (fill every `{{…}}`; keep §0–§6 numbering, the briefs cite them); `.claude/rules/<component>.md` per `### 3.x` with `paths:` matching §10 | Rule content is what §3 says the component may and must never do; the template's bullets, nothing more. Delete `_component.template.md` when done | Owner reads the rules (diff) |
| 2 roadmap | PRD + arch | `docs/05-roadmap.md` from the template: Phase 0 `0A` (scaffold, first shared schemas, harness) plus one gate-probe table only if the PRD has a measurable feasibility risk; Phase 1 `1A` vertical slice; later milestones only as ids with Plan inputs (their Exit cells may wait). `## 8.` keeps the header row; unknowns become `| — | <decision> | <input> | pending; unblocks <M> |` rows. `## 9.` one row per real risk | Every milestone: heading `### x.y Milestone <M> — …`, `**Plan inputs**` and `**Exit**` cells; Exit criteria are commands or measurements, split at `;`; `Interfaces fixed here` names consumers. Ids `0A`, `1A`, `1D.1` | Owner approves the milestone list, 0A/1A exit criteria, pending §8 rows |
| 3 process docs | stage 2 ids | `docs/STATUS.md` row for the first milestone (`unclaimed`, Plan cell `docs/plans/<slug>.md`, slug = id + short kebab title); fill `{{…}}` in `docs/plans/README.md`, `docs/adr/README.md` (+ `0000-template.md`); `docs/sdd/README.md` and `docs/journal/README.md` as seeded (the per-milestone journals are written later by `scripts/milestone/journal`); `docs/spike-results.md` when the roadmap has a Gate column | Templates; the only judgment is the slug and the test-kind wording taken from arch §9 or the PRD's testing section | none |
| 4 tooling | kit | `scripts/milestone/config` filled (pane prefix, component roots from §10, contract-test globs, base branch, `MS_CHECK_ALLOW` for the project's tool names, `MS_AGENT` = `claude` or `codex` as the owner says); the hooks file for that agent (`.claude/settings.json`, or `.codex/hooks.json` plus `AGENTS.md` and `.agents/skills` links, `install --agent codex`); `.gitignore` block; skill links | `install` did most; you fill the config and fix `MANUAL:` items the owner has answered | Owner creates `.claude/settings.local.json` from the example (Claude Code; their allowlist; never write it for them) or trusts the project in Codex |
| 5 ready | all | nothing new | `check` → `READY`; `NEXT: READY: <M>`; commit everything as one `[docs] bootstrap milestone flow` commit on the base branch (only when the owner says commit) | Owner says "run <M>" |

## Placeholders

`{{NAME}}` tokens in the templates are the full list of content decisions. Fill each from the docs; when the docs do not decide it, write the plainest true sentence and list the token in the gate message so the owner sees what you assumed. `check` refuses `READY` while any token remains. Never delete a token's whole sentence to make the check pass.

| Token | Source |
|---|---|
| `PROJECT_NAME`, `EXTRA_DESIGN_DOCS` | PRD title; extra docs in `docs/` beyond 01 and 02 (e.g. `, docs/03-tech-stack.md`), else empty |
| `TEST_KINDS`, `TEST_RULE`, `TDD_RULE`, `DONE_COMMANDS` | arch §9 or PRD testing section; the project's typecheck/lint/test commands |
| `REPO_WIDE_RULES`, `REFUSE_OUTRIGHT` | arch §7 security boundaries and §1 principles stated as "never" sentences |
| `TOOLCHAIN`, `CANONICAL_NAMES`, `COMPONENT_LIST`, `SHARED_INTERFACE_HOME` | tech stack; arch §6 names; §3 components; the package/dir that owns shared schemas |
| roadmap `0A_*`, `1A_*`, `PHASE*`, `RISK_0`… | PRD goals, risks, non-goals; arch §10 for 0A scope |
| config `PANE_PREFIX`, `COMPONENT_ROOTS`, `WHOLE_DIRS`, `CONTRACT_GLOBS`, `BASE_BRANCH`, `CHECK_ALLOW` | 2–3 letter project code; §10 top-level dirs whose children are components; dirs opened whole (fixtures, .github); `<root>/*/test/contracts/**` per component root; owner's base branch; ERE of the tool names Exit-check commands start with |

## Owner gates (stop and ask; never proxy the owner)

Goal and component list (stage 0) · rule files (stage 1) · milestone list, exit criteria, pending §8 rows (stage 2) · every `MANUAL:` line from `install` · which agent runs the workers (`MS_AGENT`) · `.claude/settings.local.json` or Codex trust · the commit · starting `driving-a-milestone`.

## Red flags

- Filling a `{{…}}` with product content the PRD does not contain, or deleting the sentence that holds it.
- Writing rule files for components the architecture does not list, or one rule file for "everything".
- Exit criteria that are adjectives ("works well") instead of a command or a number.
- Working a stage-3 line while a stage-0 or stage-2 line is not OK.
- Editing `scripts/milestone/*`, `scripts/hooks/*`, `scripts/sdd/*`, or `scripts/bootstrap/*` in the project: they are kit copies (`DRIFT:`); fix the kit, re-run `install`.
- Treating `OWNER:` lines as yours: `settings.local.json`, Herdr, a `BLOCKED (OWNER)` plan input.
- Rewriting the owner's PRD prose "for consistency".
- Declaring READY from your own reading instead of the `summary:` line.
- Running `driving-a-milestone`, `claim`, or creating the worktree.
