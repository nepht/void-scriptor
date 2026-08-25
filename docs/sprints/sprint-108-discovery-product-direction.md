# Sprint 108 — Void Scriptor v1.2 Discovery & Product Direction

- **Status:** SELESAI — arah v1.2 DISETUJUI (GO) di gate 108.31 oleh Choirudin,
  2026-08-25 ±21:45 WIB · **Base aktual:** `1.1.0` stable · **Hasil:** tema
  rilis `v1.2` "Kembali ke Alur" + scope MUST×3/SHOULD×2/COULD×1/WON'T×6
  disetujui sebagai arah resmi v1.2
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
| 108.18 | Opportunity Sizing | VERIFIED | `docs/discovery/v1.2/opportunity-sizing.md` — 6 dimensi × 6 peluang; jujur: populasi n=1 membuat semua reach mikro; nilai = kepastian arah; urutan impact-per-effort OPP-01→02→05→06→03→04 |
| 108.19 | Strategic Fit | VERIFIED | `docs/discovery/v1.2/strategic-fit.md` — 6 kriteria identitas per peluang; dua titik ketegangan terekam (Web vs local-first; remote vs local-first) keduanya sah dengan posisi yang benar |
| 108.20 | Architecture Feasibility | VERIFIED | `docs/discovery/v1.2/architecture-feasibility.md` — 7 scope review atas peta live (24 core/46 features); semua peluang feasible tanpa boundary baru, tanpa modul core baru |
| 108.21 | Data & Migration Feasibility | VERIFIED | `docs/discovery/v1.2/data-migration-feasibility.md` — 4 required_outputs; skema v56 bisa beku sepanjang v1.2; rollback trivial utk OPP-05/06; DR lintas-mesin tercatat terbuka jujur |
| 108.22 | Security & Privacy Feasibility | VERIFIED | `docs/discovery/v1.2/security-privacy-feasibility.md` — 5 required_outputs; risiko terkonsentrasi di OPP-06 (eksfiltrasi naskah) dengan mitigasi gerbang persetujuan per-konten; klasifikasi data 3 kelas |
| 108.23 | Accessibility & Localization Feasibility | VERIFIED | `docs/discovery/v1.2/a11y-localization-feasibility.md` — 7 scope dari grep repo live: `Semantics(`=0, keyboard parsial, scaling/motion/contrast belum dikaji; temuan positif: infrastruktur l10n EN+ID (`app_id.arb`) ada nyata |
| 108.24 | Success Metric Design | VERIFIED | `docs/discovery/v1.2/success-metric-design.md` — outcome/driver/guardrail/baseline/target/window lengkap; baseline jujur 0 sesi sejak 23 Agu; target usulan menunggu otoritas Choi; ketergantungan OPP-05 terekam |
| 108.25 | Experiment Plan | VERIFIED | `docs/discovery/v1.2/experiment-plan.md` — E-1…E-5 dengan jenis kanonik, biaya, dan status kelayakan otonom jujur (E-3 satu-satunya yang bisa jalan tanpa Choi/sukarelawan) |
| 108.26 | Prototype Boundaries | VERIFIED | `docs/discovery/v1.2/prototype-boundaries.md` — B1–B4 memetakan keempat requirement kanonik (no-production-data / flag-OFF / security-documented / disposable) + konsekuensi pelanggaran |
| 108.27 | Experiment Execution | PARTIAL | `docs/discovery/v1.2/experiment-execution.md` — E-3 dieksekusi penuh otonom (build web ✓ 83,2s, artefak 59MB, HTTP 200 lokal); E-3 tereksekusi otonom DAN E-1 tereksekusi via jawaban arsitek 21:45 WIB; E-2/E-5 diblokir terdokumentasi; E-4 deferred |
| 108.28 | Opportunity Prioritization | VERIFIED | `docs/discovery/v1.2/opportunity-prioritization.md` — skor 7 kriteria × 6 peluang; urutan OPP-01(34)→02(30)→05(28); selisih tipis OPP-04/06 ditandai boleh dibalik di gate |
| 108.29 | v1.2 Release Theme | VERIFIED | `docs/discovery/v1.2/release-theme-draft.md` — DRAFT "Kembali ke Alur" dengan 6 field wajib; eksplisit menunggu otoritas gate 108.31; alternatif yang ditolak beralas |
| 108.30 | Scope & Non-Goals | VERIFIED | `docs/discovery/v1.2/scope-non-goals-draft.md` — MUST×3 / SHOULD×2 / COULD×1 / WON'T×6; batas keras lintas-kategori (skema v56 beku, C1–C5 & Plugin API tak berubah) |
| 108.31 | Direction Approval Gate | VERIFIED | Keputusan Choirudin 2026-08-25 ±21:45 WIB: **GO** — tema & scope draft disetujui; paket bukti kanonik lengkap 7/7 (evidence-inventory, opportunity-registry, experiment-results, feasibility×5, success-metrics, scope-drafts, risk-register R-01…R-09) |
| 108.32 | Sprint Closure | VERIFIED | `docs/discovery/v1.2/sprint-closure.md` — DoD 8 butir terpenuhi; E-1 tereksekusi & F-03 tertutup non-friksi; data uji dibersihkan atas permintaan arsitek (backup ganda SHA-256); sprint ditutup dengan arah v1.2 tercatat |
