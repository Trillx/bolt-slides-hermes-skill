#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

REPO_URL="https://github.com/stackblitz/bolt-slides.git"
PIN="9ad90e6abf93818ea552ae49bb731556f7eb2b0a"
MIN_NODE_MAJOR=18

usage() {
  printf 'Usage: %s DESTINATION\n' "$0" >&2
  exit 2
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

select_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    SHA256_KIND=sha256sum
  elif command -v shasum >/dev/null 2>&1; then
    SHA256_KIND=shasum
  else
    fail 'required SHA-256 utility not found (install sha256sum or shasum)'
  fi
}

hash_file() {
  if [[ "$SHA256_KIND" == sha256sum ]]; then
    sha256sum "$1"
  else
    shasum -a 256 "$1"
  fi
}

generate_engine_manifest() {
  local output=$1
  local unexpected
  unexpected=$(find src/deck ! -type f ! -type d -print)
  [[ -z "$unexpected" ]] || fail 'reviewed src/deck contains a symlink or other non-regular entry'
  : > "$output"
  while IFS= read -r file; do
    hash_file "$file" >> "$output"
  done < <(find src/deck -type f -print | LC_ALL=C sort)
}

generate_dependency_manifest() {
  local output=$1
  : > "$output"
  hash_file package.json >> "$output"
  hash_file package-lock.json >> "$output"
}

[[ $# -eq 1 ]] || usage
DEST=$1

for cmd in bash git npm node tar cmp; do
  require_command "$cmd"
done
select_sha256
node -e "const m=Number(process.versions.node.split('.')[0]); if (m < $MIN_NODE_MAJOR) { console.error('Node.js $MIN_NODE_MAJOR or newer is required; found '+process.versions.node); process.exit(1) }"

PARENT=$(dirname "$DEST")
BASE=$(basename "$DEST")
[[ "$BASE" != . && "$BASE" != .. && -n "$BASE" ]] || fail "invalid destination: $DEST"
mkdir -p "$PARENT"
PARENT=$(cd "$PARENT" && pwd)
DEST="$PARENT/$BASE"
[[ ! -e "$DEST" && ! -L "$DEST" ]] || fail "destination already exists; refusing to overwrite: $DEST"

STAGE_ROOT=$(mktemp -d "$PARENT/.bolt-slides-init.XXXXXX")
PROJECT="$STAGE_ROOT/project"
PUBLISHED=0
cleanup() {
  if [[ "$PUBLISHED" != 1 ]]; then
    rm -rf "$STAGE_ROOT"
  fi
}
trap cleanup EXIT INT TERM

printf 'Cloning reviewed Bolt Slides source...\n'
git clone --quiet --no-checkout "$REPO_URL" "$PROJECT"
git -C "$PROJECT" fetch --quiet --depth 1 origin "$PIN"
git -C "$PROJECT" checkout --quiet --detach "$PIN"
ACTUAL=$(git -C "$PROJECT" rev-parse HEAD)
[[ "$ACTUAL" == "$PIN" ]] || fail "expected $PIN but checked out $ACTUAL"

unexpected_agent_file=$(find "$PROJECT" -type f \( -name AGENTS.md -o -name CLAUDE.md -o -name .cursorrules -o -name copilot-instructions.md \) -print -quit)
[[ -z "$unexpected_agent_file" ]] || fail "reviewed source contains unexpected project-agent instructions: ${unexpected_agent_file#"$PROJECT/"}"
[[ -f "$PROJECT/.bolt/skills/slides/SKILL.md" ]] || fail 'reviewed upstream skill is missing; inspect the upstream layout before changing the pin'

# Hermes uses this repository's global skill. Do not copy the conflicting project-local
# Bolt instructions—including their concealed demo trigger—into generated projects.
rm -rf "$PROJECT/.bolt"
rm -rf "$PROJECT/.git"

cat > "$PROJECT/.bolt-slides-provenance" <<EOF
repository=$REPO_URL
commit=$PIN
license=MIT
removed_project_agent_guidance=.bolt/skills/slides/SKILL.md
initialized_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
workflow=hermes:bolt-slides
EOF

(
  cd "$PROJECT"
  generate_engine_manifest .bolt-slides-engine.sha256
  generate_dependency_manifest .bolt-slides-dependencies.sha256
)

printf 'Installing locked dependencies...\n'
(
  cd "$PROJECT"
  npm ci
  npx --no-install tsc --noEmit
  npm run build
  npm audit --omit=dev
)

[[ ! -e "$DEST" && ! -L "$DEST" ]] || fail "destination appeared during initialization; refusing to replace it: $DEST"
atomic_publish_directory "$PROJECT" "$DEST" \
  || fail "destination changed during initialization; staged project was not published: $DEST"
rmdir "$STAGE_ROOT"
PUBLISHED=1
trap - EXIT INT TERM

printf '\nCreated verified Bolt Slides project at: %s\n' "$DEST"
printf 'Next: replace the demo in src/App.tsx, theme tokens.css, and update index.html.\n'
