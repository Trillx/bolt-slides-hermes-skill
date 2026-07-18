#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  printf 'Usage: %s PROJECT_DIR SLIDE_COUNT OUTPUT_DIR [WIDTH] [HEIGHT]\n' "$0" >&2
  exit 2
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

[[ $# -ge 3 && $# -le 5 ]] || usage
PROJECT=$1
COUNT=$2
OUT=$3
WIDTH=${4:-1440}
HEIGHT=${5:-900}
PORT=${BOLT_SLIDES_CAPTURE_PORT:-4173}
URL="http://127.0.0.1:$PORT"

[[ "$COUNT" =~ ^[1-9][0-9]*$ ]] || fail 'SLIDE_COUNT must be a positive integer'
[[ "$WIDTH" =~ ^[1-9][0-9]*$ ]] || fail 'WIDTH must be a positive integer'
[[ "$HEIGHT" =~ ^[1-9][0-9]*$ ]] || fail 'HEIGHT must be a positive integer'
[[ "$PORT" =~ ^[1-9][0-9]*$ ]] || fail 'BOLT_SLIDES_CAPTURE_PORT must be a positive integer'
[[ -f "$PROJECT/package.json" ]] || fail "not a Bolt Slides project: $PROJECT"
[[ -s "$PROJECT/dist/index.html" ]] || fail 'production dist/index.html is missing; run verification first'
[[ -x "$PROJECT/node_modules/.bin/vite" ]] || fail 'Vite is not installed; run verification first'
command -v curl >/dev/null 2>&1 || fail 'curl is required for capture readiness checks'

OUT_PARENT=$(dirname "$OUT")
OUT_BASE=$(basename "$OUT")
[[ "$OUT_BASE" != . && "$OUT_BASE" != .. && -n "$OUT_BASE" ]] || fail "invalid output directory: $OUT"
mkdir -p "$OUT_PARENT"
OUT_PARENT=$(cd "$OUT_PARENT" && pwd)
OUT="$OUT_PARENT/$OUT_BASE"
[[ ! -L "$OUT" ]] || fail "output directory must not be a symlink: $OUT"
if [[ -e "$OUT" ]]; then
  [[ -d "$OUT" ]] || fail "output path exists and is not a directory: $OUT"
  if [[ -n "$(printf '%s\n' "$OUT"/* "$OUT"/.[!.]* "$OUT"/..?* 2>/dev/null | while IFS= read -r p; do [[ -e "$p" || -L "$p" ]] && { printf x; break; }; done)" ]]; then
    fail "output directory is not empty; choose a new directory: $OUT"
  fi
  rmdir "$OUT"
fi

if curl -fsS --max-time 1 "$URL" >/dev/null 2>&1; then
  fail "port $PORT already serves HTTP; choose another BOLT_SLIDES_CAPTURE_PORT"
fi

CHROME=''
for candidate in chromium chromium-browser google-chrome google-chrome-stable; do
  if command -v "$candidate" >/dev/null 2>&1; then
    CHROME=$(command -v "$candidate")
    break
  fi
done
if [[ -z "$CHROME" && -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]]; then
  CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
fi
[[ -n "$CHROME" ]] || fail 'no Chromium/Chrome executable found; use the Hermes browser tool instead'

PUBLISH_STAGE=$(mktemp -d "$OUT_PARENT/.bolt-slides-publish.XXXXXX")
CAPTURE_STAGE="$PUBLISH_STAGE"
SNAP_STAGE=''
LOG=$(mktemp)
READY_PAGE=$(mktemp)
CAPTURE_LOG=''
if [[ "$CHROME" == /snap/* ]]; then
  mkdir -p "$HOME/snap/chromium/common"
  SNAP_STAGE=$(mktemp -d "$HOME/snap/chromium/common/bolt-slides-capture.XXXXXX")
  CAPTURE_STAGE="$SNAP_STAGE"
fi

SERVER_PID=''
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -f "$LOG" "$READY_PAGE"
  [[ -z "$CAPTURE_LOG" ]] || rm -f "$CAPTURE_LOG"
  [[ -z "$SNAP_STAGE" ]] || rm -rf "$SNAP_STAGE"
  [[ -z "$PUBLISH_STAGE" ]] || rm -rf "$PUBLISH_STAGE"
}
trap cleanup EXIT INT TERM

(
  cd "$PROJECT"
  exec ./node_modules/.bin/vite preview --host 127.0.0.1 --port "$PORT" --strictPort >"$LOG" 2>&1
) &
SERVER_PID=$!

READY=0
attempt=0
while (( attempt < 60 )); do
  if curl -fsS --max-time 1 "$URL" -o "$READY_PAGE" >/dev/null 2>&1 \
    && grep -Eq '<div id="root">' "$READY_PAGE"; then
    READY=1
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    cat "$LOG" >&2
    fail 'production preview exited before becoming ready'
  fi
  sleep 0.25
  attempt=$((attempt + 1))
done
if [[ "$READY" != 1 ]]; then
  cat "$LOG" >&2
  fail 'production preview did not become ready with the expected deck marker'
fi

CHROME_ARGS=(
  --headless=new
  --disable-gpu
  --hide-scrollbars
  --no-first-run
  --no-default-browser-check
  --window-size="$WIDTH,$HEIGHT"
  --run-all-compositor-stages-before-draw
  --virtual-time-budget=1800
)
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  printf 'WARN: running Chromium as root requires --no-sandbox; use an unprivileged account when possible.\n' >&2
  CHROME_ARGS+=(--no-sandbox)
fi
if [[ ${BOLT_SLIDES_ALLOW_NO_SANDBOX:-0} == 1 ]] && [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'WARN: Chromium sandbox explicitly disabled; use this only in an isolated ephemeral CI runner or container.\n' >&2
  CHROME_ARGS+=(--no-sandbox)
fi

index=1
while (( index <= COUNT )); do
  capture_file=$(printf '%s/slide-%02d.png' "$CAPTURE_STAGE" "$index")
  publish_file=$(printf '%s/slide-%02d.png' "$PUBLISH_STAGE" "$index")
  CAPTURE_LOG=$(mktemp)
  if ! "$CHROME" "${CHROME_ARGS[@]}" --screenshot="$capture_file" "$URL/#$index" >"$CAPTURE_LOG" 2>&1; then
    cat "$CAPTURE_LOG" >&2
    fail "Chromium failed while capturing slide $index"
  fi
  if [[ ! -s "$capture_file" || -L "$capture_file" ]]; then
    cat "$CAPTURE_LOG" >&2
    fail "Chromium returned success but did not create a regular non-empty screenshot for slide $index"
  fi
  if [[ "$capture_file" != "$publish_file" ]]; then
    mv "$capture_file" "$publish_file"
  fi
  rm -f "$CAPTURE_LOG"
  CAPTURE_LOG=''
  printf 'Captured staged slide %s\n' "$index"
  index=$((index + 1))
done

[[ ! -e "$OUT" && ! -L "$OUT" ]] || fail "output path appeared during capture; refusing to replace it: $OUT"
atomic_publish_directory "$PUBLISH_STAGE" "$OUT" \
  || fail "output path changed during capture; staged screenshots were not published: $OUT"
PUBLISH_STAGE=''
printf 'Published %s verified screenshots at %sx%s into %s\n' "$COUNT" "$WIDTH" "$HEIGHT" "$OUT"
