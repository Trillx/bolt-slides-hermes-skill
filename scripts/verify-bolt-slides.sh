#!/usr/bin/env bash
set -euo pipefail

PROJECT=${1:-.}
ALLOW_ENGINE_CHANGES=${ALLOW_ENGINE_CHANGES:-0}
ALLOW_DEPENDENCY_CHANGES=${ALLOW_DEPENDENCY_CHANGES:-0}
BOLT_SLIDES_STRICT_DEV_AUDIT=${BOLT_SLIDES_STRICT_DEV_AUDIT:-0}
PIN="9ad90e6abf93818ea552ae49bb731556f7eb2b0a"
MIN_NODE_MAJOR=18

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
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
  [[ -z "$unexpected" ]] || fail 'src/deck contains a symlink or other non-regular entry'
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

scan_regular_text() {
  local pattern=$1
  shift
  local found=0
  local root file
  for root in "$@"; do
    if [[ -f "$root" && ! -L "$root" ]]; then
      if grep -Iq . "$root" && grep -Eq "$pattern" "$root"; then
        printf 'MATCH: %s\n' "$root" >&2
        found=1
      fi
    elif [[ -d "$root" && ! -L "$root" ]]; then
      while IFS= read -r -d '' file; do
        if grep -Iq . "$file" && grep -Eq "$pattern" "$file"; then
          printf 'MATCH: %s\n' "$file" >&2
          found=1
        fi
      done < <(find "$root" -type f -print0)
    fi
  done
  return "$found"
}

