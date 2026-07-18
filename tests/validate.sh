#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 "$ROOT/tests/validate_package.py"
bash -n "$ROOT"/scripts/*.sh "$ROOT"/scripts/lib/*.sh "$ROOT"/tests/*.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT"/scripts/*.sh "$ROOT"/scripts/lib/*.sh "$ROOT"/tests/*.sh
elif [[ ${CI:-false} == true ]]; then
  printf 'FAIL: ShellCheck is required in CI\n' >&2
  exit 1
else
  printf 'WARN: ShellCheck is not installed; static shell analysis skipped\n' >&2
fi

"$ROOT/tests/test_atomic_publish.sh"

INSTALL_HOME=$(mktemp -d)
trap 'rm -rf "$INSTALL_HOME"' EXIT
HERMES_HOME="$INSTALL_HOME/.hermes" "$ROOT/scripts/install-hermes-skill.sh"
[[ -s "$INSTALL_HOME/.hermes/skills/productivity/bolt-slides/SKILL.md" ]] \
  || { printf 'FAIL: installer did not create SKILL.md\n' >&2; exit 1; }
HERMES_HOME="$INSTALL_HOME/.hermes" "$ROOT/scripts/install-hermes-skill.sh" --force
BACKUP_FOUND=0
for candidate in "$INSTALL_HOME/.hermes/skills/productivity"/bolt-slides.backup.*/bolt-slides; do
  if [[ -d "$candidate" ]]; then
    BACKUP_FOUND=1
    break
  fi
done
[[ "$BACKUP_FOUND" == 1 ]] || { printf 'FAIL: forced installer did not create a backup\n' >&2; exit 1; }

if [[ ${BOLT_SLIDES_RUN_E2E:-0} == 1 ]]; then
  "$ROOT/tests/test_workflow.sh"
else
  printf 'SKIP: full network/npm workflow (set BOLT_SLIDES_RUN_E2E=1 to run)\n'
fi

printf 'PASS: repository validation completed\n'
