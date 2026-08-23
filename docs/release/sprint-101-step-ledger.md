# Sprint 101 — Step Ledger: Post-Release Stabilization & Hotfix

Sumber kanonik: `sprint_101.json` (arsip resmi 2026-08-22, direktori
`referenced-chatgpt-conversation-this-is-an-2/outputs`). Eksekusi nephthys
di worktree `vs-worktrees/sprint101`, basis `origin/master` = `334022a`,
tanggal 2026-08-23. Otoritas versi/tag tetap D6 (release-contract-v1.md).

## Bukti eksekusi langsung (slice ini)

- RED→GREEN TDD: `test/app/bootstrap/crash_diagnostics_test.dart` (10 test),
  `test/app/bootstrap/startup_recovery_policy_test.dart` (8 test),
  `test/app/bootstrap/app_diagnostics_test.dart` (4 test).
  Focused run akhir: **21/21 passed** (`flutter test test/app/bootstrap/`).
- `flutter analyze`: **No issues found** (worktree sprint101).
- Produksi baru: `lib/app/bootstrap/crash_diagnostics.dart`,
  `lib/app/bootstrap/startup_recovery_policy.dart`,
  `lib/app/bootstrap/app_diagnostics.dart`; wiring produksi `lib/main.dart`.
- Privasi (101.17): `test/app/bootstrap/privacy_regression_test.dart`
  (5 test) — artefak crash/startup terkurung di direktori lokal,
  skema JSON terkunci tanpa field telemetri, konten bebas endpoint
  remote, permukaan dependensi bootstrap bebas paket jaringan.
- Proses baru: `docs/release/hotfix-runbook-v1.0.1.md`,
  `.github/ISSUE_TEMPLATE/{bug_report,crash_report}.yml`, `config.yml`.
- Refs lokal (101.1): `release/1.0`, `hotfix/1.0.1` @ `334022a`.

## Ledger 26 langkah

