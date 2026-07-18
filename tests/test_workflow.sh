#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

expect_failure() {
  local label=$1
  local expected=$2
  shift 2
  if "$@" >"$WORK/$label.log" 2>&1; then
    printf 'FAIL: expected failure did not occur: %s\n' "$label" >&2
    cat "$WORK/$label.log" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$WORK/$label.log"; then
    printf 'FAIL: %s failed for the wrong reason; expected: %s\n' "$label" "$expected" >&2
    cat "$WORK/$label.log" >&2
    exit 1
  fi
  printf 'PASS: rejected %s with the expected diagnostic\n' "$label"
}

WORK=$(mktemp -d)
SERVER_PID=''
cleanup() {
  [[ -z "$SERVER_PID" ]] || kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM
PROJECT="$WORK/deck"

"$ROOT/scripts/init-bolt-slides.sh" "$PROJECT"
[[ ! -e "$PROJECT/.bolt/skills/slides/SKILL.md" ]] || { printf 'FAIL: upstream project-local skill was copied\n' >&2; exit 1; }
cp "$ROOT/tests/fixtures/App.tsx" "$PROJECT/src/App.tsx"
python3 - "$PROJECT/index.html" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = text.replace("<title>Replace — your deck title</title>", "<title>Hermes Bolt Slides CI Verification</title>")
text = text.replace("Always replace the title + favicon emoji to match the deck topic", "Title and favicon customized by the CI fixture")
path.write_text(text, encoding="utf-8")
PY

"$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
python3 "$ROOT/tests/check_upstream_audit.py" "$PROJECT"

cp "$PROJECT/.bolt-slides-provenance" "$WORK/provenance"
python3 - "$PROJECT/.bolt-slides-provenance" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text().replace("9ad90e6abf93818ea552ae49bb731556f7eb2b0a", "0000000000000000000000000000000000000000")
path.write_text(text)
PY
expect_failure wrong-provenance 'provenance does not match the reviewed upstream pin' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
cp "$WORK/provenance" "$PROJECT/.bolt-slides-provenance"
printf 'commit=0000000000000000000000000000000000000000\n' >> "$PROJECT/.bolt-slides-provenance"
expect_failure duplicate-provenance 'exactly six canonical fields with no duplicate keys' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
cp "$WORK/provenance" "$PROJECT/.bolt-slides-provenance"

cp "$PROJECT/src/deck/Deck.tsx" "$WORK/Deck.tsx"
printf '\n// integrity-negative-test\n' >> "$PROJECT/src/deck/Deck.tsx"
expect_failure engine-tampering 'src/deck file inventory or content differs' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
cp "$WORK/Deck.tsx" "$PROJECT/src/deck/Deck.tsx"

printf 'export const unexpected = true;\n' > "$PROJECT/src/deck/Unexpected.ts"
expect_failure engine-file-addition 'src/deck file inventory or content differs' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
rm "$PROJECT/src/deck/Unexpected.ts"

printf 'export const external = true;\n' > "$WORK/External.ts"
ln -s "$WORK/External.ts" "$PROJECT/src/deck/Unexpected.ts"
expect_failure engine-symlink 'src/deck contains a symlink or other non-regular entry' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
rm "$PROJECT/src/deck/Unexpected.ts"

mv "$PROJECT/src/deck/Deck.tsx" "$WORK/Deck.deleted"
expect_failure engine-file-deletion 'src/deck file inventory or content differs' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
mv "$WORK/Deck.deleted" "$PROJECT/src/deck/Deck.tsx"

cp "$PROJECT/package.json" "$WORK/package.json"
printf ' \n' >> "$PROJECT/package.json"
expect_failure dependency-tampering 'package manifests differ from the initialized dependency lock' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
cp "$WORK/package.json" "$PROJECT/package.json"

cp "$PROJECT/src/App.tsx" "$WORK/App.tsx"
printf '\n// Delete this and build the real one\n' >> "$PROJECT/src/App.tsx"
expect_failure starter-placeholder 'starter, placeholder, or prohibited concealed-trigger content remains' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
cp "$WORK/App.tsx" "$PROJECT/src/App.tsx"

FAKE_SECRET="sk-$(printf 'FAKE%.0s' {1..8})"
printf '%s\n' "$FAKE_SECRET" > "$PROJECT/src/leak.ts"
expect_failure source-secret 'possible secret material found in browser-delivered files' "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
if grep -Fq "$FAKE_SECRET" "$WORK/source-secret.log"; then
  printf 'FAIL: secret scanner echoed matching secret content\n' >&2
  exit 1
fi
rm "$PROJECT/src/leak.ts"

printf 'VITE_REVIEW_TOKEN=not-sensitive-test-data\n' > "$PROJECT/.env.production"
expect_failure sensitive-vite-env 'VITE_ environment variable has a sensitive name' \
  "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
rm "$PROJECT/.env.production"

cp "$PROJECT/src/App.tsx" "$WORK/App.before-dist-secret.tsx"
cp "$PROJECT/vite.config.ts" "$WORK/vite.config.ts"
python3 - "$PROJECT/src/App.tsx" "$PROJECT/vite.config.ts" "${FAKE_SECRET#sk-}" <<'PY'
from pathlib import Path
import sys

app = Path(sys.argv[1])
config = Path(sys.argv[2])
suffix = sys.argv[3]
app.write_text(
    'declare const __REVIEW_TOKEN__: string;\nconsole.log(__REVIEW_TOKEN__);\n'
    + app.read_text(encoding='utf-8'),
    encoding='utf-8',
)
config.write_text(
    config.read_text(encoding='utf-8').replace(
        'plugins: [react()],',
        "plugins: [react()],\n  define: { __REVIEW_TOKEN__: JSON.stringify('sk-' + '" + suffix + "') },",
    ),
    encoding='utf-8',
)
PY
expect_failure production-secret 'possible secret material found in production output' \
  "$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT"
if grep -Fq "$FAKE_SECRET" "$WORK/production-secret.log"; then
  printf 'FAIL: production secret scanner echoed matching secret content\n' >&2
  exit 1
fi
cp "$WORK/App.before-dist-secret.tsx" "$PROJECT/src/App.tsx"
cp "$WORK/vite.config.ts" "$PROJECT/vite.config.ts"

printf '%s\n' "$FAKE_SECRET" > "$WORK/external-secret.txt"
ln -s "$WORK/external-secret.txt" "$PROJECT/src/external-link.txt"
"$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT" >"$WORK/symlink-scan.log" 2>&1
if grep -Fq "$FAKE_SECRET" "$WORK/symlink-scan.log"; then
  printf 'FAIL: secret scanner followed a symlink and echoed external content\n' >&2
  exit 1
fi
rm "$PROJECT/src/external-link.txt"

rm -f "$PROJECT/node_modules/.bin/tsc"
cat > "$PROJECT/node_modules/.bin/tsc" <<EOF
#!/usr/bin/env bash
touch "$WORK/tampered-tsc-ran"
exit 0
EOF
chmod +x "$PROJECT/node_modules/.bin/tsc"
"$ROOT/scripts/verify-bolt-slides.sh" "$PROJECT" >"$WORK/clean-install.log" 2>&1
[[ ! -e "$WORK/tampered-tsc-ran" ]] || { printf 'FAIL: verifier executed a tampered node_modules binary\n' >&2; exit 1; }

SCREENSHOTS="$WORK/screenshots"
if [[ ${BOLT_SLIDES_SKIP_CAPTURE:-0} != 1 ]]; then
  if command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1 \
    || command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1 \
    || [[ -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]]; then
    BOLT_SLIDES_CAPTURE_PORT=${BOLT_SLIDES_CAPTURE_PORT:-43173} \
      "$ROOT/scripts/capture-slides.sh" "$PROJECT" 3 "$SCREENSHOTS" 1280 720
    python3 "$ROOT/tests/assert_screenshots.py" "$SCREENSHOTS" 3 1280 720
    expect_failure capture-existing-output 'output directory is not empty' \
      "$ROOT/scripts/capture-slides.sh" "$PROJECT" 3 "$SCREENSHOTS" 1280 720

    PORT_TEST=${BOLT_SLIDES_PORT_COLLISION_TEST:-43174}
    python3 -m http.server "$PORT_TEST" --bind 127.0.0.1 --directory "$WORK" >"$WORK/http.log" 2>&1 &
    SERVER_PID=$!
    collision_ready=0
    for _ in {1..40}; do
      if curl --silent --fail "http://127.0.0.1:$PORT_TEST/" >/dev/null 2>&1; then
        collision_ready=1
        break
      fi
      sleep 0.1
    done
    [[ $collision_ready == 1 ]] || {
      printf 'FAIL: collision fixture did not become ready on port %s\n' "$PORT_TEST" >&2
      exit 1
    }
    expect_failure port-collision 'already serves HTTP' \
      env BOLT_SLIDES_CAPTURE_PORT="$PORT_TEST" \
      "$ROOT/scripts/capture-slides.sh" "$PROJECT" 1 "$WORK/collision-output" 1280 720
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=''

    STRICT_PORT=${BOLT_SLIDES_STRICT_PORT_TEST:-43175}
    python3 - "$STRICT_PORT" >"$WORK/tcp.log" 2>&1 <<'PY' &
import socket
import sys

port = int(sys.argv[1])
with socket.socket() as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', port))
    server.listen()
    while True:
        connection, _ = server.accept()
        connection.close()
PY
    SERVER_PID=$!
    strict_ready=0
    for _ in {1..40}; do
      if python3 - "$STRICT_PORT" <<'PY' >/dev/null 2>&1
import socket
import sys
with socket.create_connection(('127.0.0.1', int(sys.argv[1])), timeout=0.2):
    pass
PY
      then
        strict_ready=1
        break
      fi
      sleep 0.1
    done
    [[ $strict_ready == 1 ]] || {
      printf 'FAIL: strict-port fixture did not become ready on port %s\n' "$STRICT_PORT" >&2
      exit 1
    }
    expect_failure strict-port 'production preview exited before becoming ready' \
      env BOLT_SLIDES_CAPTURE_PORT="$STRICT_PORT" \
      "$ROOT/scripts/capture-slides.sh" "$PROJECT" 1 "$WORK/strict-port-output" 1280 720
    grep -Eqi 'port .*already in use' "$WORK/strict-port.log" \
      || { printf 'FAIL: strict-port test did not reach Vite strictPort enforcement\n' >&2; exit 1; }
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=''
  elif [[ ${CI:-false} == true ]]; then
    printf 'FAIL: Chrome/Chromium is required in the CI end-to-end job\n' >&2
    exit 1
  else
    printf 'SKIP: Chrome/Chromium not installed; screenshot behavior not exercised\n'
  fi
fi

printf 'PASS: full end-to-end workflow validation completed\n'
