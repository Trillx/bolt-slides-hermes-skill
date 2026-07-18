#!/usr/bin/env python3
"""Allowlist the reviewed upstream's development-only npm advisories."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

project = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
result = subprocess.run(
    ["npm", "audit", "--json"],
    cwd=project,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    check=False,
)
try:
    audit = json.loads(result.stdout)
except json.JSONDecodeError as exc:
    print(f"FAIL: could not parse npm audit JSON: {exc}", file=sys.stderr)
    print(result.stderr[-1000:], file=sys.stderr)
    sys.exit(1)

allowed = {
    "https://github.com/advisories/GHSA-67mh-4wv8-2f99",
    "https://github.com/advisories/GHSA-4w7w-66w2-5vf9",
    "https://github.com/advisories/GHSA-v6wh-96g9-6wx3",
    "https://github.com/advisories/GHSA-fx2h-pf6j-xcff",
}
found: set[str] = set()
for vulnerability in audit.get("vulnerabilities", {}).values():
    for via in vulnerability.get("via", []):
        if isinstance(via, dict) and via.get("url"):
            found.add(via["url"])

unexpected = found - allowed
if unexpected:
    print("FAIL: unexpected npm development advisories:", file=sys.stderr)
    for url in sorted(unexpected):
        print(f"- {url}", file=sys.stderr)
    sys.exit(1)

metadata = audit.get("metadata", {}).get("vulnerabilities", {})
if metadata.get("critical", 0):
    print("FAIL: critical npm advisory reported", file=sys.stderr)
    sys.exit(1)

if found:
    print("PASS: full npm audit contains only documented development-tool advisories:")
    for url in sorted(found):
        print(f"- {url}")
else:
    print("PASS: full npm audit reports no advisories")
