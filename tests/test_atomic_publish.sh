#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/lib/common.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

mkdir "$WORK/source"
printf 'payload\n' > "$WORK/source/file.txt"
atomic_publish_directory "$WORK/source" "$WORK/published"
[[ -f "$WORK/published/file.txt" && ! -e "$WORK/source" ]] \
  || { printf 'FAIL: normal atomic publication did not publish the source directory\n' >&2; exit 1; }

mkdir "$WORK/race-source" "$WORK/fake-bin"
printf 'payload\n' > "$WORK/race-source/file.txt"
REAL_NODE=$(command -v node)
export REAL_NODE
cat > "$WORK/fake-bin/node" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == - ]]; then
  mkdir -p "$3"
  printf 'racer\n' > "$3/racer.txt"
fi
exec "$REAL_NODE" "$@"
SH
chmod +x "$WORK/fake-bin/node"

if PATH="$WORK/fake-bin:$PATH" atomic_publish_directory "$WORK/race-source" "$WORK/race-destination" \
  >"$WORK/race.log" 2>&1; then
  printf 'FAIL: publication succeeded after a destination race\n' >&2
  exit 1
fi
[[ -f "$WORK/race-source/file.txt" ]] \
  || { printf 'FAIL: staged source was lost after a destination race\n' >&2; exit 1; }
[[ -f "$WORK/race-destination/racer.txt" ]] \
  || { printf 'FAIL: racing destination was modified after publication refusal\n' >&2; exit 1; }
for nested in "$WORK/race-destination"/.bolt-slides-*; do
  if [[ -d "$nested" ]]; then
    printf 'FAIL: staged directory was nested inside the racing destination\n' >&2
    exit 1
  fi
done

printf 'PASS: atomic directory publication refuses destination races without nesting or data loss\n'
