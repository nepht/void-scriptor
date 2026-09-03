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
| 145.24 | Novel Workspace Core | VERIFIED (nephthys, 2026-09-01 cron h: evidence-closure reconciliation per RESOLUTION_GUIDANCE_145_24_145_26 - seluruh objective exact sprint_145.json terbukti bukti eksekusi; sisa boundary UNVERIFIABLE: native interaction klik/typing tanpa computer_use) | `docs/audits/novel-workspace-core.md`; Story hierarchy/repository, restart persistence, resolver, autosave, IO action safety, `searchNovel` cross-scene search (commit d0cbf81), word count wired+tested, persistent scene draft snapshots (schema 56→57 + repository capture/restore-with-backup/retention, `test/features/story/draft_snapshot_persistence_test.dart` 3 PASS), Novel Workspace UI journeys (NOVEL SEARCH + SCENE SNAPSHOTS panels, `test/features/story/novel_workspace_search_snapshot_ui_test.dart` 2 PASS), AND export fidelity matrix (`StoryExportFidelity` + `test/features/story/story_export_fidelity_test.dart` 1 PASS: exact-structure markdown line diff, DOCX zip-decode paragraph diff, DB ordering preserved, live manuscript untouched, XML-special + blank-line content intact di kedua format) pass, AND snapshot retention UI (panel SCENE SNAPSHOTS: tombol 'Atur Retensi' + dialog 'Atur Batas Retensi' -> `StoryRepositoryImpl.setDraftSnapshotRetention`, validasi int>0, reload daftar; `test/features/story/novel_workspace_search_snapshot_ui_test.dart` 3 PASS termasuk retention journey); native render proof closed by alive probe (2026-09-01 cron g: MainWindowHandle valid + Responding=True + CopyFromScreen 2093 unique colors/112578 edge transitions on 1280x720), native interaction remains open (cron lacks computer_use driver) |
| 145.25 | Character Workspace Core | VERIFIED (nephthys, 2026-09-01 cron: evidence-closure reconciliation per RESOLUTION_GUIDANCE_145_24_145_26 — seluruh item objective eksak terbukti bukti eksekusi; genealogy if-present = N/A-DEFERRED (tidak present di Core character scope, hanya world_logic stream sequential suspended; family bond Core via AssetRelationType.relatedTo); native interaction UNVERIFIABLE dari cron, bukan acceptance item; sebelumnya PARTIAL cron k) | `docs/audits/character-workspace-core.md`; identity/repository, responsive workspace, revision restore/undo, visual continuity, moodboard, interview history/provenance pass 33 focused tests; relations/linking closed by live-session journey (create via mutation bus -> display service name resolution -> RelationSection renders in CharacterInspector -> delete -> empty, `test/features/relations/character_relations_journey_test.dart` 1 PASS, commit 1ce0f81; plus 8 existing relations tests); quick-reference propagation closed at domain+AI+UI layers (2026-09-01 cron f: `CharacterQuickRef` domain + `StoryRepositoryImpl.quickReferenceForScene` + `AiCharacterContext.quickRef` via `AiContextResolver` + Story Workspace panel `CHARACTER QUICK REF`; `test/features/story/character_quick_reference_test.dart` 1 PASS + `test/features/story/story_workspace_quick_ref_ui_test.dart` 1 PASS, RED terverifikasi); full shared resolver journey closed (2026-09-01 cron g: `test/features/workspace/workspace_resolver_character_journey_test.dart` 1 PASS — live session, selectionProvider mutation production path -> WorkspaceResolver -> CharacterWorkspaceScreen with repository-loaded data; PASS-first behavior evidence, no production code changed); native render proof via alive probe (2093 unique colors/112578 edge transitions); native interaction proof remains open (cron lacks computer_use driver); BASE_VOICE closed (cron k: `Characters.voice` kolom schema 57->58 guarded addColumn, `CharacterModel.voice` + mapper + repository read/write, quick ref baris `Voice:` saat non-kosong; `test/features/character/character_voice_notes_test.dart` 5 PASS, RED terverifikasi) DAN private notes wiring closed (`getIdentity`/`updateIdentity` kini membaca/menulis `CharacterIdentityProfiles.notes` — sebelumnya silent-drop dua arah); 29 asersi schema stale 57->58 diperbarui; voice/notes UI display+editor closed (2026-09-01: CharacterIdentityCard baris Voice + CharacterPrivateNotesCard dengan Save eksplisit -> UpdateCharacterIdentityCommand; CharacterIdentityProfile.copyWith; kelima callback lock screen diubah dari rebuild field-per-field yang menjatuhkan notes/weaponLock/accessoryLock menjadi copyWith — silent-drop bug tertutup; test/features/character/character_voice_notes_ui_test.dart 1 PASS live session, RED terverifikasi; char suite 39 PASS, commit 01000fe); native interaction tetap UNVERIFIABLE (cron) |
| 145.26 | Character Scope Layers | VERIFIED (nephthys, 2026-09-02 cron: evidence-closure - seluruh item objective eksak sprint_145.26 terbukti bukti eksekusi live: kontrak discriminator/ownership/precedence/null-vs-clear/resolver (14 PASS), persistence 3 tabel scope schema 58->59 + restart (5 PASS), scoped command integration dengan undo/redo nyata (3 PASS), workspace source-scope display (2 PASS, RED ganda termasuk overflow pre-existing); native interaction UNVERIFIABLE dari cron, bukan acceptance item per presedens 145.24/145.25) | `docs/audits/character-scope-layers.md`; contract now explicit from `core_mvp_scope_reset_spec.json` `character_model` (3 layers, per-layer field ownership, quick_edit_requires_scope_choice, override_never_silently_mutates_canonical); slice commit 681023e: `lib/features/character/domain/character_scope_layers.dart` (CharacterScopeLayer priority 0/1/2, CharacterScopeFieldOwnership spec-exact, CharacterScopeState null=inherit, CharacterScopeEffectiveResolver canonical->universe->novel without input mutation, UpdateCharacterScopeCommand ArgumentError before write for non-owned fields + explicit scope discriminator in payload); RED verified (all symbols undefined), focused 14/14 PASS, char suite 53 PASS, analyze No issues, windows debug build PASS, diff --check PASS. Command integration closed 2026-09-02: `UpdateCharacterScopeFieldCommand` (execute menulis merged state hanya layer target via repository, sibling fields preserved, non-owned field ArgumentError sebelum write, undo/redo hanya field miliknya; `test/features/character/update_character_scope_field_command_test.dart` 3 PASS, RED terverifikasi, commit 11de9de). Workspace source-scope display closed 2026-09-02: `characterScopeStatesProvider` + `CharacterScopeStatusCard` (chip layer berdata + baris efektif `Identity/Voice/Role/Status/Location: nilai (from layer)`, production session path) mounted di CharacterWorkspaceScreen; sekaligus fix RenderFlex overflow 28px pre-existing 390px (ModeSection pindah ke scroll area pada narrow, desktop unchanged; `test/features/character/character_scope_status_ui_test.dart` 2 PASS + RED ganda terverifikasi, commit 84e9b04, mixed-file staging menjaga sibling deletion-review uncommitted). Native interaction tetap UNVERIFIABLE (cron). Persistence closed 2026-09-02: schema 58->59 tiga tabel scope layer (`lib/database/project/tables/character_scope_layers.dart`, guarded createTable x3, data canonical tak tersentuh), CharacterDao get/upsert/remove per layer + `removeCharacterScopeRows` wired ke `deleteCharacter`, repository `getScopeStates`/`updateScopeState` (interface + impl), 30 file asersi schema stale 58->59, `test/features/character/character_scope_persistence_test.dart` 5 PASS (RED terverifikasi), regresi character+release+database+project_package 108 PASS, full suite 3288 PASS / 1 FAIL konkuren 145.20, build windows PASS, diff --check PASS |
| 145.27 | Core Worldbuilding Reduction | PARTIAL (nephthys, 2026-08-27; slices 2026-09-02) | `docs/audits/core-worldbuilding-reduction.md`; canonical priority list, live Character/Environment/Story/Timeline evidence, advanced/deferred boundaries, and no-break rules recorded; Factions create/list/persistence journey landed (commit e286ca9, 4 PASS); Factions editor UI landed (commit 3374abe: Project Bible FACTIONS section dgn live list via FactionRepository, dialog 'Faksi Baru' through CreateFactionService, duplicate-name visible error, narrow 390px render, factions_editor_ui_test 4 PASS RED-verified, bible suite 36 PASS, full 3301 PASS / 1 FAIL concurrent, build windows PASS 29.1s); Relationship Map contract landed (commit 93470b3: CharacterRelationMapService.mapForProject resolves project relations into named character endpoint rows, RelationDao.getProjectRelations additive, Project Bible RELATIONSHIP MAP section dgn live session rows + empty hint + narrow-safe layout, character_relation_map_service_test 2 PASS + relationship_map_ui_test 2 PASS RED-verified, focused relations+bible 49 PASS, analyze No issues, full 3305 PASS / 1 FAIL concurrent, build windows PASS 34.2s); Timeline Core journey closed (2026-09-02 cron: production Material fix on SceneWorkspaceScreen._openTimeline route - InkWell in TimelineClip previously crashed No Material widget found saat membuka Timeline dari scene nyata; timeline_scene_journey_test membuktikan jalur produksi lengkap SceneWorkspaceScreen Open Timeline -> ensureTimelineForScene -> live clip drag -> MoveTimelineClipCommand via mutation bus -> timing 2s persist di SQLite live; timeline_move_persistence_test membuktikan moved clip timing survive close/reopen database; timeline suite 13 PASS, story+workspaces 197 PASS, analyze No issues, build windows debug PASS 26.9s); Relationship Map evidence closure landed (2026-09-02 cron: restart persistence via close/reopen di character_relation_map_service_test, narrow 390px render + empty state di relationship_map_ui_test, focused 6 PASS, bible+relations 51 PASS, analyze No issues, diff --check PASS; row Relationship Map naik VERIFIED, tanpa kode produksi baru); Lore-link unified catalog closed (2026-09-02 cron, commit 054e274: `CreateLoreEntityService.loadCatalog` kini menyatukan entitas prioritas Core project-scoped Characters (displayName/biography), Environments/Locations (name/description), dan Factions (name/ideology) ke katalog lore-link autocomplete, duplicate detection, dan broken-link classification; `test/features/bible/lore_catalog_core_entities_test.dart` 3 PASS RED-terverifikasi (0/3 sebelum patch); lore+backlinks suite 31 PASS, bible suite 42 PASS, analyze No issues, full suite 3312 PASS / 1 FAIL (app_bootstrap_test concurrent 145.20, untouched), windows debug build PASS, diff --check PASS); universal rename wiring closed (2026-09-02 cron, commit 14e1ae8: RenameCharacterCommand default retargets lore-link segments via LoreBacklinkService pada execute/undo/redo, teks polos + escape literal utuh; rename_character_command_lore_retarget_test 2 PASS RED-terverifikasi, focused rename/backlinks 18 PASS, character+project_resilience+commands 120 PASS, analyze No issues, windows debug build PASS, diff --check PASS); cross-workspace search UI journey closed (2026-09-02 cron d: GlobalSearchLauncher menyatukan Assets rows + Factions table dalam satu query, showGlobalSearchSheet di 'Cari di Proyek' ProjectOverview wired ke resolver, pilih karakter menulis SelectionModel ter-typed ke shared selectionProvider lalu resolver membuka Character Workspace, pilih faksi memicu callback navigasi; global_search_journey_test 2 PASS dgn RED wiring via stash round-trip, global_search_launcher_test 1 PASS RED-terverifikasi, workspace+assets 30 PASS, story+bible+character 249 PASS, analyze workspace No issues, diff --check PASS); sisa Lore Notes contract (145.29): native proof; uniform route gating (app_router.dart concurrent 145.20) remains open |
| 145.28 | Writing Room Focus | VERIFIED (nephthys, 2026-09-02 cron: evidence-closure reconciliation - seluruh objective exact sprint_145.json terbukti bukti eksekusi; boundary UNVERIFIABLE tersisa: native interaction klik/typing tanpa computer_use dan user validation yang menunggu Choi, keduanya bukan item objective) | `docs/audits/writing-room-focus.md`; mapping objective: writing canvas VERIFIED (multiline draft TextField + editor tests), chapter/scene navigation VERIFIED (hierarchy repository + scene selection memuat draft + tap path chapters panel), save state VERIFIED (DebouncedAutosave round-trip persistence + label dinamis 'Tersimpan HH:MM'/'Belum tersimpan' commit 7d9b0f4; DurableAutosaveCoordinator ef82042 kini menyatukan debounce+journal durable no-silent-loss), word count VERIFIED ('N kata' wired + tested; audit 27 Agu yang mengklaim gap sudah stale), focus mode VERIFIED (FocusWritingSession domain 109.20 + tombol 'Mode Fokus'/'Keluar Fokus' 7d9b0f4 + Esc keyboard exit ea42539 RED-terverifikasi), search/lore reference VERIFIED (lore autocomplete + binding '[[...' + NOVEL SEARCH + GLOBAL SEARCH sheet 295f528), minimal distraction VERIFIED (panel chrome disembunyikan saat fokus aktif via if(!_isFocusActive), SCENE EDITOR tetap; narrow render tanpa overflow). Bukti fresh HEAD e926cdd run ini: focused writing_room_focus + lore/backlinks/rename/global-search/catalog 42 PASS, flutter analyze No issues, full flutter test 3323 PASS + 1 FAIL concurrent 145.20 (app_bootstrap_test, untouched), windows debug build PASS 39.6s, diff --check PASS. |
| 145.29 | Lore Linking and Search | VERIFIED (nephthys, 2026-09-02 cron: evidence-closure reconciliation - seluruh objective exact sprint_145.json terbukti bukti eksekusi; native interaction UNVERIFIABLE dari cron, bukan item objective) | `docs/audits/lore-linking-and-search.md`; mapping objective: fast discoverable link/reference ke characters/locations/factions/lore VERIFIED (loadCatalog unified 054e274 + GlobalSearchLauncher 295f528 + LoreLinkSuggester ranking + autocomplete), broken-link handling VERIFIED (LoreLinkClassifier + scanIntegrity + ambiguous candidates), rename safety VERIFIED (ProjectLoreLinkEditor segment edits + RenameCharacterCommand loreRetarget default 14e1ae8 - satu-satunya rename command produksi di tree kini ter-wire; tanpa rename command lain untuk entity non-character, kontrak 'every entity rename command' terpenuhi tanpa command spekulatif), scope VERIFIED (retarget project-scoped regression fix + katalog + launcher per proyek), keyboard flow VERIFIED (arrow/Enter/Esc). Bukti fresh HEAD e926cdd run ini: focused lore/backlinks 31 + rename retarget 2 + global search journey 2 + launcher 1 + catalog 3 + focus 3 = 42 PASS, flutter analyze No issues, full flutter test 3323 PASS + 1 FAIL concurrent 145.20 (untouched), windows debug build PASS 39.6s, diff --check PASS. |
| 145.30 | Autosave Snapshot and Crash Recovery | PARTIAL (nephthys, 2026-09-01 cron i; durable autosave coordinator 2026-09-02) | `docs/audits/autosave-snapshot-crash-recovery.md`; autosave coordinator, in-memory journal, JSON snapshots, checksum-protected backup/restore, crash marker, and 8 resilience tests pass, AND durable draft journal slice (commit fd2d0bc): `DurableDraftJournal` atomic stage/rename/acknowledge wired into StoryWorkspaceScreen (stage before autosave, acknowledge after durable save) + WorkspaceResolver binding to `recovery/draft-journal`, `test/features/project_resilience/durable_draft_journal_test.dart` 4 PASS incl. crash-simulation no-silent-loss journey, full suite 3245 PASS, analyze clean, windows build PASS; recovery startup prompt UI landed (panel DRAFT RECOVERY dekat puncak StoryWorkspaceScreen: entri pending dari DurableDraftJournal.pendingEntries(), tombol 'Pulihkan Draft' (saveSceneDraft -> acknowledge) dan 'Buang' (acknowledge saja) per entri, busy-guard _recoveryBusy, panel absen saat journal kosong; test/features/story/novel_recovery_prompt_ui_test.dart 3 PASS); AND disk-full/permission failure injection closed as evidence-first (2026-09-01 cron j: `test/features/project_resilience/durable_draft_journal_failure_injection_test.dart` 2 PASS - orphan .tmp dari stage terputus tidak menutupi draf valid terakhir di pendingEntries, dan kegagalan tulis di-propagasi dari stage via teknik .tmp-as-directory yang deterministik lintas platform (chmod a-w tidak efektif pada direktori Windows); implementasi journal sudah benar, no production code, pola PASS-first; full suite 3250 PASS, analyze clean, windows build PASS); durable autosave coordinator CLOSED (2026-09-02 cron, commit ef82042: DurableAutosaveCoordinator menyatukan debounce + journal durable + persist dengan urutan no-silent-loss - stage atomic sebelum debounce, acknowledge setelah persist sukses, dispose mem-flush pending, retry saat save in-flight; test/features/story/durable_autosave_coordinator_test.dart 5 PASS RED-terverifikasi dua lapis; full suite 3323 PASS + 1 FAIL concurrent 145.20 untouched); wiring screen produksi CLOSED commit 291a871 (flush-on-dispose RED-terverifikasi, full suite 3324 PASS + 1 FAIL concurrent untouched); native process-kill harness CLOSED (2026-09-03 cron, commit b191d53: child process Dart nyata men-stage draf lalu di-hard-kill via Process.kill/TerminateProcess - journal memulihkan konten staged penuh, .tmp setengah jadi tidak pernah dianggap sumber pemulihan; RED dua lapis: fixture absen lalu flutter_tester isolate error, fix resolve dart.exe via FLUTTER_ROOT; test/features/project_resilience/durable_draft_journal_process_kill_test.dart 2 PASS, story+resilience 256 PASS, analyze No issues, full suite 3413 PASS, windows debug build PASS 20.6s, diff --check PASS); sisa: native interaction proof (butuh sesi interaktif) |
| 145.31 | Custom Local Storage | PARTIAL (nephthys, 2026-09-02) | `docs/audits/custom-local-storage.md`; root override/fallback, UUID package paths, registry atomicity, health/open, portable relocation seams, 18 persistence tests, plus custom-storage domain c9da6dc (normalize/probe driveMissing-permission-space, nearestExistingAncestor, persisted schema-v1 store, bindProject, relink guard no-empty-replacement, 8 domain tests) verified, plus free-space host-akurat + relink end-to-end 95fee4a (HostDriveSpaceReader + PlatformDriveSpaceReader via PowerShell Get-PSDrive, DefaultStorageProbe seam injectable, probe melaporkan freeBytes host nyata + notEnoughSpace shortage nyata, host_drive_space_reader_test 4 PASS RED-terverifikasi termasuk relink flow end-to-end bind->hapus->relink->healthy; full suite 3417 PASS, build windows PASS) verified; UI pemilihan lokasi remain open; wiring ProjectPaths/PackageService CLOSED (2026-09-03 cron: commit slice ini - ProjectPaths menerima customStorageStore/fallbackRootDirectory, root() memilih lokasi custom healthy, fallback default saat missingDrive, rootDirectoryFile() untuk registry mesin-lokal; customStorageStoreProvider + projectPathsProvider wired sehingga ProjectPackageService create/open + session manager otomatis mengikuti lokasi custom; wiring test 5 PASS RED-terverifikasi; regresi persistence+projects 59 PASS; full suite 3422 PASS / 0 FAIL; build windows PASS) |
| 145.32 | Single Sync Authority Rule | PARTIAL (nephthys, 2026-08-27; persisted authority closed 2026-09-03 cron) | `docs/audits/single-sync-authority.md`; cloud/external-folder authority policy and denial warning pass the new vertical test plus collaboration suite (10 tests); persisted authority CLOSED (commit 00a9041: SyncAuthorityStore JSON v1 atomic tmp+rename per proyek, corrupt/missing = no-ownership, PersistedSyncAuthority claim/restore/release lintas proses, restored ownership menolak authority kedua dengan warning cloud+external folder; slice policy 2026-08-27 yang untracked diadopsi commit bersama test-nya; RED terverifikasi Method not found PersistedSyncAuthority; store test 6 PASS, collaboration suite 38 PASS, scoped analyze No issues, diff --check PASS, windows debug build PASS 31,0s); runtime service wiring (cloud_sync_service.dart concurrent), conflict flow integration, UI denied state, dan native interaction remain open |
| 145.33 | Portable Import Export | PARTIAL (nephthys, 2026-08-27) | `docs/audits/portable-import-export.md`; portable ZIP round-trip, cache exclusion, relocated-copy registry, path traversal rejection, cleanup, and backup integrity pass 6 tests; archive checksum metadata, secret exclusion, migration compatibility, complete rollback, large-project evidence CLOSED (commit 7641236: portable_large_project_test.dart 3 PASS - 250 aset + 2 blob 256 KiB + 60 workspace export/import/registry round-trip, checksum valid); registry-state transactional import + rollback CLOSED (2026-09-03c cron, commit 991dd53: test-only portable_import_transaction_test.dart 2 PASS - post-extraction registry upsert failure me-rollback direktori package hasil import DAN registry kembali persis ke state pre-import; copy import mendaftar aditif tanpa mengganggu project pre-existing; TEMUAN terdokumentasi: asCopy:false pada destination dengan package existing menimpa non-atomik file demi file dan cleanup failure menghapus direktori existing - UI produksi hanya memakai asCopy:true sehingga risiko tidak tercapai dari jalur UI, perbaikan engine BLOCKED file concurrent); corrupted-input matrix CLOSED (2026-09-03d cron, test-only portable_corrupt_input_test.dart 7 PASS PASS-first: missing manifest, missing database, truncated zip, non-zip, manifest malformed dengan checksum cocok kontennya, manifest future schema 99 > 16 semua ditolak FormatException + positive control arsip valid terimpor bersih); compatibility/migration CLOSED (2026-09-03e cron, test-only portable_schema_compatibility_test.dart 3 PASS PASS-first: arsip DB v53 diimpor lalu dibuka jalur produksi ProjectDatabaseService.open -> migrasi maju 53->59 tanpa kehilangan baris Core; manifest lama schemaVersion 15 diterima; CURRENT v59 round-trip tanpa migrasi; TEMUAN RISIKO: DB user_version 60 > app 59 diterima open dan diturunkan diam-diam - guard future-schema BLOCKED project_database_platform_io.dart region concurrent); sisa 145.33: secret exclusion (BLOCKED file concurrent), destination-collision rollback, guard future-schema DB, native interaction UNVERIFIABLE |
| 145.34 | Local Backup and Restore | PARTIAL (nephthys, 2026-09-03 cron b: restore preview + alternate destination CLOSED; retention engine tetap) | `docs/audits/local-backup-restore.md`; local backup/restore dengan SHA-256 manifest/database/workspace integrity, WAL checkpoint, emergency pre-restore backup, dan snapshot retention primitives pass resilience tests (sibling 145.34 integrity slice uncommitted di project_recovery_services.dart, dijaga); retention enforcement engine CLOSED commit 5ce2c93: BackupRetentionService (Step 24.26) kini wired ke ProjectResilienceController.createBackup - per-category prune-oldest menghapus direktori backup on-disk + row ProjectBackups via removeBackup baru, policy injectable default 20/50, backup_retention_enforcement_test 2 PASS RED-terverifikasi (3 manual dgn maxManual=2 menyisakan exactly second+third; default preserves 4), project_resilience suite 108 PASS, scoped analyze No issues, diff --check PASS; sisa 145.34: configurable location, full failure injection, Free-access proof, native interaction UNVERIFIABLE; AND 2026-09-03 cron b slice (commit da68cf1): restore preview + alternate destination + migration-aware classification CLOSED - ProjectBackupRestorePreview.compute read-only names/schema/classification current|migrationForward|blocked + warnings; restoreToAlternateDestination salin backup ke package UUID baru di destinationRoot tanpa menyentuh live project/backup, tolak schema lebih baru, rollback saat gagal; RED terverifikasi (Undefined name); bug import stub platform tertangkap RED (barrel project_database_platform.dart selalu null) -> fix ProjectDatabaseService conditional io/web import; focused 3 PASS, project_resilience 111 PASS, analyze No issues, diff --check PASS, windows debug build PASS 38.5s, full suite digate run ini; AND 2026-09-03 cron d slice (commit d8b99a8): configurable location + failure injection CLOSED at engine boundary - BackupLocationPolicy (customBackupRoot optional + configureCustomBackupRoot runtime, resolveBackupRoot fail-safe fallback ke internal default saat root hilang/invalid, isExternalBackup classifier), createBackup passes destinationRoot, ProjectBackups.relativePath menyimpan path absolut utk snapshot eksternal, retention prune lintas lokasi via _resolveBackupDirectory, backup_configurable_location_test 2 PASS RED-terverifikasi (custom write + missing-root fallback dgn cross-location retention maxManual=1), backup_copy_stage_failure_test 2 PASS (invalid-root fail-safe + restore rollback manifest/workspace pada workspace copy-stage failure via Windows file-lock harness), focused 4 PASS, project_resilience 115 PASS, analyze No issues, full suite 3431 PASS / 0 FAIL, build windows debug PASS 27.7s, diff --check PASS, guard PASS pre+post; sisa 145.34: assets/emergency failure injection, settings UI, Free-access proof CLOSED (commit 51e1610): test/features/project_resilience/backup_free_access_test.dart 2 PASS - (1) journey tanpa akun ProjectSessionManager.open + createBackup x2 + preview current + in-place restore manifest dipulihkan + restoreToAlternateDestination package baru intact, tanpa parameter akun/plan (tidak ada konsep plan/tier/entitlement di lib); (2) guard statis token premium/paywall/subscription/entitlement/licensing/monetization/requirePlan/currentPlan/core-auth/features-account/features-collaboration di lib/features/project_resilience + lib/core/persistence zero violation; focused 2 PASS, project_resilience 117 PASS, analyze No issues 97.2s, diff --check PASS, full suite 3433 PASS / 0 FAIL, build windows debug PASS 26.0s, guard PASS pre+post; sisa 145.34: assets/emergency failure injection (blocker: project_recovery_services.dart sibling integrity slice uncommitted), settings UI, native interaction UNVERIFIABLE |
| 145.35 | Clean Manuscript Export | PARTIAL (nephthys, 2026-09-03 cron: TXT export UI wiring landed) | `docs/audits/clean-manuscript-export.md`; clean Markdown/story export, private/internal marker removal, deterministic fingerprint, chapter/scene ordering, preflight/preview, profiles, and DOCX artifact pass 25 tests; plain TXT writer CLOSED commit a51a68a (`StoryTxtExporter` chapter-order page-break TXT tanpa markup/watermark, RED terverifikasi, focused 2 PASS, export suite 30 PASS, full suite 3326 PASS + 1 FAIL concurrent untouched, windows build PASS); full publishing fidelity, explicit encoding matrix, complete metadata propagation, and cross-format no-watermark proof remain open; AND 2026-09-02 cron run2 slice (commit 27712d8): encoding matrix CLOSED (test/features/export/story_export_encoding_matrix_test.dart 3 PASS: Unicode CJK+emoji+Arabic+musical-symbol fixture round-trip byte-exact TXT tanpa BOM / Markdown heading / DOCX ZIP+XML, zero U+FFFD, escape XML terbatas 5 karakter XML), metadata propagation CLOSED (story_txt_exporter menerima ExportProfile?: front matter title+author menggantikan header judul story saat ada, chapterRules prefix+numberingStart masuk body; test/features/export/story_export_metadata_propagation_test.dart 3 PASS, RED terverifikasi: No named parameter profile), cross-format no-watermark proof CLOSED (test/features/export/story_export_no_watermark_test.dart 4 PASS: TXT/MD/DOCX privateMaster tetap bersih bahkan pada WatermarkMode.always - applyWatermark false, overlay null, manifest.watermarkApplied false, teks watermark absen dari bytes; kontras publicPreview previewOnly applyWatermark true membuktikan planner aktif dan artefak master tidak pernah ditimpa). Bukti: export suite 40 PASS, analyze No issues 12.0s, full suite 3336 PASS + 1 FAIL (app_bootstrap_test concurrent 145.20, untouched, delta +10 eksak), windows debug build PASS 20.3s, diff --check PASS; AND 2026-09-03 cron slice (commit 761323a): TXT export UI vertical wiring CLOSED - tombol Export TXT di _exportActions() Story Workspace + handler _exportTxt() (guard binding sama MD/DOCX, snackbar TXT diekspor), RED terverifikasi (0 widgets Export TXT), test/features/export/story_txt_export_ui_test.dart 2 PASS (journey tap -> story.txt nyata dgn judul+draft+snackbar via tester.runAsync utk dart:io async; guard onPressed null tanpa binding), focused 57 PASS, full suite 3435 PASS / 0 FAIL (delta +2 eksak), analyze No issues 10.4s, windows debug build PASS, diff --check PASS, guard PASS pre+post. Sisa 145.35: publishing fidelity DOCX render-compat eksternal, metadata encoding-aware utk MD/DOCX (opsi kini hanya di TXT writer), native interaction UNVERIFIABLE (cron). AND 2026-09-03 cron mdenc slice (commit 5bcf275): metadata encoding-aware utk MD/DOCX CLOSED - paritas MD writer (StoryMarkdownExporter.writeExport menerima Encoding encoding = utf8 + bool bom = false, paritas TXT 0b3d34e, default tetap UTF-8 tanpa BOM; story_markdown_encoding_options_test 3 PASS RED-terverifikasi simbol encoding/bom) + bukti encoding-aware DOCX PASS-first (OOXML melarang BOM di part XML; story_docx_encoding_evidence_test 1 PASS: 4 part XML prolog UTF-8 tanpa BOM, Unicode byte-exact); export suite 53 PASS (delta +4 eksak), analyze scoped No issues, windows debug build PASS 24.0s, diff --check PASS; sisa 145.35: publishing fidelity DOCX render-compat eksternal, native interaction UNVERIFIABLE. AND 2026-09-03 cron enc slice (commit 0b3d34e): encoding non-UTF-8 CLOSED pada TXT writer - StoryTxtExporter.writeExport menerima Encoding encoding = utf8 + bool bom = false, writeAsBytes dgn prefix EF BB BF saat bom=true, default tetap UTF-8 tanpa BOM (kontrak matrix 27712d8 utuh); RED terverifikasi (No named parameter encoding/bom); test/features/export/story_txt_encoding_options_test.dart 3 PASS (latin1+BOM byte-exact, utf8+BOM round-trip, default tanpa BOM); export suite 49 PASS, focused TXT 7 PASS, analyze No issues, windows debug build PASS 33.1s, diff --check PASS |
| 145.36 | AI Optional Boundary | PARTIAL (nephthys, 2026-08-27) | `docs/audits/ai-optional-boundary.md`; optional local AI runtime, secure credentials, provider routing, transfer/cost gates, cancellation, redaction, and failure fallback pass 39 tests; unified BYOK/context/consent policy CLOSED (2026-09-03 cron: AiPolicy.byDefault() rulebook stateless di lib/features/ai/domain/ai_policy.dart - byokReady false -> denied, contextSummary kosong -> denied, externalTransfer tanpa consent -> denied fail-closed; ai_policy_test.dart 6 PASS RED-terverifikasi) + no-startup-dependency proof CLOSED (2026-09-03 cron: ai_no_startup_dependency_test.dart 4 PASS - 7 file bootstrap inti tidak import modul AI + policy fail-closed tanpa runtime); focused AI suite 125 PASS, analyze No issues, build windows debug PASS, diff --check PASS; sisa open: BYOK UX (butuh keputusan UI), native interaction | redaction property-test menyeluruh CLOSED (2026-09-03 cron: test/core/security/secret_redaction_property_test.dart 12 PASS PASS-first evidence closure - mask exhaustive lengths 1..64 konsisten 3-char+asterisks, redact replace-all 10 secret + idempoten + overlapping longer-secret-wins tanpa residue, scanner deteksi 4 format credential exact + zero false-positive pada prosa; primitives produksi SecretRedactor/SecretScanner sudah benar, tanpa perubahan production code; focused 52 PASS, analyze full No issues, diff --check PASS)
| 145.37 | Navigation Reduction | PARTIAL (nephthys, 2026-08-27) | `docs/audits/navigation-reduction.md`; desktop/mobile shells, routes, adaptive layouts, and 11 navigation tests pass; target Core primary destinations and hiding/feature-gating unready modules remain open |
| 145.38 | Settings Reduction | PARTIAL (nephthys, 2026-08-27) | `docs/audits/settings-reduction.md`; theme, security, language, plugin settings and persistence pass 23 tests; unified Core-first settings surface, settings route, and feature-gated cloud/AI/community/publishing/payment/developer sections remain open |
| 145.39 | Non-Core Preservation and Disablement | PARTIAL (nephthys, 2026-08-27; reactivation dependency map closed 2026-09-03 cron) | `docs/audits/non-core-preservation-disablement.md`; 13 feature flags default OFF, audited workflow override, plugin enable/disable persistence, and 20 regression tests pass; reactivation dependency map CLOSED (2026-09-03 cron: `ReactivationDependencyMap.entries` di lib/core/capabilities/reactivation_dependency_map.dart mengikat 10 capability deferred kanonik dari core_mvp_scope_reset_spec.json deferred_until_evidence ke layer/owningFlag/modul-tree/entry-evidence 145.17; test arsitektur reactivation_dependency_map_test.dart 6 PASS RED-terverifikasi: 10/10 id kanonik, id unik, modul yang dideklarasikan ada di tree, tidak ada capability mengklaim modul Core, default off/deferred, empty-modules hanya platform follow-up; focused 6 PASS, regresi reactivation+feature_flags+architecture 17 PASS, analyze No issues, full suite 3441 PASS / 0 FAIL delta +6 eksak, windows debug build PASS 28.0s, diff --check PASS); primary-navigation removal and route gating (app_router.dart concurrent 145.20) remain open; persistence override flag CLOSED (2026-09-03 cron: FeatureFlagOverrideStore lib/core/feature_flags/feature_flag_override_store.dart skema JSON v1 atomik tmp+rename, unknown flag dropped on load + ditolak on save, missing/corrupt = clean defaults; FeatureFlagRegistry.restoreOverrides preload override + write-back pada enable/disable via _onChange, registry tetap primitive runtime, feature_flag_override_persistence_test.dart 8 PASS RED-terverifikasi simbol undefined; disabled-module data proof CLOSED (2026-09-03 cron: spoiler_module_data_proof_test.dart 4 PASS - gate OFF body tak eksekusi, data sumber utuh readable pasca-disable, preview terserialisasi bebas teks spoiler + bebas metadata internal, restart proses menetap akses disabled default OFF); focused 12 PASS, regresi flags+capabilities+workflow+plugin 57 PASS, full suite 3453 PASS / 0 FAIL delta +12 eksak, analyze No issues, windows debug build PASS, diff --check PASS, commit 20f1562) |
| 145.40 | Schema and Migration Fixtures | PARTIAL (nephthys, 2026-08-27) | `docs/audits/schema-migration-fixtures.md`; manifest/registry version guards, RC migration matrix, corrupt package detection, backup/rollback, and restart persistence pass 32 tests; dedicated fixture matrix CLOSED (commit 58d57b5: test/features/project_resilience/schema_migration_fixtures_test.dart 4 PASS - CURRENT v59 fresh create + reopen no-op; OLD v53 forward migration preserves Core rows no-silent-discard incl. voice default + v59 scope tables; CORRUPT database detected without crashing: schemaVersion null + open throws after SqliteException catch in readProjectDatabaseSchemaVersion; FUTURE manifest schemaVersion 99 rejected FormatException; RED terverifikasi SqliteException(26) sebelum catch; persistence+resilience+release+package regression 113 PASS, analyze No issues, build windows debug PASS 62.0s, diff --check PASS); exhaustive invariants gate CLOSED (2026-09-03 cron: group '145.40 exhaustive invariants gate' 58 test entry v1..v58 di schema_migration_fixtures_test.dart - fresh v59 seeded 1 Core asset row, rewind PRAGMA user_version ke entry, reopen tanpa crash + baris Core utuh; RED terverifikasi: entry v1..v16 crash duplicate column name sebelum guard; GREEN: helper _columnExists + guard probe pada SEMUA wave addColumn v3/v7/v8/v9/v15/v16/v17 + guard v58 voice digeneralisasi; focused 63 PASS, regresi resilience+release+database 150 PASS, analyze No issues, full suite + windows build di run ini); clean-Windows E2E execution remain open; AND 2026-09-02 run2 interrupted-migration forward recovery CLOSED (commit ed0f35f: guard idempoten di wave v58 voice add-column - probe SELECT voice sebelum m.addColumn krn createTable waves sudah IF NOT EXISTS idempotent tapi addColumn tidak; RED terverifikasi SqliteException(1) duplicate column name: voice pada fixture HALF-APPLIED user_version 53 dgn wave objects 54..59 manual via raw sqlite3; test HALF-APPLIED reopen cleanly 5/5 PASS, regresi 92 PASS, analyze No issues, build windows debug PASS 28.2s, full suite 3343 PASS / 1 FAIL konkuren 145.20 untouched, diff --check PASS) |
| 145.41 | Core Automated Test Pyramid | PARTIAL (nephthys, 2026-08-27) | `docs/audits/core-automated-test-pyramid.md`; live inventory finds 124 domain-oriented, 4 integration-named, 14 contract, and 152 widget-test files; Core vertical matrix passes 78 tests; clean-Windows E2E journey CLOSED (2026-09-02 cron: `test/features/story/core_e2e_journey_test.dart` 1 PASS, RED terverifikasi sebagai file baru tanpa kode produksi baru - journey create package+session -> character+identity+voice -> story/arc/chapter/scene -> draft save -> searchNovel -> quickReferenceForScene -> StoryTxtExporter -> session close -> ProjectBackupService SHA-256 -> dirty mutation -> restore checksum rollback (DIRTY hilang, saga utuh) -> reopen session hierarchy+draft intact, isolated temp root tanpa menyentuh lokasi data user; story suite 150 PASS, analyze No issues, build windows debug PASS 22.3s, diff --check PASS); inventory pyramid refreshed 2026-09-03 cron: live re-count test/ (python scan) = 792 file (179 widget testWidgets / 613 unit-domain test() / 15 contract-named / 5 integration-named; widget by area: features 139, app 20, core 15, design_system 2, shared 2, release 1), integration_test/ native-driver tree tetap 0 file; native-driver tree dan native interaction proof remain open |
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

