# QA and Delivery

## Quality gates

A finished deck passes four gates:

1. Evidence and content.
2. Mechanical build.
3. Browser behavior.
4. Visual inspection and handoff.

## 1. Evidence and content audit

For every slide, verify:

- The headline is a specific claim or orientation, not generic filler.
- Each number matches its source exactly, including unit, period, denominator, and rounding.
- Quotes are verbatim and attributed.
- Customer, employee, facility, product, and certification claims are verified.
- Sources are visible in the slide footer/caption or documented in the evidence notes.
- `[DATA NEEDED]` remains only when the user intentionally accepts an incomplete draft.
- No starter names, fictional metrics, or demo copy remain.

For work documents, ask a fresh reviewer to challenge claims rather than merely proofread them.

## 2. Mechanical checks

Run:

```bash
bash "$BOLT_SLIDES_SKILL_DIR/scripts/verify-bolt-slides.sh" .
```

This checks:

- Upstream provenance is present.
- The locked `src/deck/` engine is unchanged.
- Common starter placeholders are absent.
- A real title is present.
- TypeScript passes.
- The production build succeeds.
- Production dependencies pass `npm audit --omit=dev`.

Do not hide a failed check. Fix it or document a user-approved exception.

## 3. Browser behavior matrix

Exercise the app in a browser at both a wide and narrow viewport.

| Area | Verification |
|---|---|
| Navigation | Right/down/space advance; left/up reverse; builds advance before slides |
| Deep links | `/#1`, a middle slide, and the final slide open correctly |
| Sidebar | `S` opens/closes thumbnail rail and selecting a thumbnail navigates |
| Grid | `G` opens/closes overview and selecting a slide navigates |
| Presenter | `P` opens a second tab, notes render, timer runs, slide/build state synchronizes |
| Annotation | `A` tools draw and erase; annotations remain attached while layout changes |
| Fullscreen | `F` enters/exits when browser permits |
| UI | `H` hides chrome; Escape closes overlays/modes |
| Console | No uncaught exceptions, React warnings, failed fetches, or missing assets |
| Reduced motion | OS/browser reduced-motion mode remains usable |

Presenter notes and annotations use browser-local state. Do not claim they synchronize across different audience devices or persist to a server unless the deck has been extended and tested to do so.

## 4. Viewport matrix

At minimum inspect:

- 1440×900 desktop/laptop.
- 1280×720 common screen share/projector.
- 390×844 phone portrait.
- 844×390 phone landscape when mobile viewing matters.

Look for:

- Text clipping at the viewport or container edge.
- Content requiring vertical scrolling.
- Fixed multi-column layouts that should stack.
- Oversized headings producing orphaned words.
- Sources, captions, or speaker UI colliding with body content.
- Low contrast, especially muted text and chart labels.
- Images with incorrect crop/focal point.
- Interactive controls too small for touch.
- Repetitive slide silhouettes.
- Empty areas that make an unbalanced left-aligned block appear accidental.

## Screenshot workflow

If Chromium is installed:

```bash
bash "$BOLT_SLIDES_SKILL_DIR/scripts/capture-slides.sh" . 12 ./qa-wide 1440 900
bash "$BOLT_SLIDES_SKILL_DIR/scripts/capture-slides.sh" . 12 ./qa-mobile 390 844
```

Replace `12` with the deck's actual slide count and choose output directories that do not already contain files. The script starts a localhost-only production preview with strict port binding, verifies a deck-specific readiness marker, captures each `/#N` route, validates every PNG, and publishes the screenshot directory only after the complete set succeeds. Do not trust Chromium's exit code alone: some confined builds can report success even when no screenshot was written. The script handles Snap Chromium by writing through its allowed staging directory and then transactionally publishing verified files to the requested output directory.

If Ubuntu AppArmor blocks Chromium with `No usable sandbox!`, install a path-specific AppArmor profile that grants `userns` to the browser binary. Do not disable the sandbox on a workstation. `BOLT_SLIDES_ALLOW_NO_SANDBOX=1` exists only for already-isolated, ephemeral CI runners or containers and emits a warning when used.

After capture, enumerate the output files and build a contact sheet or inspect every image individually. A log line saying “captured” is not evidence unless the files can be read back.

If Chromium is not available, use the browser tool to navigate and capture screenshots. Do not install a large browser dependency without checking the environment and user preference.

## Fresh-eye review prompt

Give rendered images to a subagent or vision reviewer with this brief:

```text
Review this presentation as a skeptical visual QA reviewer. Assume defects exist.
For every slide, identify clipping, overlap, weak hierarchy, low contrast,
unsupported or ambiguous claims, repetitive layouts, poor responsive behavior,
misleading charts, missing sources, awkward wrapping, and content that appears
AI-generated or generic. Distinguish blocking defects from polish issues.
```

Then fix at least one identified issue and re-render the affected slides. If the first review reports no issues, inspect more critically rather than treating it as proof.

### Vision-tool semantics and fallback

A vision attachment tool may return only a confirmation such as “image loaded into context.” That is not the review result and should not be quoted to the user. After the attachment call, inspect the pixels directly in the next model step and write the findings yourself.

If contact-sheet analysis triggers a model/provider serialization error or produces no usable findings:

1. Do not repeat the identical failing call indefinitely or end the workflow with the raw provider error.
2. Retry with one slide image at a time; smaller inputs isolate malformed-image or multi-image handling issues.
3. If vision still fails, inspect through the browser screenshot flow or delegate the rendered files to a fresh-eye subagent.
4. Continue mechanical/browser checks while visual review is retried.
5. Report the QA blocker plainly only after the alternate paths fail; never treat “image attached” as evidence that visual QA passed.

The durable requirement is verified visual findings, not use of any particular vision tool.

## Production build and local preview

```bash
npm run build
npm run preview -- --host 127.0.0.1
```

Test the preview build, not only the Vite development server.

## Static deployment choices

The production output is `dist/` and can be deployed to:

- Vercel.
- Cloudflare Pages.
- Netlify.
- GitHub Pages.
- An nginx/Caddy static site.
- Local file/server distribution when offline constraints allow it.

Prefer a free or existing host. Do not add a paid service without discussing alternatives.

### Security

- Never expose `npm run dev` to the public internet.
- Put confidential decks behind authenticated hosting; an obscure URL is not access control.
- A client-side password screen is only a deterrent if the protected content ships in the same JavaScript bundle. Use real server/edge authentication for sensitive material.
- Do not embed API secrets in React code, Vite variables, or the built bundle.
- If live data is required, use a scoped backend or pre-generated snapshot. Browser-delivered credentials are public.

## PDF/PPTX companion files

The upstream framework does not provide native PDF or PPTX export.

Possible companion outputs:

1. Print/PDF workflow added and tested for the specific deck.
2. Per-slide screenshots assembled into a flattened PDF.
3. Per-slide screenshots inserted into a flattened PPTX.
4. A separately authored editable PPTX using the `pptx` skill.

State limitations clearly:

- Flattened output preserves appearance, not web interaction.
- Screenshot-based PPTX is not meaningfully editable.
- A separately authored PPTX may require layout differences and separate QA.

## Delivery checklist

- [ ] Source directory is present and readable.
- [ ] `dist/` was generated from the delivered source.
- [ ] Verification command and result are recorded.
- [ ] Evidence/source notes are included.
- [ ] Local run commands are included.
- [ ] Known limitations are explicit.
- [ ] If deployed, the live URL was fetched and navigation exercised.
- [ ] If a companion PDF/PPTX exists, its loss of interactivity is stated.
