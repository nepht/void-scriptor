# VOID SCRIPTOR — Pre-Release Stabilization Gate

Date: 2026-08-22
Status: `IN_PROGRESS`
Phase: `PRE-RELEASE / ACTIVE DEVELOPMENT`
Position: before Sprint 101 post-release contract
Canonical branch observed: `master`
Version observed: `0.1.0+1`

## Purpose

Gate ini mendefinisikan fase yang harus dilalui sebelum kontrak Sprint 101 (`1.0.0 -> 1.0.1`) dapat dieksekusi. Sprint 101 tetap dipertahankan sebagai roadmap pascarilis; dokumen ini tidak mengubah status Sprint 101 dan tidak membuat klaim bahwa versi `1.0.0` telah dirilis.

## Why this gate exists

Sprint 101 mengasumsikan baseline `1.0.0`, jalur `main` / `release/1.0` / `hotfix/1.0.1`, dan proses patch pascarilis. Repository live saat gate dibuat masih berada pada branch `master`, version `0.1.0+1`, tanpa tag release, dan working tree memiliki perubahan concurrent/user-owned. Karena itu branch, version, signing, dan release metadata tidak boleh diubah hanya untuk memenuhi dokumen Sprint 101.

## Current evidence boundary

| Area | Status | Evidence / limitation |
|---|---|---|
| Native project creation and package persistence | `LOCALLY VERIFIED` | Focused Create Project tests, full Flutter suite, Linux debug build/startup; full human UI click-to-package trace remains limited by WSLg input accessibility. |
| Novel authoring | `LOCALLY VERIFIED` | Story/Chapter/Scene creation, selected-scene autosave, restart persistence, Markdown/DOCX export tested locally. |
| Image queue and fake provider | `LOCALLY VERIFIED` | Persistent queue, provider contract, loopback HTTP output download, package-scoped output. |
| Live AI provider | `BLOCKED` / `UNVERIFIABLE` | No live ComfyUI service at `127.0.0.1:8188`; no real credential or billable request used. |
| Web project persistence | `UNSUPPORTED BY CURRENT ARCHITECTURE` | Current persistence path uses native filesystem/SQLite APIs; no IndexedDB/Web database adapter is claimed. |
| Workspace separation ADR-WS-001 | `NOT_STARTED` | ADR is registered; Novel/Character namespace and link implementation are not complete. |
| Hosted CI | `NOT VERIFIED` | Existing readiness evidence records no green hosted CI run for current local HEAD. |
| Release packaging/signing/update/rollback | `DEFERRED` | No verified production release baseline or signed artifact. |

## Gate workstreams

### G1 — Native project lifecycle

Required evidence:

- create project on a supported native filesystem;
- write manifest and project database;
- open, close, and reopen the same project;
- verify project identity and database readability;
- verify failure feedback and no partial project remains;
- record a user-facing native smoke result separately from widget/service tests.

Status: `PARTIAL`.

### G2 — Novel workflow

Required evidence:

- create Novel / Story;
- create Chapter and Scene;
- select a different Scene;
- write and autosave to the selected Scene;
- close/reopen and verify persistence;
- export Markdown and DOCX;
- verify Scene A is not overwritten while editing Scene B.

Status: `LOCALLY VERIFIED`; broader exploratory and release gates remain pending.

### G3 — Image generation workflow

Required evidence:

- submit from UI;
- persist queue/job state;
- execute deterministic fake/local provider;
- poll provider lifecycle;
- fetch remote output;
- store output inside the project package;
- display or resolve output through the application;
- classify live provider and image-quality evidence independently.

Status: `LOCALLY VERIFIED WITH FAKE PROVIDER`; live provider remains blocked.

### G4 — Workspace separation

Required evidence from `ADR-WS-001`:

- distinct Novel and Character workspace IDs and namespaces;
- explicit `novel_character_link` ownership by Novel;
- `REFERENCE`, `SNAPSHOT`, and `FORK` semantics;
- no direct cross-workspace table/file mutation;
- unlink and deletion safety;
- permission checks on both boundaries;
- backup/export provenance and rebuildable projection cache.

Entry reference: Sprint 109 Step 109.3.

