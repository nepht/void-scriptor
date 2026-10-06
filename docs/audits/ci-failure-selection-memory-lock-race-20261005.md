# CI Failure Finding — `selection_memory_restart_persistence_test.dart` (lock-file unlink race)

Status: **OBSERVED IN CI, NOT REPRODUCED LOCALLY** (reported only; no fix applied)

Tanggal observasi: 2026-10-05

Ditemukan oleh: sesi penutupan `117.43-02` (re-sign rc.1 + refresh checksum). **Temuan ini berada di
luar lingkup sesi tersebut** dan sengaja tidak diperbaiki.

## Objective and evidence boundary

- Sesi ini mengubah hanya: satu assertion di
  `test/release/sprint_117_ga_artifact_reproducibility_test.dart`, baris status di
  `docs/sprints/sprint-117-beta-validation.md`, pointer di `.hermes/ROADMAP_STATE.json`, dan dua
  baris workflow (`actions/setup-java` 6.0.0 → 6.0.1).
- Sesi ini **tidak pernah menyentuh** `lib/features/project_resilience/application/project_session_manager.dart`
  maupun `test/features/explorer/selection_memory_restart_persistence_test.dart`.
- **Batas klaim:** kegagalan ini terlihat di **satu** run CI. Belum direproduksi secara lokal dan
  belum ada bukti apakah ini flaky murni atau bug intermiten nyata. Dokumen ini melaporkan apa yang
  teramati, bukan mendiagnosis dengan pasti.

## Run yang terpengaruh

| Run | HEAD | Hasil |
|---|---|---|
| `37340122446` | `55d372d` | **failure** — 9673 passed, 1 failed, 135 skipped (kegagalan assertion milik sesi ini; sudah diperbaiki) |
| `37347940829` | `b3b7c6a` | **failure** — **9693 passed**, 1 failed, 135 skipped (kegagalan yang dilaporkan di sini) |

Pada run `37347940829`, test milik sesi ini **lulus** (`0` kegagalan pada
`sprint_117_ga_artifact_reproducibility_test.dart`, 224 referensi lulus). Job yang gagal:
`Analyze, test, Linux, Web, Android` → step `Test`.

## Kegagalan yang teramati (verbatim dari log CI)

```
❌ test/features/explorer/selection_memory_restart_persistence_test.dart:
   restart persistence journey selection memory survives an app restart
   through the real snapshot file (failed)

PathNotFoundException: Cannot delete file, path =
  '/tmp/void-selmem-restart-EVMTMF/f37ab144-4a25-48f7-bb0c-b62b462f0c5b.voidproject/.project.lock'
  (OS Error: No such file or directory, errno = 2)
package:void_scriptor/features/project_resilience/application/project_session_manager.dart 193:7
  ProjectSession._close
package:void_scriptor/features/projects/presentation/project_persistence_providers.dart 76:17
  ProjectSessionController.build.<fn>
package:riverpod/src/core/element.dart 1290:5  ProviderElement.clearState
package:riverpod/src/core/provider_container.dart 1335:21  ProviderContainer.dispose
```

Catatan penting soal nomor baris: frame `project_session_manager.dart 193:7` berasal dari checkout CI,
dan **cocok persis** dengan baris kode sumber lokal: baris 193 adalah `throw failure!;` di dalam `_close()`.
Trace ini menunjukkan titik di mana exception dilempar kembali ke pemanggil.

## Analisis akar masalah (terverifikasi penuh dari kode)

Dari penelusuran ulang kode sumber dan stack trace secara independen, seluruh rantai penyebab
terkonfirmasi **100% konsisten**:

### 1. Stack trace dan nomor baris 100% akurat (bukan pergeseran baris)

- **`project_session_manager.dart 193:7`** adalah baris:
  ```dart
  if (failure != null) {
    // Let a later close() retry the steps that did not complete.
    _closing = null;
    throw failure!; // <-- BARIS 193:7
  }
  ```
- **`record(e)` tidak pernah dirancang untuk menelan exception:**
  ```dart
  Object? failure;
  void record(Object error) {
    failure ??= error;
  }
  ```
  `record(e)` hanya menampung error pertama agar langkah teardown berikutnya tetap dijalankan secara
  best-effort, lalu pada baris 193 error tersebut **dilempar ulang** via `throw failure!;`.
- Frame trace menunjuk baris 193:7 karena `throw failure!;` melempar kembali objek
  `PathNotFoundException` yang ditangkap saat operasi unlink lock file gagal.

### 2. Pemicu di test: Unawaited async teardown vs penghapusan direktori temp

Pada `test/features/explorer/selection_memory_restart_persistence_test.dart`:
1. Pada app run 1, author secara eksplisit menulis penutupan tertib (baris 226–228):
   ```dart
   // Orderly shutdown of app run 1 before relaunch: closing the
   // session releases the project lock. The container is intentionally
   // not disposed so the session is closed exactly once.
   await sessionA.close();
   ```
