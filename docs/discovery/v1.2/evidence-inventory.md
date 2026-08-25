# 108.3 — Evidence Inventory

> Sprint 108 · disusun 2026-08-25 · kanonik sources: user_feedback,
> support_issues, workflow_data, crash_data, performance_data,
> research_notes, product_constraints
> Prinsip: hanya sumber yang BENAR-BENAR ADA yang dicatat; kekosongan dinyatakan
> sebagai kekosongan, tidak diisi generalisasi.

| Sumber kanonik | Yang tersedia (lokasi) | Keterbatasan |
|---|---|---|
| user_feedback | Tidak ada kanal eksternal (tanpa distribusi publik/telemetry). Proxy yang sah: arahan & keputusan langsung Choirudin selama kolaborasi (mis. pilihan OFFLINE, keputusan tanpa LLM lokal 25 Agu, preferensi anti-OP untuk lore) | Single-user; bukan sampel pengguna; mudah bias penyelia |
| support_issues | Register `docs/release/v1.1.0-known-issues.md` (KI-01/02 CLOSED, KI-03 OPEN, KI-04 PARTIAL) + `v1.1.0-troubleshooting.md` | Semua entri self-found saat engineering, bukan laporan lapangan |
| workflow_data | Nol instrumentasi pemakaian (telemetry absen). Proxy: coverage test workflow/automation (`+1713` suite; modul `test/automation/*` mengontrakkan trigger/gate/saga) menunjukkan workflow yang DIRANCANG, bukan yang DIPAKAI | Tidak membuktikan pola pakai nyata; risiko membangun utk workflow fiktif |
| crash_data | Checkpoint watch berkala: `pgrep` + integritas biner, 7 checkpoint nol insiden (`v1.1.0-watch-checkpoints.md`) | Aplikasi tidak berjalan kontinu; ketiadaan crash dalam window pendek ≠ stabilitas jangka panjang |
| performance_data | `~/vs_perf_107.log` (+58, termasuk FTS5 20k dokumen interaktif); startup metrics berfase; pagination/prefetch terkontrak test | Belum ada profil beban dunia-nyata jangka panjang; dataset benchmark dev-only |
| research_notes | Ledger sprint `docs/sprints/`, catatan arsitektur `docs/architecture/`, pembelajaran gateway AI (Alpakyros/OpenAI-compatible: makna kode error 401/403/400), referensi skill engineering | Pengetahuan proses/engineering, belum sistematis sebagai insight produk |
| product_constraints | Hardware: AMD RX 590 GME 8GB (Polaris; LLM lokal dihapus 25 Agu), RAM 32GB; lingkungan: WSL Ubuntu + Windows host, render GUI butuh GPU; operasional: MODE OFFLINE, hosted CI di-waive; carry-over: KI-03 platform, KI-04 installer/updater | Constraint nyata dan terverifikasi — bagian terkuat dari inventori ini |

## Implikasi metode discovery

1. Langkah berbasis data pemakaian (108.6 Workflow Observation, 108.7 Friction
   Map) harus menggantikan data instrumentasi dengan **observasi langsung atas
   workflow nyata Choirudin** (Void Cube Saga sebagai beban kerja uji sesungguhnya),
   dan menyatakan metode itu di setiap kesimpulan.
2. Kekosongan telemetry adalah temuan discovery tersendiri: apakah v1.2 perlu
   observabilitas lokal ringan (privacy-preserving, offline-first) sebagai peluang
   — kandidat untuk Opportunity Registry (108.17), BUKAN kesimpulan sekarang.
3. Semua klaim lintas-platform dan multi-user ditandai hipotesis sampai ada alat
   ujinya.