Current evidence (G4 domain slice):

- `NovelCharacterLink` enforces distinct Novel/Character workspace IDs, Novel ownership, required role/visibility, and explicit `REFERENCE` / `SNAPSHOT` / `FORK` modes.
- Link JSON round-trip preserves mode, ownership, IDs, role, visibility, and timestamps.
- `NovelCharacterLinkService` provides domain create/list/unlink behavior; unlink preserves the conceptual Character source.
- Focused workspace tests: `5` passed; Character + Story + Workspace regression: `38` passed; analyzer clean; format and diff checks passed.

Current persistence evidence (G4 persistence slice):

- Added project-scoped `NovelCharacterLinks` Drift table with guarded migration `54 → 55`.
- Regenerated `project_database.g.dart` successfully.
- `NovelCharacterLinkRepository` persists, lists, unlinks, and reloads links after closing/reopening the project database.
- Timestamp mapper normalizes persisted values back to UTC.
- Focused persistence/schema tests: `8` passed; Character + Story + Workspace + related schema regression: `44` passed; scoped analyzer clean; diff check passed.
- All discovered stale project database schema assertions were updated from `54` to `55`.

Current session-boundary evidence (G4 session slice):

- `ProjectSession` now owns `NovelCharacterLinkRepository` constructed from its active `ProjectDatabase` and `package.projectId`.
- Session A link data is not visible through a separate Project B session.
- After `session.close()`, queries against the closed active database fail as expected.
- Existing close/open lifecycle tests remain green.
- Session-focused tests: `7` passed; project-resilience + workspace regression: `38` passed; scoped analyzer clean; diff check passed.

Known warning retained: some Character lifecycle tests emit Drift's multi-instance database warning. It does not fail the tests, but the session/database ownership hardening is not considered fully resolved until that warning is addressed.

Current filesystem and permission evidence (G4 filesystem slice):

- Added `WorkspaceFileNamespace` under `<project-package>/workspaces/<workspaceId>/`.
- Workspace identifiers are constrained to safe alphanumeric/underscore/hyphen IDs.
- Absolute paths, traversal paths, empty paths, and invalid workspace identifiers are rejected with `ArgumentError`.
- File resolution uses normalized absolute paths and verifies the result remains inside the workspace root; sibling-prefix escapes are not accepted.
- `ProjectSession` now owns the namespace through `session.workspaceFiles`, bound to the active package root.
- Filesystem lifecycle tests cover workspace creation, file creation, traversal rejection, and session binding.
- Workspace + project-resilience regression: `40` tests passed; scoped analyzer clean; diff check passed.

Current backup/export evidence (G4 archive slice):

- Portable export now includes the project `workspaces/` namespace in addition to manifest, database, and assets.
- Disposable `cache/` remains excluded from portable archives.
- Imported copies preserve workspace files and rewrite the project database project IDs through the existing copy-import path.
- Archive import explicitly rejects absolute entry paths and traversal entries; partial output is removed on failure.
- Export/import regression plus workspace suite: `41` tests passed; scoped analyzer clean; diff check passed.

Current projection/UI evidence (G4 read-model slice):

- `WorkspaceProjectionCache` is session-owned, memoizes per Novel Workspace, supports explicit invalidation, and clears on session close.
- The cache loader reads `NovelCharacterLinkRepository`, keeping Drift as source of truth rather than persisting cache state.
- `WorkspaceResolver` passes the selected Story/Novel ID through the active session projection cache into `StoryWorkspaceScreen`.
- `WorkspaceProjectionCard` renders linked Character projections with loading, error, empty, and populated states; the populated card is verified at a 390 px viewport without overflow.
- Session integration proves persisted links remain hidden until cache invalidation and are reloaded from Drift afterward.
- Project resilience + Story + Workspace regression: `67` tests passed; scoped analyzer clean; diff check passed.

Remaining boundary: multi-instance warning remediation.
Status: `PARTIAL — DOMAIN CONTRACT VERIFIED; PERSISTENCE BOUNDARY NOT STARTED`.

### G5 — Platform capability contract

Required evidence:

- native platforms declare filesystem/SQLite capability honestly;
- Web does not expose a misleading Create Project path while native persistence is unavailable;
- unsupported capability returns a visible, actionable error or is disabled;
- supported-platform builds are tested from the current source snapshot.

Status: `VERIFIED` (2026-08-23). Marker: G5_CAPABILITY_EVIDENCE.

Evidence:

- Contract: lib/features/platform/domain/platform_capability.dart —
  PlatformCapability {localFileSystem, projectSqliteDatabase, readOnlySqlite},
  PlatformCapabilitySet.supports/require, typed
  UnsupportedPlatformCapabilityError with actionable Indonesian message;
  resolver injectable via isWeb for deterministic tests.
- Native declares filesystem+SQLite+read-only honestly (all three true);
  Web claims none of them (project packages use dart:io; drift web read-only
  throws UnsupportedError) — no misleading capability.
- Guard at ProjectController.createProject (single choke point) throws the
  typed error before any package creation; web test asserts zero directories
  created.
- CreateProjectScreen: honest inline banner + disabled Create action when
  localFileSystem unsupported; native keeps action enabled. Legacy failure
  snackbar test still green.
- Focused: 9/9 PASS. Regression scoped: 169 PASS. flutter analyze full:
  No issues found!. Builds from current source snapshot: web --release OK,
  linux --debug OK. git diff --check PASS.

### G6 — Pre-release baseline

Before Sprint 101 can be reconsidered:

- define the actual `1.0.0` acceptance contract;
- decide whether `master` remains the development branch or is formally mapped to `main`;
- establish version source and release metadata without guessing;
- produce a clean/reviewable release candidate boundary;
- verify installer/package/signing/update/rollback scope or explicitly remove those claims from the release contract;
- run full tests, analyzer, diff check, and supported target builds on the exact release candidate snapshot;
- obtain explicit release authority before creating release branches/tags or changing version metadata.

Status: `PARTIAL` (2026-08-23). Marker: G6_BASELINE_INVENTORY_EVIDENCE.

Evidence:

- Baseline inventory written to `docs/audits/pre-release-baseline-inventory.md`
  from live repo state at `4298284` (branch/tag/CI/version/signing/release-asset
  audit, 92 unpushed commits, dormant Sprint-50 release contracts classified).
- All seven G6 items inventoried; six are authority decisions that remain open
  (acceptance contract, branch mapping, version source, RC boundary,
  installer/signing/update/rollback scope, release authority).
- G6 cannot close without those decisions; Sprint 101 remains DEFERRED per the
  advancement rule.

## Advancement rule

Do not execute Sprint 101.1–101.26 until G1–G6 have an explicit evidence-backed verdict and the release baseline is accepted. Do not mark this gate complete because code or documents exist. A green local domain test proves only its domain boundary.

## Current verdict

`PRE-RELEASE GATE: IN PROGRESS`

`SPRINT 101: DEFERRED — NOT STARTED`

`PRODUCTION READINESS: NOT VERIFIED`

## Source references

- `docs/audits/sprint-001-100-final-readiness.md`
- `docs/SPRINT_PROGRESS.md`
- `docs/IMPLEMENTATION_LEDGER.md`
- `docs/audits/official-json-source.md`
- external canonical Sprint JSON archive, Sprint 101
- `workspace_separation_architecture.json` / `ADR-WS-001`

### G4 Migration Runner & Workspace Backup Evidence (2026-08-23)

Evidence commands:

```text
flutter test test/features/workspaces/workspace_migration_runner_test.dart   # 2 passed
flutter test test/features/project_resilience/project_recovery_services_test.dart  # 3 passed
flutter test test/features/workspaces test/features/project_resilience test/features/story test/features/character  # 98 passed
flutter analyze (scoped 8 items)                                             # No issues found!
git diff --check (scoped)                                                    # PASS
```

Verified behaviors:

- `ProjectBackupService.create/restore` now includes `workspaces/`; restore deletes destination workspace before copy so post-backup mutations do not survive rollback.
- Backup metadata records deterministic SHA-256 map (`workspaceFiles`, POSIX relative paths); tampered workspace files abort restore with `Workspace backup checksum mismatch`.
- `WorkspaceMigrationRunner.migrate()` validates identifiers/assignments before any mutation (no backup created on rejection).
- Migration sequence: pre-migration backup -> disk inventory of `assets/stories|characters` -> copy into typed namespaces under `legacy/` without deleting sources -> links created ONLY from explicit assignments (deterministic IDs, reference mode) -> per-file checksum validation -> projection cache invalidation/rebuild -> rollback drill executed on a disposable package copy using the real backup.
- Live-data cutover is NOT executed by these tests; no production legacy packages were found or migrated. Running the runner against real user data remains an explicit operator action.

Status updates:

- G4 backup/export boundary-aware policy: export/restore round-trip VERIFIED (typed Novel export excludes Character manuscripts; provenance link manifest preserved incl. mode/timestamps); collision choices (link-existing / snapshot / fork / skip) PENDING.
- G4 permissions/lifecycle: application-layer review+explicit-decision VERIFIED at session/repository level; UI review dialog PENDING.
- G4 mixed-workspace migration plan: runner infrastructure VERIFIED (steps: backup, inventory, copy, explicit links, validate, projection rebuild, rollback drill); legacy-source deletion/cutover intentionally NOT performed.
- G4 deletion review dialog: VERIFIED (2026-08-23). `CharacterDeletionReviewDialog`
  + `showCharacterDeletionReviewDialog` wired from `CharacterHeader` delete
  button through `CharacterActions.reviewDeletion/delete(decision:)`. Honest
  loading/error/empty states; confirm disabled until an explicit
  `unlink` decision exists (auto-selected only when there are zero Novel
  links, where unlinking nothing is the only possible outcome); cancel pops
  null. Evidence: dialog tests 5/5 PASS; scoped regression (workspaces +
  character + story + project_resilience) 103/103 PASS; `flutter analyze`
  No issues found!; `git diff --check` PASS.


## G4 Collision Choices Evidence

Marker: G4_COLLISION_CHOICES_EVIDENCE
Date: 2026-08-23

- RED: workspace_import_collision_choices_test.dart failed on missing
  WorkspaceImportCollisionChoice / collisionChoice parameter.
- GREEN implementation: lib/features/workspaces/application/
  workspace_import_service.dart adds enum WorkspaceImportCollisionChoice
  {fail, skip, adoptExistingLinks}; default fail preserves the legacy
  StateError pre-check ordering (collision check before archive decode);
  skip returns untouched (skipped: true); adoptExistingLinks keeps existing
  files and inserts only link-manifest entries whose link_id is absent.
  snapshot/fork are deliberately NOT offered: no transform exists yet.
- Focused: 7/7 PASS (4 new + 3 legacy import tests).
- Regression scoped: 107 PASS (workspaces, character, story,
  project_resilience).
- flutter analyze: No issues found!
- git diff --check: PASS. dart format applied to owned files.


### G4 export/import character representation (ADR-WS-001 portable_novel_export)

Status: VERIFIED (2026-08-23). Marker: G4_EXPORT_REPRESENTATION_EVIDENCE.

Contract source: MASTER_SPRINT_VOID_SCRIPTOR_JSON/workspace_separation_architecture.json,
backup_export_rules.portable_novel_export + restore_collision. Finding: the ADR
already defines snapshot/fork semantics; the previously-pending design decision
was resolved from the canonical source, not invented.

Evidence:

- Export: WorkspaceCharacterRepresentation enum (reference_manifest default /
  embedded_snapshot / fork); exportNovel declares it in the manifest (ADR line:
  portable export MUST declare representation). Embedded/fork exports carry
  each linked canonical character as workspace/characters/<id>.json with
  provenance block; missing canonical character fails honestly (StateError).
- Import: restoring an embedded/fork archive materializes canonical characters
  from archived payloads into the target store (projectId rewritten); an
  existing canonical character is a hard stop (never overwrite); partial
  inserts roll back; reference_manifest restores leave the store untouched.
- Tests: workspace_export_representation_test.dart 5/5 PASS;
  workspace_import_embedded_test.dart 3/3 PASS.
- Gates: dart format 4 owned files OK; flutter analyze: No issues found!;
  focused workspaces suite 46/46 PASS; git diff --check PASS.