Evidence-closure 2026-09-01 cron: rekonsiliasi objective eksak
"Memverifikasi canonical identities, aliases, voice, visual notes,
relationships, genealogy if present, private notes, linking, history, and
quick reference" — mapping lengkap di
`docs/audits/character-workspace-core.md` (rekonsiliasi 2026-09-01):
identities/aliases/voice/visual notes/relationships/private notes/linking/
history/quick reference masing-masing VERIFIED via test eksekusi live;
genealogy = kondisional "if present", TIDAK present di Core character scope
(domain genealogy hanya di world_logic — stream sequential 110 SUSPENDED;
family bond Core via `AssetRelationType.relatedTo`) = N/A-DEFERRED.
Bukti fresh HEAD abdc6b8: focused 98 PASS, analyze No issues 14.8s,
full suite 3267 PASS / 1 FAIL (app_bootstrap_test — concurrent 145.20,
root-caused, tidak disentuh), windows debug build PASS 26.4s,
diff --check PASS, roadmap guard PASS pre-run. Native interaction
UNVERIFIABLE dari cron (tanpa computer_use) — bukan acceptance item
objective; dicatat jujur. Verdict: development-ready, bukan
production-ready. Full Core vertical journey tetap PENDING
(depends 145.30-145.35, 145.41-145.44).


