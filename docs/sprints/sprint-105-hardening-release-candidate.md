# Sprint 105 — Void Scriptor v1.1 Hardening & Release Candidate

- **Status:** BERJALAN (2026-08-25)
- **Base:** `1.1.0-beta.1` (manifest @`4ba2a08`, commit `9de73f1`) · **Dev:** `1.1.0-rc-dev` · **Target milestone:** `1.1.0-rc.1`
- **Start condition:** Sprint 104 COMPLETE 35/35 + beta lolos validasi (suite +1699, analyze bersih, release train PASS) — TERPENUHI.
- **Kanonik:** `sprint_105.json` (36 langkah, VALIDATED).

| # | Langkah | Status | Bukti |
|---|---|---|---|
| 105.1 | Release Candidate Entry Gate | VERIFIED | Enam bukti wajib ada: (1) beta_artifact_verified = manifest `docs/release/v1.1.0-beta.1-artifact-manifest.md` SHA-256 terukur @`4ba2a08`; (2) no_open_p0 = Release Blocker Register (baris 105.4) KOSONG sejak pembukaan; (3) beta_test_report = full suite **+1699 All tests passed** FULLTEST_EXIT=0 pada versi beta (`vs_full_suite_104.log`); (4) migration_report = migrasi DB 53→54→55→56 ter-guard + test roundtrip/migration hijau dalam suite; (5) security_review = modul `lib/workflow/workflow_security.dart` + `rule_validation.dart` + `AutomationNetworkPolicy` + `SecretReference` teruji dalam suite; (6) performance_report = focused perf gates PASS pada release train beta |
| 105.2 | Feature Freeze | VERIFIED | Kebijakan efektif sejak baris ini untuk seluruh v1.1: new_features=BLOCK, optional_refactors=BLOCK, release_fixes=ALLOW_WITH_REVIEW (wajib justifikasi di commit message + entri ledger); sprint 105 hanya mengerjakan hardening/verifikasi/artefak |
| 105.3 | Beta Issue Triage | VERIFIED | Klasifikasi temuan beta: **fixed_before_rc** — 27 asersi skema basi 55→56 diperbarui (`69f5557`); race checkpoint `_finish` terminal-status diperbaiki (`083eed7`); save-gate editor automation (`4ba2a08`). **accepted_known_issue** — signing & SBOM artefak NOT AVAILABLE (toolchain lokal tanpa infra penandatanganan; konsisten pola v1.0.1/alpha/beta). **deferred_post_1.1** — hosted CI diaktifkan ulang (keputusan D6, billing), build macOS/iOS, wiring C1 jalur hidup. **rejected_with_reason** — tidak ada |
| 105.4 | Release Blocker Register | VERIFIED | Register kanonik (fields: issue_id/severity/owner/affected_build/reproduction/status/evidence): **KOSONG — tidak ada blocker RC terbuka** saat entry gate. Setiap temuan baru wajib masuk tabel ini sebelum 105.35 |
| 105.5 | Version Freeze | VERIFIED | Identitas kandidatrilis dibekukan: **`1.1.0-rc.1`** (build number menyusul +5 saat 105.32); pubspec/format tidak boleh berubah kecuali eksekusi 105.32 |
| 105.6 | Project Format Compatibility | PENDING | — |
| 105.7 | Database Schema Freeze | PENDING | — |
