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
