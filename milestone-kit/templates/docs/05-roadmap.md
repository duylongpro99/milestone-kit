# {{PROJECT_NAME}} — Roadmap

**Status:** Draft v0.1 · **Date:** {{DATE}} · **Inputs:** 01-prd.md, 02-architecture.md{{EXTRA_DESIGN_DOCS}}
**Delivery model:** one human (owner) directing Claude Code; no other engineers.

Each phase is a list of **milestones**. A milestone is the unit of architectural planning: one plan (CLAUDE.md §1 form) per milestone, written only when every input the plan depends on is already recorded in the decision log (§8).

---

## 1. Estimation model

Estimates are for a coding agent, not a team. Three kinds of work have very different clocks:

| Kind | Unit | Typical size | What bounds it |
|---|---|---|---|
| **Agent work** | agent-session: one focused Claude Code session on a scoped task, ending with tests passing and a human review | 1–3 hours wall clock | Spec clarity, test harness quality, owner review bandwidth |
| **Owner work** | owner-hour | as stated | {{OWNER_ONLY_WORK}} |
| **External wait** | calendar days | as stated | {{EXTERNAL_WAITS}} |

---

## 2. Milestones and planning rules

### 2.1 What a milestone is

| Rule | Meaning |
|---|---|
| **One milestone, one plan** | Each milestone gets exactly one architectural plan in CLAUDE.md §1 form. Sessions inside the milestone do not re-open placement or interface decisions made in the plan. |
| **Plan only when inputs exist** | Every milestone lists its *plan inputs*: gate results, §8 decisions, docs, or owner-supplied items. The plan is not written until all of them are logged. |
| **Interfaces are decided at the earliest milestone that crosses them** | A shape shared by two milestones is fixed in the first one. Later milestones extend it; they do not redefine it. |
| **Tunables are not plan material** | Constants and thresholds change through tests, never by re-opening a plan. |
| **A milestone ends at a gate, not a date** | The exit condition is a test, a measurement, or a §8 entry. |
| **Change of ownership needs an ADR** | A plan that moves responsibility between components is an ADR draft under CLAUDE.md §3; the owner decides before any code. |

### 2.2 Phase map

| Phase | Milestones | Reason for the split |
|---|---|---|
| 0 | **0A** scaffold + harness{{PHASE0_GATES_SUMMARY}} | 0A items share layout, boundaries and the first shared schemas, so they need one coherent plan. |
| 1 | **1A** vertical slice, then {{PHASE1_MILESTONES}} | 1A fixes the shared interfaces through one path end to end; later milestones widen it. |

---

## 3. Phase 0 — {{PHASE0_TITLE}}

### 3.1 Milestone 0A — {{0A_TITLE}}

| | |
|---|---|
| **Plan inputs** | 01–02 docs. No gate results needed. |
| **Plan scope** | {{0A_SCOPE}} |
| **Interfaces fixed here** | {{0A_INTERFACES}}. These are consumed by {{0A_CONSUMERS}}. |
| **Sessions** | {{0A_SESSIONS}} |
| **Exit** | {{0A_EXIT}} |

| # | Task | Sessions | Verification the agent can do alone |
|---|---|---|---|
| 0.1 | {{0A_TASK_1}} | 1 | {{0A_TASK_1_VERIFY}} |

{{PHASE0_GATE_PROBES}}

### 3.3 Exit criteria

{{PHASE0_EXIT}}

---

## 4. Phase 1 — {{PHASE1_TITLE}}

### 4.1 Milestone 1A — Vertical slice

One path end to end; everything later imitates this slice.

| | |
|---|---|
| **Plan inputs** | 0A{{1A_EXTRA_INPUTS}} |
| **Plan scope** | {{1A_SCOPE}} |
| **Interfaces fixed here** | {{1A_INTERFACES}}. {{1A_CONSUMERS}} extend them; none redefines them. |
| **Sessions** | {{1A_SESSIONS}} |
| **Exit** | {{1A_EXIT}} |

---

## 7. Working with Claude Code on this repo

- **One milestone, one plan.** Written once per milestone in §3–§6, after its plan inputs are in §8. Re-opening placement or an interface means re-planning the milestone and a §8 row saying why.
- **One session, one component.** Each task row is a session-sized task with a named verification. Do not merge rows.
- **Numbers, not adjectives.** Owner reports from live testing carry a measurement the agent can act on.
- **State, not history, at session start.** `docs/STATUS.md` is the one-page index every session reads first. Boundaries live in `.claude/rules/`, history in `docs/journal/`. Parallel sessions use separate worktrees, one milestone each.
- **Decision log is in this file.** Every gate result and default chosen goes into §8 with a date. A milestone plan may not start until its inputs are there.

---

## 8. Decision log

| Date | Decision | Input | Result |
|---|---|---|---|
| {{DATE}} | Estimation model: coding agent plus one owner, no team; milestone is the planning unit | Owner | This document v0.1 |
{{PENDING_S8_ROWS}}

---

## 9. Top risks and re-plan triggers

A trigger that fires re-opens only the milestone named in the response, not the phase.

| Phase | Risk | Trigger | Response |
|---|---|---|---|
| 0 | {{RISK_0}} | {{TRIGGER_0}} | {{RESPONSE_0}} |
