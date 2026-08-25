# 108.25 — Experiment Plan

> Sprint 108 · disusun 2026-08-25 · kanonik experiment_types:
> prototype_test, workflow_simulation, technical_spike, usability_test,
> performance_spike
> Prinsip: eksperimen TERKECIL yang mengurangi ketidakpastian terbesar dulu.

| id | jenis | peluang | pertanyaan yang dijawab | metode | biaya | status kelayakan mandiri |
|---|---|---|---|---|---|---|
| E-1 | usability_test + workflow_simulation | OPP-01 | MENGEMPA pemakaian berhenti 23 Agu? Apakah alur masuk aplikasi mulus? | (a) Choi jawab satu kalimat alasannya; (b) satu sesi pakai nyata terpandu di build v1.1.0, catat titik macet | menit | butuh Choi (blokir otonom) |
| E-2 | technical_spike | OPP-06 | Berapa latensi/biaya/kualitas AI remote end-to-end? | satu prompt → satu provider remote, catat angka nyata; WAJIB lewat gerbang persetujuan privasi 108.22 | kecil + biaya token | butuh izin Choi (blokir otonom) |
| E-3 | performance_spike | OPP-03 | Mampukah jalur Web di-build & dilayani dari artefak rilis? | `flutter build web --release` + sajikan statis + ukur artefak | sedang (menit-build) | ✅ BISA otonom |
| E-4 | prototype_test | OPP-05 | Mampukah jurnal metadata-only menolak konten cerita? | prototipe flag-OFF + test anti-leakage di salinan proyek sintetis | sedang | menuntut tulis kode → di luar mode otonom-aman (DEFERRED ke sprint implementasi) |
| E-5 | usability_test | OPP-04 | Mampukah orang luar instal→buka tanpa bantuan? | serahkan portable ZIP ke 1 sukarelawan, amati tanpa menolong | kecil | butuh sukarelawan eksternal |

## Urutan eksekusi

E-1 (paling murah, membuka makna semua temuan lain) → E-3 (otonom, jalan
sekarang) → E-2/E-5 (menunggu izin/orang) → E-4 (masuk sprint implementasi
pasca-gate bila OPP-05 terpilih).

Hasil tiap eksperimen dicatat di `experiment-execution.md` (108.27).
