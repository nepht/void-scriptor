# Sprint 108 — Void Scriptor v1.2 Discovery & Product Direction

- **Status:** BERJALAN (dibuka 2026-08-25 20:29 WIB) · **Base aktual:** `1.1.0` stable · **Target:** tema rilis `v1.2` disetujui lewat Direction Approval Gate
- **Kanonik:** `sprint_108.json` (32 langkah, VALIDATED; `depends_on: [107]`)
- **Deviasi kanonik terdokumentasi (konsekuensi keputusan arsitek):** `start_condition`
  kanonik menyebut "Sprint 107 COMPLETE dan **v1.1.1** stabil selama observation
  window"; `base_version` kanonik `1.1.1`. Choirudin memilih opsi A pada penutupan
  S107 (2026-08-25 20:29 WIB): **tidak ada hotfix ⇒ tidak ada rilis `1.1.1`**;
  baseline nyata discovery ini adalah **`1.1.0` stable** yang saat pembukaan masih
  berada dalam observation window pasca-rilis (auto-close 2026-08-26 ±13:57 WIB).
  Deviasi ini direkam atas wewenang arsitek; semua langkah yang menyentuh "kondisi
  v1.1.x" membaca baseline aktual 1.1.0.
- **Karakter sprint:** discovery murni — bukti penggunaan, friction/unmet-need,
  evaluasi fitur v1.1, feasibility, eksperimen kecil, prioritisasi, satu tema
  rilis v1.2, lalu gerbang persetujuan arah (108.31). Bukan sprint fitur.
- **Pitfall konkurensi:** worktree ramai milik multi-agen (ci.yml, README,
  docs/audits/*, lib/ routing) — sprint ini HANYA menyentuh file miliknya sendiri.
- **Batas jujur awal:** tanpa telemetry produksi (KI-03) dan tanpa kanal distribusi
  publik (KI-04), langkah berbasis data pemakaian nyata (108.3, 108.6, 108.9–108.11)
  hanya dapat bekerja atas bukti lokal: checkpoint record watch, known-issues,
  regresi suite, catatan rilis, dan observasi workflow Choirudin sendiri sebagai
  pengguna pertama. Keterbatasan ini dicatat per langkah, tidak disembunyikan.

| # | Langkah | Status | Bukti |
|---|---|---|---|
| 108.1 | Discovery Charter | VERIFIED | `docs/discovery/v1.2/charter.md` memuat seluruh required_fields kanonik: decision (tema v1.2 via gate 108.31 / penundaan terdokumentasi), questions Q1–Q5, scope, non_goals, owners (nephthys eksekusi, Choirudin otoritas keputusan), deadline draft 2026-08-29 |
| 108.2 | Stable Baseline Review | VERIFIED | `docs/discovery/v1.2/baseline-review.md` — enam input kanonik dinilai dari bukti langsung (suite +1713, perf +58, regresi +41, KI register, kontrak C1–C5, watch record); baseline aktual **1.1.0** (deviasi kanonik 1.1.1 terekam); temuan: kolom Signature/SBOM di stable-manifest STALE |
| 108.3 | Evidence Inventory | VERIFIED | `docs/discovery/v1.2/evidence-inventory.md` — tujuh sumber kanonik dipetakan dengan lokasi bukti + keterbatasan jujur (telemetry nol, single-user, benchmark dev-only); implikasi metode untuk 108.6–108.7 |
| 108.4 | Assumption Register | VERIFIED | `docs/discovery/v1.2/assumptions-register.md` — 6 asumsi (A-01…A-06) dengan field wajib lengkap id/statement/risk/evidence_needed/test_method/status; semua OPEN menunggu uji |
| 108.5 | User Segment Review | VERIFIED | `docs/discovery/v1.2/user-segments.md` — segmen S1 terbukti dari bukti pemakaian nyata (registry projects.json + DB), keenam dimensi kanonik terisi; segmen S2 dinyatakan HIPOTESIS tanpa persona fiktif |
| 108.6 | Workflow Observation | VERIFIED | `docs/discovery/v1.2/workflow-observation.md` — rekonstruksi sesi nyata 22–23 Agu atas proyek "Test Novel" (metode forensik mtime+DB read-only, isi cerita tak dibuka); temuan kunci: pemakaian berhenti total pasca-sesi uji |
| 108.7 | Friction Map | VERIFIED | `docs/discovery/v1.2/friction-map.md` — F-01…F-05 dengan field wajib lengkap; tiap entri berbukti; F-03 (retensi) ditandai n=1 rapuh, F-04 ditandai inferensi |
| 108.8 | Unmet-Need Map | VERIFIED | `docs/discovery/v1.2/unmet-needs.md` — UN-01…UN-06 rumusan masalah-murni berbukti (problem_before_solution); keinginan tanpa bukti sengaja tidak didaftarkan |
| 108.9 | Support & Incident Analysis | PENDING | Pola masalah dari rekaman support/inciden |
| 108.10 | Workflow Intelligence Evaluation | PENDING | Penggunaan, keberhasilan, batas fitur workflow v1.1 |
| 108.11 | Automation Safety Evaluation | PENDING | Nilai vs risiko automation |
| 108.12 | Platform Experience Review | PENDING | Perbandingan workflow/keterbatasan antar platform didukung |
| 108.13 | Plugin Ecosystem Review | PENDING | Kebutuhan ekstensi & hambatan Plugin API v1 |
| 108.14 | AI & Compute Direction Review | PENDING | Local/remote/provider: biaya, privasi, kualitas, latency |
| 108.15 | Competitive & Adjacent Research | PENDING | Pola produk relevan tanpa menyalin otomatis |
| 108.16 | Technology Capability Review | PENDING | Kemampuan teknologi tersedia & kematangannya |
| 108.17 | Opportunity Registry | PENDING | Masalah terverifikasi → peluang yang dapat dibandingkan |
| 108.18 | Opportunity Sizing | PENDING | Skala & ketidakpastian tiap peluang |
| 108.19 | Strategic Fit | PENDING | Kesesuaian dengan identitas & prinsip VOID SCRIPTOR |
| 108.20 | Architecture Feasibility | PENDING | Dapat dibangun tanpa merusak boundary/ownership |
| 108.21 | Data & Migration Feasibility | PENDING | Kebutuhan data/schema/migrasi/backup/rollback |
| 108.22 | Security & Privacy Feasibility | PENDING | Permission/threat/data flow/retention/transfer sejak discovery |
| 108.23 | Accessibility & Localization Feasibility | PENDING | A11y & lokalisasi sebelum prioritisasi |
| 108.24 | Success Metric Design | PENDING | Metrik hasil, driver, guardrail utk peluang utama |
| 108.25 | Experiment Plan | PENDING | Eksperimen terkecil untuk mengurangi ketidakpastian |
| 108.26 | Prototype Boundaries | PENDING | Prototype ≠ implementasi produksi |
| 108.27 | Experiment Execution | PENDING | Eksekusi eksperimen + catatan hasil/kegagalan/batas |
| 108.28 | Opportunity Prioritization | PENDING | Pilihan berdasar nilai, bukti, feasibility, biaya, risiko |
| 108.29 | v1.2 Release Theme | PENDING | Satu tema rilis berbasis bukti |
| 108.30 | Scope & Non-Goals | PENDING | Must/Should/Could/Won't + batas v1.2 |
| 108.31 | Direction Approval Gate | PENDING | Persetujuan arah hanya jika bukti & risiko cukup jelas — keputusan Choirudin |
| 108.32 | Sprint Closure | PENDING | Tutup discovery setelah arah v1.2 dipilih ATAU keputusan menunda dicatat |
