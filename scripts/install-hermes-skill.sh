#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEST="${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides"
FORCE=0

usage() {
  printf 'Usage: %s [--destination PATH] [--force]\n' "$0" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination)
      [[ $# -ge 2 ]] || usage
      DEST=$2
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    *) usage ;;
  esac
done

ROOT=$(cd "$ROOT" && pwd)
PARENT=$(dirname "$DEST")
BASE=$(basename "$DEST")
[[ "$BASE" != . && "$BASE" != .. && -n "$BASE" ]] || { printf 'ERROR: invalid destination: %s\n' "$DEST" >&2; exit 1; }
mkdir -p "$PARENT"
PARENT=$(cd "$PARENT" && pwd)
DEST="$PARENT/$BASE"

if [[ "$ROOT" == "$DEST" ]]; then
  printf 'Skill is already located at the Hermes destination: %s\n' "$DEST"
  exit 0
fi

if [[ -e "$DEST" && "$FORCE" != 1 ]]; then
  printf 'ERROR: destination exists; use --force to replace it with a timestamped backup: %s\n' "$DEST" >&2
  exit 1
fi

STAGE=$(mktemp -d "$PARENT/.bolt-slides-install.XXXXXX")
BACKUP_ROOT=''
BACKUP=''
COMMITTED=0
cleanup() {
  rm -rf "$STAGE"
  if [[ "$COMMITTED" != 1 && -n "$BACKUP" && -e "$BACKUP" && ! -e "$DEST" ]]; then
    mv "$BACKUP" "$DEST"
    rmdir "$BACKUP_ROOT" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

(
  cd "$ROOT"
  tar \
    --exclude=.git \
    --exclude=.github \
    --exclude=tests \
    --exclude='*.zip' \
    -cf - .
) | (
  cd "$STAGE"
  tar -xf -
)

[[ -s "$STAGE/SKILL.md" ]] || { printf 'ERROR: staged skill is missing SKILL.md\n' >&2; exit 1; }
[[ -s "$STAGE/LICENSE" ]] || { printf 'ERROR: staged skill is missing LICENSE\n' >&2; exit 1; }
[[ -s "$STAGE/THIRD_PARTY_NOTICES.md" ]] || { printf 'ERROR: staged skill is missing third-party notices\n' >&2; exit 1; }

if [[ -e "$DEST" ]]; then
  BACKUP_ROOT=$(mktemp -d "$PARENT/bolt-slides.backup.XXXXXX")
  BACKUP="$BACKUP_ROOT/bolt-slides"
  mv "$DEST" "$BACKUP"
fi

mv "$STAGE" "$DEST"
COMMITTED=1
trap - EXIT INT TERM

printf 'Installed Hermes Bolt Slides skill at: %s\n' "$DEST"
if [[ -n "$BACKUP" ]]; then
  printf 'Previous installation backed up at: %s\n' "$BACKUP"
fi
printf 'Start a new Hermes session to refresh skill discovery.\n'