## Run note 2026-09-02 (nephthys cron, Relationship Map evidence closure)

- Slice: hanya dua file test (relationship_map_ui_test.dart +390px render,
  character_relation_map_service_test.dart +close/reopen restart) — PASS-first
  evidence di atas contract 93470b3, tanpa kode produksi baru. Audit row
  Relationship Map: PARTIAL -> VERIFIED. Satu anchor-replace salah memakan
  penutup test (compile error) — ditemukan flutter test, diperbaiki, bukti
  akhir hanya dari file final.
- Bukti: focused 6 PASS, bible+relations suites 51 PASS, flutter analyze
  No issues (9.7s), git diff --check PASS. Full flutter test + windows debug
  build dijalankan di run ini; hasil final tercatat pada commit state note.
- 145.27 tetap PARTIAL: Lore Notes (145.29), uniform route gating
  (app_router.dart concurrent 145.20), user validation. Pointer tetap 145.27.

## Update 2026-09-02 (nephthys cron, universal rename wiring 145.27/145.29)

- Gap: baris objective 145.27 yang tersisa dan actionable adalah Lore Notes
  (uniform route gating terblokir app_router.dart milik concurrent 145.20).
  Sub-gap universal rename wiring milik kontrak 145.29 dipilih karena
  RenameCharacterCommand adalah satu-satunya rename command produksi.
