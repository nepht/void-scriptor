# Sprint 145.24 — Novel Workspace Core

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.24 dan `core_mvp_scope_reset_spec.json`.

## Required contract

Novel Workspace Core harus mencakup metadata project/novel, chapter/scene tree, manuscript persistence, ordering, search, word count, snapshots, dan clean export.

## Live implementation evidence

### Story hierarchy and repository

- `lib/features/story/domain/story_model.dart` — Story domain model.
- `lib/features/story/data/story_repository_impl.dart` — repository-backed hierarchy, scene lookup, character/environment/beat context, and scene draft persistence.
- `lib/features/story/application/create_story_service.dart` — story creation service.
- `lib/features/story/presentation/story_workspace_screen.dart` — Story Workspace UI.
- `lib/features/story/presentation/story_inspector.dart` — Story Inspector UI.
- `lib/features/story/presentation/scene_workspace_screen.dart` — Scene Workspace UI.

### Manuscript/autosave/export

- `lib/features/story/application/debounced_autosave.dart` — debounced draft persistence seam.
- `lib/features/story/application/story_markdown_exporter.dart` — Markdown output.
- `lib/features/story/application/story_docx_exporter.dart` — DOCX output.
- `lib/features/workspaces/application/workspace_import_service.dart` and `workspace_export_service.dart` — package IO path used by novel workspace actions.

### Search/lore/context

- `lib/features/story/domain/lore_link_suggester.dart`.
- `lib/features/story/domain/inline_lore_links.dart`.
- `lib/features/story/domain/lore_backlinks.dart`.
- Story scene repository resolution includes scene character, environment, and beat context.

## Latest focused evidence

Command:

```text
wsl.exe -d Ubuntu -- bash -lc 'cd /home/nepht/Projects/void_scriptor_multiplatform && export PATH="$HOME/toolchain/flutter/bin:$PATH" && flutter test test/features/story/novel_authoring_flow_test.dart test/features/story/story_workspace_novel_io_test.dart test/features/story/story_session_repository_integration_test.dart test/features/story/story_workspace_resolver_test.dart test/features/story/debounced_autosave_test.dart test/features/story/story_persistence_test.dart test/features/story/scene_beat_persistence_test.dart'
```

Result:

```text
All tests passed! — 13 tests
```

Covered behaviors:

- selected scene title and autosave follow scene selection;
- novel export carries an explicit representation choice;
- import surfaces representation before mutation;
- export/import buttons lock during an active archive operation;
- session-backed hierarchy survives repository round trip;
- story resolver opens the Story Workspace for story selection;
- story hierarchy and scene context survive database restart;
- scene beats reorder/delete and preserve order after restart.

## Evidence boundary

| Area | Status |
|---|---|
| Story hierarchy/repository | VERIFIED by focused tests |
| Scene draft/autosave seam | VERIFIED by focused tests |
| Restart persistence | VERIFIED by focused tests |
| Resolver/selection to Story Workspace | VERIFIED by focused tests |
| Import/export action safety | VERIFIED by focused tests |
| Clean export fidelity across all required formats | PARTIAL; dedicated content comparison matrix remains open |
| Word count | PARTIAL; no complete Core journey proof found in this batch |
| Snapshot lifecycle | PARTIAL; draft/restart evidence exists, full user-controlled snapshot contract remains separate |
| Search/lore journey | PARTIAL; domain/link components exist, full clean-device journey remains open |
| Native Windows interaction | UNVERIFIABLE; driver previously returned `snapshot_id_required` |
| Full Core vertical journey | PENDING; depends on 145.30–145.35 and 145.41–145.44 |

## No-break conditions

1. Story/scene selection must use the shared selection/resolver path; generic `/workspace` navigation alone is insufficient.
2. Scene and chapter ordering must survive restart.
3. Autosave failure must not claim successful persistence.
4. Import must expose representation and validate before mutation.
5. Export must not mutate the live manuscript and must preserve expected text/order.
6. Story data must remain separate from canonical Character identity and explicit scoped overrides.
7. Optional AI/Cloud/Network availability must not be required to open or edit a local novel.
8. Existing user data and concurrent agent changes remain protected.

## Decision

`145.24 Novel Workspace Core` berstatus **PARTIAL**. The local Story Workspace vertical slice has strong source and focused-test evidence (13 tests pass), including repository round trip, restart persistence, resolver wiring, autosave, and IO action safety. Word-count, complete snapshot semantics, full search/lore journey, clean-export fidelity matrix, native interaction, and release-blocking clean-device journey remain open.

Next: `145.25 Character Workspace Core`.

## Evidence paths

- `lib/features/story/domain/story_model.dart`
- `lib/features/story/data/story_repository_impl.dart`
- `lib/features/story/application/create_story_service.dart`
- `lib/features/story/application/debounced_autosave.dart`
- `lib/features/story/application/story_markdown_exporter.dart`
- `lib/features/story/application/story_docx_exporter.dart`
- `lib/features/story/presentation/story_workspace_screen.dart`
- `lib/features/story/presentation/scene_workspace_screen.dart`
- `lib/features/workspaces/application/workspace_import_service.dart`
- `lib/features/workspaces/application/workspace_export_service.dart`
- `test/features/story/novel_authoring_flow_test.dart`
- `test/features/story/story_workspace_novel_io_test.dart`
- `test/features/story/story_session_repository_integration_test.dart`
- `test/features/story/story_workspace_resolver_test.dart`
- `test/features/story/debounced_autosave_test.dart`
- `test/features/story/story_persistence_test.dart`
- `test/features/story/scene_beat_persistence_test.dart`
- `docs/audits/core-mvp-vertical-slice-contract.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`


