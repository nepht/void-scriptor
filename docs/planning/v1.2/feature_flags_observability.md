# 109.8 — Feature Flags & Observability

> Kanonik 109.8: "Menyiapkan rollout aman dan pengukuran tanpa mengumpulkan isi
> kreatif secara default." Disusun nephthys 2026-08-26. Langkah ini diimplementasi
> sebagai KODE TERUJI, bukan hanya dokumen.

## FF — Feature flag registry (live)

`lib/core/feature_flags/feature_flag_registry.dart`:

- 13 flag kanonik Wave 1 (`vs12_lore_links`, `vs12_contradictions`,
  `vs12_voice_interview`, `vs12_conlang`, `vs12_focus_writing`, `vs12_lore_graph`,
  `vs12_plot_board`, `vs12_moodboard`, `vs12_spoiler_sharing`, `vs12_pov`,
  `vs12_pacing`, `vs12_export`, `vs12_quests`) — nama mengikuti urutan
  feature_contracts.md dan menjadi identifier stabil untuk langkah-langkah berikutnya.
- **Default OFF dipaksa**: tidak ada API untuk membuat flag baru di luar daftar;
  nama tak dikenal ditolak `ArgumentError` di semua operasi.
- `resetToDefaults()` kembali ke semua-OFF; instans independen (tanpa kebocoran global).
- Persistensi override (settings) menyusul di langkah yang membangun UI settings-nya;
  registry sendiri murni in-memory agar mudah diuji.

## OBS — Jurnal lokal anti-leakage by construction (live)

`lib/core/observability/local_usage_journal.dart` (keputusan M2/S108):

- **Opt-in, default OFF**; saat OFF, `record()` tidak menyimpan apa pun.
- Anti-leakage **by construction**, bukan oleh disiplin pemanggil:
  whitelist ganda — hanya 9 event type sah dan hanya 8 key field sah
  (`flag/outcome/surface/durationMs/count/format/reasonCode/schemaVersion`) yang
  pernah tersimpan; field konten ("title", "excerpt", …) dibuang diam-diam meski
  pemanggil mencoba mengirimnya. Isi kreatif TIDAK MUNGKIN masuk jurnal.
- Audit trail privasi: mengaktifkan jurnal otomatis merekam event
  `journal_opted_in`; `clear()` menghapus seluruh riwayat (hak pengguna).
- Kap 5000 entri; persistensi satu file JSON di dalam storage yang dikonfigurasi;
  file korup terdegradasi ke state kosong non-fatal (bukan crash).

## Wiring mendatang

| Konsumen | Rencana |
|---|---|
| Setiap fitur Wave 1 | cek `registry.isEnabled(flag)` sebelum mengekspos permukaan UI pertama |
| Composition root (Riverpod) | sediakan instance registry+journal saat fitur pertama mengonsumsi (F1) |
| Settings | toggle opt-in journal + tampilkan isi & tombol hapus (langkah fitur/settings terkait) |

## Bukti eksekusi TDD (2026-08-26)

Siklus RED→GREEN nyata: RED awal (class belum ada → gagal load), perbaikan kompilasi
(urutan direktif `library`, impor `dart:io`), koreksi ekspektasi tes terhadap desain
audit (`journal_opted_in`), lalu GREEN akhir:

```
flutter test test/core/observability test/core/feature_flags
→ 00:00 +13: All tests passed!
dart format (5 files) → bersih
flutter analyze (4 items) → No issues found!
```
Gerbang penuh (analyze seluruh repo + full suite) dieksekusi sebelum komit; hasil
tercatat di baris ledger langkah ini.