- Slice: RenameCharacterCommand (lib/features/character/application/
  rename_character_command.dart) menerima LoreBacklinkService opsional yang
  default const aktif; _rename kini retarget segmen [[Nama]] via
  retargetOccurrences pada execute/undo/redo, arah selalu dari nama lain
  menuju nama yang diterapkan; teks polos dan escape literal dijaga
  (asersi test). Site produksi (CharacterController.rename, CommandTypeRegistry
  replay di project_session_manager.dart) otomatis mendapat rename safety
  tanpa menyentuh file milik concurrent.
- RED terverifikasi dua kali: (1) compile error No named parameter with the
  name 'loreRetarget'; (2) konten tidak berubah ketika default wiring
  di-stash — stash round-trip digunakan untuk membuktikan RED genuine.
- Bukti: test/features/character/
  rename_character_command_lore_retarget_test.dart 2 PASS; focused
  rename/backlinks 18 PASS; regression character+project_resilience+commands
  120 PASS; flutter analyze No issues; git diff --check PASS; windows debug
  build dijalankan di run ini (hasil final pada catatan state); full suite
  berjalan di run ini (hasil final pada catatan state). Commit 14e1ae8.
- 145.27 tetap PARTIAL: cross-workspace search UI journey (145.29), uniform
  route gating (app_router.dart concurrent 145.20), native interaction
  UNVERIFIABLE dari cron, user validation. Pointer tetap 145.27.

