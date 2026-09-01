# Sprint 145 — Product Scope Reset & Core MVP Recovery (Step Ledger)

Sumber kanonik: `sprint_145.json` (CORRECTIVE_IMPLEMENTATION_PLAN, 50 langkah)
di export eksternal
`C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`.
Status hidup = ledger ini (konvensi repositori), bukan file JSON eksternal.

## Rekonsiliasi baseline audit — 2026-08-25

Audit awal (langkah 145.1–145.8, 145.42) dieksekusi eksternal pada 2026-08-23
atas baseline `origin/master 334022a3…` dan regresi penuh di commit
`d4c3b8a3…`. Kedua SHA diverifikasi independen oleh nephthys (2026-08-25):
keduanya ada sebagai commit dan merupakan leluhur HEAD saat ini, dengan 54
komit di antaranya — artinya baseline audit **valid tapi basi dua hari**:
dibuat sebelum penyelesaian Sprint 104 (beta `1.1.0-beta.1+4` @4ba2a08),
Sprint 105 (RC `1.1.0-rc.1+5`), Sprint 106 (promosi stable v1.1.0), dan
persiapan hotfix Sprint 107. Suite penuh kini 1.735 test (vs 1.279 saat audit).
Implikasi: klaim COMPLETED langkah 145.1/145.5/145.7/145.8 dipertahankan
sebagai bukti historis dengan provenance eksplisit; langkah inventaris
berikutnya wajib membaca keadaan HEAD terkini, bukan menyalin kesimpulan
baseline lama.

## Status langkah

