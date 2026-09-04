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
| Clean export fidelity across all required formats | VERIFIED by `StoryExportFidelity` + `test/features/story/story_export_fidelity_test.dart` (2026-09-01 cron c): markdown exact-line diff, DOCX zip-decode paragraph diff, DB ordering preserved, live manuscript untouched, XML-special + blank-line content intact |
| Word count | VERIFIED: live word count wired + tested (`'3 kata'` assertion di `test/features/story/story_workspace_test.dart`; progres target di `test/features/story/word_targets_test.dart` 5 test) |
| Snapshot lifecycle | VERIFIED for core contract (schema 56→57 persistence, capture, restore-with-backup, retention + UI journey): `draft_snapshot_persistence_test.dart` 3 PASS + `novel_workspace_search_snapshot_ui_test.dart` 3 PASS. Batas retensi lintas restart tetap session-scoped sesuai kontrak domain 109.22 (bukan gap slice ini) |
| Search/lore journey | VERIFIED for core search: `searchNovel` cross-scene domain (`novel_search_test.dart` 2 PASS) + NOVEL SEARCH UI journey (`novel_workspace_search_snapshot_ui_test.dart`); lore link/backlink komponen teruji terpisah (`lore_link_autocomplete_test.dart`, `lore_backlinks_test.dart` di story suite) |
| Native Windows interaction | PARTIAL (2026-09-01 cron g): native window render proven via alive probe (exe launched, PowerShell `MainWindowHandle` valid + `Responding=True`, `CopyFromScreen` pixel stats 2093 unique colors / 112578 edge transitions on 1280x720 — non-empty render). Foreground input/click interaction remains UNVERIFIABLE from cron (no computer_use driver; previously returned `snapshot_id_required`) |
| Full Core vertical journey | PENDING; depends on 145.30–145.35 and 145.41–145.44 (bukan acceptance tambahan 145.24 per RESOLUTION_GUIDANCE_145_24_145_26) |

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

`145.24 Novel Workspace Core` berstatus **VERIFIED** (2026-09-01 cron h, rekonsiliasi evidence-closure per RESOLUTION_GUIDANCE_145_24_145_26). Seluruh objective exact sprint_145.json kini punya bukti eksekusi: project/novel metadata, chapter/scene tree, manuscript persistence + restart, ordering, search (domain + UI journey), word count, snapshots (persistence + restore + retention UI), clean export (fidelity matrix). Native interaction klik/typing tetap UNVERIFIABLE dari cron (tanpa computer_use) dan terekam jujur sebagai boundary tersendiri; native window render TERBUKTI via alive probe.

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

## Update 2026-09-01 (cron c: export fidelity matrix)

