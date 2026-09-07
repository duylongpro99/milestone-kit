#!/usr/bin/env bash
set -euo pipefail

CLI_CMD="codex"
CLI_LABEL="Codex"

if [ "${HERDR_ENV:-}" != "1" ]; then
  echo "Not running inside a Herdr-managed pane (HERDR_ENV=1 is unset)." >&2
  exit 1
fi

if ! command -v "$CLI_CMD" >/dev/null 2>&1; then
  echo "'$CLI_CMD' was not found on PATH." >&2
  exit 1
fi

p_name=""
s_name=""
split_dir=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --p-name)
      [ "$#" -ge 2 ] || { echo "--p-name requires a value" >&2; exit 2; }
      p_name="$2"
      shift 2
      ;;
    --s-name)
      [ "$#" -ge 2 ] || { echo "--s-name requires a value" >&2; exit 2; }
      s_name="$2"
      shift 2
      ;;
    --split-r)
      [ -z "$split_dir" ] || { echo "--split-r and --split-d are mutually exclusive" >&2; exit 2; }
      split_dir="right"
      shift
      ;;
    --split-d)
      [ -z "$split_dir" ] || { echo "--split-r and --split-d are mutually exclusive" >&2; exit 2; }
      split_dir="down"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${HERDR_WORKSPACE_ID:-}" ]; then
  echo "Missing HERDR_WORKSPACE_ID; is this really a Herdr-managed pane?" >&2
  exit 1
fi

if [ -n "$split_dir" ]; then
  split_json=$(herdr pane split --current --direction "$split_dir" --cwd "$PWD" --focus)
  target_pane=$(printf '%s' "$split_json" | jq -r '.result.pane.pane_id')
  target_tab="${HERDR_TAB_ID:-}"
else
  tab_json=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --focus)
  target_pane=$(printf '%s' "$tab_json" | jq -r '.result.root_pane.pane_id')
  target_tab=$(printf '%s' "$tab_json" | jq -r '.result.tab.tab_id')
fi

herdr pane run "$target_pane" "$CLI_CMD"

herdr agent wait "$target_pane" --status idle --timeout 30000 >/dev/null 2>&1 || true

if [ -n "$p_name" ]; then
  herdr pane rename "$target_pane" "$p_name" >/dev/null
fi

if [ -n "$s_name" ]; then
  # Codex has no `--name` launch flag, and its `/rename` opens a "Type a name
  # and press Enter" modal instead of taking the name inline — so this is two
  # separate submits, not one "/rename NAME" line. `agent prompt` (unlike
  # `pane run`) honors the pane's live bracketed-paste mode, so its Enter
  # reliably submits instead of risking becoming a literal newline.
  herdr agent prompt "$target_pane" "/rename" --wait --timeout 5000 >/dev/null 2>&1 || true
  sleep 0.5
  herdr agent prompt "$target_pane" "$s_name" --wait --timeout 5000 >/dev/null 2>&1 || true
fi

echo "Started $CLI_LABEL in pane $target_pane (tab $target_tab)."
