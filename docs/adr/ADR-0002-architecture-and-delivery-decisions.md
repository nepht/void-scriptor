# ADR-0002 - Architecture and Delivery Decision Record

- Status: Accepted (2026-09-05, Choirudin-authorized decision recorded by Codex)
- Date: 2026-09-05
- Step: Sprint 145.48 Architecture and Delivery Decision Records
- Driver: Choirudin (product/architecture authority), drafted by nephthys cron
- Scope note: this record consolidates decisions ALREADY chosen and enforced
  in the live tree, each with alternatives, tradeoffs, consequences, and
  review triggers. It proposes no new decision. Product, pilot-recruitment,
  and release decisions (Sprint 145.43-145.47, 145.49-145.50) remain with the
  architect. Facts cited below were re-verified against the live tree at
  drafting time (HEAD 33aef69); commit SHAs are quoted from the sprint ledger.

## Ratification — 2026-09-05

Choirudin requested help selecting the current direction and applying it.
Codex records acceptance of the existing D1-D7 foundation: Windows-first
Flutter, local-first isolated project storage, protected module boundaries,
single-owner sync, guarded migrations, evidence-based testing, and staged
delivery. This accepts the architecture, not every historical proof claim.
No new feature expansion, architecture rewrite, release, push, or pilot
recruitment is authorized by this record. Future platforms remain deferred,
not deleted. Native tests and failure-matrix acceptance remain outstanding.
ADR-0003 now supplies the selected recovery direction; the older scope note
above describes this document at drafting time.

## Decisions

### D1. Stack: Flutter desktop, Windows-first
- Choice: Flutter (pubspec sdk >=3.12.0; CI pins 3.44.9) with the Windows
  desktop runner as the primary Core deliverable. web/ and android/ trees are
  retained but do not gate Core MVP.
- Alternatives: native Win32/WPF (rejected: rebuild cost, no portable path);
  Electron/TypeScript (rejected: memory footprint, no drift/SQLite lineage);
  mobile-first multi-platform (deferred by the Core MVP scope lock, 145.16).
- Tradeoffs: one Dart codebase and one state primitive vs. per-platform UI
  fidelity; desktop toolchain immaturity accepted and mitigated with
  widget-level proof instead of native-driver E2E.
- Consequences: acceptance evidence is Flutter-test-based; native interaction
  proof requires an interactive session (recurring UNVERIFIABLE boundary).
- Review trigger: a Core journey that must ship mobile/web, or a Flutter SDK
  upgrade that changes drift/Riverpod majors.

### D2. Storage: local-first per-project package, no account/cloud in Core
- Choice: Projects/<uuid>/ packages with a per-project Drift/SQLite database
  (NativeDatabase, ProjectDatabase.currentSchemaVersion = 59) plus filesystem
  blobs; global registry and manifest JSON written atomically (tmp + rename).
  Local session persistence works without account/identity (145.14 primary
  user, 145.20 core-without-account journey).
- Alternatives: one global database (rejected: per-project isolation and
  portability); server/Postgres storage (rejected: violates the local-first
  product promise, 145.13); JSON-only documents (rejected: relational queries
  and migrations are required by the Core hierarchy).
- Tradeoffs: migration discipline on every schema bump vs. trivial schema
  evolution; the filesystem package shape is what makes portable ZIP
  import/export possible (145.33).
- Consequences: custom storage locations (145.31) relocate roots but never
  change the package layout; data-safety tooling (backup/restore, journals)
  targets the package boundary.
- Review trigger: any proposal to move Core data behind a server or a shared
  global database.

### D3. Module boundaries: features depend on core, never core on features
- Choice: lib/core must not import lib/features; shared value types live in
  lib/core/domain (ADR-0001). Deferred capabilities reactivate only through
  FeatureFlagRegistry (13 flags, all default OFF, kill-switch) with
  CapabilityGate/RouteCapabilityGuard descriptors, and
  ReactivationDependencyMap binds each deferred capability to its owning flag
  and modules (145.22, 145.39).
- Alternatives: per-feature DI containers (rejected: heavier, no scan
  enforcement); allowlist-based dependency guard (rejected: allowlists rot;
  ADR-0001 deliberately keeps a zero-allowlist scan).
- Tradeoffs: occasional compatibility re-exports vs. free cross-imports;
  features own their Drift repositories by design.
- Consequences: test/core/architecture/core_dependency_direction_test.dart is
  the standing gate; new shared types go to lib/core/domain, never as
  core-side feature imports.
- Review trigger: a change that cannot compile without a core->features
  import, or a new capability that cannot name its owning flag.