Deferred honestly: user-facing dialogs to pick representation at export time /
collision+representation at import time are not wired into screens yet.

### G4_EXPORT_IMPORT_OPTIONS_UI_EVIDENCE (2026-08-23)

- Scope: additive presentation wiring for the ADR-WS-001 export/import contracts.
- New workspace_export_options_dialog.dart: representation picker reference_manifest / embedded_snapshot / fork; confirm locked until an explicit choice — no silent default.
- New workspace_import_options_dialog.dart: archive-declared representation surfaced honestly ("Not declared" when absent), collision choices fail / skip / adoptExistingLinks, loading and failure states honest, confirm locked until explicit choice.
- TDD: RED verified (missing widget load failure), then GREEN 3/3 export dialog + 3/3 import dialog.
- Gates: dart format 4 owned files; flutter analyze PASS (0 issues, exit code verified directly, not via pipe); regression test/features/workspaces 52/52 PASS; git diff --check PASS.
- Note: RadioListTile groupValue/onChanged deprecated after Flutter 3.32; migrated to the RadioGroup ancestor API instead of silencing lints.
- Boundary: dialogs are presentation contracts only. No production caller wires export/import services into any screen yet — that integration is recorded as follow-up, not claimed complete.

### G4_EXPORT_IMPORT_ACTIONS_WIRING_EVIDENCE (2026-08-23)

- Scope: dialog-to-service binding layer so screens never bypass the ADR-WS-001 explicit-choice contract.
- New WorkspaceExportActions (presentation): carries the dialog option object into WorkspaceExportService.exportNovel characterRepresentation.
- New WorkspaceImportActions (presentation): run() binds the collision choice; peekCharacterRepresentation() reads the archive-declared representation before any mutation.
- Extended WorkspaceImportService with static peekManifest (read-only manifest access, no workspace mutation).
- Story workspace screens are concurrent-owned modified files; they were NOT touched. Wiring them is now a 3-line additive patch calling these actions.
- TDD: RED verified (missing symbols), then GREEN 2/2.
- Gates: dart format 4 owned files OK; flutter analyze PASS (0 issues, exit verified directly); regression test/features/workspaces 54/54 PASS; git diff --check PASS.
- Boundary honest: no production screen caller exists yet (recorded follow-up); live-data cutover remains an operator action.

### G4_STORY_SCREEN_CALLER_EVIDENCE (2026-08-23)

- Scope: additive production caller wiring in story_workspace_screen.dart (concurrent-owned file; permission granted by Choirudin this session).
- Screen gained three optional constructor params: novelExportActions / novelImportActions / pickImportArchive. Null keeps buttons absent — no fabricated IO path.
- Export Novel button opens the export options dialog (explicit representation required), then WorkspaceExportActions.run; success/failure surfaced via snackbar.
- Import Novel button picks an archive via the injected picker, peeks the declared characterRepresentation before any mutation, opens the import options dialog (explicit collision choice required), then WorkspaceImportActions.run; skipped/restored-count outcomes surfaced honestly.
- Additive proof: screen diff moved from +24/-3 (pre-existing concurrent edits) to +118/-3; net nephthys contribution +94 insertions, 0 deletions.
- Tests: test/features/story/story_workspace_novel_io_test.dart 3/3 PASS (buttons absent when unwired; export dialog choice carried into actions; import peek-before-dialog plus explicit collision choice). Widget tests use recording doubles because the fake-async zone cannot run real zip I/O; real end-to-end archive I/O remains proven in workspace_actions_test.dart.
- Pitfall recorded: real filesystem/SQLite inside testWidgets requires tester.runAsync or the suite hangs; runAsync returns nullable futures in this Flutter version.
- Gates: dart format OK; flutter analyze PASS (0 issues after removing one unused import); combined regression test/features/workspaces + test/features/story 78/78 PASS; git diff --check PASS.

### G4_RESOLVER_PRODUCTION_WIRING_EVIDENCE (2026-08-23)

