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
| 108.9 | Support & Incident Analysis | VERIFIED | `docs/discovery/v1.2/support-incidents.md` — SI-01…SI-05 dengan group_by kanonik lengkap; nol insiden produk terverifikasi; pola root_cause yang bisa dikurangi: ketergantungan WSL tunggal + buta pemakaian |
| 108.10 | Workflow Intelligence Evaluation | VERIFIED | `docs/discovery/v1.2/workflow-intelligence.md` — 7 metrik kanonik dievaluasi jujur: creation/repeat_use = 0 nyata, failure dsb. tak terdefinisi (0/0), abandonment subsistem 100%; kapabilitas teruji ≠ adopsi |
| 108.11 | Automation Safety Evaluation | VERIFIED | `docs/discovery/v1.2/automation-safety.md` — 6 sinyal kanonik = 0 kejadian nyata; verdikt dua arah: nilai belum tersalurkan, risiko lapangan belum teruji; hanya keamanan kondisi-uji yang terbukti |
| 108.12 | Platform Experience Review | VERIFIED | `docs/discovery/v1.2/platform-experience.md` — 7 dimensi kanonik; tersedia ≠ tervalidasi (hanya Linux x64 berbukti penuh); web = kandidat platform kedua termurah; a11y dimensi tertipis |
| 108.13 | Plugin Ecosystem Review | VERIFIED | `docs/discovery/v1.2/plugin-ecosystem.md` — API v1 teruji (+23) tapi nol permintaan nyata; verdikt: pelihara stabilitas v1, jangan investasi ekosistem tanpa bukti permintaan (menunggu uji S2) |
| 108.14 | AI & Compute Direction Review | VERIFIED | `docs/discovery/v1.2/ai-compute-direction.md` — 4 provider terpasang; lokal mustahil di RX 590 (A-02/A-03); arah: remote opt-in + gerbang privasi; eksperimen kecil sebelum investasi |
| 108.15 | Competitive & Adjacent Research | VERIFIED | `docs/discovery/v1.2/competitive-adjacent-research.md` — 5 required_outputs lengkap (patterns/tradeoffs/differentiation/sources/tanggal); sumber publik nyata (Campfire/World Anvil/Scrivener/Novelcrafter/Sudowrite); pasar bergerak ke BYO-key = searah arsitektur VS |
| 108.16 | Technology Capability Review | VERIFIED | `docs/discovery/v1.2/technology-capability.md` — 13 teknologi diklasifikasi jujur: 4 PRODUCTION_READY, 4 LIMITED, 1 EXPERIMENTAL, 4 UNSUITABLE (lokal-AI di RX 590, installer, telemetri, GUI-verify WSLg) |
| 108.17 | Opportunity Registry | VERIFIED | `docs/discovery/v1.2/opportunity-registry.md` — OPP-01…OPP-06 dengan 7 field wajib per entri; hanya masalah terverifikasi yang diangkat; semua menunggu pemetaan & gate |
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