| Langkah | Judul | Status | Bukti |
|---|---|---|---|
| 145.1 | Application Source Entry Gate | COMPLETED (historis, diverifikasi silang) | Kontrak: project root `/home/nepht/Projects/void_scriptor_multiplatform`, origin/master `334022a3…`, Flutter 3.44.9/Dart 3.12.2; nephthys 2026-08-25: SHA ada & ancestor HEAD |
| 145.2 | Non-destructive Source Backup | VERIFIED (segar, nephthys 2026-08-25) | Pre-audit backup non-rotating + verifikasi baca-tulis penuh; rincian di bawah |
| 145.3 | Project Structure Inventory | VERIFIED (nephthys, 2026-08-25 @dc06fe1+) | Bukti di bawah |
| 145.4 | Secrets and Sensitive File Audit | VERIFIED (nephthys, 2026-08-25 @dc06fe1+) | Bukti di bawah |
| 145.5 | Reproducible Build Baseline | COMPLETED (historis) + **TEMUAN INTEGRITAS segar** | Historis: GitHub Actions `32628588565` success @334022a (era pra-billing). Segar (nephthys 2026-08-25 @c6af37b): **build Linux debug GAGAL pada snapshot terkomit murni** — lihat section temuan di bawah; PASS hanya setelah set adopsi minimal diterapkan |
| 145.6 | Runtime Baseline | VERIFIED (proses-level, nephthys 2026-08-25) | Launch bundle debug hasil build HEAD+adopsi: proses hidup ≥30s, RSS stabil ±550 MB (2 sampel), Dart VM service listening, nol exception/fatal di log, shutdown bersih SIGTERM exit 143. Verifikasi visual konten DEFERRED — WSLg tanpa GPU (MESA/ZINK gagal pilih device), konsisten dengan temuan 107.24 |
| 145.7 | Automated Test Baseline | COMPLETED (historis) | Kontrak: analyze PASS, 41 focused Core tests, regresi 1.279 PASS @d4c3b8a, build Web/Linux PASS; keadaan kini: suite 1.735 PASS @dc06fe1 (bukti Checkpoint 3) |
| 145.8 | Implementation Evidence Registry Population | COMPLETED (historis) | `implementation_evidence_registry.json` (IER-001) di export eksternal: 13 capability, ringkas 11 IMPLEMENTED_VERIFIED + 2 PLANNED; baseline audit 2026-08-23 |
| 145.9 | Working Feature Protection List | VERIFIED (nephthys, 2026-08-27) | `docs/audits/working-feature-protection-list.md`; live feature owners, user paths, no-break contracts, evidence boundaries, and known gaps recorded read-only |
| 145.10 | Dependency and Coupling Map | VERIFIED (nephthys, 2026-08-27) | `docs/audits/dependency-coupling-map.md`; router/shell orchestration, startup/save seams, three direct core→features imports, and no-break rules recorded read-only |
| 145.11 | Data Ownership Map | VERIFIED (nephthys, 2026-08-27) | `docs/audits/data-ownership-map.md`; registry/manifest, per-project DB, filesystem artifacts, feature repositories, optional systems, and no-break ownership rules recorded read-only |
| 145.12 | Existing User Data Compatibility | VERIFIED (nephthys, 2026-08-31 cron: fixture matrix 8/8 PASS; sisa scope terdelegasi eksplisit, bukan gap langkah ini) | `docs/audits/existing-user-data-compatibility.md` + `test/core/persistence/project_compatibility_fixtures_test.dart` (manifest legacy/future/missing/id-mismatch, registry missing/corrupt/future-schema, open ID-mismatch/future-schema); re-verify segar run ini @878c62e: focused 8/8 PASS, analyze no issues, full suite 3200/3200 PASS, build windows debug PASS; sisa milik langkah lain: DB old/current/future/corrupt migration matrix ->145.40, process/power/disk/permission/drive failure matrix ->145.42, sample-data user nyata ->butuh data user, native UI proof ->gate terpisah |
| 145.13 | Product Promise Lock | VERIFIED (nephthys, 2026-08-27) | `docs/audits/product-promise-lock.md`; canonical local-first promise, Core inclusion/exclusion, and acceptance guardrails recorded without expanding scope |
| 145.14 | Primary User and Job | VERIFIED (nephthys, 2026-08-31 cron: keputusan pengguna direkam dari otorisasi eksplisit Choirudin @9c4fd199) | `docs/audits/primary-user-and-job.md` + `test/core/roadmap/roadmap_guard_test.dart` (live-ledger test); primary user = novelis long-form mandiri di Windows, job = plan-write-continuity-export local-first, pain/constraints/success direkam tanpa asumsi; bukti: focused test RED (BLOCKED) -> GREEN (VERIFIED), doc audit primary-user-and-job.md, analyze no issues, roadmap guard PASS |
| 145.15 | Core / Cloud / Network Roadmap Split | VERIFIED (nephthys, 2026-08-27) | `docs/audits/core-cloud-network-roadmap-split.md`; canonical layer mapping, dependency direction, release eligibility, and startup guards recorded without changing features |
| 145.16 | Core MVP Scope | VERIFIED (nephthys, 2026-08-27) | `docs/audits/core-mvp-scope-lock.md`; Windows local-first Core boundary, writing/worldbuilding/data-safety inclusions, vertical journey, navigation reduction, and guardrails recorded without code changes |
| 145.17 | Explicit Deferred Scope | VERIFIED (nephthys, 2026-08-27) | `docs/audits/explicit-deferred-scope.md`; non-Core registry, reasons, entry evidence, safe-off defaults, and Core isolation guards recorded without activating or deleting features |
| 145.18 | Vertical Slice Contract | VERIFIED (nephthys, 2026-08-27) | `docs/audits/core-mvp-vertical-slice-contract.md`; release-blocking Create→Chapter→Write→Autosave→Close→Reopen→Search/Lore→Export→Backup→Restore journey, failure criteria, evidence matrix, and sequencing recorded |
| 145.19 | Core Dependency Direction | VERIFIED (nephthys, 2026-08-31 cron: ADR-0001 ownership contract + zero-violation enforcement @ this run) | `docs/adr/ADR-0001-core-shared-type-ownership.md` + `test/core/architecture/core_dependency_direction_test.dart` (RED 3 violations → GREEN 0); ProjectModel/AssetType/CommandHistoryRecord+Status moved to lib/core/domain, old paths kept as compatibility exports, Drift repository stays feature-owned; bukti: architecture test PASS, analyze no issues, focused regression 45 PASS, full suite 3202 PASS, windows debug build PASS |
| 145.20 | Core Without Account | VERIFIED (nephthys, 2026-09-01 cron) | Persisted local session restore (Guest/Offline) verified incl. real disk-backed restart and logout-clear: test/core/auth/ (10 tests) + test/app/auth/auth_flow_test.dart (7). Complete local journey without account - session restore, project create, open DB, story/chapter/scene create, draft save, backup, content-loss restore, reopen, query - proven by test/features/projects/core_without_account_journey_test.dart (PASS). UI restart wiring (persisted session opens Dashboard, login skipped) by test/app/auth/persisted_session_restart_test.dart (PASS). No account identity stored (userId/email explicit nulls); no pre-existing account-coupled identity to migrate. Full gates this run: flutter analyze clean, full suite 3215 PASS, windows debug build PASS. Boundaries: native interaction UNVERIFIABLE (cron has no computer_use driver); ProjectBackupService.restore crashes if project.db is fully deleted (emergency pre-restore backup reads missing file) - sibling-owned file, recorded here as known limitation, not fixed from cron |
| 145.21 | Core Without Internet or Providers | VERIFIED (nephthys, 2026-09-01 cron @87f1e19) | Complete Core journey (project create/open, story/chapter/scene, draft save, debounced autosave, markdown export, backup, content-loss restore, reopen, no-credential/no-exception persistence) proven under total provider+DNS failure (SocketException transport, AI provider failing listModels/generate) by test/features/projects/core_without_internet_providers_test.dart (2 tests PASS: journey + widget bounded non-modal failure). Existing seams re-exercised live: ProviderRouter.resolve, AiProviderHealthProbe (unavailable + redacted message), AiProviderWithTimeout, AiModelRegistry cache-fallback rethrow, AiGenerationQueueScreen renders failed job with retry action and no AlertDialog. Gates this run: focused test PASS (after one tooltip assertion typo fixed), flutter analyze No issues, full suite 3217 PASS, windows debug build PASS, git diff --check PASS. Boundaries: native interaction UNVERIFIABLE (cron has no computer_use driver); drift multiple-database warning avoided by sequencing (catalog check after project db closed), not by suppression |
| 145.22 | Module Boundary and Feature Flags | VERIFIED (nephthys, 2026-09-01 cron) | Cross-module no-side-effect enforcement closed: enforceable `CapabilityGate` boundary primitive (lib/core/capabilities/capability_gate.dart) over FeatureFlagRegistry — descriptor (id + owning flag + fallback), strict path throws CapabilityDisabledError BEFORE body runs while OFF (no network/credential/fs/db/payment side effect possible), degraded path returns safe fallback, unknown id ArgumentError, kill-switch forces guarded OFF. RED→GREEN test: test/core/capabilities/capability_gate_test.dart 6 PASS. Existing primitives re-verified: FeatureFlagRegistry 13 flags default-OFF + kill-switch, workflow audit flag, architecture test 0 core→features violations. Per-capability service wiring deliberately deferred until non-Core activation (Core MVP scope-lock: CloudSyncService not composed in production). Gates this run: flutter analyze No issues, full suite 3223 PASS, windows debug build PASS, git diff --check PASS |
| 145.23 | Startup Path Simplification | VERIFIED (nephthys, 2026-09-01 cron) | Local-only status exposed honestly at Dashboard first frame: new `LocalOnlyStatusBadge` (lib/features/dashboard/presentation/widgets/local_only_status.dart) renders for Guest/Offline sessions only ("Local-only session - no account, no cloud sync." + cloud_off icon) and never for authenticated sessions; RED->GREEN test test/features/dashboard/dashboard_local_status_test.dart 3 PASS (guest desktop, offline narrow 390px, authenticated negative) + tester.takeException() null. Existing recovery/local-auth bootstrap seams preserved (prepareBootstrap dependency-free recovery, persisted Guest/Offline restore). Gates this run: flutter analyze No issues, full suite 3226 PASS, windows debug build PASS (build/windows/x64/runner/Debug/void_scriptor.exe), git diff --check PASS. Boundaries: native first-frame timing UNVERIFIABLE (cron has no computer_use driver); optional init deferral beyond existing seams (provider lazy composition, AI BYOK explicit) remains PARTIAL by design; recent-project availability unchanged (Dashboard renders RecentProjects via provider while session restore completes) |
| 145.24 | Novel Workspace Core | PARTIAL (nephthys, 2026-09-01 cron c: export fidelity matrix landed) | `docs/audits/novel-workspace-core.md`; Story hierarchy/repository, restart persistence, resolver, autosave, IO action safety, `searchNovel` cross-scene search (commit d0cbf81), word count wired+tested, persistent scene draft snapshots (schema 56→57 + repository capture/restore-with-backup/retention, `test/features/story/draft_snapshot_persistence_test.dart` 3 PASS), Novel Workspace UI journeys (NOVEL SEARCH + SCENE SNAPSHOTS panels, `test/features/story/novel_workspace_search_snapshot_ui_test.dart` 2 PASS), AND export fidelity matrix (`StoryExportFidelity` + `test/features/story/story_export_fidelity_test.dart` 1 PASS: exact-structure markdown line diff, DOCX zip-decode paragraph diff, DB ordering preserved, live manuscript untouched, XML-special + blank-line content intact di kedua format) pass; native proof remains open (cron lacks computer_use driver) |
| 145.25 | Character Workspace Core | PARTIAL (nephthys, 2026-08-27) | `docs/audits/character-workspace-core.md`; identity/repository, responsive workspace, revision restore/undo, visual continuity, moodboard, interview history/provenance pass 33 focused tests; relations/linking, quick-reference propagation, and native proof remain open |
| 145.26 | Character Scope Layers | BLOCKED (scope model/precedence contract missing) | `docs/audits/character-scope-layers.md`; canonical identity and scene-local visual override exist, but Universe/Timeline Override, Novel-specific State, scoped commands, effective resolver, and migration tests are missing |
| 145.27 | Core Worldbuilding Reduction | PARTIAL (nephthys, 2026-08-27) | `docs/audits/core-worldbuilding-reduction.md`; canonical priority list, live Character/Environment/Story/Timeline evidence, advanced/deferred boundaries, and no-break rules recorded; Factions/Relationship Map/Lore Notes contracts and uniform route gating remain open |
| 145.28 | Writing Room Focus | PARTIAL (nephthys, 2026-08-27) | `docs/audits/writing-room-focus.md`; canvas, chapter/scene navigation, autosave/reopen, word count, lore binding, and focus domain tests pass 10 focused tests; screen focus integration, visible save state, and native proof remain open |
| 145.29 | Lore Linking and Search | PARTIAL (nephthys, 2026-08-27) | `docs/audits/lore-linking-and-search.md`; deterministic links/suggestions, keyboard flow, broken/ambiguous reports, rename-safe retargeting, lore creation, and project-scoped mutation regression pass 31 focused tests; complete cross-domain catalog/search UI, universal rename wiring, and native proof remain open |
| 145.30 | Autosave Snapshot and Crash Recovery | PARTIAL (nephthys, 2026-08-27) | `docs/audits/autosave-snapshot-crash-recovery.md`; autosave coordinator, in-memory journal, JSON snapshots, checksum-protected backup/restore, crash marker, and 8 resilience tests pass; durable journal, atomic save, process/power/disk-full injection, no-silent-loss restart proof, and end-to-end autosave recovery UI remain open |
| 145.31 | Custom Local Storage | PARTIAL (nephthys, 2026-08-27) | `docs/audits/custom-local-storage.md`; root override/fallback, UUID package paths, registry atomicity, health/open, portable relocation seams, and 18 persistence tests pass; user-selected C:/D:/USB lifecycle, free-space/drive health, missing-drive state, explicit relink UI, and no-empty-replacement proof remain open |
| 145.32 | Single Sync Authority Rule | PARTIAL (nephthys, 2026-08-27) | `docs/audits/single-sync-authority.md`; cloud/external-folder authority policy and denial warning pass the new vertical test plus collaboration suite (10 tests); runtime service wiring, persisted authority, conflict flow integration, and UI denied state remain open |
| 145.33 | Portable Import Export | PARTIAL (nephthys, 2026-08-27) | `docs/audits/portable-import-export.md`; portable ZIP round-trip, cache exclusion, relocated-copy registry, path traversal rejection, cleanup, and backup integrity pass 6 tests; archive checksum metadata, secret exclusion, migration compatibility, complete rollback, and large-project stress evidence remain open |
| 145.34 | Local Backup and Restore | PARTIAL (nephthys, 2026-08-27) | `docs/audits/local-backup-restore.md`; local backup/restore with SHA-256 manifest/database/workspace integrity, WAL checkpoint, emergency pre-restore backup, and snapshot retention primitives pass the resilience tests; configurable location, backup retention policy, restore preview, alternate destination, migration-aware restore, full failure injection, and Free-access proof remain open |
| 145.35 | Clean Manuscript Export | PARTIAL (nephthys, 2026-08-27) | `docs/audits/clean-manuscript-export.md`; clean Markdown/story export, private/internal marker removal, deterministic fingerprint, chapter/scene ordering, preflight/preview, profiles, and DOCX artifact pass 25 tests; plain TXT writer, full publishing fidelity, explicit encoding matrix, complete metadata propagation, and cross-format no-watermark proof remain open |
| 145.36 | AI Optional Boundary | PARTIAL (nephthys, 2026-08-27) | `docs/audits/ai-optional-boundary.md`; optional local AI runtime, secure credentials, provider routing, transfer/cost gates, cancellation, redaction, and failure fallback pass 39 tests; unified BYOK/context/consent policy and dedicated no-startup-dependency proof remain open |
| 145.37 | Navigation Reduction | PARTIAL (nephthys, 2026-08-27) | `docs/audits/navigation-reduction.md`; desktop/mobile shells, routes, adaptive layouts, and 11 navigation tests pass; target Core primary destinations and hiding/feature-gating unready modules remain open |
| 145.38 | Settings Reduction | PARTIAL (nephthys, 2026-08-27) | `docs/audits/settings-reduction.md`; theme, security, language, plugin settings and persistence pass 23 tests; unified Core-first settings surface, settings route, and feature-gated cloud/AI/community/publishing/payment/developer sections remain open |
| 145.39 | Non-Core Preservation and Disablement | PARTIAL (nephthys, 2026-08-27) | `docs/audits/non-core-preservation-disablement.md`; 13 feature flags default OFF, audited workflow override, plugin enable/disable persistence, and 20 regression tests pass; primary-navigation removal, route gating, reactivation dependency map, and disabled-module data proof remain open |
| 145.40 | Schema and Migration Fixtures | PARTIAL (nephthys, 2026-08-27) | `docs/audits/schema-migration-fixtures.md`; manifest/registry version guards, RC migration matrix, corrupt package detection, backup/rollback, and restart persistence pass 32 tests; dedicated old/current/future/corrupt fixture matrix, exhaustive invariants, forward recovery, no-silent-discard, and clean-Windows execution remain open |
| 145.41 | Core Automated Test Pyramid | PARTIAL (nephthys, 2026-08-27) | `docs/audits/core-automated-test-pyramid.md`; live inventory finds 124 domain-oriented, 4 integration-named, 14 contract, and 152 widget-test files; Core vertical matrix passes 78 tests; clean-Windows E2E/integration_test tree/native interaction remain unverified |
| 145.42 | Data Safety Failure Matrix | IN_PROGRESS (milik eksekutor lain — JANGAN digandakan) | Tercakup historis: concurrent-open ditolak, isolasi DB antar proyek, regresi 1.279 @d4c3b8a; sisa kontrak: process_kill, power_loss, disk_full, permission_loss, drive_removal, interrupted move/import/export/restore, device validation |
| 145.43–145.50 | (UX, sertifikasi, pilot, keputusan penutupan) | PENDING | — |