- Scope: additive injection in workspace_resolver.dart (concurrent-owned; allowed by contract). Net nephthys contribution: +14 lines (2 imports + novelExportActions/novelImportActions injection), 0 deletions; pre-existing concurrent diff (+93/-5) untouched.
- Production path now live: project session -> WorkspaceExportActions/WorkspaceImportActions (package + novelCharacterLinks) -> StoryWorkspaceScreen. Export Novel enabled in production; Import Novel visible-but-disabled until a file picker dependency is approved (pubspec protected) - honest capability signal, no fabricated IO path.
- Test: test/features/workspace/workspace_resolver_wiring_test.dart 1/1 PASS - real ProjectSessionManager().open(package) fixture via tester.runAsync; asserts Export enabled, Import disabled, dialog opens with production wiring. RED was proven first (button absent before patch).
- Contract discovery: Import button renders disabled (not absent) when picker missing; test expectation corrected to match the real contract.
- Gates: dart format OK (owned test only; concurrent resolver NOT reformatted); flutter analyze PASS (0 issues after lint cleanup); regression workspaces+story+workspace = 80/80 PASS; git diff --check PASS.

## G4_LIVE_CUTOVER_EVIDENCE

Date: 2026-08-23. Scope: first production execution of WorkspaceMigrationRunner against a real user package (operator-approved by Choirudin: jalankan).

Target package: ~/VoidScriptor/Projects/778f5427-9019-4dd9-9fad-f3b96733d5c1.voidproject ("Test Novel", created 2026-08-22 by app v0.1.0). Safety conditions verified before run: no lockfile, no running void_scriptor process, pre-migration backup enabled by runner.

Execution harness: test/live_cutover_test.dart, operator-gated via VOID_SCRIPTOR_LIVE_CUTOVER=1 (no-op in ordinary suite; suite-safe run proven first).

Run 1 (pre-fix): report backupCreated=true, validatedCounts=true, rollbackDrillPassed=true; but workspaces/novels/novel-main was NOT created. Root cause (real bug, caught by live run): Phase 4 copy loop skipped directory creation when the legacy folder was an empty scaffold (DB-only packages keep zero files on disk).

Fix (TDD): RED test/features/workspaces/workspace_migration_empty_scaffold_test.dart (failed: expected workspaces/novels/novel-main exists, reason recorded) -> GREEN patch in workspace_migration_runner.dart Phase 4 (await target.create(recursive: true) before copy) -> focused test PASS.

Run 2 (post-fix): backupCreated=true (backups/3c94e6e1-0e53-48bf-b87f-da337032cbfb, 1.5 MB); inventoriedStories=[7335a9f2-0f5c-4adc-8e41-bcc55277b3c8]; copiedStoryFiles=0 (honest: empty legacy scaffold); createdLinks=0 (package has 0 characters); validatedCounts=true; projectionRebuilt=true; rollbackDrillPassed=true; workspaces/novels/novel-main verified on disk.

Boundary honesty: this package carries DB-only content (1 story/1 chapter/1 scene in SQLite), so file-copy and link-creation phases executed vacuously. Copy-with-files and link paths remain covered by the fixture-based migration tests (workspace_migration_runner_test.dart), which do exercise real files. Legacy sources untouched; deletion of legacy folders remains a separate future decision.

Closeout gates (2026-08-23): dart format 3 owned files OK; flutter analyze PASS (No issues found); scoped suites test/features/workspaces + story + workspace + live_cutover = 82/82 PASS; git diff --check PASS.

## G6_UUPM_TRIAL_EVIDENCE

Trial adaptasi selektif skill komunitas ui-ux-pro-max (audit baca-saja di
~/tools/uupm-audit, lisensi MIT, tanpa instalasi bulk). Mesin pencarian
aturannya (search.py --domain ux --stack flutter) menghasilkan satu aturan
High yang relevan: tombol pemicu I/O harus disabled saat proses berjalan;
multi-klik tidak boleh memulai pekerjaan paralel.

Audit dialog ekspor novel menemukan pelanggaran nyata: fungsi handler
ekspor dan impor arsip novel pada story_workspace_screen.dart tidak memiliki
guard sibuk sehingga ekspor arsip paralel mungkin terjadi saat zip berjalan.