### D4. Sync authority: exactly one owner per live project
- Choice: PersistedSyncAuthority (JSON v1 per project, atomic tmp + rename)
  claims cloud/external-folder ownership; AuthorityGuardedCloudSyncService
  denies unauthorized push with a user-readable error and parks denied writes
  in SyncAuthorityConflictJournal (JSONL, atomic, corrupt entries
  quarantined). Cloud sync is not composed into production startup by default
  (145.32, 145.36 no-startup-dependency).
- Alternatives: last-writer-wins cloud sync (rejected: silent data loss for
  long-form novels); filesystem-watch mirroring (rejected: no authority
  boundary).
- Tradeoffs: extra ceremony for optional cloud features vs. unbounded
  concurrent-writer corruption risk.
- Consequences: offline Core never touches authority paths; any future sync
  provider must go through the same claim/deny/journal contract.
- Review trigger: any feature that writes project data outside the owning
  session.

### D5. Schema evolution: exact-next, guarded, fixture-proven
- Choice: migrations always advance from the LIVE schema version (currently
  59) with the exact next integer; waves are guarded and idempotent (probe
  before addColumn); generated .g.dart files are committed; every bump adds a
  fixture entry (145.40 matrix); a database whose user_version is newer than
  the app schema is rejected at open without touching the file
  (SchemaVersionTooNewException guard).
- Alternatives: auto-migrations (rejected: silent data mutation risk);
  schemaless extension columns (rejected: query/migration needs).
- Tradeoffs: slower feature landings vs. a no-silent-loss upgrade guarantee
  (145.12 compatibility matrix).
- Consequences: stale schema assertions across test/ are swept on every bump;
  interrupted migrations recover through the guarded idempotent waves.
- Review trigger: a migration that cannot be expressed guarded/idempotent, or
  any request to downgrade a user database.

### D6. Testing: domain-first pyramid with explicit evidence boundaries
- Choice: domain/unit tests dominate the pyramid; real-filesystem/DB
  integration tests cover journeys (create/write/autosave/backup/restore);
  widget tests cover surfaces at desktop and 390px-narrow widths with
  tester.takeException() null; architecture tests (dependency direction,
  capability map) run as standing gates; the roadmap pointer is gated by
  tool/roadmap_guard.dart. flutter build windows --debug proves compilation
  only; native interaction proof requires an interactive session and is never
  inferred from builds or tests.
- Alternatives: integration-heavy pyramid (rejected: slow and flaky on a
  shared worktree); screenshot-diff E2E (deferred: needs a stable native
  driver tree).
- Tradeoffs: several narrow suites per slice vs. one broad suite; cron runs
  cannot produce native interaction evidence (recorded per sprint).
- Consequences: completion claims carry explicit
  VERIFIED/PARTIAL/UNVERIFIABLE boundaries; concurrent-owned failures are
  triaged rather than fixed blindly.
- Review trigger: a Core journey without a domain test, or a flaky suite that
  survives focused retries.

### D7. Build/delivery: CI matrix plus Windows debug local gate; no release pipeline yet
- Choice: GitHub Actions (flutter 3.44.9) runs analyze, full test, and builds
  linux debug / web release / apk debug, plus a windows-latest job; locally
  each slice gates on focused test -> regression -> flutter analyze ->
  git diff --check -> flutter build windows --debug. No release packaging,
  signing, or distribution pipeline exists yet.
- Alternatives: standing release CI (rejected: release readiness is a
  separate decision, 145.49/145.50); no CI (rejected: regression drift).
- Tradeoffs: CI matrix breadth vs. focus; debug builds are not distributable
  artifacts.
- Consequences: producing a pilot or user artifact (145.45) requires a
  deliberate release-packaging step first.
- Review trigger: pilot recruitment (145.45) or any user-distributable build
  request.

## Decision log reference
Evidence for each decision lives in
docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md (ledger) with
commit/test citations: 145.13/145.16 (scope and promise lock), 145.14
(9c4fd199), 145.19 (c0b8b7d + ADR-0001), 145.20 (core_without_account
journey), 145.22 (CapabilityGate), 145.26 (schema 58->59), 145.31/145.33
(storage relocation + portable ZIP), 145.32 (sync authority), 145.39
(RouteCapabilityGuard + reactivation map), 145.40 (fixture matrix).

## Open items owned by the architect (not decided here)
- 145.43-145.46: UX prototype, certification, pilot recruitment, user
  validation. 145.47: evidence-based prioritization. 145.49: Core MVP
  recovery path choice. 145.50: sprint closure.