## Bukti 145.2 — Non-destructive Source Backup (nephthys, 2026-08-25)

Eksekusi via skrip `void_scriptor_preaudit_backup_wsl.sh` (read-only terhadap
source tree; hanya `tar` membaca):

- Artefak (TIDAK ikut rotasi harian):
  `/mnt/d/Hermes_Storage/Backups/Void_Scriptor/Pre_Audit/void_scriptor_multiplatform_preaudit_20260825_172347_dc06fe1.tar.gz`
- Ukuran 64M; snapshot pada HEAD `dc06fe1ca096981952ca31fc331a88ce120074da`
  (branch master), 415 dirty path milik user/agen lain ikut terarsipkan apa
  adanya tanpa diubah.
- Verifikasi integritas konten penuh: 12.327 file di dalam arsip di-hash dan
  dibandingkan byte-per-byte terhadap source (`cmp` source.sha256 vs
  archive.sha256 — identik).
- Verifikasi keterbacaan: `tar -tzf` sukses (13.203 entri);
  `sha256sum -c` sidecar: OK.
- Manifest: `*.manifest.txt` (purpose, created_at, head, branch,
  tracked_files=2032, dirty_paths_at_snapshot=415).
- Backup harian otomatis (job cron `Backup Harian Void Scriptor Multiplatform
  WSL ke D`, retensi 7 snapshot, last ok 2026-08-25 02:00) tetap berjalan
  terpisah; artefak pre-audit ini suplemen milestone yang tidak terrotasi.