Perbaikan TDD pada blok Novel IO milik jalur ADR-WS-001: flag _novelIoBusy
mengunci kedua tombol selama operasi berjalan (blok finally melepasnya).
RED dibuktikan (onPressed masih closure saat run pending), GREEN 4/4 focused;
regresi gabungan 83/83; analyze PASS; git diff --check PASS; diff layar tetap
aditif (+130/-3; -3 milik konkuren sebelumnya).

Vonis trial: skill terbukti bernilai (satu temuan High actionable per audit);
adopsi inti selektif direkomendasikan; keputusan instalasi milik Choirudin.

## G6 DECISIONS AND CLOSEOUT (2026-08-23)

Keputusan otoritas oleh Choirudin (disampaikan lewat paket saran nephthys dan
disetujui eksekusi):

- D1+D5 acceptance scope: kontrak rilis v1.0.0 terdokumentasi di
  docs/audits/release-contract-v1.md. Cakupan IN: inti novel/karakter/story,
  workspace separation ADR-WS-001, persistence, export/import arsip dengan
  representasi eksplisit, wiring produksi ber-guard, live cutover, versi
  tunggal. Eksplisit DI LUAR v1: installer/signing/update/rollback/distribusi,
  cloud/akun/komunitas/publishing/pembayaran, sertifikasi connector.
- D2 branch mapping: tetap master; tanpa rename. Push ke origin dilakukan
  agar CI kembali bermakna.
- D3 single source versi: pubspec.yaml sumber kebenaran;
  VoidProjectFormat.applicationVersion wajib sinkron, dijaga
  test/version_single_source_test.dart. Bukti penjaga: saat konstanta
  dimutasi menjadi 9.9.9, test gagal (exit 1, Expected 0.1.0 / Actual 9.9.9);
  file asli dipulihkan hash-identical setelahnya.
- D4 RC boundary: pilah commit scoped dieksekusi sebatas yang AMBAR-KOMPILASI.
  Hasil probe worktree pada HEAD 4298284 membuktikan 18 error jika kode
  features/workspaces di-commit tanpa mutasi konkuren project_database.dart
  (+1775 baris .g.dart) karena tabel novel_character_links (migrasi v55)
  masih bercampur tabel creature_ecology_states (v54) milik jalur lain dalam
  satu diff belum-tercommit. Karena itu: commit dokumen + test penjaga versi
  sekarang; sisanya (kode workspaces, patch layar/resolver, test terkait,
  live cutover harness) menunggu commit skema oleh pemilik jalur konkuren,
  lalu dipilah lanjut. Disclosure ini adalah bagian dari keputusan D4.
- D6 release authority: hanya Choirudin yang membuat tag/menaikkan versi;
  nephthys menyiapkan draft dan evidence saja.

Status gerbang: G6 ditutup sebagai VERIFIED-with-disclosure untuk sisi
keputusan; pelaksanaan penuh v1.0.0 menunggu rantai D4 sisa sebagaimana
didisclosure di atas.

## G6_CI_RECOVERY_EVIDENCE

Setelah push D2, CI master kembali bermakna dan menunjuk tiga utang riwayat;
semuanya ditangani berurutan dengan bukti:

1. FORMAT (run 32623996965): 49 pelanggaran `dart format` tertanam sejak
   sebelum push (riwayat jalur lain). Diperbaiki mekanis di worktree
   terpisah, commit `chore: dart format baseline across lib+test (49 files)`
   (8fb1b5f), tanpa menyentuh worktree utama.
2. ANALYZE (run 32624619496): test yatim ter-commit lama
   `test/features/marketplace/application/marketplace_controller_test.dart`
   mengimpor controller yang hanya ada sebagai file untracked di jalur
   terlindung konkuren. Dengan izin eksplisit Choirudin, satu file
   `lib/features/marketplace/application/marketplace_controller.dart`
   (47 baris) dicommit scoped (55878e0) dengan disclosure; probe detached
   HEAD membuktikan analyze 0 issues dan test target 3/3 PASS sebelum push.
   Tiga modifikasi presentasi marketplace tetap uncommitted.
3. Verdict akhir run 32627484098 pada SHA 55878e0: completed/success.
   Pertama kali master hijau penuh di CI (analyze + test + build
   Linux/Web/Android/macOS/iOS). Watcher: /home/nepht/ci_watch5.log
   (ci_exit=0).
