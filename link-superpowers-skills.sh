#!/usr/bin/env bash
set -euo pipefail

# link-superpowers-skills.sh
#
# Symlinks every skill from this repo's skills/superpowers/skills/ tree into
# a given project's .claude/skills directory (or a custom destination).
#
# Usage:
#   link-superpowers-skills.sh <project-path> [--prefix PREFIX] [--dest-subdir DIR]
#
#   <project-path>     Path to the target project. Skills are linked into
#                       <project-path>/.claude/skills by default.
#   --prefix PREFIX    Name each linked folder "PREFIX-<skill>" instead of
#                       "<skill>". e.g. --prefix sp -> sp-brainstorming, sp-tdd
#   --dest-subdir DIR  Link into <project-path>/DIR instead of
#                       <project-path>/.claude/skills
#
# The source repo defaults to this script's own location; override with
# SUPERPOWERS_REPO.
#
# Examples:
#   scripts/link-superpowers-skills.sh ~/code/my-app
#   scripts/link-superpowers-skills.sh ~/code/my-app --prefix sp
#   SUPERPOWERS_REPO=/path/to/superpowers scripts/link-superpowers-skills.sh ~/code/my-app

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SUPERPOWERS_REPO:-$SCRIPT_DIR/skills/superpowers}"

PREFIX=""
DEST_SUBDIR=".claude/skills"
PROJECT_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)
      [ $# -ge 2 ] || { echo "error: --prefix needs a value" >&2; exit 2; }
      PREFIX="$2"; shift 2 ;;
    --prefix=*)
      PREFIX="${1#*=}"; shift ;;
    --dest-subdir)
      [ $# -ge 2 ] || { echo "error: --dest-subdir needs a value" >&2; exit 2; }
      DEST_SUBDIR="$2"; shift 2 ;;
    --dest-subdir=*)
      DEST_SUBDIR="${1#*=}"; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
    *)
      if [ -n "$PROJECT_PATH" ]; then
        echo "error: unexpected extra argument: $1" >&2; exit 2
      fi
      PROJECT_PATH="$1"; shift ;;
  esac
done

if [ -z "$PROJECT_PATH" ]; then
  echo "error: missing <project-path>" >&2
  echo "usage: $0 <project-path> [--prefix PREFIX] [--dest-subdir DIR]" >&2
  exit 2
fi

if [ ! -d "$PROJECT_PATH" ]; then
  echo "error: project path does not exist: $PROJECT_PATH" >&2
  exit 1
fi

if [ ! -d "$REPO/skills" ]; then
  echo "error: no skills dir at $REPO/skills (set SUPERPOWERS_REPO?)" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
DEST="$PROJECT_PATH/$DEST_SUBDIR"

# Guard against linking into a symlinked dest that resolves back into this repo.
if [ -L "$DEST" ]; then
  resolved="$(readlink -f "$DEST" 2>/dev/null || true)"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      echo "error: $DEST is a symlink into the repo ($resolved)." >&2
      echo "Remove it (rm \"$DEST\") and re-run; it will be recreated as a real dir." >&2
      exit 1
      ;;
  esac
fi

names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -maxdepth 2 -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0)

if [ "${#names[@]}" -eq 0 ]; then
  echo "error: found no SKILL.md under $REPO/skills" >&2
  exit 1
fi

mkdir -p "$DEST"

for i in "${!names[@]}"; do
  name="${names[$i]}"
  src="${srcs[$i]}"

  if [ -n "$PREFIX" ]; then
    linkname="${PREFIX}-${name}"
  else
    linkname="$name"
  fi
  target="$DEST/$linkname"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    rm -rf "$target"
  fi

  ln -sfn "$src" "$target"
  echo "linked $linkname -> $src ($DEST)"
done
