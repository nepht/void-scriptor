# Sprint 145.41 — Core Automated Test Pyramid

Tanggal audit: 2026-08-27
Sumber kanonik: `sprint_145.json`, item `145.41`.
Status: **PARTIAL**.

## Kontrak kanonik

Menambahkan fast domain/storage unit tests, database/import integration tests, dan minimum end-to-end vertical slice pada clean Windows environment.

## Evidence terverifikasi

Inventaris live repository:

- Domain-oriented test files: **124**
- Files bernama `*_integration_test.dart`: **4**
- Contract test files: **14**
- Widget-test files yang memuat `testWidgets`: **152**
- `integration_test/`: tidak ada pada working tree saat audit.

Core vertical matrix yang dijalankan:

```bash
flutter test \
  test/core/project_package \
  test/core/persistence \
  test/features/project_resilience \
  test/features/projects \
  test/features/story/novel_authoring_flow_test.dart \
  test/features/story/story_workspace_novel_io_test.dart \
  test/features/story/story_session_repository_integration_test.dart \
  test/app/shell/core_mvp_navigation_test.dart
```

Hasil:

```text
78 tests passed
All tests passed!
```

Coverage behavior yang terlihat dalam output mencakup package creation/round-trip, manifest and registry persistence, corrupt package handling, backup/restore, migration pre-backup, autosave, portable export/import, project lifecycle, project creation rollback, story authoring/autosave, story repository round-trip, export busy state, dan Core navigation.

## Gaps

- Tidak ada `integration_test/` native driver suite pada tree saat audit.
- E2E vertical slice yang tersedia berjalan in-process/widget/integration-named test, bukan clean Windows native journey.
- Clean Windows snapshot final tidak ditemukan pada `D:/VoidScriptor_Windows_Snapshots/void-windows-sprint-20260827-final`.
- Native capture/click-through belum dapat diverifikasi; driver sebelumnya meminta `snapshot_id_required`.
- Full Flutter analyzer masih terblokir oleh Flutter cleanup pada path iOS ephemeral yang terbaca read-only.
- Test pyramid belum memiliki satu machine-readable gate yang menghubungkan unit, persistence/import integration, dan clean-Windows E2E sebagai satu acceptance result.

## Verdict

`PARTIAL`: lapisan domain, widget, persistence, import, migration, dan in-process integration memiliki evidence nyata; clean Windows E2E dan native interaction belum tersedia. Tidak ada klaim production readiness.

## Non-actions

Tidak ada penambahan migration/schema, cleanup, pemindahan project, penghapusan data, commit, push, atau tag.

## Provenance

Jenis evidence: live test-tree inventory, focused Flutter test execution, source/test inspection. Tidak mencakup native Windows runtime interaction.

nephthys — 2026-08-27


## Update 2026-09-02 (nephthys cron, clean-environment E2E journey)

- Gap "minimum end-to-end vertical slice pada clean Windows environment"
  mendapat bukti eksekusi headless pertama pada environment terisolasi:
  `test/features/story/core_e2e_journey_test.dart` (1 PASS, ~6-8 detik).
- Journey: `ProjectPackageService.create` (paket UUID + manifest + database
  segar) -> `ProjectSessionManager.open` -> `CharacterRepositoryImpl`
  create/update (biography + voice) + identity notes ->
  `CreateStoryService` story/arc/chapter/scene + `addCharacter` ->
  `StoryRepositoryImpl.saveSceneDraft` -> `searchNovel` (match judul+draft,
  trim, query kosong kosong) -> `quickReferenceForScene` (canon + notes
  identitas + role) -> `StoryTxtExporter.exportStory` -> `session.close` ->
  `ProjectBackupService.create` (SHA-256 manifest) -> mutasi kotor (story
  "DIRTY") -> `restore` checksum-verified (DIRTY terhapus, saga utuh) ->
  reopen session -> `getStoryHierarchy` + draft intact.
- Isolasi: seluruh paket berada di `Directory.systemTemp.createTemp
  ('s41-e2e-')`; lokasi data pengguna tidak disentuh. Session ditutup sebelum
  backup agar copy WAL aman; WAL checkpoint sudah ditangani service
  resilience sesuai audit 145.34.
- RED terverifikasi: file journey baru (symbol-level journey tidak ada
  sebelumnya; kompilasi pertama gagal di ekspektasi API yang salah, lalu
  diperbaiki terhadap API produksi). Tidak ada kode produksi baru - pola
  PASS-first evidence di atas kontrak eksisting.
- Bukti gerbang: focused 1 PASS; story suite 150 PASS; `flutter analyze`
  No issues found!; `flutter build windows --debug` PASS (22.3s);
  `git diff --check` PASS.
- Sisa gap 145.41: `integration_test/` native-driver tree dan native
  interaction proof (butuh sesi interaktif, UNVERIFIABLE dari cron);
  inventory pyramid belum diperbarui ulang setelah slice ini.

## Update 2026-09-03 (nephthys cron: inventory pyramid refresh)

Gap 'inventory pyramid refresh' di baris 145.41 ledger CLOSED via live
re-count of test/ (scan *_test.dart, klasifikasi testWidgets vs test,
nama file contract/integration):

- Total file test: 792 (naik dari 294 baseline audit 2026-08-27;
  sejak itu Core vertical slices 145.x menambah banyak test eksekusi).
- Widget-layer (testWidgets): 179 file (features 139, app 20, core 15,
  design_system 2, shared 2, release 1).
- Unit/domain-layer (test()): 613 file.
- Contract-named: 15 file; integration-named: 5 file (in-process).
- integration_test/ native-driver tree: 0 file (tetap kosong).

Pembacaan pyramid: dominasi unit/domain + widget terbukti live;
lapisan native-driver integration_test/ tetap 0 -> gap 'integration_test/
native-driver tree' TIDAK berubah (tetap open). Native interaction proof
tetap UNVERIFIABLE dari cron (butuh sesi interaktif).
## Update 2026-09-04 cron run24 (nephthys, cited-test provenance adopted)

The story test files this audit cites as provenance were still untracked at audit time; they are
now adopted into the repository byte-identical (commit of run24, pattern of run12/run23). Cited-test
provenance no longer resolves to untracked files. No status rows rewritten; Verdict unchanged.