- Repository tag tidak dibuat — pembuatan tag menunggu otorisasi D6/user
  sesuai kontrak rilis.

### Rute restore (runbook)

1. Target pemulihan kosong, mis. `mkdir -p ~/Projects/restored`.
2. `tar -xzf <arsip>.tar.gz -C ~/Projects/restored` — menghasilkan folder
   `void_scriptor_multiplatform/` utuh (termasuk working tree dirty saat
   snapshot; `.git` internal ikut terarsip).
3. Verifikasi pasca-restore: `cd ~/Projects/restored/void_scriptor_multiplatform`
   lalu bandingkan `find . -type f ! -path './build/*' ! -path './.dart_tool/*'
   -print0 | sort -z | xargs -0 sha256sum` terhadap daftar hash di arsip;
   minimal pastikan `git rev-parse HEAD` = `dc06fe1ca096981952ca31fc331a88ce120074da`.
4. Alternatif cepat tanpa ekstraksi penuh: clone dari dalam arsip tidak
   disarankan; gunakan `git fetch` dari remote atau ekstraksi penuh seperti
   di atas. Remote GitHub juga memuat HEAD yang sama (`dc06fe1`) sehingga
   rute kedua adalah `git clone` + reaplikasi pekerjaan tak-ter-commit dari
   arsip bila diperlukan.

