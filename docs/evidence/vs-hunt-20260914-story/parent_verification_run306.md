# Parent verification run306 — dua bukti yang menentukan verdict vs Skeptic

Skeptic mengonfirmasi 8/8 temuan Hunter, termasuk BUG-STORY-04/05/06
(klaim: `File.rename` gagal menimpa destinasi yang sudah ada). Orang tua
(parent) memverifikasi klaim platform ini secara runtime sebelum Referee
bekerja, karena Skeptic tidak boleh menjalankan kode target.

## Probe 1 — semantic File.rename pada Windows/Dart SDK produksi

Skrip disposable (bukan bagian repo): `C:\Users\nepht\AppData\Local\Temp\vs_rename_probe.dart`
menjalakan Dart VM SDK yang sama dipakai proyek
(`D:\DevTools\Flutter SDK\flutter\bin\cache\dart-sdk\bin\dart.exe`):

```
dest.txt      = 'OLD'   (sudah ada)
dest.txt.tmp  = 'NEW'
await staging.rename(dest.path)
```

Output aktual:

```
RENAME_OVER_EXISTING: OK dest=NEW
staging still present: false
EXIT=0
```

Kesimpulan: pada toolchain target (Windows, SDK Flutter/Dart repo ini),
`File.rename` MENGGANTIKAN destinasi yang sudah ada. Premis satu-satunya
BUG-STORY-04/05/06 ("re-export ke path yang sudah ada gagal di rename
terakhir") terbantahkan. Kondisi gagal lain yang mungkin (destinasi
terkunci proses lain, read-only, beda volume) bukan klaim temuan.
Referee mengadopsi bukti ini dan mem-DISMISS ketiganya; bukti test tambahan
`test/features/story/story_export_interrupt_safety_test.dart:153-180`
sudah mem-pin re-export sukses + tidak ada sisa `.tmp` untuk jalur TXT.

File probe dihapus setelah run (`PROBE_CLEANED` terverifikasi). Tidak ada
file pengguna yang disentuh; hanya Direktori sistem temp.

## Probe 2 — spot-check kutipan Hunter di HEAD

`git rev-parse HEAD` = 9a549f4d8c7ffb5a53419db4bd78b96728625209.
Empat lokasi dikutip line-exact sebelum rantai dilanjutkan:

- contradiction_analysis.dart:178-180 (map literal by subjectId)
- contradiction_inbox.dart:219-234 (fromJson tanpa record dismissal)
- story_markdown_exporter.dart:77-86 (staging -> rename)
- word_targets.dart:125-136 (recordWords tanpa guard scopeKey)

## Konsekuensi perbaikan run ini

Empat REAL BUG diperbaiki TDD (STORY-01/03/07/08). STORY-02 (kontrak
serialisasi inbox) sengaja tidak dikerjakan: perbaikannya mengubah bentuk
JSON tersimpan (`toJson` perlu menyertakan record dismissal), yang masuk
kategori perubahan kontrak data — butuh keputusan arah sebelum patch
(persist records vs wajibkan store non-null). Antrean + arah konkret
dicatat di ledger sprint.
