# Sprint 145.30 — Autosave Snapshot and Crash Recovery

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.30`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Menguji atomic saves, journals, snapshots, crash/power/disk-full recovery, visible status, no silent loss, and user-controlled restore.`

## Evidence yang tersedia

### Autosave dan journal

- `lib/features/project_resilience/application/save_coordinator.dart`
  - debounce autosave;
  - `markDirty()` dan `saveNow()`;
  - flush saat `dispose()`;
  - callback persist dan journal dapat diinjeksi.
- `AutosaveJournal` menyimpan sequence number dan mencegah duplikasi sequence.
- **Batas:** journal tersebut hanya in-memory. Belum ada durable journal yang survive restart, checksum entry, atau recovery inbox untuk perubahan yang belum tersimpan.

### Snapshot dan restore

- `lib/features/project_resilience/application/project_version_control_service.dart`
  - create/list snapshot;
  - compare data;
  - restore melalui callback;
  - prune dengan retention count.
- **Batas:** snapshot berbasis JSON asset data dan belum dibuktikan sebagai snapshot konsisten dari seluruh project database + workspace saat crash.

### Backup integrity dan user-controlled restore

- `lib/features/project_resilience/application/project_recovery_services.dart`
  - session lock/crash marker;
  - backup manifest dan database;
  - SHA-256 checksum untuk manifest/database/workspace;
  - penolakan backup yang tampered;
  - emergency backup sebelum restore;
  - restore workspace/assets;
  - cache clear dan trash restore.
- Restore dipicu melalui service/UI action, sehingga dapat menjadi user-controlled.

### Startup recovery

- `lib/app/bootstrap/startup_recovery_policy.dart`
  - failure streak persisted;
  - normal/safe/recovery mode;
  - healthy shutdown reset.
- Ini membuktikan bootstrap failure policy, bukan pemulihan draft autosave project.

## Verification terbaru

Command:

```bash
flutter test \
  test/features/project_resilience/save_coordinator_test.dart \
  test/features/project_resilience/project_recovery_services_test.dart \
  test/features/project_resilience/project_version_control_service_test.dart
```

Result:

```text
All tests passed! — 8 tests
```

Covered behavior:

- debounced autosave;
- clean coordinator tidak menyimpan;
- manual save;
- in-memory journal sequence;
- session lock/crash marker lifecycle;
- backup restore;
- database checksum rejection;
- workspace checksum rejection;
- cache/trash behavior;
- snapshot create/compare/restore/prune.

## Gap terhadap acceptance

| Acceptance | Status | Reason |
|---|---|---|
| Autosave state | PARTIAL | Debounce/flush terbukti; status durable belum terbukti |
| Atomic save | BLOCKED | Tidak ditemukan temp→flush→rename contract untuk project save |
| Durable journal | BLOCKED | `AutosaveJournal` hanya in-memory |
| Snapshots | PARTIAL | JSON snapshots terbukti; full-project crash-consistent snapshot belum terbukti |
| Process-kill recovery | UNVERIFIABLE | Belum ada controlled process-kill harness |
| Power-loss recovery | UNVERIFIABLE | Tidak diuji pada filesystem live |
| Disk-full recovery | BLOCKED | Belum ada injectable failure seam; tidak aman memenuhi ini dengan mengisi disk |
| Visible save/recovery status | PARTIAL | Resilience/recovery UI ada; autosave dirty/saved/recovery status end-to-end belum terhubung |
| No silent loss | BLOCKED | Tidak ada restart test untuk durable pending journal/draft recovery |
| User-controlled restore | PARTIAL | Service/UI restore action ada; autosave recovery selection flow belum terbukti |

## Ownership and safety boundary

Worktree shared dan memiliki perubahan concurrent pada resilience, bootstrap, dan test files. Audit ini tidak mengubah production code, tidak menambah migration, tidak menghapus backup/snapshot, dan tidak menjalankan disk-filling atau process-kill terhadap project aktif.

## Verdict

**PARTIAL — development evidence tersedia, acceptance 145.30 belum lengkap.**

Langkah lanjutan yang diperlukan bila kontrak failure-injection disetujui:

1. tetapkan format durable autosave journal dan atomic-write contract;
2. tulis RED restart test untuk pending journal dan no silent loss;
3. tambahkan failure-injection seam untuk write/rename/disk-full/permission errors;
4. implementasikan recovery listing dan user-controlled restore;
5. jalankan focused suite, full analyzer/test/build gates, lalu native proof terpisah.

145.42 tetap tidak disentuh karena berada di bawah eksekutor lain.


## Update 2026-09-01 (cron h: durable draft journal slice)

- Slice no-silent-loss landed (commit fd2d0bc):
  `lib/features/project_resilience/application/durable_draft_journal.dart`
  (`DurableDraftJournal`) menyimpan draf yang belum autosave ke
  `<package>/recovery/draft-journal/<scene>.json` secara atomic
  (write `<scene>.json.tmp` -> flush -> rename), sehingga crash atau
  power-loss tidak meninggalkan file setengah jadi; `acknowledge`
  menghapus entri hanya SETELAH autosave durable sukses.