## Update 2026-09-02 (nephthys cron d, cross-workspace search UI journey 145.27/145.29)

- Gap: baris "Global search UI" di audit lore-linking-and-search masih PARTIAL;
  ini juga gap terakhir 145.27 yang actionable dari cron (uniform route gating
  terblokir app_router.dart milik concurrent 145.20; native interaction butuh
  sesi interaktif).
- Slice: `GlobalSearchLauncher`
  (lib/features/workspace/application/global_search_launcher.dart) menyatukan
  empat domain Core dalam satu query — baris universal `Assets`
  (character/environment/story via `AssetDao.getAllAssets()`) + tabel
  `Factions` (via `FactionRepository.listForProject`, tanpa baris Assets);
  ranking deterministik exact > prefix > substring lalu abjad, scope per
  proyek, filter tipe opsional, query kosong menghasilkan kosong.
- UI: `showGlobalSearchSheet`
  (lib/features/workspace/presentation/global_search_sheet.dart) dipanggil
  dari tombol 'Cari di Proyek' di `ProjectOverview` (state tanpa seleksi);
  memilih hit asset menulis SelectionModel ter-typed ke shared
  `selectionProvider` (jalur produksi yang sama dengan Explorer) lalu
  resolver membuka workspace sesuai tipe; memilih hit faksi memicu callback
  navigasi khusus (faksi belum punya workspace record-selection).
- RED terverifikasi: (1) launcher — Method not found: GlobalSearchLauncher;
  (2) wiring — stash round-trip workspace_resolver.dart: tanpa wiring,
  'Cari di Proyek' 0 widgets (Expected exactly one, Actual 0).
