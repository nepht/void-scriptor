# 109.2 Output 2/4 — Non-Goals v1.2 (Sprint 109)

> Basis: scope DISATUKUI di gate 108.31 (`docs/discovery/v1.2/scope-non-goals-draft.md`)
> + batas kanonik `sprint_109.json`. Disusun nephthys 2026-08-26.

## Non-goal tetap (diwarisi dari scope disetujui, tidak berubah oleh S109)

- NG-1 Installer MSI/deb & updater otomatis (gap KI-04 carry-over).
- NG-2 Telemetri produksi/hosting (KI-03; jurnal lokal opt-in M2 tetap satu-satunya jalur data).
- NG-3 Cloud sync / akun layanan awan — melanggar local-first.
- NG-4 Plugin API v2 / ekspansi marketplace publik.
- NG-5 Platform mobile/iOS/macOS native baru (scaffold ada, tanpa klaim).
- NG-6 Perbaikan a11y menyeluruh lintas produk — CATATAN NUANSA: acceptance per-fitur
  kanonik (mis. `screen_reader_announcement` F10, `screen_reader_access` F8, langkah
  109.48) TETAP WAJIB untuk fitur baru v1.2; yang non-goal hanyalah remedi retroaktif
  seluruh modul lama (utang terukur di 108.23).
- NG-7 Modul di luar 13 capability + fondasi 109.3–109.8 tidak disentuh
  (collaboration, multiverse, cinema, audio lanjutan, dll. tetap seperti semula).

## Batas keras yang justru diperkuat S109

- Kontrak C1–C5 dan Plugin API v1 tidak berubah.
- Tidak ada co-ownership lintas workspace; unlink ≠ delete karakter (ADR-WS-001).
- Flag default OFF untuk SEMUA fitur baru; local-first; export data user tersedia.
- Tidak ada penghapusan/mutasi destruktif data pengguna: restore membuat backup,
  sinkronisasi board eksplisit dengan preview konflik, export tidak memutasi sumber.

## D-SCHEMA-01 — Keputusan terbuka (dicatat jujur, bukan disembunyikan)

Draft scope disetujui menulis "skema project.db tetap v56" sebagai batas keras paket
MUST discovery. Kanonik S109 berbeda arah: `migration_rollback_required=true`,
langkah 109.4 (Shared Data Schema) + 109.5 (Migration, Backup & Rollback Plan),
dan banyak capability tak terbayangkan tanpa tabel tambahan (moodboard, quest,
snapshot, board…).

**Posisi kerja kontrak ini**: evolusi skema ADDITIVE-ONLY diizinkan mengikuti kanonik
(sumber yang ditunjuk Choi untuk sprint ≥100), setiap migrasi wajib guarded + rollback
test + restart persistence test, dan nomor skema final >56 DIRATIFKASIKAN ulang oleh
Choirudin di Alpha Acceptance Gate 109.51. Tidak ada migrasi dieksekusi sebelum
109.4/109.5 menyetujui rinciannya. Bila Choi ingin v56 tetap beku, semua fitur
dipaksa jalur tanpa-skema (file/JSON sidecar) — lebih mahal dan lebih rapuh, dan
itu keputusan miliknya, bukan nephthys.

Status: OPEN — default mengikuti kanonik sampai diputuskan lain.