| # | Langkah | Status | Bukti / alasan |
|---|---|---|---|
| 101.1 | Maintenance Branch | VERIFIED* | `release/1.0` + `hotfix/1.0.1` dibuat lokal di SHA stabil `334022a`. *Push cabang ke origin = keputusan pemilik repo (menunggu Choirudin). |
| 101.2 | Version Development State | PARTIAL | Mekanisme satu-sumber teruji (`test/version_single_source_test.dart`). Nilai `1.0.1-dev` belum diterapkan: pubspec masih `0.1.0+1` dan bump versi adalah otoritas D6. |
| 101.3 | Post-Release Monitoring | PARTIAL | Lapisan tangkap crash + artefak keputusan startup TERBANGUN & TERUJI (bootstrap diagnostics, JSON per kejadian, signature). Monitor `installer_failure`/`update_failure` N/A — subsystem tsb eksplisit di luar v1. Tanpa telemetri eksternal (desain lokal-saja). |
| 101.4 | Issue Intake | VERIFIED | Template GitHub `bug_report.yml` + `crash_report.yml` melayani seluruh `accepted_inputs` lewat kategori tambahan. |
| 101.5 | Severity Classification | VERIFIED | Tabel P0–P3 di runbook; `classification_required` terpenuhi via field template; `allowed_priorities` P0–P3. |
| 101.6 | Reproduction Record | VERIFIED | Seluruh `required_fields` ada sebagai field template (issue_id otomatis dari nomor issue). |
| 101.7 | Data-Loss Gate | VERIFIED | Aturan tertulis: risiko data = default P0 = release blocker (runbook §Data-Loss Gate; konsisten DoD 101.26). |
| 101.8 | Crash Analysis | VERIFIED | `CrashSignature.of()` mengelompokkan per tipe+baris pertama pesan (3 test); prosedur triage 6 dimensi di runbook. |
| 101.9 | Startup Recovery | PARTIAL | Mesin keputusan normal→safe→recovery + counter persisten + reset TERUJI end-to-end (`prepareBootstrap` 2-fase). Mode UI eksplisit (layar safe/diagnostic/reset) BELUM dibangun — keputusan mode saat ini hanya terekam sebagai artefak. |
| 101.10 | Project Integrity | VERIFIED (evidence ada) | Cakupan test hidup: open/close & lifecycle `test/features/project_resilience/project_session_lifecycle_test.dart`, save/autosave `save_coordinator_test.dart`, recovery `project_recovery_services_test.dart`, backup `backup_retention_service_test.dart`, health `lib/core/persistence/project_health_service.dart` + `test/core/persistence/project_persistence_test.dart` (atomic replacement). |
| 101.11 | Migration Compatibility | PARTIAL | Kontrak live: format schema 16 (`VoidProjectFormat.currentSchema`), DB 53 (`ProjectDatabase.currentSchemaVersion`), plugin API semver berpasangan. Angka `=1` di spec dibaca sebagai kontrak kompatibilitas v1, bukan nilai literal live; tidak ada breaking change di slice ini. Rekonsiliasi angka menunggu putusan arsitek. |
| 101.12 | Installer Validation | BLOCKED | Installer tidak ada; eksplisit DI LUAR cakupan v1.0.0 (release-contract-v1.md). |
| 101.13 | Update Validation | BLOCKED | Update service tidak ada; eksplisit DI LUAR cakupan v1. |
| 101.14 | Rollback Validation | BLOCKED | Bergantung jalur update/installer yang tidak ada. |
| 101.15 | Performance Comparison | DEFERRED | Tidak ada artefak baseline v1.0.0 terukur; perbandingan tanpa baseline = karangan. Profil benchmark dev-only ada (Sprint 26) untuk dipakai nanti. |
| 101.16 | Security Review | PARTIAL | Checklist wajib per-hotfix ditetapkan (runbook §Review keamanan); penerapan pertama menyusul pada diff hotfix nyata. Disiplin secret sudah berjalan lintas sesi. |
| 101.17 | Privacy Regression | VERIFIED | Aplikasi lokal-saja kini dijaga test otomatis: 5 test membuktikan artefak hanya lahir di direktori diagnostics yang diinjeksikan, skema JSON tanpa field telemetri, tanpa marker endpoint/provider remote, dan layer bootstrap bebas dependensi jaringan (`privacy_regression_test.dart`). Tanpa transfer keluar by design. |
| 101.18 | Accessibility Regression | PENDING | Baseline a11y v1 belum pernah dibangun (tidak ada yang bisa diregresikan); dicatat sebagai utang, bukan klaim. |
| 101.19 | Localization Regression | PENDING | Infrastruktur l10n (ARB/AppLocalizations) tidak ada di repo — diverifikasi kosong. Locale en/id menjadi target infrastruktur mendatang. |
| 101.20 | Automated Regression Suite | VERIFIED | Aturan 1-fix-1-test ditegakkan runbook + CI hijau; fix pada slice ini sendiri lahir dari RED test (bukti proses). |
| 101.21 | Hotfix Scope Lock | VERIFIED | Daftar allowed/blocked di runbook; seluruh perubahan slice ini termasuk kategori allowed (bug/integrity fix + docs), aditif, tanpa redesign. |
| 101.22 | Release Candidate | BLOCKED (otoritas) | Promosi `1.0.1-dev`→`1.0.1-rc.1` = tag/bump = D6 milik Choirudin. Draft urutan siap di runbook. |
| 101.23 | Final Validation | BLOCKED | Menunggu RC. Gate yang bisa jalan tanpa RC (regression tests, security checks) sudah hijau pada level slice; install/upgrade/rollback BLOCKED oleh 101.12–101.14. |
| 101.24 | Artifact Lock | BLOCKED | Belum ada artefak rilis (checksum/signature/SBOM menyusul setelah RC). |
| 101.25 | Patch Release | BLOCKED (otoritas) | Tag `v1.0.1` + channel stable = D6. |
| 101.26 | Sprint Closure | PENDING | DoD belum terpenuhi (P0/P1: tidak ada isu aktif; upgrade/rollback/artefak: BLOCKED struktural). Ditutup hanya setelah blokade otoritas/struktural diselesaikan. |

## Rekap

VERIFIED: 101.1*, 101.4–101.8, 101.10, 101.17, 101.20, 101.21 (10)
PARTIAL: 101.2, 101.3, 101.9, 101.11, 101.16 (5)
BLOCKED: 101.12–101.14, 101.22–101.25 (8; 3 di antaranya otoritas D6)
DEFERRED: 101.15 (1)
PENDING: 101.18, 101.19, 101.26 (3)

Status sprint: **IN_PROGRESS** — fondasi stabilisasi terbangun dan teruji;
penutupan menunggu keputusan rilis (D6) dan subsistem installer/update yang
memang di luar kontrak v1.