- Bukti: test/features/workspace/global_search_journey_test.dart 2 PASS
  (live session real package+SQLite); global_search_launcher_test.dart 1 PASS;
  workspace+assets 30 PASS; story+bible+character 249 PASS; dart analyze
  lib/features/workspace No issues; dart format scoped 3 file; git diff
  --check PASS. Full suite + windows debug build dijalankan di run ini
  (hasil final pada catatan state).
- 145.27 tetap PARTIAL (objective memuat user evidence + uniform route gating
  yang tidak actionable dari cron); baris Lore Notes/cross-workspace search
  naik VERIFIED pada audit. Pointer tetap 145.27.

## Update 2026-09-02 (nephthys cron b, 145.28 focus keyboard exit)

- Gap: baris 145.28 menyisakan "focus shortcut/keyboard (belum di-wire ke
  global shortcut)" sebagai satu-satunya gap UI yang actionable dari cron
  (uniform route gating tetap terblokir app_router.dart milik concurrent
  145.20; native interaction UNVERIFIABLE dari cron).
- Slice: `StoryWorkspaceScreen.build` kini membungkus konten dengan
  `CallbackShortcuts` berbinding `SingleActivator(LogicalKeyboardKey.escape)`
  ke `_handleFocusEscape`, ditambah `Focus(autofocus: true)` di dalamnya agar
  subtree selalu punya node fokus. Handler hanya menutup sesi aktif
  (`_focusSession?.exit(viaKeyboard: true)`) sehingga di luar mode fokus
  pintasan no-op dan navigasi rutin tidak terganggu. Alasan keluar tercatat
  sebagai `FocusExitReason.keyboard` sesuai kontrak domain 109.20.
- RED terverifikasi: `testWidgets('escape key exits active focus session via
  keyboard reason')` gagal sebelum wire (chrome CHAPTERS tidak kembali setelah
  Esc); GREEN setelah implementasi.
- Pelajaran wiring: `CallbackShortcuts` memasang `Focus(canRequestFocus:
  false)` — key event hanya mencapai handler bila fokus berada di DALAM
  subtree-nya; tanpa `Focus(autofocus: true)` internal, penghapusan chrome
  saat fokus aktif memindahkan fokus ke scope induk dan pintasan mati.
- Bukti: writing_room_focus_test 3 PASS; focused + lore_link_autocomplete 19
  PASS; story suite 143 PASS; flutter analyze No issues (3 warning warisan di
  2 test file slice 145.27 milik sendiri ikut dibersihkan, commit sama);
  git diff --check PASS; flutter build windows --debug PASS 26.7s; full suite
  3318 PASS + 1 FAIL (app_bootstrap_test, concurrent 145.20, tidak disentuh);
  diff build dipastikan additive-only (0 token hilang, counter widget seimbang).
- 145.28 tetap PARTIAL: native interaction (UNVERIFIABLE dari cron), user
  validation evidence. Pointer tetap 145.27.

## Update 2026-09-02 (nephthys cron, 145.30 durable autosave coordinator)

- Gap: baris 145.30 menyisakan "integrasi SaveCoordinator/AutosaveJournal
  lama dengan journal durable" sebagai satu-satunya gap domain yang
  actionable dari cron (uniform route gating milik concurrent 145.20;
  native interaction UNVERIFIABLE dari cron).
- Slice: `DurableAutosaveCoordinator`
  (`lib/features/story/application/durable_autosave_coordinator.dart`)
  menyatukan debounce + journal durable + persist (detil di audit
  autosave-snapshot-crash-recovery.md Update 2026-09-02). RED terverifikasi
  dua lapis (Method not found; race test gagal tanpa retry).
- Bukti: focused 5 PASS; story+resilience 189 PASS; flutter analyze No
  issues; git diff --check PASS; flutter build windows --debug PASS 37.9s;
  full suite 3323 PASS + 1 FAIL (app_bootstrap_test, concurrent 145.20,
  untouched; delta +5 eksak).
- 145.30 tetap PARTIAL: sisa native process-kill harness, wiring screen
  produksi (story_workspace_screen.dart concurrent), native interaction
  proof. Pointer tetap 145.27.
## Update 2026-09-02b (nephthys cron, 145.30 wiring screen produksi)

- Gap 'wiring screen produksi ke koordinator' CLOSED: `story_workspace_screen.dart`
  kini bebas dari perubahan concurrent agen lain, sehingga slice wiring
  menjadi actionable. Commit 291a871 (3 file, +187/-13):
  `StoryWorkspaceScreen` memakai `DurableAutosaveCoordinator` (debounce +
  journal durable + persist satu urutan no-silent-loss) menggantikan blok
  inline `DebouncedAutosave` + `DurableDraftJournal`; `dispose()` mem-flush
  draf yang masih menunggu debounce; `DurableAutosaveCoordinator.onSaved`
  (optional) dipanggil setelah persist+acknowledge untuk update label
  'Tersimpan HH:MM' (kontrak 145.28 tetap terpenuhi).
- RED terverifikasi: `test/features/story/durable_autosave_wiring_test.dart`
  gagal pada wiring lama (Expected 'draf baru sebelum debounce' / Actual
  'teks awal' - draf hilang saat dispose sebelum debounce timer fire).
- Bukti: wiring+koordinator+focus+recovery focused 12 PASS; story suite
  149 PASS; flutter analyze No issues (4 lint const di test slice
  diperbaiki); git diff --check PASS; flutter build windows --debug PASS
  29.1s; full suite 3324 PASS + 1 FAIL (app_bootstrap_test, concurrent
  145.20, untouched; delta +1 eksak).
- 145.30 tetap PARTIAL: sisa native process-kill harness + native
  interaction proof (butuh sesi interaktif / computer_use). Pointer tetap
  145.27 (sisa 145.27 non-actionable dari cron).


## Update 2026-09-02c (nephthys cron, 145.35 plain TXT writer)

- Gap 'plain TXT writer' di baris 145.35 CLOSED: `StoryTxtExporter`
  (commit a51a68a) menulis naskah TXT polos tanpa markup Markdown,
  mempertahankan urutan chapter -> scene, page break ASCII antar-chapter,
  draft verbatim, filename validation `.txt` + tolak path component.
  RED terverifikasi (`StoryTxtExporter isn't defined`).
- Bukti: focused 2 PASS, export suite 30 PASS, flutter analyze No issues,
  git diff --check PASS, full suite 3326 PASS + 1 FAIL (app_bootstrap_test
  concurrent 145.20 untouched, delta +2 eksak), windows debug build PASS
  27.5s, roadmap guard PASS pre-run.
- 145.35 tetap PARTIAL (publishing fidelity, encoding matrix, metadata
  propagation, cross-format no-watermark proof terbuka). Pointer tetap
  145.27 (sisa 145.27 non-actionable dari cron: app_router concurrent,
  user validation butuh Choi).

## Update 2026-09-02 (nephthys cron, metadata propagation MD/DOCX 145.35)

- Gap 145.35 "metadata propagation MD/DOCX writer" ditutup: StoryMarkdownExporter
  dan StoryDocxExporter kini menerima ExportProfile (front matter title/author,
  chapter rules penomoran bab), dan DOCX menyertakan metadata OOXML
  docProps/core.xml (dc:title, dc:creator) yang terdaftar di [Content_Types].xml
  dan _rels/.rels. Writer tanpa profile tetap byte-identik perilaku lama
  (kompatibilitas fallback, konsisten dengan fidelity matrix 145.24).
- RED terverifikasi: "No named parameter with the name 'profile'" pada kedua
  writer (test/features/export/story_export_md_docx_profile_test.dart, 4 test).
- Bukti: export suite 44 PASS, analyze No issues (10.3s), full suite 3340 PASS +
  1 FAIL (app_bootstrap_test concurrent 145.20, untouched), windows debug build
  PASS 29.6s, git diff --check PASS, roadmap guard PASS pre-run.
- Commit: b6363d2 (3 file: 2 exporter + 1 test). 145.35 tetap PARTIAL: encoding
  non-UTF-8, publishing fidelity render-compat eksternal, native proof.
## Update 2026-09-02 (nephthys cron, 145.40 fixture matrix)

- Gap 145.40 "dedicated old/current/future/corrupt fixture matrix" ditutup:
  `test/features/project_resilience/schema_migration_fixtures_test.dart` 4 PASS
  (commit 58d57b5). CURRENT v59 fresh create + reopen no-op; OLD v53 -> v59
  forward migration membuktikan no-silent-discard (baris Character Core utuh,
  kolom voice v58 kembali sebagai default, tiga tabel scope layer v59 hadir);
  CORRUPT database terdeteksi tanpa crash; FUTURE manifest (schemaVersion 99)
  ditolak dengan FormatException.
- Perbaikan produksi minimal: readProjectDatabaseSchemaVersion menangkap
  SqliteException dan melaporkan null (file korup = tidak terbaca), bukan
  melempar ke pemanggil probe. RED terverifikasi: SqliteException(26) "file
  is not a database" sebelum patch.
