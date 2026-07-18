#!/usr/bin/env python3
"""Validate the public Hermes skill package without third-party Python modules."""
from __future__ import annotations

import re
import stat
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


required_files = [
    "SKILL.md",
    "README.md",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "references/component-catalog.md",
    "references/hermes-vs-upstream.md",
    "references/qa-and-delivery.md",
    "references/upstream-and-security.md",
    "templates/deck-brief.md",
    "scripts/init-bolt-slides.sh",
    "scripts/verify-bolt-slides.sh",
    "scripts/capture-slides.sh",
    "scripts/install-hermes-skill.sh",
    "scripts/lib/common.sh",
    "tests/test_atomic_publish.sh",
    "tests/check_upstream_audit.py",
    "tests/assert_screenshots.py",
]
for relative in required_files:
    require((ROOT / relative).is_file(), f"missing required file: {relative}")

skill_path = ROOT / "SKILL.md"
skill = skill_path.read_text(encoding="utf-8")
require(skill.startswith("---\n"), "SKILL.md must start with YAML frontmatter at byte 0")
frontmatter_match = re.match(r"\A---\n(.*?)\n---\n", skill, re.DOTALL)
require(frontmatter_match is not None, "SKILL.md frontmatter is not closed correctly")
if frontmatter_match:
    frontmatter = frontmatter_match.group(1)
    fields = {}
    for line in frontmatter.splitlines():
        match = re.match(r"^([a-zA-Z][a-zA-Z0-9_-]*):\s*(.*)$", line)
        if match:
            fields[match.group(1)] = match.group(2).strip().strip('"')
    require(fields.get("name") == "bolt-slides", "frontmatter name must be bolt-slides")
    require(bool(re.fullmatch(r"\d+\.\d+\.\d+", fields.get("version", ""))), "version must use SemVer")
    require(fields.get("author") == "Michael Rodriguez", "author must identify Michael Rodriguez")
    require(fields.get("license") == "MIT", "license field must be MIT")
    description = fields.get("description", "")
    require(description.startswith("Use when "), "description must start with 'Use when '")
    require(len(description) <= 1024, "description exceeds 1024 characters")
require(len(skill) <= 100_000, "SKILL.md exceeds Hermes' 100,000-character limit")
require("metadata:" in skill and "hermes:" in skill, "Hermes metadata block is missing")
require("references/hermes-vs-upstream.md" in skill, "Hermes/upstream comparison is not linked from SKILL.md")

license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
require("MIT License" in license_text, "LICENSE is not MIT")
require("Copyright (c) 2026 Michael Rodriguez" in license_text, "original copyright notice is missing")

notices = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
require("Copyright (c) 2026 StackBlitz" in notices, "StackBlitz copyright notice is missing")
require("https://github.com/stackblitz/bolt-slides" in notices, "canonical upstream URL is missing")
require("adapted and paraphrased" in notices, "adapted-documentation relationship is not explicit")

pin_pattern = re.compile(r"[0-9a-f]{40}")
pin_sources = [
    ROOT / "README.md",
    ROOT / "THIRD_PARTY_NOTICES.md",
    ROOT / "references/upstream-and-security.md",
    ROOT / "references/hermes-vs-upstream.md",
    ROOT / "scripts/init-bolt-slides.sh",
    ROOT / "scripts/verify-bolt-slides.sh",
]
pins = set()
for path in pin_sources:
    found = set(pin_pattern.findall(path.read_text(encoding="utf-8")))
    require(len(found) == 1, f"{path.relative_to(ROOT)} must contain exactly one upstream pin")
    pins.update(found)
require(len(pins) == 1, f"upstream pin is inconsistent across files: {sorted(pins)}")

for script in (ROOT / "scripts").glob("*.sh"):
    mode = script.stat().st_mode
    require(bool(mode & stat.S_IXUSR), f"script is not executable: {script.relative_to(ROOT)}")
    require(script.read_text(encoding="utf-8").startswith("#!/usr/bin/env bash\n"), f"invalid Bash shebang: {script.relative_to(ROOT)}")

private_patterns = {
    "local Linux home path": re.compile(r"/home/creamike", re.IGNORECASE),
    "personal email": re.compile(r"mikerodriguez2324@gmail\.com", re.IGNORECASE),
    "private product example": re.compile(r"BenchQC", re.IGNORECASE),
    "incorrect upstream domain": re.compile(r"bolts\.nu", re.IGNORECASE),
}
secret_patterns = {
    "AWS access key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "private key": re.compile(r"BEGIN (?:RSA|OPENSSH|EC|DSA) PRIVATE KEY"),
    "GitHub token": re.compile(r"gh[pousr]_[A-Za-z0-9]{20,}"),
    "OpenAI-style secret": re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
}
for path in ROOT.rglob("*"):
    if not path.is_file() or ".git" in path.parts:
        continue
    if path.resolve() == Path(__file__).resolve():
        # This validator necessarily contains the deny-list strings it enforces.
        continue
    data = path.read_bytes()
    if b"\x00" in data:
        continue
    try:
        content = data.decode("utf-8")
    except UnicodeDecodeError:
        continue
    require("\r\n" not in content, f"CRLF line endings found: {path.relative_to(ROOT)}")
    for label, pattern in private_patterns.items():
        require(not pattern.search(content), f"{label} found in {path.relative_to(ROOT)}")
    for label, pattern in secret_patterns.items():
        require(not pattern.search(content), f"possible {label} found in {path.relative_to(ROOT)}")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
for phrase in [
    "independent community integration",
    "not an official StackBlitz or Bolt product",
    "Why not just use the bundled Bolt skill?",
    "Hermes Agent",
    "hermes skills list",
]:
    require(phrase in readme, f"README missing required disclosure or verification guidance: {phrase}")

workflow = (ROOT / ".github/workflows/validate.yml").read_text(encoding="utf-8")
require(workflow.count("persist-credentials: false") == 2, "both CI checkouts must disable persisted credentials")
require("macos-latest" in workflow and "ubuntu-latest" in workflow, "CI must exercise Linux and macOS")
require(not re.search(r"uses:\s+[^\s]+@v\d", workflow), "GitHub Actions must be pinned to immutable commit SHAs")

if errors:
    print("VALIDATION FAILED", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    sys.exit(1)

print(f"PASS: validated public skill package at {ROOT}")
