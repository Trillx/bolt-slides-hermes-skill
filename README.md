# Hermes Bolt Slides Skill

[![Validate](https://github.com/Trillx/bolt-slides-hermes-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/Trillx/bolt-slides-hermes-skill/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
  <img src="assets/hermes-agent-girl-bolt-slides.png" alt="Hermes Agent Girl harnessing the Bolt Slides runtime" width="900">
</p>

<p align="center"><strong>From evidence to a verified React presentation—built, checked, and delivered by Hermes Agent.</strong></p>

An evidence-first, verification-heavy **Hermes Agent skill** for creating responsive React presentations with [Bolt Slides](https://github.com/stackblitz/bolt-slides) by StackBlitz.

> [!IMPORTANT]
> This is an independent community integration for Hermes Agent. It is not an official StackBlitz or Bolt product, and StackBlitz does not endorse or maintain it.

## Install it by asking Hermes

Use the copy button on this block, paste it into a Hermes chat, and send:

```text
Install the Bolt Slides skill for my active Hermes Agent profile from:
https://github.com/Trillx/bolt-slides-hermes-skill

Inspect the repository and my current skills before changing anything. If a
bolt-slides skill already exists, stop and ask before replacing it. Otherwise:
1. Clone the complete repository into skills/productivity/bolt-slides.
2. Run tests/validate.sh.
3. Confirm hermes skills list shows bolt-slides enabled.
4. Remind me to start a new Hermes session so the skill is discovered.
```

That is the easiest installation path. Hermes can inspect the package, install the complete repository, run its validation, and report exactly what changed. Prefer commands? The full manual installation and lifecycle instructions are below.

## What this is

Bolt Slides provides the presentation runtime: React components, navigation, presenter mode, annotations, responsive layouts, and the web-app foundation.

This repository provides the Hermes workflow around that runtime:

- Hermes skill metadata and trigger guidance, discoverable after installation and a new session.
- Evidence-first research and anti-fabrication rules.
- A reviewed, pinned upstream revision.
- Engine and dependency checksum locks.
- Starter-content and concealed-trigger rejection.
- Mechanical verification, dependency audit, and screenshot automation.
- Wide and narrow viewport QA requirements.
- Licensing, security, delivery, and upstream-update procedures.

It does **not** vendor, replace, or maintain a separate fork of the Bolt Slides engine. New deck projects are initialized from a pinned, reviewed upstream commit and preserve StackBlitz's MIT license.

## Why not just use the bundled Bolt skill?

The upstream repository contains `.bolt/skills/slides/SKILL.md`. At the reviewed commit, it does **not** contain an `AGENTS.md` file. If a future Bolt workspace or another checkout contains `AGENTS.md`, that file is directory-scoped agent guidance whose effect depends on the coding agent's instruction-loading and precedence rules; it is not automatically registered as a reusable Hermes skill.

| Upstream Bolt Slides workflow | This Hermes skill |
|---|---|
| Skill lives inside one Bolt Slides checkout under `.bolt/skills/` | Skill installs in Hermes and can be invoked from a new session after discovery |
| Optimized for an agent already operating inside the deck repository | Creates a clean, pinned deck project before authoring |
| Remains at whichever repository revision the user opened; it has no separate reviewed initialization boundary | Pins a reviewed commit and verifies that exact provenance later |
| Primarily authoring and design guidance | Adds research, provenance, security, verification, capture, and delivery gates |
| Assumes the project context supplies the runtime | Explicitly checks Node/npm/Git, installs from the lockfile, type-checks, builds, and audits |
| Upstream instructions may change with the repository | Updates are treated like dependency upgrades and reviewed before changing the pin |
| Useful with Bolt, Claude Code, Codex, Cursor, and other agents | Intentionally optimized and packaged only for Hermes Agent |

This is not a claim that Hermes is universally better than Bolt or that this repository supersedes Bolt Slides. It is a safer and more ergonomic **Hermes integration** because it matches Hermes skill discovery, tool use, linked references, artifact verification, and notification conventions.

Read [`references/hermes-vs-upstream.md`](references/hermes-vs-upstream.md) for the detailed architecture comparison.

## Requirements

### Skill runtime

- Hermes Agent
- Git
- Node.js 18 or newer
- npm
- `tar`
- `cmp`
- One SHA-256 utility: `sha256sum` (Linux) or `shasum` (macOS)
- Python 3 for repository validation and screenshot assertions

### Optional visual capture

- `curl`
- Chromium, Chromium Browser, Google Chrome, or Google Chrome Stable

Native Windows PowerShell is not currently supported by the shell scripts. Use WSL. Linux is tested locally; Linux and macOS are exercised in CI.

## Manual installation and lifecycle

### Clone directly into Hermes

```bash
mkdir -p "${HERMES_HOME:-$HOME/.hermes}/skills/productivity"
git clone https://github.com/Trillx/bolt-slides-hermes-skill.git \
  "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides"
```

Verify the complete installation, then start a new Hermes session so the skill loader discovers it:

```bash
hermes skills list
```

Confirm that `bolt-slides` appears as an enabled local skill. The `hermes skills inspect` command currently resolves install-source identifiers rather than every manually cloned local skill, so it is not a reliable verification command for this installation method.

To force-load it in a CLI session instead of relying on metadata routing:

```bash
hermes -s bolt-slides
```

### Clone elsewhere, then install

```bash
git clone https://github.com/Trillx/bolt-slides-hermes-skill.git
cd bolt-slides-hermes-skill
bash scripts/install-hermes-skill.sh
```

The installer refuses to overwrite an existing installation unless `--force` is provided. Forced installs first stage and validate the replacement, then retain the previous installation in a uniquely named backup.

Do not use `hermes skills install` with this repository's raw `SKILL.md` URL. Hermes can fetch explicitly linked support files for compatible skills, but this package also depends on executable shell/Python assets, nested helper files, file modes, and repository-level validation. Use one of the complete-repository installation methods above.

### Update or remove

For a direct Git clone, review changes and fast-forward the installed checkout:

```bash
git -C "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides" fetch --tags origin
git -C "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides" pull --ff-only
bash "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides/tests/validate.sh"
```

If you cloned elsewhere and used `install-hermes-skill.sh`, update and validate that source checkout, then reinstall transactionally:

```bash
git -C ./bolt-slides-hermes-skill pull --ff-only
bash ./bolt-slides-hermes-skill/tests/validate.sh
bash ./bolt-slides-hermes-skill/scripts/install-hermes-skill.sh --force
```

The installer prints the unique backup path retained for the previous installation.

To remove a manual installation, first confirm the displayed path, then move or delete that `bolt-slides` directory and start a new session. Preserve any local changes or backups before removal.

## Use

Ask Hermes naturally:

```text
Create an interactive Bolt Slides capability deck from these verified source files. Build the evidence contract first, cite every factual claim, and test wide and mobile layouts.
```

Or initialize a deck manually:

```bash
bash "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides/scripts/init-bolt-slides.sh" ./my-deck
cd ./my-deck
```

After replacing the starter in `src/App.tsx`, theming the deck, and updating `index.html`:

```bash
bash "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides/scripts/verify-bolt-slides.sh" .
```

Optional screenshots:

```bash
bash "${HERMES_HOME:-$HOME/.hermes}/skills/productivity/bolt-slides/scripts/capture-slides.sh" \
  . 12 ./qa-wide 1440 900
```

## What verification checks

- Provenance contains exactly one canonical value for every required field and matches the reviewed upstream repository and commit.
- The complete `src/deck/` regular-file inventory and contents match the initialized engine lock; symlinks and special entries are rejected.
- Dependency manifests still match the initialized lock unless explicitly reviewed.
- Starter demo, placeholder title, and prohibited trigger content are absent.
- Likely secrets are absent from source, Vite environment/configuration files, and the final production bundle; sensitive `VITE_` variable names are rejected because their values are browser-visible.
- TypeScript type-check succeeds.
- Production build succeeds and creates `dist/index.html`.
- Production dependency audit passes.
- Screenshot commands use the production preview and transactionally publish real, non-empty files rather than trusting Chromium's exit code.

Mechanical verification does not replace visual review. Every deck still requires pixel inspection, browser-console review, interaction tests, and at least one fix-and-reverify cycle.

## Repository structure

```text
SKILL.md                          Hermes skill instructions
assets/hermes-agent-girl-bolt-slides.png  Repository hero artwork
references/                       Deep guidance loaded on demand
templates/deck-brief.md           Evidence and design contract
scripts/init-bolt-slides.sh       Pinned project initializer
scripts/verify-bolt-slides.sh     Mechanical quality gates
scripts/capture-slides.sh         Wide/mobile screenshot automation
scripts/install-hermes-skill.sh   Safe local installer
scripts/lib/common.sh              Shared atomic publication primitive
tests/                            Metadata and end-to-end tests
.github/workflows/validate.yml    Continuous validation
```

## Upstream credit

Bolt Slides is created and maintained by StackBlitz:

- Repository: <https://github.com/stackblitz/bolt-slides>
- Project license: MIT
- Reviewed commit: `9ad90e6abf93818ea552ae49bb731556f7eb2b0a`

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) and [`references/upstream-and-security.md`](references/upstream-and-security.md).

## Security

Decks execute in the viewer's browser. Never bundle API keys, bearer tokens, database credentials, private MCP endpoints, or unredacted confidential exports. Read [`SECURITY.md`](SECURITY.md) before publishing a deck or changing the upstream pin.

## Contributing

Bug reports, focused improvements, documentation corrections, portability fixes, and carefully reviewed upstream-pin updates are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

Original material in this repository is licensed under the [MIT License](LICENSE).

Bolt Slides remains copyright StackBlitz and is distributed under its own MIT License. Required notices are preserved in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Generated projects preserve the upstream `LICENSE` file.
