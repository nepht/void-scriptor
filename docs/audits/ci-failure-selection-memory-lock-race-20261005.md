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
dan **nomor barisnya tidak cocok** dengan file yang sama di pohon kerja lokal (di `HEAD` lokal,
`193` adalah `throw failure!;`). Ini berarti log itu sendiri tidak dapat dipakai untuk menunjuk baris
kode secara pasti. Karena itu dokumen ini **tidak mengklaim baris tertentu**; ia mengutip trace apa
adanya dan menandai lokasi kandidat di bawah sebagai dugaan, bukan bukti.

## Dugaan akar masalah (hipotesis, belum dikonfirmasi)

Pola **guard-lalu-hapus** (`exists()` diikuti `delete()`) adalah TOCTOU: antara pemeriksaan dan
penghapusan, file bisa hilang lebih dulu, sehingga `delete()` melempar `PathNotFoundException`.
Pola ini muncul di **dua** tempat di `project_session_manager.dart`:

| Lokasi | Kode |
|---|---|
| `_close()` (sekitar baris 182–186) | `if (await package.lockFile.exists()) { await package.lockFile.delete(); }` |
| jalur gagal-open (sekitar baris 413–416) | `if (companionWritten && await package.lockFile.exists()) { await package.lockFile.delete(); }` |

**Koreksi penting terhadap dugaan awal:** hipotesis pertama adalah blok unlink di `_close()` berada
**di luar** penanganan `record(e)`. **Itu salah** — sudah diperiksa langsung di sumber: blok unlink
memang dibungkus `try { ... } on Object catch (e) { record(e); }` (sekitar baris 182–188), begitu
pula di jalur gagal-open (sekitar baris 413–418). Jadi *tidak benar* bahwa error itu lolos tanpa
penanganan. Kedua lokasi identik polanya:

```dart
try {
  if (await package.lockFile.exists()) {
    await package.lockFile.delete();
  }
} on Object catch (e) {
  record(e);   // atau komentar "Best-effort" di jalur gagal-open
}
```

Karena `catch` menangkap `Object`, `PathNotFoundException` **seharusnya** tertangkap dan diteruskan
ke `record(e)`, bukan lolos sebagai kegagalan test. Maka mekanisme yang menyampaikan error itu ke
permukaan **belum jelas** dari pembacaan statis ini. Ini justru memperkuat kesimpulan bahwa
**diagnosis belum selesai** — jangan menganggap penyebabnya sudah diketahui.

Dua kandidat yang masih terbuka (keduanya belum diuji):

1. **Nomor baris trace tidak dapat dipercaya.** Frame menunjuk `project_session_manager.dart 193:7`,
   tetapi baris 193 di sumber lokal adalah `throw failure!;` di dalam `_close()`. Bila pemetaan baris
   CI bergeser, lokasi sebenarnya bisa jadi **tempat lain** yang memang tidak dibungkus `record(e)`.
   Prioritas pertama adalah menyamakan baris, bukan menebak.
2. **`record(e)` tidak selalu menelan error.** Perlu diperiksa apakah `record` di kelas itu benar-benar
   menyerap exception, atau apakah ada jalur (mis. setelah `record(e)`, `failure` tetap terisi lalu
   `throw failure!` di baris 190–193) yang melemparkan error **berbeda** — dan apakah error yang
   dilempar ulang itu yang muncul sebagai `PathNotFoundException`.

Kenapa ia muncul di jalur `ProviderContainer.dispose`: `Riverpod` membuang state provider, yang
memanggil `ProjectSession.close()` → `_close()`. Bila lock sudah dilepas/dihapus oleh pemilik yang
sah saat itu (mis. `lock.release()` di baris 174, atau pelepasan oleh sesi lain di dalam test journey
yang memang menguji restart), `delete()` menjadi operasi atas file yang sudah tidak ada — dan
pertanyaannya adalah **bagaimana** error itu naik ke permukaan meskipun ada `catch`.

**Mengapa ini masuk akal sebagai race, bukan bug deterministik:** `PathNotFoundException` pada
unlink file lock bergantung pada urutan/ketepatan waktu antara pelepasan lock dan pembuangan
container. Itu tidak dipengaruhi oleh perubahan checksum/assertion yang dilakukan sesi ini.

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

## Langkah tindak lanjut yang disarankan (untuk pemilik area)

1. Tentukan apakah kegagalan ini berulang: jalankan ulang CI pada `b3b7c6a` atau jalankan
   `flutter test test/features/explorer/selection_memory_restart_persistence_test.dart`
   berulang kali untuk mengukur laju kegagalan. Satu run belum cukup untuk menyimpulkan.
2. Bila berulang: **selesaikan dulu diagnosis** — samakan nomor baris CI dengan sumber nyata dan
   periksa apakah `record(e)` benar-benar menyerap exception di jalur itu. Baru setelah itu
   pertimbangkan perbaikan (mis. membuat unlink toleran terhadap file yang sudah tidak ada, atau
   memastikan langkah teardown tetap best-effort di kedua lokasi pada tabel di atas).
3. Bila ternyata satu kali saja: catat sebagai flaky dan pertimbangkan menambah determinisme pada
   urutan pelepasan lock vs pembuangan container di test journey tersebut.

## Dampak pada status sprint 117

**Sprint 117 belum dapat dinyatakan hijau.** Gate `117.43` lulus lokal (224/224) di kedua kondisi
(dengan pohon build dan pada simulasi clean checkout), dan test `117.43` lulus di CI. Namun pipeline
CI secara keseluruhan masih merah karena temuan di atas, sehingga status hijau tidak boleh diklaim
sampai kegagalan ini diselesaikan atau dibuktikan tidak berulang.
