# Agent instructions (Codex)

This project's working rules are in `CLAUDE.md`. Read it fully at the start of every session; it is the single source of rules for every coding agent here, and its section numbers (§0 to §6) are cited by the milestone briefs.

## Component boundaries

Per-component rules live in `.claude/rules/<component>.md`. Each file starts with a `paths:` list. Claude Code loads a rule file by itself when a touched path matches; Codex does not. Before you create or edit a file, open the rule file whose `paths:` cover it and follow it as a compile error. When no rule file covers the path, the file is outside every component: stop and surface it (`CLAUDE.md §1`).

## Skills

Skills are under `.agents/skills/` (links into a shared kit). Never edit them; overrides live in `CLAUDE.md` and `docs/plans/README.md §Superpowers`. Invoke a skill by name when its description matches the task.

## Hooks

`.codex/hooks.json` wires `scripts/hooks/guard-scope.sh`, `guard-superpowers-paths.sh` and `require-handoff.sh`. In a milestone worktree they enforce the write scope in `.claude/scope.json` and the handoff at session end. A denial names the only sanctioned way out (`NEEDS-OWNER` in the handoff); never edit `.codex/`, `.claude/`, or `scripts/hooks/` to get past one.
