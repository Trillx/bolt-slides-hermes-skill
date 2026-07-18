# Upstream, Licensing, and Security

## Provenance

Framework:

- Repository: https://github.com/stackblitz/bolt-slides
- License: MIT
- Reviewed pin: `9ad90e6abf93818ea552ae49bb731556f7eb2b0a`
- Reviewed source date: 2026-07-16

The initializer uses the reviewed commit rather than `main`. This prevents silent upstream changes from modifying future decks.

## Attribution

Bolt Slides is copyright StackBlitz and distributed under the MIT License. Preserve the upstream `LICENSE` file in generated projects. Component/API summaries and authoring concepts in this workflow include adapted and paraphrased upstream guidance, while the Hermes orchestration and executable gates are original integration work. This is not an official StackBlitz product.

## Review findings incorporated here

The reviewed upstream skill had strong visual and authoring guidance, but it also contained a concealed exact-phrase trigger that silently preserved the fictional demo deck. The initializer deliberately removes the upstream `.bolt/` agent guidance from generated Hermes projects, and verification rejects prohibited trigger content. At the reviewed pin, no `AGENTS.md` exists.

The reviewed repository built and type-checked successfully. At review time, production dependencies passed `npm audit --omit=dev`; the Vite 5 development toolchain reported one moderate and one high development-only vulnerability through these advisories:

- `GHSA-67mh-4wv8-2f99`
- `GHSA-4w7w-66w2-5vf9`
- `GHSA-v6wh-96g9-6wx3`
- `GHSA-fx2h-pf6j-xcff`

The test suite allowlists only those reviewed advisory URLs and fails on newly reported advisories. Treat Vite as localhost-only development/preview infrastructure, do not browse untrusted sites while it is running, and deploy only the static `dist/` output. The capture script starts a short-lived localhost production preview and terminates it after capture.

## Updating the upstream pin

Do not update the pin merely because `main` moved. Treat an update like a dependency upgrade.

1. Clone the candidate revision into a temporary directory.
2. Compare:
   - `.bolt/skills/slides/SKILL.md`
   - Any `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, or `.github/copilot-instructions.md`
   - `package.json` and `package-lock.json`
   - `src/deck/`
   - `src/components/`
   - `src/styles/`
   - `vite.config.ts`
   - CI workflow
3. Search the candidate instructions for:
   - Hidden phrases or secret modes.
   - Instructions to conceal behavior.
   - Network calls or credential handling.
   - New external services.
   - New dependencies.
   - Engine modifications that change presenter, annotation, or local-storage behavior.
4. Run:

```bash
npm ci
npx tsc --noEmit
npm run build
npm audit --omit=dev
npm audit
```

5. Exercise the browser controls and both wide/narrow layouts.
6. Confirm that the initializer still removes all bundled project-agent guidance and that instruction precedence remains unambiguous.
7. Update the pin in `scripts/init-bolt-slides.sh`, `scripts/verify-bolt-slides.sh`, and the public documentation together.
8. Re-run the skill's end-to-end test using a newly initialized project on Linux and macOS.

## Dependency policy

- Keep the lockfile.
- Use `npm ci` for deterministic verification.
- Do not run `npm audit fix --force` blindly; it may perform major upgrades.
- Review major React, Vite, Framer Motion, and TypeScript upgrades individually.
- Production deployments should contain static build output, not `node_modules` or a Vite development process.

## Runtime data and privacy

The reviewed engine uses:

- URL hashes for slide deep links.
- `BroadcastChannel` for same-origin audience/presenter tab synchronization.
- `localStorage` for presenter-note overrides.
- In-memory per-slide annotation state in the reviewed revision.

These mechanisms do not create multi-user collaboration or server persistence by themselves. Never promise cross-device synchronization without adding and testing a backend.

## Live-data safety

A React presentation runs in the viewer's browser. Anything bundled or delivered to that browser is inspectable.

- Never put API keys, bearer tokens, database credentials, or private MCP endpoints in the deck.
- Prefer sanitized snapshots for internal ERP/HR/financial data.
- If live data is needed, place secrets behind a server-side API with narrow authorization and explicit CORS.
- Redact personal and confidential information before publishing.
- Apply real hosting authentication to confidential decks.

## Engine lock

The initializer writes `.bolt-slides-engine.sha256` for the complete `src/deck/` file inventory and contents. Verification regenerates a canonical manifest and rejects additions, removals, or content changes. This is not a cryptographic supply-chain guarantee; it is a practical change detector tied to the exact pinned provenance check.

When an engine change is explicitly required:

1. Document the reason.
2. Review the exact diff.
3. Test every presentation control.
4. For a reviewed one-time verification, run `ALLOW_ENGINE_CHANGES=1 bash "$BOLT_SLIDES_SKILL_DIR/scripts/verify-bolt-slides.sh" .`.
5. Regenerate the checksum file only through an explicit, reviewed project process; never rewrite it merely to suppress a gate.
6. Keep the modification and approval record in project source control.

For an approved dependency-manifest change, apply the same discipline and use `ALLOW_DEPENDENCY_CHANGES=1` for the reviewed verification run. Production audit must still pass. Set `BOLT_SLIDES_STRICT_DEV_AUDIT=1` when policy requires every development advisory to be fixed rather than reviewed and allowlisted.
