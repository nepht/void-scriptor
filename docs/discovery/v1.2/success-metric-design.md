# 108.24 — Success Metric Design

> Sprint 108 · disusun 2026-08-25 · kanonik required_fields per metrik utama:
> outcome_metric, driver_metrics, guardrails, baseline, target,
> measurement_window

## Metrik hasil utama (mengikuti OPP-01+02)

**outcome_metric**: jumlah hari-menulis aktif per minggu (sesi dengan ≥1 edit
narratif nyata pada proyek hidup).
- baseline: **0 sesi sejak 23 Agu 20:48**; sebelum itu ±1 sesi produktif
  (22–23 Agu) dalam 9 hari observasi.
- target (usulan, otoritas akhir di Choi): **≥3 hari aktif/minggu bertahan
  4 minggu** setelah arah v1.2 dieksekusi tahap pertama.
- measurement_window: **28 hari** sejak adopsi langkah v1.2 pertama.

## driver_metrics

1. waktu-dari-luncur-sampai-edit-pertama (target < 60 detik — mengukur friksi
   masuk alur; sumber: jurnal OPP-05 bila dibangun, else mtime proxy).
2. scene/chapter tersentuh per minggu (kedalaman alur naratif).
3. rasio sesi-yang-selesai-dengan-save (ketahanan alur kerja).

## guardrails

- g1: NOL string konten cerita bocor ke jurnal pemakaian (diuji test
  anti-leakage — syarat OPP-05).
- g2: NOL migrasi skema project.db sepanjang window (v56 beku).
- g3: suite penuh tetap hijau di tiap checkpoint rilis internal.
- g4: crash rate tetap 0 laporan (crash_diagnostics existing).

## Ketergantungan jujur

Tanpa OPP-05 (jurnal lokal opt-in), outcome & driver hanya terukur lewat proxy
filesystem (mtime) yang rapuh — pasangkan OPP-05 dengan apa pun yang
diprioritaskan agar metrik ini benar-benar terukur, bukan dikira-kira.
Metrik ini MENUNGGU keputusan gate 108.31; angka target boleh direvisi Choi.