- Wiring produksi: `StoryWorkspaceScreen` meng-stage SETIAP suntingan ke
  journal SEBELUM debounce autosave jalan dan meng-acknowledge hanya
  setelah `saveSceneDraft` sukses; `WorkspaceResolver` mem-binding
  journal ke direktori `recovery/draft-journal` dalam paket proyek aktif
  (null di luar sesi: journal jujur tidak aktif, autosave utama tetap).
- RED terverifikasi: `DurableDraftJournal` Method not found sebelum
  implementasi. GREEN:
  `test/features/project_resilience/durable_draft_journal_test.dart`
  4 PASS termasuk journey crash-simulation (stage -> new instance ->
  pending replay -> acknowledge) dan no-silent-loss restart (konten
  belum pernah tersimpan ke DB tetap pulih dari journal).
- Focused regression: story+resilience 15 PASS (story_workspace,
  novel_workspace_search_snapshot_ui, novel_authoring_flow,
  debounced_autosave, save_coordinator, project_recovery_services).
- Gates: full suite 3245 PASS; flutter analyze No issues; windows debug
  build PASS; git diff --check PASS.
- Sisa gap 145.30: pemulihan end-to-end di UI saat startup (prompt
  pemulihan ke pengguna), failure-injection disk-full/permission,
  process-kill harness native, integrasi SaveCoordinator/AutosaveJournal
  lama dengan journal durable ini.

## Update 2026-09-01 (cron i: recovery startup prompt UI slice)

- Slice recovery prompt UI landed:
  `StoryWorkspaceScreen` kini memuat panel `DRAFT RECOVERY` dekat puncak
  layar (sebelum panel chrome lain) saat `DurableDraftJournal` memiliki
  entri pending; panel absen ketika journal kosong (negatif teruji).
  Setiap entri menampilkan scene + cuplikan konten dengan dua aksi
  user-controlled: 'Pulihkan Draft' (`saveSceneDraft` lalu `acknowledge`
  — urutan no-silent-loss; crash di tengah meninggalkan entri yang masih
  bisa dipulihkan ulang) dan 'Buang' (`acknowledge` tanpa menulis ke
  repository). Guard `_recoveryBusy` mencegah aksi ganda.
- RED terverifikasi: 2 journey gagal pada `Found 0 widgets with text
  "DRAFT RECOVERY"`; test file sebelumnya (run terputus) memakai real IO
  di fake-async zone sehingga hang — diperbaiki dengan
  `_FakeDurableDraftJournal` in-memory (override `pendingEntries`/
  `acknowledge`), kontrak asersi UI tidak berubah.
- Bukti: focused 3 PASS (restore journey, discard journey, negative);
  story+resilience regression 181 PASS; `flutter analyze` No issues;
  full suite 3248 PASS (= 3245 + 3, cocok eksak);
  `flutter build windows --debug` PASS; `git diff --check` PASS.
- Sisa gap 145.30: failure-injection disk-full/permission, process-kill
  harness native, integrasi SaveCoordinator/AutosaveJournal lama dengan
  journal durable ini, native interaction proof (butuh sesi interaktif).


## Update 2026-09-01 (cron j: failure injection)

- Gap failure-injection disk-full/permission untuk DurableDraftJournal
  ditutup sebagai evidence-first: `test/features/project_resilience/durable_draft_journal_failure_injection_test.dart`
  (2 test) menutup dua boundary TANPA kode produksi baru.
  (1) Orphan .tmp dari stage() yang terputus (crash setelah flush,
  sebelum rename) TIDAK menutupi draf valid terakhir: pendingEntries
  tetap memulihkan konten dari file .json utama (filter endsWith
  '.json' mengabaikan .tmp dan file non-JSON).
  (2) Kegagalan tulis di-propagasi dari stage(): path .tmp dijadikan
  direktori sehingga openWrite melempar FileSystemException — teknik
  deterministik lintas platform menggantikan chmod a-w yang terbukti
  tidak efektif pada direktori Windows (pertama kali dicoba, stage
  malah sukses = setup injection salah, bukan bug kode).
- Pola PASS-first (seperti journey 145.25g): implementasi journal
  sudah benar di boundary ini; tidak ada kode produksi yang ditulis
  tanpa RED nyata.
- Bukti: focused 6 PASS (4 journal + 2 failure-injection); regression
  story+resilience 52 PASS; flutter analyze No issues (18.3s); full
  suite 3250 PASS (= 3248 + 2, cocok eksak, ~12 mnt); flutter build
  windows --debug PASS (21.9s); git diff --check PASS.
- Sisa gap 145.30: native process-kill harness, integrasi
  SaveCoordinator/AutosaveJournal lama dengan journal durable ini,
  native interaction proof (butuh sesi interaktif).