- Gap matriks fidelity export ditutup (commit slice ini):
  `lib/features/story/application/story_export_fidelity.dart` berisi
  `StoryExportFidelity` + `FidelityHunk`/`FidelityReport`; validator meniru
  pola EKSAK kedua exporter (bukan regex longgar): markdown dibandingkan
  baris-per-baris (heading, blank-line separator, draft verbatim,
  trailing trimRight), DOCX di-decode dari zip (ZipDecoder verify:true),
  document.xml diparse jadi paragraf (style + teks unescaped) lalu
  dibandingkan urut.
  `test/features/story/story_export_fidelity_test.dart` (1 test, fixture
  2 bab x 2 scene, synopsis, karakter XML `<' ' '&' '>` di draft, blank
  line internal draft): memverifikasi 5 prasyarat no-break 145.24 -
  judul story tepat 1x, hunk chapter->scene->draft-line terstruktur,
  urutan mengikuti ordering database (sortOrder), export TIDAK memutasi
  naskah hidup (draft byte-identical sebelum/sesudah), semua konten draft
  hadir utuh di kedua format.
  Temuan fidelity: DOCX menambahkan paragraf kosong untuk blank line
  internal draft (split per baris) - direkam sebagai kontrak format,
  bukan bug; markdown mempertahankan blank line verbatim.
  RED terverifikasi (StoryExportFidelity/FidelityHunk isn't defined).
- Bukti: focused 1 PASS, story suite 134 PASS, `flutter analyze` No
  issues, `git diff --check` PASS, full suite 3234 PASS,
  `flutter build windows --debug` PASS.
- Sisa gap 145.24: native interaction proof (cron tidak punya
  computer_use driver), snapshot retention UI (minor).

## Update 2026-09-01 (cron d: snapshot retention UI)

- Gap snapshot retention UI ditutup (commit slice ini): panel SCENE
  SNAPSHOTS di StoryWorkspaceScreen kini punya tombol 'Atur Retensi'
  (ikon Icons.tune) di samping 'Snapshot'. Dialog 'Atur Batas Retensi'
  mengumpulkan input angka (keyboardType number, onSubmitted/submit
  'Terapkan'), mem-validasi int > 0, lalu memanggil
  `StoryRepositoryImpl.setDraftSnapshotRetention(sceneId,
  maxSnapshots: limit)` dan memuat ulang daftar snapshot — pemangkasan
  pelanggaran tetap di repository (_enforceRetention), bukan di UI.
  Pola dialog-based input dipertahankan (kontrak satu TextField di main
  tree tetap aman; pelajaran cron c).
- RED terverifikasi: `snapshot retention UI sets limit and trims
  visible list` gagal `Bad state: No element` di `find.text('Atur
  Retensi')` (UI belum ada), 2 test existing tetap PASS -> GREEN setelah
  implementasi: test baru menekan tombol, mengisi '1', menekan
  'Terapkan', lalu meng-assert `lastRetentionSceneId == 'scene-a'`,
  `lastRetentionLimit == 1`, dan snapshot tertua ('checkpoint 1')
  hilang dari daftar (fake mensimulasikan _enforceRetention).
- Batas retensi tetap session-scoped sesuai kontrak domain 109.22
  (DraftSnapshotStore.retentionLimit in-memory); persistensi limit
  lintas restart bukan scope slice ini dan tidak diklaim.
- Bukti: focused 3 PASS (2 existing + 1 retention baru), story suite
  135 PASS (naik dari 134), `flutter analyze` No issues, format scoped
  2 file 0 changed, `git diff --check` PASS; full suite + windows debug
  build direkam di update ledger berikutnya.
- Sisa gap 145.24: native interaction proof (cron tidak punya
  computer_use driver).

## Update 2026-09-01 (cron g: native render proof)

- Native alive probe pertama untuk 145.24 dieksekusi tanpa computer_use:
build windows debug diluncurkan dari bash background (`exec
./build/windows/x64/runner/Debug/void_scriptor.exe`), PowerShell
`Get-Process` membaca PID, `MainWindowHandle` non-nol, `Responding=True`,
judul window `void_scriptor`.
- Render proof via `CopyFromScreen` pada window rect 1280x720:
2093 unique colors + 112578 edge transitions = konten non-kosong
(splash kosong biasanya <200 colors). Ini menutup boundary render,
bukan interaction: tidak ada klik/typing native yang diklaim.
- Aplikasi dimatikan bersih via `Stop-Process` setelah probe
(tidak ada proses Flutter lain selama run; satu proses Flutter pada
satu waktu dijaga: full test dan build dijalankan sekuensial).
- Gates run ini: focused workspace+character+relations+selection 48 PASS;
full suite 3239 PASS (~11.5 mnt); `flutter analyze` No issues (118.5s);
`flutter build windows --debug` PASS (45.7s); `git diff --check` PASS;
roadmap guard PASS pre-run.
- Sisa gap 145.24: native interaction proof (butuh computer_use / sesi
interaktif pengguna). Cron tidak boleh mengklaimnya.

## Update 2026-09-01 (cron h: evidence-closure reconciliation, 145.24 VERIFIED)

- Rekonsiliasi audit + ledger hanya dari bukti eksekusi (RESOLUTION_GUIDANCE_145_24_145_26).
  Tabel evidence-boundary direkonsiliasi: export fidelity, word count, snapshot
  lifecycle, dan search journey naik ke VERIFIED karena masing-masing kini punya
  test eksekusi nyata (bukan lagi komponen tanpa journey). Full Core vertical
  journey tetap PENDING namun bukan acceptance tambahan 145.24.
- Native interaction klik/typing tetap UNVERIFIABLE dari cron (tanpa
  computer_use); native window render sudah terbukti via alive probe cron g.
  Keputusan menjadikan klik/typing prasyarat verifikasi akan membutuhkan sesi
  interaktif; 145.24 ditutup VERIFIED tanpa mengarang bukti tersebut.
- Gates segar run ini (Windows canonical, HEAD 4770ecc): `flutter analyze` No
  issues (16.7s); proving suite `flutter test test/features/story` 142 PASS;
  `test/features/workspaces` 55 PASS; focused search/snapshot/recovery/fidelity
  7 PASS; full `flutter test` 3262 PASS + 2 FAIL yang keduanya milik surface
  concurrent 145.20 (app_bootstrap_test vs main.dart/app_router uncommitted;
  splash_screen_test untracked vs splash_screen.dart sibling) - didiagnosis
  root cause-nya dan dilaporkan, tidak disentuh; `git diff --check` PASS;
  `flutter build windows --debug` PASS (22.9s). Tidak ada commit source baru;
  perubahan hanya ledger/audit/state.
## Update 2026-09-04 cron run24 (nephthys, cited-test provenance adopted)

The story test files this audit cites as provenance were still untracked at audit time; they are
now adopted into the repository byte-identical (commit of run24, pattern of run12/run23). Cited-test
provenance no longer resolves to untracked files. No status rows rewritten; Verdict unchanged.