## Bukti 145.3 — Project Structure Inventory (nephthys, 2026-08-25, HEAD dc06fe1+)

Read-only; angka = file `.dart` kecuali disebut lain:

- Identitas: `void_scriptor` v`1.1.0-rc.1+5`, SDK `>=3.12.0 <4.0.0`;
  2.033 tracked files; 127 entri `pubspec.lock`.
- Kode: `lib` 968 (features 553, core 220, database 129, app 21,
  automation 15, workflow 12, design_system 12, shared 3, release 1,
  l10n 1); `test` 607 (features 400, core 132, app 26, automation 14,
  workflow 13, release 7, database 5, lain-lain 10).
- Database: Drift, `lib/database/project/{daos,tables}`,
  `currentSchemaVersion = 56` (`project_database.dart:338`); migrasi di
  `project_database.dart`; generated `project_database.g.dart`.
- Platform targets: android/ios/linux/macos/windows/web semua PRESENT.
  Tidak ada backend/server directory — arsitektur local-first.
- Assets: 433 file (brands/backgrounds/fonts/logos) — catatan: sebagian
  asset brand milik agen lain, statusnya diatur pemiliknya.
- Tooling: `tool/workflow_example.dart`; `tools/*.py`
  (generate_release_metadata, verify_engineering_report,
  verify_repository_hardening); workflows: ci.yml, release-train.yml,
  security.yml.