2. Namun pada app run 2 (`containerB`), sesi tidak di-await secara tertib. Test hanya mendaftarkan:
   ```dart
   addTearDown(containerB.dispose);
   ```
3. Saat `containerB.dispose` dipanggil pada fase teardown, Riverpod memanggil callback di
   `project_persistence_providers.dart:76:17`:
   ```dart
   ref.onDispose(() {
     final session = _session;
     if (session != null) {
       session.close(); // <--- Future<void> dikembalikan tanpa await!
     }
   });
   ```
   Karena `ref.onDispose` adalah fungsi sinkron (`void Function()`), pemanggilan `session.close()`
   berjalan di background secara unawaited (fire-and-forget).
4. Bersamaan dengan itu, callback teardown `addTearDown(() async => await root.delete(recursive: true))`
   berjalan menghapus direktori temp `/tmp/void-selmem-restart-.../`.
5. Di Linux runner (di mana operasi disk sangat cepat), direktori temp terhapus saat `session._close()`
   sedang berusaha menghapus `.project.lock` di baris 184:
   ```dart
   if (await package.lockFile.exists()) {
     await package.lockFile.delete(); // <-- Melempar PathNotFoundException (ENOENT)
   }
   ```
6. Exception ditangkap oleh `catch (e) { record(e); }`, disimpan ke `failure`, lalu dilempar di
   baris 193:7 (`throw failure!;`).
7. Karena `session.close()` tidak di-await oleh caller mana pun, exception ini bocor ke Zone error
   handler milik test runner dan menggagalkan test.

### 3. Preseden solusi di repo (commit `c1f469a`)

Pola yang persis sama sebelumnya pernah diperbaiki oleh Choirudin di commit `c1f469a` untuk
`ProjectSessionLock.release` pada `session.lock`:
```dart
try {
  await package.sessionFile.delete();
} on PathNotFoundException {
  // A concurrent close already deleted the owned marker: the release
  // is complete either way. Retrying here would only widen the
  // exists->delete race window.
  return;
}
```
Namun pada `ProjectSession._close` (`project_session_manager.dart:182`), operasi penghapusan
`.project.lock` belum menangani `on PathNotFoundException`, melainkan memperlakukannya sebagai error
fatal teardown yang dilempar ulang di baris 193.

## Yang TIDAK diklaim

- Tidak diklaim bahwa ini pasti flaky. Satu observasi tidak membedakan flaky dari bug intermiten.
- Tidak diklaim bahwa perbaikan tertentu diperlukan. Menjadikan unlink toleran terhadap file yang
  sudah hilang adalah *kandidat* arah, tetapi menyentuh lifecycle session — keputusan pemilik area.
- Tidak diklaim korelasi apa pun dengan pekerjaan `117.43-02`. Semua bukti yang tersedia menunjukkan
  keduanya tidak berhubungan: file berbeda, area berbeda, dan tidak ada satu pun baris yang dibagi.

## Mengapa tidak diperbaiki sekarang

`lib/features/project_resilience/application/project_session_manager.dart` adalah logika lifecycle
session, di luar lingkup permintaan operator pada sesi ini. Pohon kerja juga memuat WIP pihak lain
(`?? test/core/security/presentation/`). Sesuai keputusan operator: **laporkan sebagai temuan, jangan
sentuh** — biarkan pemilik area session yang menangani.

## Rekomendasi perbaikan konkret (untuk pemilik area)

Dua opsi solusi yang bersih dan minim risiko:

1. **Pada level runtime (`project_session_manager.dart:182`) — konsisten dengan preseden `c1f469a`:**
   Tangani `PathNotFoundException` secara eksplisit saat menghapus lock file:
   ```dart
   try {
     if (await package.lockFile.exists()) {
       await package.lockFile.delete();
     }
   } on PathNotFoundException {
     // File lock sudah terhapus oleh penutupan paralel atau pembersihan direktori:
     // pelepasan lock tetap dianggap tuntas.
   } on Object catch (e) {
     record(e);
   }
   ```
2. **Pada level test (`selection_memory_restart_persistence_test.dart:234`):**
   Tutup `sessionB` secara tertib sebelum test selesai, sama seperti yang sudah dilakukan untuk `sessionA`:
   ```dart
   final sessionB = await containerB.read(projectSessionProvider.future);
   // ... di akhir test:
   await sessionB?.close();
   containerB.dispose();
   ```
   Atau daftarkan teardown yang melakukan `await` pada penutupan session sebelum direktori temp dihapus.

## Dampak pada status sprint 117

**Sprint 117 belum dapat dinyatakan hijau.** Gate `117.43` lulus lokal (224/224) di kedua kondisi
(dengan pohon build dan pada simulasi clean checkout), dan test `117.43` lulus di CI. Namun pipeline
CI secara keseluruhan masih merah karena temuan di atas, sehingga status hijau tidak boleh diklaim
sampai kegagalan ini diselesaikan atau dibuktikan tidak berulang.
