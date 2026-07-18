# Contributing

Thank you for improving the Hermes Bolt Slides skill.

## Scope

Good contributions include:

- Hermes-specific workflow improvements.
- Portability and error-reporting fixes.
- Tests for real failure modes.
- Accessibility, responsive-QA, and evidence-quality guidance.
- Documentation corrections.
- Carefully reviewed updates to the pinned Bolt Slides revision.

Changes to the Bolt Slides presentation engine belong upstream unless this repository's integration specifically requires them. Open engine and component changes at <https://github.com/stackblitz/bolt-slides> first when appropriate.

## Development

```bash
git clone https://github.com/Trillx/bolt-slides-hermes-skill.git
cd bolt-slides-hermes-skill
bash tests/validate.sh
```

The full end-to-end test downloads the reviewed upstream revision and installs npm packages:

```bash
BOLT_SLIDES_RUN_E2E=1 bash tests/validate.sh
```

## Pull requests

1. Keep changes focused.
2. Add or update tests for behavior changes.
3. Run `bash tests/validate.sh`.
4. Run the full end-to-end test for initializer, verification, capture, or pin changes.
5. Update `CHANGELOG.md` for user-visible changes.
6. Preserve `LICENSE` and `THIRD_PARTY_NOTICES.md`.
7. Do not add secrets, personal paths, private URLs, or proprietary source material.

## Updating the upstream pin

A pin update is a dependency and behavior upgrade, not routine housekeeping.

1. Review the upstream diff from the old pin to the candidate.
2. Inspect `.bolt/skills/slides/SKILL.md`, all `AGENTS.md`/`CLAUDE.md`/`.cursorrules`/Copilot instruction files, package manifests, engine, components, styles, Vite configuration, and CI.
3. Search for concealed triggers, network calls, credential handling, new services, and dependency changes.
4. Run upstream type-check, build, production audit, and browser tests.
5. Confirm that initializer removal/rejection of project-agent instructions still matches the candidate tree.
6. Update the pin in the initializer, verifier, tests, README, notices, and security reference together.
7. Run the full end-to-end test on Linux and macOS.
8. Include the review evidence in the pull request.

## Style

- Shell scripts target Bash and must pass `bash -n` and ShellCheck.
- Quote paths and variables.
- Fail closed on integrity, build, audit, or missing-artifact errors.
- Error messages must name the failed gate and a useful remediation.
- Documentation should separate verified facts from recommendations.
- Do not claim affiliation with or endorsement by StackBlitz.

## Conduct

Be respectful, specific, evidence-driven, and constructive. Harassment, discriminatory behavior, doxxing, credential disclosure, and knowingly deceptive contributions are not accepted.
