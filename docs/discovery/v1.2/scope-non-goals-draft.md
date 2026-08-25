# 108.30 — Scope & Non-Goals v1.2 (DRAFT untuk gate 108.31)

> Status: **DRAFT usulan nephthys** — final setelah persetujuan Choi (108.31).
> Kanonik categories: MUST / SHOULD / COULD / WONT

## MUST (identitas v1.2 — tanpa ini rilis tak bermakna)

- M1: Jawaban E-1 (alasan berhenti Choi) + perbaikan friksi masuk-alur yang
  ia temukan dalam sesi terpandu (biner rilis v1.1.0).
- M2: Jurnal pemakaian lokal opt-in metadata-only (OPP-05) — flag default OFF,
  whitelist field, test anti-leakage wajib (batas B3/B4 108.26).
- M3: Penguatan fokus alur story→scene→timeline (OPP-02): memperpendek jarak
  buka-aplikasi → edit naratif; tanpa modul core baru, tanpa migrasi skema
  (kontrak 108.20/108.21).

## SHOULD (masuk v1.2 bila kapasitas & syarat terpenuhi)

- S1: Gerbang privasi AI remote + eksekusi E-2 setelah otorisasi Choi
  (persetujuan per-konten, biaya tertutup).
- S2: Satu siklus distribusi sukarelawan (OPP-04/E-5) memakai paket portable.

## COULD (bila sisa kapasitas, tanpa janji)

- C1: Profil performa Web lanjutan pasca-E-3 (runtime interaksi, bukan cuma
  build+sajikan).

## WON'T (secara eksplisit DI LUAR v1.2)

- W1: Installer MSI/deb & updater otomatis (KI-04 gap — tetap carry-over).
- W2: Telemetri produksi/hosting (KI-03 — tetap terbuka jujur).
- W3: Plugin API v2 / ekspansi marketplace publik (nol permintaan nyata).
- W4: Platform mobile/iOS/macOS native baru (scaffold tetap, tanpa klaim).
- W5: Cloud sync / akun layanan awan (melawan local-first tanpa bukti minta).
- W6: Perbaikan a11y menyeluruh (dicatat utang terukur di 108.23, bukan diabaikan).

Batas keras lintas-kategori: skema project.db tetap v56; kontrak C1–C5 dan
Plugin API v1 tidak berubah; semua implementasi lewat gerbang TDD penuh.