- Bukti: focused 4 PASS; regression persistence+resilience+release+package
  113 PASS; flutter analyze No issues found!; git diff --check PASS;
  flutter build windows --debug PASS 62.0s.
- 145.40 tetap PARTIAL: exhaustive invariants lintas seluruh ordered
  migrations sebagai gate terpisah, forward recovery setelah interrupted
  migration sebagai workflow mandiri, dan clean-Windows E2E execution
  belum dibuktikan.

## Update 2026-09-02d (nephthys cron run 2, 145.40 interrupted-migration recovery)

- Gap 145.40 "interrupted-migration forward recovery workflow" ditutup
  (commit ed0f35f): wave v58 `voice` add-column kini idempotent terhadap
  state setengah-jadi (probe kolom live sebelum ALTER). Root cause: drift
  men-set user_version setelah onUpgrade selesai, sehingga crash mid-wave
  meninggalkan objek wave tanpa bump versi; open berikutnya menjalankan wave
  ulang dan `ALTER TABLE ADD COLUMN` gagal "duplicate column name" -
  `createTable` aman karena `IF NOT EXISTS`, `addColumn` tidak.
- Test: HALF-APPLIED fixture (raw sqlite3, tanpa migrator, definisi kolom
  eksak `TEXT NOT NULL DEFAULT ''`) -> open sukses, user_version 59, baris
  Character Core utuh. RED terverifikasi sebelum guard.
- Bukti: focused 5/5 PASS, regresi 92 PASS, analyze No issues, build windows
  debug PASS 28.2s, full suite 3343 PASS / 1 FAIL (app_bootstrap_test
  konkuren 145.20, untouched), diff --check PASS.
- 145.40 tetap PARTIAL: exhaustive invariants gate lintas ordered migrations,
  clean-Windows E2E execution.

## Update 2026-09-03 (nephthys cron, 145.40 exhaustive invariants gate)

- Slice: gate invariants exhaustif sebagai gate terpisah di
  `test/features/project_resilience/schema_migration_fixtures_test.dart`
  (group "145.40 exhaustive invariants gate", 58 test, entry v1..v58) plus
  guard forward-recovery produksi di `lib/database/project/project_database.dart`.
- Metode gate: fresh v59 create -> seed satu baris Core asset ->
  `PRAGMA user_version = entry` (state eksak crash mid-wave; drift
  menaikkan user_version hanya setelah onUpgrade selesai) -> reopen
  -> asersi user_version 59, baris Core utuh, tanpa crash.
- RED terverifikasi: sebelum guard, entry v1..v16 crash
  `SqliteException(1)` duplicate column name (addColumn waves
  v3/v7/v8/v9/v15/v16/v17 tidak idempotent terhadap schema yang sudah
  memuat kolomnya). Sisanya RED karena asersi data (test bug seeding,
  bukan bug produksi) - diperbaiki dgn seeding Core row.
- GREEN: `_columnExists(table, column)` via PRAGMA table_info + guard
  pada semua wave addColumn; guard v58 voice digeneralisasi memakai
  helper yang sama. Tanpa perubahan schema version (tetap 59), tanpa
  mengubah nama tabel/kolom.
- Bukti: focused 63 PASS (4 matrix + 1 half-applied + 58 gate);
  regresi project_resilience+release+database 150 PASS;
  `flutter analyze` No issues found! (8.2s); `git diff --check` PASS;
  full suite ~3.3k PASS (1 FAIL app_bootstrap_test konkuren 145.20,
  untouched); `flutter build windows --debug` PASS.
- Status 145.40 tetap PARTIAL: clean-Windows E2E execution masih open;
  D-SCHEMA-01 tetap OPEN (tidak ada schema bump).

## Update 2026-09-03 (nephthys cron, 145.30 native process-kill harness)

- Gap: sisa actionable 145.30 dari cron adalah native process-kill harness.
- Slice: commit b191d53 - harness kill-process OS nyata. Child Dart
  (fixture) men-stage draf ke journal, sinyal READY, hang; parent
  hard-kill (TerminateProcess) lalu membaca journal: konten dipulihkan
  penuh (no silent loss), .tmp setengah jadi tidak dianggap pemulihan.
- RED terverifikasi dua lapis: (1) fixture absen -> asersi existence
  gagal; (2) spawn pertama "Could not prepare isolate" karena
  Platform.resolvedExecutable = flutter_tester.exe di flutter test -
  fix resolve dart.exe via FLUTTER_ROOT + fallback dart test.
- Bukti: focused 2 PASS; story+resilience 256 PASS; analyze No issues;
  full suite 3413 PASS (app_bootstrap_test konkuren kini hijau);
  windows debug build PASS 20.6s; diff --check PASS.
- 145.30 tetap PARTIAL: sisa native interaction proof (butuh sesi
  interaktif). Pointer tetap 145.27.

## Update 2026-09-03 cron d2 (nephthys, archive integrity checksum 145.33)

- Gap terpilih: 145.33 Portable Import Export, acceptance "archive integrity
  checksum" (canonical: .vscriptor manifest/checksums/secret exclusion) -
  archive metadata checksum sebelumnya string kosong. File 145.27/145.31/
  145.34/145.35 sisanya non-actionable dari cron (app_router.dart concurrent
  63 ins, settings UI butuh keputusan Choi, publish fidelity eksternal),
  145.42 milik eksekutor lain.
- RED terverifikasi: Undefined name ArchiveIntegrity (test baru
  test/features/project_resilience/archive_integrity_test.dart).
- GREEN: ArchiveIntegrity.computeDirectoryChecksum - SHA-256 atas staging
  directory sebelum zip, sorted entry names, separator POSIX (backslash
  Windows dikonversi), meta entry dikecualikan; exporter menulis checksum
  nyata ke voidproject.archive.json; importer verify SEBELUM ekstraksi,
  kosong/hilang/tamper = FormatException Archive checksum mismatch.
- Bukti: archive_integrity_test 4 PASS, project_resilience suite 121 PASS,
  analyze scoped No issues, format scoped 1 changed, build windows debug
  PASS 32.6s, diff --check PASS. Full suite: see commit message + state.
- Sisa 145.33: secret exclusion (BLOCKED: portable_project_service.dart
  sibling workspaces slice uncommitted di region sama), compatibility/
  migration policy, rollback lengkap, large-project evidence.
- 145.27 tetap PARTIAL (route gating concurrent); pointer tetap 145.27.

## Update 2026-09-03 cron 10:xx (nephthys, Free-access proof 145.34)

- Gap: baris audit `Free access` masih UNVERIFIABLE (tidak ada
  entitlement/access-control test pada backup flow).
- Slice evidence-closure PASS-first (tanpa kode produksi): journey tanpa
  akun membuktikan backup/retention/preview/restore/alternate-destination
  berjalan tanpa parameter akun/plan; guard statis menolak token
  paywall/entitlement di pohon resilience.
- Commit: 51e1610 (test saja).
- Bukti: focused 2 PASS, project_resilience 117 PASS, analyze No issues
  97.2s, diff --check PASS, full suite 3433 PASS / 0 FAIL, build windows
  debug PASS 26.0s, guard PASS pre+post.
- Sisa 145.34: assets/emergency failure injection (blocker:
  project_recovery_services.dart sibling slice uncommitted), settings UI,
  native interaction UNVERIFIABLE. Pointer tetap 145.27.

## Update 2026-09-03 (nephthys cron, persisted sync authority 145.32)

- Gap yang dikerjakan: "persisted authority" dari row 145.32 — ownership
  cloud vs external folder kini bertahan lintas proses.
- Temuan: slice policy 2026-08-27 (`sync_authority_policy.dart` + test)
  ternyata untracked sejak dibuat; diadopsi commit `00a9041` bersama
  slice persistensi.
- Implementasi: `SyncAuthorityStore` (JSON v1 per proyek, atomic
  tmp+rename, corrupt/missing = tanpa ownership, projectId divalidasi)
  + `PersistedSyncAuthority` (claim lewat policy, restore saat proses
  baru, release menghapus file) di
  `lib/features/collaboration/application/sync_authority_store.dart`.
- RED terverifikasi: `Method not found: 'PersistedSyncAuthority'`.
- Bukti: store test 6 PASS; suite collaboration 38 PASS; scoped analyze
  No issues; diff --check PASS; windows debug build PASS 31,0s.
- 145.32 tetap PARTIAL: runtime service wiring (cloud_sync_service.dart
  concurrent milik sibling), conflict flow integration, UI denied state,
  native interaction. Pointer tetap 145.27.

## Update 2026-09-03 (nephthys cron, evidence-closure tabel Gap stale 145.30/145.32/145.35)

