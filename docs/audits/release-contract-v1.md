# Release Contract v1.0.0 — Void Scriptor

Keputusan otoritas oleh Choirudin (D1+D5+D6), dicatat nephthys 2026-08-23.
Bukti gerbang: `docs/audits/pre-release-stabilization-gate.md` (G1–G6).

## Cakupan IN (janji v1.0.0)

1. Inti penulisan: novel, karakter, dan cerita (story) dengan persistence
   SQLite per proyek.
2. Workspace separation ADR-WS-001: workspace bertipe (novel/karakter),
   export/import arsip novel dengan kontrak representasi eksplisit
   (referenceManifest | embeddedSnapshot | fork), collision policy,
   migration runner dengan backup pra-migrasi dan never-delete-source.
3. Wiring produksi: tombol Export/Import Novel aktif dari session nyata
   dengan guard sibuk (tanpa ekspor/impor paralel).
4. Live cutover terbukti pada paket nyata (evidence G4_LIVE_CUTOVER).
5. Versi tunggal: pubspec.yaml sumber kebenaran; dijaga test sinkronisasi
   terhadap VoidProjectFormat.applicationVersion.

## DI LUAR cakupan v1.0.0 (dinyatakan eksplisit, bukan klaim tersirat)

- Installer, code signing, update service, rollback, distribusi publik
  (PBDS-001 tetap PLANNED).
- Cloud sync, akun, komunitas/chat (CMM-001), publishing & pembayaran
  (PRS-001, CRPRO-001, PDR-001), reader mode (RCE-001).
- Sertifikasi connector AI (PCR-001).

## Kriteria penerimaan

- Seluruh gerbang G1–G6 berstatus hijau dengan evidence tertaut.
- Regresi gabungan jalur terdampak hijau; flutter analyze bersih;
  `git diff --check` bersih.
- Test penjaga versi hijau.

## Otoritas rilis (D6)

Tag dan nomor versi hanya dibuat oleh Choirudin. nephthys menyiapkan draft
dan evidence; tidak pernah membuat tag atau menaikkan versi secara mandiri.