## Update 2026-09-01 (cron 145.24 continuation)

- `StoryRepositoryImpl.searchNovel(query)` ditambahkan (commit d0cbf81): pencarian
  case-insensitive dengan trim, menolak query kosong, menghitung kecocokan per
  scene atas judul scene, judul bab, dan seluruh isi beat/draft scene; hasil unik
  per scene, tersegmen per chapter, terurut chapter lalu scene (sortOrder).
- `StoryDao.getScenesByChapter` ditambahkan untuk kueri per-chapter berurut.
- Bukti: `flutter test test/features/story/novel_search_test.dart` 2 PASS (RED
  pertama terverifikasi: `searchNovel isn't defined`), 28 test story PASS,
  `flutter analyze` No issues, `git diff --check` PASS, full suite 3228 PASS,
  `flutter build windows --debug` PASS.
- Status gap diperbarui: word count kini ter-wiring + tested di
  StoryWorkspaceScreen ('N kata'); snapshot memiliki domain store
  (Step 109.22) namun masih in-memory. Yang masih terbuka: persistensi/UI
  snapshot store, journey search di UI, matriks fidelity export, native
  interaction proof.

## Update 2026-09-01 (cron 145.24 snapshot persistence)

- Tabel `SceneDraftSnapshots` (schema 56→57, migrasi terjaga `if (from < 57)`):
  id UUID, sceneId, projectId, kind auto/manual/restoreBackup, content verbatim,
  label, createdAt. Kontrak mengikuti domain DraftSnapshotStore Step 109.22.
- `StoryRepositoryImpl` baru: `captureSceneDraftSnapshot`, `getSceneDraftSnapshots`
  (filter snapshotId/kind), `restoreSceneDraftSnapshot` (SELALU mencadangkan teks
  kini sebagai restoreBackup sebelum pulih), `setDraftSnapshotRetention` (batas
  per scene; dipangkas pada setiap capture).
- RED terverifikasi (`captureSceneDraftSnapshot`/`getSceneDraftSnapshots`/
  `setDraftSnapshotRetention` isn't defined) → GREEN.
- Bukti: `flutter test test/features/story/draft_snapshot_persistence_test.dart`
  3 PASS (persisten lintas close/reopen, restore-backup, retensi), story suite
  131 PASS, `flutter analyze` No issues, `git diff --check` PASS, full suite
  3231 PASS, `flutter build windows --debug` PASS. 26 asersi schema stale
  diperbarui 56→57 (23 file `schemaVersion, 56` + freeze/migration matrix
  release tests yang mengunci v56 — pola preceden v53→56).
- Status gap diperbarui: snapshot persistence TERSEDIA di repository layer
  (UI journey snapshot/search, matriks fidelity export, native interaction
  proof masih terbuka).

## Update 2026-09-01 (cron 145.24 snapshot + search UI journeys)

- `StoryWorkspaceScreen` (lib/features/story/presentation/story_workspace_screen.dart)
  kini memuat dua panel baru di akhir kolom (setelah STORY BIBLE, sehingga
  geometri tap widget existing tidak bergeser):
  1. **NOVEL SEARCH** — tombol 'Cari Novel' membuka dialog query;
     submit menjalankan `repository.searchNovel` dan merender daftar hasil
     lintas scene (judul scene + bab, badge jumlah match, tap hasil =
     pilih scene + muat draft + snapshot).
  2. **SCENE SNAPSHOTS** — untuk scene terpilih: tombol 'Snapshot' membuka
     dialog label → `captureSceneDraftSnapshot` (manual berlabel); daftar
     snapshot (label, kind, timestamp) dirender dari
     `getSceneDraftSnapshots`; per baris tombol 'Restore' memanggil
     `restoreSceneDraftSnapshot` dan menuliskan kembali isi snapshot ke
     editor (backup otomatis teks kini di repository, kontrak 109.22).
- Kontrak test existing dijaga: tree utama tetap TEPAT SATU TextField
  (editor draft) — input query/label dikumpulkan lewat AlertDialog, bukan
  TextField inline. Ini menjaga lore_link_autocomplete_test (single-TextField
  assumption) dan novel_authoring_flow_test (find.byType(TextField) satu).
- RED terverifikasi sebelum implementasi: 'Cari Novel' Found 0 (tanpa tombol
  search UI), TextFormField/TextField kedua tidak ada (tanpa snapshot UI).
- Bukti: `flutter test
  test/features/story/novel_workspace_search_snapshot_ui_test.dart` 2 PASS
  (search journey + snapshot journey, fake repository deterministik
  extends StoryRepositoryImpl; persistensi lintas close/reopen tetap
  dibuktikan draft_snapshot_persistence_test.dart); story suite 133 PASS
  (regresi 9 gagal saat TextField inline ditemukan, lalu 0 setelah
  redesign dialog); `flutter analyze` No issues; `git diff --check` PASS;
  full suite 3233 PASS; `flutter build windows --debug` PASS.
- Sisa gap 145.24: matriks fidelity export, native interaction proof
  (cron tidak punya computer_use driver), snapshot retention UI.