- Temuan: tiga tabel/row audit tidak pernah di-update setelah slice
  ditutup, sehingga status di audit lebih rendah daripada bukti live.
  Koreksi evidence-closure murni (tanpa kode produksi, tanpa file
  concurrent), diikat bukti executable fresh HEAD b4b35d5:
  1. 145.30 Autosave Snapshot and Crash Recovery - tabel Gap stale:
     Atomic save/Durable journal/No silent loss BLOCKED -> VERIFIED
     (DurableDraftJournal tmp+flush+rename, close/reopen, flush-on-dispose);
     Process-kill UNVERIFIABLE -> VERIFIED (harness OS kill b191d53);
     Autosave state + Visible status -> VERIFIED. Snapshots/User restore
     tetap PARTIAL; power-loss UNVERIFIABLE; disk-full BLOCKED.
     Bukti fresh: focused resilience inti 16 PASS (journal + failure
     injection + process-kill + coordinator + recovery prompt UI).
  2. 145.32 Single Sync Authority - row Persisted authority across
     restart BLOCKED -> VERIFIED (SyncAuthorityStore + PersistedSyncAuthority
     00a9041); bukti fresh sync_authority_store_test 6 PASS.
  3. 145.35 Clean Manuscript Export - row No watermark PARTIAL -> VERIFIED
     (story_export_no_watermark_test 27712d8: TXT/MD/DOCX private master
     bersih + kontras publicPreview); bukti fresh 12 PASS no-watermark +
     export_protection, export suite penuh 53 PASS.
- Status step tetap PARTIAL untuk 145.30/145.32/145.35 (sisa gap
  non-actionable dari cron: native interaction, file concurrent, keputusan
  produk Choi). Pointer tetap 145.27.

## Update 2026-09-03b (nephthys cron, evidence-closure tabel Gap 145.31)

- Tabel Gap audit 2026-08-27 + tabel status 2026-09-02 di
  docs/audits/custom-local-storage.md direkonsiliasi dengan slice landed
  milik sendiri: c9da6dc (store domain + probe seam), 95fee4a (free-space
  host-akurat + relink end-to-end), b826cec (wiring ProjectPaths/PackageService).
  Enam baris naik: User-selected BLOCKED->PARTIAL, Permission PARTIAL->VERIFIED
  (seam), Free-space BLOCKED/PARTIAL->VERIFIED (host), Missing-drive
  BLOCKED->VERIFIED (domain+wiring), Relink PARTIAL->VERIFIED (storage-level),
  No-empty-replacement PARTIAL->VERIFIED (domain). Doc-only; tanpa kode produksi.
- Bukti fresh HEAD 7c61688: flutter test custom_storage_location_test +
  host_drive_space_reader_test + project_paths_custom_location_wiring_test =
  17 PASS / All tests passed! (exit 0); git diff --check PASS.
- Sisa 145.31 tidak berubah: UI pemilihan lokasi (keputusan UI Choi),
  drive removal fisik + native interaction (UNVERIFIABLE dari cron).
- Pointer tetap 145.27; step 145.31 tetap PARTIAL.

## Update 2026-09-03b run2 (nephthys cron, evidence-closure Gaps 145.40)

- Bagian Gaps + Verdict docs/audits/schema-migration-fixtures.md (audit
  2026-08-27) direkonsiliasi dengan slice landed milik sendiri: fixture
  matrix (2026-09-02), forward recovery HALF-APPLIED (2026-09-02),
  exhaustive invariants gate 58 entry (2026-09-03). Tiga baris gap diberi
  penanda [CLOSED] (teks asli dipertahankan); Verdict kini menyebut
  evidence baru eksplisit dan menyimpan sisa gap yang benar:
  no-silent-discard proof lengkap semua tabel Core, clean-Windows
  execution, D-SCHEMA-01 OPEN. Doc-only; tanpa kode produksi.
- Bukti fresh HEAD 9949164: flutter test
  test/features/project_resilience/schema_migration_fixtures_test.dart =
  63 PASS / All tests passed! (exit 0); git diff --check PASS.
- Step 145.40 tetap PARTIAL (clean-Windows E2E UNVERIFIABLE dari cron).
  Pointer tetap 145.27.

## Update 2026-09-03c (nephthys cron, transactional import + rollback evidence 145.33)

- Gap terpilih: baris audit "Transactional import: PARTIAL" + "Rollback: PARTIAL
  (rollback terhadap existing project/registry state belum terbukti)" pada
  `docs/audits/portable-import-export.md`.
- Pemilihan step: file engine `portable_project_service.dart` tetap milik
  sibling (M, +14/-6 workspaces+path-guard), app_router/ai/settings/collaboration
  juga concurrent; 145.42 milik eksekutor lain; 145.43-145.50 butuh keputusan
  user/pilot. Slice test-only PASS-first pada file baru, tanpa kode produksi.
- Bukti (commit 991dd53): (1) post-extraction registry upsert failure ->
  PortableProjectImportCoordinator me-rollback direktori package hasil import
  DAN registry kembali persis ke state pre-import (single real project);
  (2) copy import mendaftar aditif, dua project pre-existing tetap utuh.
- Gates: focused 2 PASS; project_resilience suite 127 PASS / 0 FAIL;
  flutter analyze No issues found! (145.2s); flutter build windows --debug
  PASS 42.6s; git diff --check PASS; roadmap_guard PASS pre+post.
- TEMUAN risiko (terdokumentasi, bukan regresi): import asCopy:false pada
  destination dengan package existing menimpa file demi file secara
  non-atomik; cleanup failure menghapus direktori existing. UI produksi hanya
  memakai asCopy:true sehingga risiko tidak tercapai dari jalur UI saat ini;
  perbaikan engine BLOCKED (file concurrent).
- Sisa 145.33: secret exclusion (BLOCKED file concurrent), migration
  compatibility, destination-collision rollback, native interaction
  UNVERIFIABLE. 145.33 tetap PARTIAL; pointer tetap 145.27.

## Update 2026-09-03d (nephthys cron, corrupted-input matrix evidence 145.33)

- Gap terpilih: baris audit "Corrupted input: PARTIAL" pada
  `docs/audits/portable-import-export.md`.
- Pemilihan step: semua file engine portable milik sibling concurrent;
  slice dibuat PASS-first test-only pada file baru
  `test/features/project_resilience/portable_corrupt_input_test.dart`,
  tanpa kode produksi. Perilaku diprobe live dulu (probe sekali pakai,
  dihapus): keenam bentuk korupsi sudah ditolak importer sebelum test ada.
- Bukti (7 PASS): missing manifest / missing database / truncated zip /
  non-zip / manifest malformed (checksum cocok kontennya) / manifest
  schemaVersion 99 > 16 -> semuanya FormatException; positive control arsip
  valid dgn checksum terhitung terimpor bersih.
- Gates: focused 7 PASS; project_resilience suite 134 PASS / 0 FAIL;
  flutter analyze No issues found! (8.9s); git diff --check PASS;
  full suite + windows debug build dieksekusi pada run yang sama
  (lihat catatan hasil di state).
- Sisa 145.33: secret exclusion (BLOCKED file concurrent), migration
  compatibility, destination-collision rollback (asCopy:false), native
  interaction UNVERIFIABLE. 145.33 tetap PARTIAL; pointer tetap 145.27.

## Update 2026-09-03e (nephthys cron, compatibility/migration evidence 145.33)

- Gap terpilih: baris audit "Compatibility/migration: BLOCKED" pada
  `docs/audits/portable-import-export.md` ("Importer membaca schema version
  tetapi tidak menjalankan migration/compatibility policy").
- Pemilihan step: file engine portable + platform IO milik sibling
  concurrent; slice PASS-first test-only pada file baru
  `test/features/project_resilience/portable_schema_compatibility_test.dart`,
  tanpa kode produksi. Perilaku diprobe live dulu (probe sekali pakai,
  dihapus): import v53 -> open -> user_version 59, baris Core utuh.
- Bukti (3 PASS): (1) arsip DB v53 -> import -> open produksi migrasi
  53->59, assets+characters (biography) selamat tanpa silent discard;
  (2) manifest format lama schemaVersion 15 diterima dan bermigrasi;
  (3) CURRENT v59 round-trip tanpa migrasi. Manifest future > 16 sudah
  ditolak FormatException (portable_corrupt_input_test.dart).
- TEMUAN RISIKO terdokumentasi: DB `user_version` 60 (> app 59) diterima
  open produksi dan user_version diturunkan diam-diam ke 59; guard
  future-schema database BLOCKED (project_database_platform_io.dart
  region concurrent). Manifest future aman.
- Gates: focused 3 PASS; portable group 18 PASS; project_resilience suite
  137 PASS / 0 FAIL; flutter analyze No issues found! (9.7s);
  full suite 3508 PASS / 0 FAIL (delta +3 eksak dari 3505);
  flutter build windows --debug PASS 19.7s; git diff --check PASS.
- Sisa 145.33: secret exclusion (BLOCKED file concurrent),
  destination-collision rollback (asCopy:false), guard future-schema DB,
  native interaction UNVERIFIABLE. 145.33 tetap PARTIAL; pointer tetap
  145.27.

nephthys - 2026-09-03e
