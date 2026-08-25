# 109.6 — Permission & Privacy Model

> Kanonik 109.6: "Menentukan akses data lokal, media, sharing, ekspor, dan analisis."
> Disusun nephthys 2026-08-26 dari audit live (`workspace_permission_policy.dart`
> lengkap, `security_settings.dart`, `lib/l10n/`) + aturan permission_rules ADR-WS-001
> + keputusan discovery M2 (jurnal lokal opt-in).

## PM1 — Model akses lokal

- **Baseline single-user local-first**: satu pengguna lokal = `isLocalProjectOwner`,
  mencakup kedua boundary (diuji: "explicit local project owner grant covers both
  workspace boundaries"). Tidak ada autentikasi jaringan — NG-3 melarang cloud/account.
- **Pembaca beta BUKAN pengguna aplikasi**: mereka menerima paket ekspor; kontrol
  akses mereka = clearance di dalam paket (F16, langkah 109.31), bukan akun/permission runtime.
- **Titik penegakan**: keputusan permission diambil di application layer
  (`WorkspacePermissionPolicy` + `AuthorizedWorkspaceProjectionReader` + repository),
  bukan di widget. Widget tanpa gerbang ini dianggap cacat review security 109.47.

## PM2 — Aturan lintas-workspace (live + ADR, tanpa perubahan)

| Aturan | Status |
|---|---|
| Akses novel ≠ akses character (dua arah) | live, teruji |
| Baca lintas butuh link eksplisit + grant ganda | live, teruji |
| Tulis canon karakter hanya via owner API + grant | live, teruji |
| Field privat karakter tersembunyi tanpa grant eksplisit | live, teruji |
| Share/export wajib menghormati kedua boundary | aturan ADR — dieksekusi oleh sanitizer F16+F19 |

## PM3 — Privasi media & file

- Media (moodboard, referensi) disimpan **di dalam package**, path relatif package;
  path absolut host tidak pernah menjadi data kanonis (pola Sprint 20).
- Aplikasi TIDAK memindai filesystem di luar package untuk mencari file hilang —
  state missing-file ditampilkan apa adanya (acceptance `missing_file_state` 109.28).
- Tidak ada upload otomatis dalam bentuk apa pun; semua jalur keluar data adalah
  ekspor yang diminta pengguna secara eksplisit.

## PM4 — Analisis & telemetri

- Jurnal pemakaian lokal (M2/S108): **opt-in, default OFF, metadata-only whitelist**,
  test anti-leakage wajib; isi kreatif tidak pernah masuk.
- Observability langkah 109.8 membangun DI ATAS batas itu: metrik event lokal,
  tanpa isi dokumen/karakter; tidak ada endpoint remote (KI-03 tetap terbuka jujur).

## PM5 — Enkripsi & lock (warisan Sprint 30)

`SecuritySettings` per proyek sudah ada: `encryptionEnabled` default **false**,
KDF iterations, salt/hash passphrase, `locked` default **true**. Keputusan v1.2:
dipertahankan apa adanya (tidak diwajibkan, tidak dibongkar); arsip share F16
mengandalkan redaksi + manifest audience, enkripsi arsip share TIDAK dijanjikan di
Wave 1 — naikkan ke 109.47 bila threat review menuntut.

## PM6 — Ledger default privasi (mengikat fitur Wave 1)

| Kategori data | Default |
|---|---|
| Manuskrip, karakter, lore, media | Lokal saja, tak pernah keluar tanpa ekspor eksplisit |
| Field privat karakter | Tersembunyi dari projection/proses novel tanpa grant |
| Data spoiler pada share | Tersembunyi default (safe_default level tertinggi, 109.30) |
| Metadata pemakaian | OFF sampai pengguna opt-in; whitelist field; bisa dihapus |
| Crash report | File lokal saja; dikirim hanya jika pengguna memilih kirim manual (KI-03) |
