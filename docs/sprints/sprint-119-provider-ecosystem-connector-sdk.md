# Sprint 119 — Provider Ecosystem & Connector SDK

Status: ACTIVE

Canonical contract: `sprint_119.json`

Entry evidence: `docs/planning/v1.3/sprint_119_entry_gate.json`

Execution boundary: local, permissioned, test-gated work only. The authorized
GitHub App certification overlay does not authorize public publication, secret
handling, or claims for other providers.

| Step | Title | Status | Evidence / next action |
|---|---|---|---|
| 119.1 | Sprint Entry Gate | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_entry_gate.json`; begin 119.2 |
| 119.2 | Connector SDK Charter | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_connector_sdk_charter.json`; external execution and publication remain deferred; begin 119.3 |
| 119.3 | Connector Trust Model | PENDING | Define trust tiers, permission defaults, review, visibility, support, and revocation |
| 119.4 | Manifest Schema v1 | PENDING | Define typed manifest validation and forbidden-field diagnostics |
| 119.5 | Connector Identity & Stable IDs | PENDING | Define connector, publisher, package, installation, account, and connection IDs |
| 119.6 | Capability Interface Foundation | PENDING | Define discovery, execution, cancellation, health, usage, errors, and lifecycle |
| 119.7 | Authentication Broker | PENDING | Define OAuth/OIDC, credential references, redirects, refresh, reauth, and revoke |
| 119.8 | Secret Reference API | PENDING | Define opaque secret operations, rotation, deletion, redaction, and reauth |
| 119.9 | Brokered HTTP Client | PENDING | Define allowlists, TLS, redirects, headers, timeouts, cancellation, audit, and limits |
| 119.10 | Rate Limit & Resilience Contract | PENDING | Define retry-after, backoff, jitter, circuit breaker, idempotency, concurrency, and health |
| 119.11 | Async Job & Event Contract | PENDING | Define long-running jobs, progress, cancellation, resume, durability, ordering, and deduplication |
| 119.12 | Storage Connector Interface | PENDING | Define roots, listing, metadata, transfer, delta, delete, health, and permissions |
| 119.13 | Quota & Usage Interface | PENDING | Define values, units, periods, freshness, source, estimates, and availability |
| 119.14 | AI Connector Interface | PENDING | Define models, modalities, execution, streaming, cancellation, usage, cost, destination, and health |
| 119.15 | Developer Connector Interface | PENDING | Define organizations, workspaces, resources, read/write scopes, limits, and audit |
| 119.16 | Creative Connector Interface | PENDING | Define assets, metadata, rights, attribution, import, export, transformations, and health |
| 119.17 | Payment Connector Interface | PENDING | Define checkout, portal, payment tokens, invoices, refunds, region/currency, and errors |
| 119.18 | Webhook & Billing Event Contract | PENDING | Define signatures, replay protection, idempotency, ordering, retry, reconciliation, and audit |
| 119.19 | Account Center UI Extension Slots | PENDING | Define provider, connection, settings, usage, health, and action slots |
| 119.20 | Icon & Brand Asset Contract | PENDING | Define icon source, permission, version, themes, fallback, and accessible name |
| 119.21 | Typed Settings Schema | PENDING | Define typed values, validation, defaults, secret refs, dependencies, visibility, and migration |
| 119.22 | Permission Declaration & Consent | PENDING | Define purpose, data categories, destination, duration, revocation, and least privilege |
| 119.23 | Brokered Data Access | PENDING | Define account, project, novel, character, and workspace data boundaries |
| 119.24 | Novel–Character Boundary Enforcement | PENDING | Enforce default-deny separation between novel and character data |
| 119.25 | Sandbox Runtime | PENDING | Define connector isolation, resource limits, lifecycle, and failure containment |
| 119.26 | Network Policy Enforcement | PENDING | Enforce declared destinations, TLS, proxying, and network denial by default |
| 119.27 | Filesystem & Process Restrictions | PENDING | Enforce filesystem roots, process restrictions, and denial diagnostics |
| 119.28 | Telemetry & Privacy Contract | PENDING | Define opt-in telemetry, minimization, retention, destination, and deletion |
| 119.29 | Logging, Diagnostics & Redaction | PENDING | Define structured diagnostics, correlation, error reporting, and secret redaction |
| 119.30 | Local Development Mode | PENDING | Define safe local development, mocks, fixtures, and no-production-claim boundaries |
| 119.31 | Connector Scaffolding Tool | PENDING | Define generated package layout, manifest, tests, and safety defaults |
| 119.32 | Mock Services & Fixtures | PENDING | Define deterministic mock identity, storage, AI, and webhook/payment services |
| 119.33 | Contract Test Runner | PENDING | Define reusable connector contract suites and failure reporting |
| 119.34 | End-to-End Connector Harness | PENDING | Define connect, use, refresh, error, reauth, disconnect, and cleanup coverage |
| 119.35 | Certification Automation | PENDING | Define reproducible certification checks, evidence, and fail-closed output |
| 119.36 | Signed Package Format | PENDING | Define package identity, signature, verification, expiry, and rejection behavior |
| 119.37 | SDK Versioning & Deprecation | PENDING | Define compatibility, deprecation, migration, and support windows |
| 119.38 | Connector Catalog Metadata | PENDING | Define catalog metadata, visibility, limitations, support, and update state |
| 119.39 | Install, Update & Rollback | PENDING | Test signature, compatibility, permission diff, migration, rollback, disable, and cleanup |
| 119.40 | Submission & Review Workflow | PENDING | Define submission, automated checks, human review, remediation, approval, rejection, appeal, and publication states |
| 119.41 | Runtime Health & Diagnostics | PENDING | Expose version, health, permissions, latency, errors, limits, jobs, cache, and support action |
| 119.42 | Kill Switch, Suspension & Revocation | PENDING | Define version/capability disable, suspension, token revoke, queue stop, notification, and recovery |
| 119.43 | SDK Documentation | PENDING | Document quickstart, manifest, capabilities, permissions, UI, testing, packaging, certification, security, privacy, and migration |
| 119.44 | Reference Connectors | PENDING | Build generic mock identity, storage, AI, and webhook/payment connectors |
| 119.45 | Connector Migration & Compatibility | PENDING | Test SDK upgrades, manifest migrations, permission changes, settings migration, rollback, and data preservation |
| 119.46 | Accessibility & Localization Gate | PENDING | Validate keyboard, screen reader, scaling, status text, errors, icons, locales, and RTL |
| 119.47 | SDK Security & Privacy Gate | PENDING | Test sandbox, permissions, network, secrets, logs, supply chain, signatures, and telemetry |
| 119.48 | Controlled SDK Pilot | PENDING | Require explicit consent, support, withdrawal, incident handling, and evidence without invented participants |
| 119.49 | Alpha Acceptance Gate | PENDING | Evaluate isolation, tooling, certification, docs, pilot evidence, security, and privacy |
| 119.50 | Sprint Closure | PENDING | Record alpha decision or an evidence-backed deferral |