validate_provenance() {
  local -a lines=()
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done < .bolt-slides-provenance

  [[ ${#lines[@]} -eq 6 ]] \
    || fail 'provenance must contain exactly six canonical fields with no duplicate keys'
  [[ "${lines[0]}" == 'repository=https://github.com/stackblitz/bolt-slides.git' ]] \
    || fail 'provenance does not name the canonical StackBlitz repository'
  [[ "${lines[1]}" == "commit=$PIN" ]] \
    || fail "provenance does not match the reviewed upstream pin: $PIN"
  [[ "${lines[2]}" == 'license=MIT' ]] \
    || fail 'provenance does not record the upstream MIT license'
  [[ "${lines[3]}" == 'removed_project_agent_guidance=.bolt/skills/slides/SKILL.md' ]] \
    || fail 'provenance does not record removal of conflicting upstream agent guidance'
  [[ "${lines[4]}" =~ ^initialized_utc=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] \
    || fail 'provenance contains an invalid initialization timestamp'
  [[ "${lines[5]}" == 'workflow=hermes:bolt-slides' ]] \
    || fail 'provenance does not identify the Hermes Bolt Slides workflow'
}

[[ -d "$PROJECT" ]] || fail "project directory not found: $PROJECT"
cd "$PROJECT"

for cmd in npm node cmp; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done
select_sha256
node -e "const m=Number(process.versions.node.split('.')[0]); if (m < $MIN_NODE_MAJOR) { console.error('Node.js $MIN_NODE_MAJOR or newer is required; found '+process.versions.node); process.exit(1) }"

[[ -f package.json ]] || fail 'package.json not found'
[[ -f package-lock.json ]] || fail 'package-lock.json not found'
[[ -f src/App.tsx ]] || fail 'src/App.tsx not found'
[[ -f index.html ]] || fail 'index.html not found'
[[ -f .bolt-slides-provenance ]] || fail '.bolt-slides-provenance not found'
[[ -f .bolt-slides-engine.sha256 ]] || fail '.bolt-slides-engine.sha256 not found'
[[ -f .bolt-slides-dependencies.sha256 ]] || fail '.bolt-slides-dependencies.sha256 not found'

validate_provenance
[[ ! -e .bolt/skills/slides/SKILL.md ]] || fail 'conflicting upstream project-local skill remains in the generated project'

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

generate_engine_manifest "$TMP/engine.sha256"
printf 'Checking engine integrity and file inventory...\n'
if ! cmp -s .bolt-slides-engine.sha256 "$TMP/engine.sha256"; then
  if [[ "$ALLOW_ENGINE_CHANGES" == 1 ]]; then
    warn 'src/deck differs from the initialized engine lock (allowed by explicit environment override)'
  else
    fail 'src/deck file inventory or content differs from the initialized engine lock; revert or explicitly review the engine change'
  fi
fi

generate_dependency_manifest "$TMP/dependencies.sha256"
printf 'Checking dependency-manifest integrity...\n'
if ! cmp -s .bolt-slides-dependencies.sha256 "$TMP/dependencies.sha256"; then
  if [[ "$ALLOW_DEPENDENCY_CHANGES" == 1 ]]; then
    warn 'package manifests differ from the initialized dependency lock (allowed by explicit environment override)'
  else
    fail 'package manifests differ from the initialized dependency lock; review the dependency change before proceeding'
  fi
fi

printf 'Checking starter placeholders and concealed triggers...\n'
PLACEHOLDER_PATTERN='Replace — your deck title|Component demo|Dashboards are everywhere|Northwind|Delete this and build the real one|build demo p'
if scan_regular_text "$PLACEHOLDER_PATTERN" src/App.tsx index.html .bolt AGENTS.md CLAUDE.md .cursorrules .github/copilot-instructions.md; then
  :
else
  fail 'starter, placeholder, or prohibited concealed-trigger content remains'
fi

if ! grep -Eq '<title>[^<]+' index.html; then
  fail 'index.html does not contain a non-empty title'
fi

if scan_regular_text '\[DATA NEEDED\]' src public index.html; then
  :
else
  warn '[DATA NEEDED] remains in delivered content; confirm that this is an intentionally incomplete draft'
fi

SECRET_PATTERN='AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}'
ENV_FILES=()
SECRET_INPUTS=(src public index.html)
for config_file in vite.config.*; do
  if [[ -L "$config_file" ]]; then
    fail 'Vite configuration files must not be symlinks'
  elif [[ -f "$config_file" ]]; then
    SECRET_INPUTS+=("$config_file")
  fi
done
for env_file in .env .env.*; do
  if [[ -L "$env_file" ]]; then
    fail 'Vite environment files must not be symlinks'
  elif [[ -f "$env_file" ]]; then
    ENV_FILES+=("$env_file")
    SECRET_INPUTS+=("$env_file")
  fi
done
if scan_regular_text "$SECRET_PATTERN" "${SECRET_INPUTS[@]}"; then
  :
else
  fail 'possible secret material found in browser-delivered files; only sanitized filenames were printed'
fi
if (( ${#ENV_FILES[@]} > 0 )); then
  if scan_regular_text 'VITE_[A-Za-z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|CREDENTIAL)' "${ENV_FILES[@]}"; then
    :
  else
    fail 'a VITE_ environment variable has a sensitive name; VITE_ values are delivered to the browser'
  fi
fi

printf 'Installing a clean dependency tree from the lockfile...\n'
npm ci

printf 'Type-checking...\n'
npx --no-install tsc --noEmit

printf 'Building production assets...\n'
npm run build
[[ -s dist/index.html ]] || fail 'production build did not create a non-empty dist/index.html'
if scan_regular_text "$SECRET_PATTERN" dist; then
  :
else
  fail 'possible secret material found in production output; only sanitized filenames were printed'
fi

printf 'Auditing production dependencies...\n'
npm audit --omit=dev

printf 'Checking development dependency advisories...\n'
if ! npm audit; then
  if [[ "$BOLT_SLIDES_STRICT_DEV_AUDIT" == 1 ]]; then
    fail 'development dependency audit reported findings and strict mode is enabled'
  fi
  warn 'development-only advisories remain at the reviewed upstream pin; keep Vite localhost-only and see references/upstream-and-security.md'
fi

printf '\nPASS: Bolt Slides mechanical verification completed.\n'
printf 'Production-preview and visual/browser QA are still required before delivery.\n'
