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
| 119.3 | Connector Trust Model | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_connector_trust_model.json`; external certification and publication remain deferred; begin 119.4 |
| 119.4 | Manifest Schema v1 | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_manifest_schema.json`; 10 focused tests, release suite 4,226 PASS, full analyzer clean, Windows debug build PASS; external gates remain deferred; begin 119.5 |
| 119.5 | Connector Identity & Stable IDs | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_connector_identity.json`; 10 focused tests, release suite 4,236 PASS, full analyzer clean, Windows debug build PASS; external certification and provider evidence remain deferred; begin 119.6 |
| 119.6 | Capability Interface Foundation | VERIFIED-LOCAL | Commit `7e591ec`; `docs/planning/v1.3/sprint_119_capability_interface.json`, `lib/features/world_logic/domain/sprint_119_capability_interface.dart`, and `test/release/sprint_119_capability_interface_test.dart`; focused 10/10 PASS, `flutter analyze --no-pub` PASS, `flutter test --no-pub test/core` PASS, full `flutter test --no-pub` 11,337 PASS / 4 SKIP, Windows debug build PASS; working-tree test EOL CRLF 184/184; provider execution, health, usage, certification, signing, release, and publication remain DEFERRED-EXTERNAL; begin 119.7 only after pointer repair is verified |
| 119.7 | Authentication Broker | VERIFIED-LOCAL | `docs/planning/v1.3/sprint_119_authentication_broker.json`, `lib/features/account/domain/sprint_119_authentication_broker.dart`, and `test/release/sprint_119_authentication_broker_test.dart`; focused 15/15 PASS, `flutter analyze` PASS, Core regression PASS, release suite PASS, `git diff --check` PASS; provider execution, token issuance, interactive session, and external certification remain DEFERRED-EXTERNAL; begin 119.8 |
| 119.8 | Secret Reference API | VERIFIED-LOCAL | Commit `7f3987f`; `docs/planning/v1.3/sprint_119_secret_reference_api.json`, `lib/features/account/domain/sprint_119_secret_reference_api.dart`, and `test/release/sprint_119_secret_reference_api_test.dart`; focused 5/5 PASS, Core regression 734/734 PASS, `flutter analyze --no-pub` PASS, Windows debug build PASS; local opaque-reference contract only, vault/provider integration and external evidence remain DEFERRED-EXTERNAL; begin 119.9 |
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

### 2026-10-12 - Stability gate recheck COMPLETE (5/5 hijau) - state write menunggu approval operator (cron `b0c2c7d744d9`)

- Scope: quality gate only (governance rule 4). Tidak ada pekerjaan fitur roadmap; `next_step` tetap `119.5`.
- Semua lima required checks diukur ulang pada tree ini (HEAD `4c0e097`, ahead 199):
  1. `dart run tool/roadmap_guard.dart` -> PASS exit 0 (recommended `119.5`, last_resolved `119.4`, canonical `ecc66b4719f4784eb6c73d6f9daea5cf442d87b94a731841e565ac6ff49a0ec4`).
  2. `flutter analyze` -> PASS exit 0, `No issues found!`.
  3. focused Core regression `flutter test test/core` -> 715/715 PASS exit 0.
  4. `full flutter test` -> 5 shard deterministik. S1_core +715, S2_featA +2170 ~2, S4_release +4236, S5_misc +477 ~1 exit 0; S3 awal mencapai +3675 ~1 lalu exit 1 karena satu timeout beban 10 menit (bukan assertion failure) pada `test/features/workspace/empty_workspace_navigation_test.dart`. S3 dipecah ulang: sisa S3 +3634 ~1 exit 0, test fokus tersebut 3/3 PASS, dan seluruh dir `test/features/workspace` 42/42 PASS; hasil komposit tidak memiliki failure assertion. Log awal `cache/_full_suite_shards_20261012k.log` / `.results` / `_shard_full_suite_20261012k.sh`; rerun S3 `cache/_full_suite_s3_remaining_20261012l.log`; core `cache/_core_regression_20261012l.log`.
  5. `flutter build windows --debug --no-pub` -> PASS exit 0 (464.2s).
- Dua keluarga merah sebelumnya SUDAH hijau berkat commit operator `2e2d29b` ("isolate authorized connector overlay"): keluarga overlay AUTHORIZED_LOCAL (14 gate + 118.1 entry gate + 118.46 closure) dan keluarga re-sign rilis (113.38 x2 / 113.39 / 113.40 / 117.43).
- BATAS: penulisan `.hermes/ROADMAP_STATE.json` (`stability_gate.status` `RECHECK_REQUIRED` -> `PASS`) DITOLAK oleh protected-file guard (tidak ada approver interaktif). Field itu BELUM ter-update; gate flip menunggu approval operator. Precedent: `6114554`. Feature step `119.5` TIDAK dimulai.
- Claim boundary: local evidence only; no release/tag/publication/push; `execution_authorized=false`; `approval_state=PENDING_OPERATOR`. Snapshot sebelum mutasi: `~/AppData/Local/hermes/backups/qg_stability_gate_20261012_1508/`.

### 2026-10-13 - Stability gate recheck + flip `stability_gate` -> PASS via gateway (cron `b0c2c7d744d9`)

- Scope: quality gate only (governance rule 4). Tidak ada pekerjaan fitur roadmap; `next_step` tetap `119.8`.
- HEAD `b519e4c` (ahead 17) sudah memuat perbaikan operator: repoint SDK `3.47.6 -> 3.47.7` (`640ae99`/`79e17a5`) dan re-sign + regenerasi kandidat rc.1 (`b519e4c`) sehingga keluarga rilis 113.38/113.39/113.40 hijau kembali.
- Enam check battery pada HEAD `b519e4c`:
  1. `dart run tool/roadmap_guard.dart` -> PASS exit 0.
  2. `flutter analyze --no-pub` -> PASS exit 0, `No issues found!`.
  3. focused Core regression `flutter test --no-pub test/core` -> 734/734 PASS exit 0.
  4. `flutter build windows --debug --no-pub` -> PASS exit 0.
  5. `full flutter test` (7 shard deterministik) -> PASS exit 0 pada pass kedua (0 fail, 7 blok `All tests passed!`).
  6. flaky retest `test/features/project_resilience/session_lock_release_race_test.dart` -> rerun 5x fokus, semua PASS exit 0.
- FLAKY (jujur): pass PERTAMA full suite + satu burst rerun fokus menunjukkan gagal non-deterministik di `session_lock_release_race_test.dart:63` (`Expected both-ok / Actual PathAccessException errno 32/5` Windows file-lock): `root.delete(recursive:true)` milik test balapan dengan `session.close()` (defect TEST pre-existing dari `75e1a3a`, produk tidak beregresi; test 1 di file yang sama selalu lulus). Karena flaky terdeteksi, `stability_gate.evidence.checks.flaky_retest.zero_flaky_detected=false` dengan `reruns` 5x lulus.
- FLIP: `stability_gate.status` `RECHECK_REQUIRED -> PASS` lewat SATU-SATUNYA jalur resmi `dart run tool/roadmap_guard.dart --stability-gateway --evidence cache/_stability_20261013i_evidence.json` (fail-closed: `head_sha==HEAD`, 6 check PASS, 0 proses toolchain lain, scheduler in-scope paused sementara - cron mem-pause lalu me-resume `6cad4c19796e` dan `b0c2c7d744d9`). Evidence tersimpan di `stability_gate.evidence` (`applied_by=stability-gateway`, `applied_at=2026-10-13T17:02:37Z`).
- Claim boundary: local evidence only; no release/tag/publication/push; `execution_authorized=false`; `approval_state=PENDING_OPERATOR`. Snapshot pra-mutasi: `~/AppData/Local/hermes/backups/qg_stability_gate_20261013_2305/`.