- Docs: SPRINT_PROGRESS.md, MASTER_SPRINT.md, IMPLEMENTATION_GOAL/LEDGER,
  audits/, benchmarks/, release/, sprints/, workflows/.
- Generated/build: `build/`, `.dart_tool/` ada (tidak diinventarisasi
  sebagai sumber).
- Entry point: `lib/main.dart` (bootstrap gate + recovery shell, Sprint
  101.3/101.9), root app `lib/app/void_app.dart`.

## Bukti 145.4 — Secrets and Sensitive File Audit (nephthys, 2026-08-25)

Metode read-only; output hanya path/jumlah, nilai tidak pernah dicetak:

- Filename sensitif (worktree incl. untracked): hanya nama kode fitur
  credential (`encrypted_credential_store.dart`,
  `credential_store.dart`, `credentials_vault.dart`) — bukan file rahasia.
- Blok `BEGIN … PRIVATE KEY` pada seluruh tracked files: NONE.
- Kandidat assignment (api_key/token/password/passphrase) per area:
  lib=7, test=6, tool/tools/web/platform-dirs=0 — indikasi awal identitas
  variabel kode, bukan materi rahasia; review manual menyusul bila
  dikontrakkan lebih dalam.
- Referensi dotenv di lib/tool: NONE (kecocokan grep hanyalah
  `environmentId` DAO).
