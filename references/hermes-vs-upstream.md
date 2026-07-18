# Hermes Integration vs. the Upstream Agent Workflow

## Short answer

This skill does not compete with or replace Bolt Slides. It uses Bolt Slides as the presentation engine and adds the orchestration needed for a reusable Hermes workflow.

The upstream repository is designed to make agents productive **inside one Bolt Slides project**. This repository is designed to let Hermes start from an arbitrary conversation, create a controlled project, gather evidence, author the deck, verify the result, and deliver a tested artifact.

## What exists upstream

At reviewed commit `9ad90e6abf93818ea552ae49bb731556f7eb2b0a`, the canonical upstream repository contains:

```text
.bolt/skills/slides/SKILL.md
src/deck/
src/components/
src/styles/
src/App.tsx
```

It does not contain `AGENTS.md` at that revision.

The bundled `.bolt/skills/slides/SKILL.md` is valuable project-local guidance. It explains the component system, theme, responsive design, and how an agent should turn the demo into a deck. Bolt can load that guidance naturally when the repository is opened in its hosted environment. Other coding agents can read it when operating inside the checkout.

An `AGENTS.md` file, when present in a project, is directory-scoped and may be hierarchical. Its effect and precedence depend on the coding agent that loads it. In Hermes, project rules are loaded from the active working directory and must be reconciled with user/system instructions and loaded skills; a conflict that changes scope or safety requires explicit resolution rather than silent precedence guessing. `AGENTS.md` does not install a global Hermes capability, perform prerequisite discovery, or create a reviewed checkout on its own.

## The lifecycle difference

### Upstream project-local lifecycle

```text
Open or clone Bolt Slides
        ↓
Agent enters that repository
        ↓
Agent reads project-local instructions
        ↓
Agent edits the included demo project
        ↓
User runs or deploys the result
```

### Hermes skill lifecycle

```text
User asks for a presentation from any Hermes conversation
        ↓
Hermes skill routing identifies an interactive web deck
        ↓
Hermes establishes the evidence and delivery contract
        ↓
Initializer checks out the reviewed upstream commit
        ↓
Hermes researches, authors, and themes original content
        ↓
Integrity, placeholder, secret, typecheck, build, and audit gates run
        ↓
Wide/mobile screenshots and browser interactions are inspected
        ↓
Hermes fixes defects, re-verifies, packages, and optionally deploys
```

## Why this is better specifically for Hermes

“Better” here means better integrated with Hermes—not a better presentation engine.

### 1. Global skill discovery

Hermes loads `SKILL.md` metadata from enabled skill directories at session startup. After installation and a new session, this lets the capability route from a normal request even when no Bolt Slides project exists yet; metadata routing remains conditional rather than guaranteed.

The upstream skill stays under `.bolt/skills/` in one project. Hermes should not rely on every future deck already containing and exposing that local file.

### 2. Tool-aware orchestration

Hermes can combine the authoring guidance with its own research, browser, file, deployment, messaging, and verification tools. This workflow tells Hermes when to use those capabilities and what evidence must exist before a claim is allowed into a slide.

### 3. Reproducible initialization

The initializer uses an exact reviewed Git commit rather than silently following the latest `main`. It confirms the checkout, removes the conflicting bundled `.bolt/` agent guidance, preserves the upstream license, records provenance, and snapshots engine/dependency checksums. It also fails if an upstream update unexpectedly introduces `AGENTS.md`-style instruction files.

### 4. Fail-closed quality gates

The upstream guide emphasizes design and composition. This integration adds executable gates:

- Engine-change detection.
- Dependency-manifest change detection.
- Starter and placeholder rejection.
- Concealed-trigger rejection.
- Browser-delivered secret scanning.
- TypeScript type-check.
- Production build.
- Production dependency audit.
- Screenshot artifact verification.

These checks are useful for an autonomous local agent because plausible-looking output is not enough; Hermes must prove that the artifact builds and that claimed screenshots actually exist.

### 5. Evidence discipline

This skill explicitly requires sourced claims, marks unknowns as `[DATA NEEDED]`, and separates research from authoring. That matters when Hermes builds management, financial, manufacturing, technical, or customer-facing decks from connected systems.

### 6. Observable failures and delivery

Hermes may run long, multi-tool workflows. The skill requires exact error reporting, fallback attempts, and confirmed out-of-band notification when the user requests it. A generic project instruction usually does not define that operational contract.

### 7. Delivery beyond Bolt

The deck is a normal Vite/React application. Hermes can package source and `dist/`, deploy to a static host, generate a separate PDF/PPTX snapshot when requested, and verify the delivered URL. Bolt hosting is optional.

## Why not copy the upstream skill verbatim?

A direct copy would create four problems:

1. It would remain optimized for an agent already inside the upstream repository.
2. It would not define Hermes skill triggers, linked references, or tool workflows.
3. It would track upstream behavioral assumptions without a review boundary.
4. It would omit the executable safety and artifact-verification gates in this integration.

The reviewed upstream instructions also contained an exact-phrase condition that preserved the demonstration deck instead of following the normal replacement workflow. Whether intended as a demo shortcut or test hook, that behavior is inappropriate in a general autonomous skill because it is not obvious from the user's ordinary request. This integration does not copy the bundled `.bolt/` skill into initialized projects and actively rejects the phrase pattern during verification.

## When the upstream workflow is the better choice

Use the upstream workflow directly when:

- The user is already working inside Bolt's hosted environment.
- They want the latest upstream behavior rather than a reviewed pin.
- They are manually experimenting with the component showcase.
- They do not need Hermes research, evidence, notification, or delivery automation.

## When the Hermes workflow is the better choice

Use this skill when:

- The request begins in Hermes rather than inside a deck repository.
- Claims must be grounded in files, web research, or connected systems.
- Reproducibility and upstream-change control matter.
- The deck must pass mechanical and visual quality gates.
- The user expects Hermes to package, deploy, verify, and report the final artifact.

## Relationship statement

A precise description is:

> Hermes Bolt Slides Skill is an independent Hermes Agent workflow that initializes and validates the MIT-licensed Bolt Slides engine by StackBlitz. Bolt Slides supplies the web-presentation runtime; this repository supplies Hermes-native research, orchestration, verification, and delivery procedures.
