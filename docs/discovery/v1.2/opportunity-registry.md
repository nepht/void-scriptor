# 108.17 — Opportunity Registry

> Sprint 108 · disusun 2026-08-25 · kanonik required_fields per entri:
> opportunity_id, problem, segment, evidence, expected_outcome,
> constraints, confidence
> Hanya masalah TERVERIFIKASI (F-map, UN-map, SI-map) yang boleh jadi peluang.

### OPP-01 — Pahami & pulihkan retensi pengguna inti
- problem: satu-satunya pengguna aktif berhenti total sejak 23 Agu 20:48
- segment: S1 (penulis-tunggal teknis)
- evidence: timeline mtime proyek "Test Novel"; pgrep NO_PROCESS semua checkpoint (F-03/UN-01)
- expected_outcome: alasan berhenti diketahui (jawaban langsung Choi termurah); pemakaian harian tersambung lagi
- constraints: n=1; tanpa telemetri; penyebab bisa non-produk (sibuk/keputusan sadar)
- confidence: tinggi akan pentingnya; rendah akan penyebab (belum diuji)

### OPP-02 — Kedalaman jalur naratif daripada lebar subsistem
- problem: hanya 5/157 tabel pernah tersentuh; nilai produk tak terrealisasi
- segment: S1
- evidence: COUNT(*) DB read-only (F-01/UN-02); pola pasar: modularity-onboarding (108.15)
- expected_outcome: v1.2 memfokuskan investasi pada pipeline story→scene→timeline yang benar-benar dipakai
- constraints: butuh konfirmasi arah Choirudin; risiko mengabaikan subsistem lain harus disadari
- confidence: tinggi

### OPP-03 — Validasi platform kedua termurah (Web)
- problem: ketergantungan tunggal WSL Linux x64 (KI-03)
- segment: S1 → prasyarat S2
- evidence: uji web bootstrap/guard ada tanpa validasi penuh (108.12); klasifikasi LIMITED (108.16)
- expected_outcome: klaim platform kedua berbasis bukti run nyata
- constraints: performa Web belum diprofil; bukan Windows-native (kebutuhan OS harian Choi tetap terbuka)
- confidence: sedang

### OPP-04 — Uji distribusi ke satu pembaca/penulis kedua sungguhan
- problem: segmen S2 masih hipotesis tanpa satu pun uji eksternal (KI-04)
- segment: S2 (hipotesis)
- evidence: paket portable siap end-to-end; nol pengguna eksternal (A-01 OPEN)
- expected_outcome: satu siklus instalasi-pakai-lapor oleh orang lain berhasil
- constraints: butuh sukarelawan + saluran manual; tanpa installer grafis
- confidence: sedang-rendah (ketergantungan eksternal)

### OPP-05 — Sinyal pemakaian tanpa telemetri hosting
- problem: keputusan produk buta pemakaian (KI-03 warisan)
- segment: S1
- evidence: seluruh observasi 108.6–108.11 bergantung forensik filesystem (SI-03/UN-04)
- expected_outcome: jurnal sesi lokal opt-in sederhana (tanpa server) sebagai proxy telemetri
- constraints: tetap bukan telemetri produksi; privasi konten wajib terjaga
- confidence: sedang

### OPP-06 — Eksperimen AI remote opt-in terukur
- problem: nilai AI tak pernah diuji end-to-end; hardware lokal mustahil
- segment: S1
- evidence: 4 provider terpasang, ai_generation_jobs=0; RX 590 UNSUITABLE (108.14/108.16)
- expected_outcome: satu prompt→satu provider remote dengan angka latensi+biaya+kualitas nyata
- constraints: biaya token keluar kantong; persetujuan privasi konten novel wajib dulu
- confidence: sedang

Semua entri menunggu pemetaan 108.18+ dan keputusan gate 108.31.