- Konsisten dengan kebijakan: kunci privat codesign tinggal di
  `~/codesign/` WSL, di luar repo.

## TEMUAN INTEGRITAS — 2026-08-25: snapshot terkommit tidak buildable

Ditemukan oleh cek build HEAD-murni (worktree isolasi `~/vs_head_buildcheck`
pada `c6af37b`, tanpa file WIP siapa pun):

1. Build #1 GAGAL (kernel_snapshot_program): `.g.dart` terkommit mereferensi
   kelas `NovelCharacterLinks` & `CreatureEcologyStates`, tetapi file
   definisinya tidak pernah terkommit:
   - `lib/database/project/tables/novel_character_links.dart`
   - `lib/database/project/tables/creature_ecology_states.dart`
   Keduanya untracked di worktree utama (milik slice DB agen lain).
2. Build #2 GAGAL (asset bundling): pubspec terkommit mendeklarasikan
   `assets/brands/own_brands/void_scriptor/` dan
   `assets/fonts/SpaceGrotesk/` yang juga belum terkommit.
3. Pemindaian referensi menyeluruh (131 file lib/test untracked vs
   `git grep HEAD`): hanya 2 file tabel + 2 path asset itu yang
   direferensikan kode/pubspec terkommit. Set adopsi minimal = 4 item.
4. Build #3 PASS (`✓ Built …/void_scriptor`) setelah set minimal
   disalin ke worktree isolasi; runtime probe 145.6 lulus pada biner itu.

Implikasi: clone bersih dari master saat ini TIDAK bisa dikompilasi; suite
hijau kemarin berjalan di atas disk yang mengandung WIP tak-terkommit.
Perbaikan permanen adalah KEPUTUSAN ADOPSI milik Choirudin (meng-commit
set minimal, atau koordinasi dengan agen pemilik slice DB) — nephthys
tidak meng-commit file milik agen lain tanpa otorisasi. Sampai diputuskan,
HEAD murni tetap dianggap NOT BUILDABLE secara reproduksi.

## Bukti 145.6 — Runtime Baseline proses-level (nephthys, 2026-08-25)

- Biner: `~/vs_head_buildcheck/build/linux/x64/debug/bundle/void_scriptor`
  (hasil build #3 pada `c6af37b` + set adopsi minimal).
- Launch headless-safe (tanpa DISPLAY) via skrip probe:
  ALIVE_AFTER_30S=yes; VmRSS 549.804 kB stabil pada dua sampel (3s apart);
  Threads 24→23; log bootstrap berakhir di "The Dart VM service is
  listening on http://127.0.0.1:…".
- ERROR_SCAN: hanya warning grafis WSLg (libEGL/MESA/ZINK) — konsisten
  temuan 107.24; nol unhandled exception/fatal/crash.
- Shutdown: SIGTERM → exit status 143 (bersih, sesuai rencana).
- Batas jujur: verifikasi visual konten UI DEFERRED (WSLg tanpa GPU).

## Catatan konkurensi

Ledger ini dibuat nephthys setelah konfirmasi belum ada ledger Sprint 145 di
repo. Langkah 145.42 sedang dimiliki eksekutor lain (IN_PROGRESS di kontrak);
nephthys tidak mengerjakannya. Langkah berikutnya yang aman dieksekusi:
145.3 Project Structure Inventory (membaca keadaan HEAD terkini).
