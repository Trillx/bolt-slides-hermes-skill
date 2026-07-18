# Changelog

All notable changes to this project are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.2] - 2026-07-18

### Security

- Reject contradictory duplicate provenance fields and non-regular engine entries.
- Scan Vite environment/configuration inputs and built `dist/` assets for likely browser-delivered secrets.
- Refuse destination races with a shared non-nesting atomic directory publication helper.

### Fixed

- Exercise Vite `--strictPort` with a non-HTTP TCP collision fixture.
- Document complete-package installation, installer-based updates, and all executable prerequisites accurately.

## [1.0.1] - 2026-07-18

### Fixed

- GitHub Actions browser capture on isolated Ubuntu runners with an explicit, warned CI-only sandbox override.
- Deterministic port-collision fixture readiness on Linux and macOS.
- Manual local-skill verification guidance for current Hermes CLI behavior.
- GitHub Actions upgraded to immutable v6 action commits using the Node.js 24 action runtime.

## [1.0.0] - 2026-07-18

### Added

- Hermes-native skill for evidence-first Bolt Slides authoring.
- Pinned initialization from reviewed StackBlitz Bolt Slides source.
- Engine and dependency integrity locks.
- Starter-content, concealed-trigger, and browser-secret checks.
- TypeScript, production-build, and dependency-audit verification.
- Chromium screenshot capture with explicit artifact verification.
- Snap Chromium writable-directory staging.
- Evidence brief, component catalog, visual-QA guide, and security/update guidance.
- Public licensing, attribution, contribution, and security documentation.
- Automated metadata, script, negative-path, and end-to-end validation.
- Transactional initialization, installation, and screenshot publication.
- Removal of conflicting upstream project-agent guidance from generated Hermes projects.
- Exact provenance and complete engine file-inventory verification.
- Symlink-safe, non-echoing browser-source secret scanning.
- Clean `node_modules` reinstalls before project tool execution.
- Linux/macOS CI, strict-port production-preview capture, PNG validation, and adversarial regression tests.
