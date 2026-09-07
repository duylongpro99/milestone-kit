---
paths:
  - "{{COMPONENT_PATH_GLOB}}"
---
# `{{COMPONENT_DIR}}` — {{COMPONENT_ROLE}}

- **May depend on:** {{MAY_DEPEND_ON}}.
- **Must never:** {{MUST_NEVER}}.
- {{OWNED_SHAPES_OR_RESPONSIBILITIES}}
- Names come from `docs/02-architecture.md §6`. No synonyms.
- Consumed via the package's public entry point; no deep imports.
