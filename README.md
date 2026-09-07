# milestone-kit

Roadmap milestones for a Claude Code driver session and worker sessions on Claude Code or Codex, with everything the kit depends on in one clone: the kit, the two session skills, and superpowers as a submodule.

| Path | What |
|---|---|
| `skills/milestone-kit/` | The kit: skills, scripts, hooks, templates. Start with its `README.md` and `USAGE.md`. |
| `skills/cc-session/` | Starts a Claude Code session as a Herdr pane. Linked into projects as `cris-managed-session` when `MS_AGENT=claude` (default). |
| `skills/cx-session/` | Starts a Codex session as a Herdr pane. Linked as `cris-managed-session` when `install --agent codex`. |
| `skills/superpowers/` | Submodule (obra/superpowers). Linked into projects as `obra-<skill>`. |
| `link-superpowers-skills.sh` | Links every superpowers skill into a project's `.claude/skills/` (and `.agents/skills/` for Codex). Called by the kit's `install`. |

```bash
git clone --recurse-submodules <this-repo> ~/personal/agent/milestone-kit
~/personal/agent/milestone-kit/skills/milestone-kit/scripts/bootstrap/install ~/code/my-app
cd ~/code/my-app && scripts/bootstrap/check
# workers on Codex instead of Claude Code:
~/personal/agent/milestone-kit/skills/milestone-kit/scripts/bootstrap/install ~/code/my-app --agent codex
```

Herdr is a separate tool that must be on `PATH` for the driver; it is not vendored here. Codex support covers the worker sessions only (`skills/milestone-kit/USAGE.md §8`); the driver is always Claude Code. OpenCode is not supported.
