# milestone-kit

Roadmap milestones for Claude Code driver and worker sessions, with the two skill sets they depend on vendored as submodules.

| Path | What |
|---|---|
| `skills/milestone-kit/` | The kit: skills, scripts, hooks, templates. Start with its `README.md` and `USAGE.md`. |
| `skills/head-chief/` | Submodule. `skills/managed-session` is linked into projects as `cris-managed-session`. |
| `skills/superpowers/` | Submodule (obra/superpowers). Linked into projects as `obra-<skill>`. |
| `link-superpowers-skills.sh` | Links every superpowers skill into a project's `.claude/skills/`. Called by the kit's `install`. |

```bash
git clone --recurse-submodules <this-repo> ~/personal/agent/milestone-kit
~/personal/agent/milestone-kit/skills/milestone-kit/scripts/bootstrap/install ~/code/my-app
cd ~/code/my-app && scripts/bootstrap/check
```

Herdr is a separate tool that must be on `PATH` for the driver; it is not vendored here.
