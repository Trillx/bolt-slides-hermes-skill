# Security Policy

## Supported versions

Security fixes are applied to the latest release on the `main` branch. Older release archives may not receive backports.

## Reporting a vulnerability

Use GitHub's private vulnerability-reporting or Security Advisory feature for this repository. Do not publish exploit details, credentials, private deck data, or proof-of-concept secrets in a public issue.

Include:

- A concise description of the impact.
- Affected files and versions.
- Reproduction steps using non-sensitive test data.
- Suggested remediation, if known.

## Security boundaries

This repository is a local Hermes workflow and set of shell utilities. It does not operate a hosted service and does not collect analytics.

The initializer performs network and package-manager operations:

1. Clones `https://github.com/stackblitz/bolt-slides.git`.
2. Checks out one hard-coded Git commit.
3. Confirms the actual commit matches the reviewed pin.
4. Installs the upstream lockfile with `npm ci`.
5. Type-checks, builds, and audits production dependencies.

A Git commit pin improves reproducibility but is not a complete cryptographic supply-chain guarantee. Review upstream changes before updating the pin.

## Deck-data rules

A generated deck runs in a viewer's browser. Browser-delivered code and data are inspectable.

Never place these in a deck:

- API keys, access tokens, or session credentials.
- Database passwords or connection strings.
- Private MCP, ERP, HR, or internal-service endpoints.
- Unredacted customer, employee, health, financial, export-controlled, or regulated data.

Use sanitized snapshots for sensitive systems. If live data is necessary, place secrets behind a narrow server-side API with authentication, authorization, rate limiting, and explicit CORS.

## Development server

Vite is development infrastructure. Bind it to localhost. Production delivery must use the static `dist/` output or an intentionally secured application server.

## Dependency policy

- Preserve lockfiles and use `npm ci`.
- Do not run `npm audit fix --force` automatically.
- Fail releases when production dependency auditing fails.
- Evaluate development-only advisories separately, documenting whether they are reachable in the supported local workflow.
- Review React, Vite, Framer Motion, and TypeScript major upgrades individually.
