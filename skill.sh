#!/usr/bin/env bash
# Install or uninstall tstack skills for Claude Code and Codex.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=("${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/skills" "${CODEX_HOME:-${HOME}/.codex}/skills")

UNINSTALL=false
DRY_RUN=false

usage() {
  printf 'usage: %s [install|uninstall] [--dry-run] [--project /path/to/repo]\n' "$0"
  printf '  install     link skills (default)\n'
  printf '  uninstall   remove links that point back here\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    install) UNINSTALL=false; shift ;;
    uninstall|--uninstall) UNINSTALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --project)
      if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
        printf 'error: --project requires a path\n' >&2
        usage >&2
        exit 1
      fi
      TARGETS=("$2/.claude/skills" "$2/.agents/skills")
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

for TARGET in "${TARGETS[@]}"; do
  if [[ "$UNINSTALL" == false && "$DRY_RUN" == false ]]; then
    mkdir -p "$TARGET"
  fi
  changed=0
  skipped=0

  for skill in "$ROOT"/skills/*/; do
    skill="${skill%/}"
    name="$(basename "$skill")"
    link="$TARGET/$name"

    if [[ "$UNINSTALL" == true ]]; then
      [[ -L "$link" ]] || continue
      destination="$(readlink "$link")"
      if [[ "${destination%/}" != "$skill" ]]; then
        printf 'skip %s (points elsewhere)\n' "$link"
        skipped=$((skipped + 1))
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        printf 'would remove %s\n' "$link"
      else
        rm "$link"
      fi
      changed=$((changed + 1))
      continue
    fi

    if [[ -L "$link" ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        rm "$link"
      fi
    elif [[ -e "$link" ]]; then
      printf 'skip %s (exists and is not a symlink)\n' "$link"
      skipped=$((skipped + 1))
      continue
    fi
    if [[ "$DRY_RUN" == true ]]; then
      printf 'would link %s -> %s\n' "$link" "$skill"
    else
      ln -s "$skill" "$link"
    fi
    changed=$((changed + 1))
  done

  if [[ "$UNINSTALL" == true ]]; then
    action=removed
    [[ "$DRY_RUN" == false ]] || action='would remove'
    printf '%s %d skills from %s' "$action" "$changed" "$TARGET"
  else
    action=linked
    [[ "$DRY_RUN" == false ]] || action='would link'
    printf '%s %d skills into %s' "$action" "$changed" "$TARGET"
  fi
  if [[ "$skipped" -gt 0 ]]; then
    printf ' (%d skipped)' "$skipped"
  fi
  printf '\n'
done
