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
  (8 test) — artefak crash/startup terkurung di direktori lokal,
  skema JSON terkunci tanpa field telemetri, konten bebas endpoint
  remote, permukaan dependensi bootstrap bebas paket jaringan,
  secret di pesan/stack/signature teredaksi `[REDACTED]` sebelum
  menyentuh disk (diagnostic_redaction), dan `CrashDiagnostics.purge()`
  menghapus seluruh artefak diagnostik on demand (data_deletion).
- Proses baru: `docs/release/hotfix-runbook-v1.0.1.md`,
  `.github/ISSUE_TEMPLATE/{bug_report,crash_report}.yml`, `config.yml`.
- Refs lokal (101.1): `release/1.0`, `hotfix/1.0.1` @ `334022a`.
- Uji hidup Linux (WSLg): binary debug `build/linux/x64/debug/bundle/void_scriptor`
  diluncurkan langsung; proses stabil, log hanya warning rendering software
  WSLg (MESA/EGL/ZINK), tanpa exception. Artefak bootstrap produksi di disk:
  `~/.local/share/com.voidscriptor.void_scriptor/VoidScriptor/state/startup-decision.json`
  (`mode:normal`, `attempt:1`) dan `state/startup.json`
  (`consecutiveFailures:0` setelah frame pertama); `diagnostics/crash`
  tidak tercipta (nol artefak crash pada boot sehat).
- Recovery UI (101.9): `lib/app/bootstrap/bootstrap_gate.dart`
  (`RecoveryShell` + `BootstrapGate`, RED→GREEN, 10 test widget);
  `lib/main.dart` kini mematuhi `lastOutcome.mode` — boot ter-eskalasi
  menampilkan shell dependensi-nol dengan Try again / Reset configuration;
  reset = `StartupFailureStore.reset()` + exit bersih (configuration_reset).
  Focused bootstrap suite: **39/39 passed**; analyze bersih.
- Security review (101.16): penerapan pertama checklist runbook atas diff
  riil `origin/master...HEAD` (+1414/−1) — hasil per butir di
  `docs/release/sprint-101-security-review.md`; tanpa pelemahan keamanan,
  satu utang dicatat (penyaringan konten cerita dalam artefak diagnostik,
  aman oleh kontainmen lokal-saja).
- Uji hidup jalur pemulihan (101.9): binary rebuild dari `72bb941`
  diluncurkan dengan streak terinjeksi `consecutiveFailures:2` → artefak
  disk membuktikan eskalasi nyata: `startup-decision.json` =
  `{"mode":"recovery","attempt":3}`, lalu `startup.json` kembali ke 0 —
  artinya frame pertama RecoveryShell benar-benar ter-render; proses stabil,
  log tanpa exception. Tangkapan layar tidak memungkinkan (jendela WSLg tak
  terekspos ke enumerasi jendela Windows); bukti fungsional bersandar pada
  artefak disk yang sama dengan jalur boot normal.

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
| 101.9 | Startup Recovery | VERIFIED* | Mesin keputusan normal→safe→recovery TERUJI end-to-end dan kini DIWAJIBKAN saat boot: `BootstrapGate` men-swap aplikasi penuh dengan `RecoveryShell` dependensi-nol untuk mode safe/recovery; Try again tersedia; Reset configuration menjalankan configuration_reset nyata (`store.reset()` + exit bersih, wiring di `main.dart`). 10 test widget baru (total bootstrap 39/39). *Mode diagnostic hadir sebagai petunjuk lokasi artefak crash di layar (`suggestDiagnostics`) + artefak JSON siap dilampirkan ke laporan; layar penjelajah diagnostik khusus tidak dibangun (utang kecil yang eksplisit). |
| 101.10 | Project Integrity | VERIFIED (evidence ada) | Cakupan test hidup: open/close & lifecycle `test/features/project_resilience/project_session_lifecycle_test.dart`, save/autosave `save_coordinator_test.dart`, recovery `project_recovery_services_test.dart`, backup `backup_retention_service_test.dart`, health `lib/core/persistence/project_health_service.dart` + `test/core/persistence/project_persistence_test.dart` (atomic replacement). |
| 101.11 | Migration Compatibility | PARTIAL | Kontrak live: format schema 16 (`VoidProjectFormat.currentSchema`), DB 53 (`ProjectDatabase.currentSchemaVersion`), plugin API semver berpasangan. Angka `=1` di spec dibaca sebagai kontrak kompatibilitas v1, bukan nilai literal live; tidak ada breaking change di slice ini. Rekonsiliasi angka menunggu putusan arsitek. |
| 101.12 | Installer Validation | BLOCKED | Installer tidak ada; eksplisit DI LUAR cakupan v1.0.0 (release-contract-v1.md). |
| 101.13 | Update Validation | BLOCKED | Update service tidak ada; eksplisit DI LUAR cakupan v1. |
| 101.14 | Rollback Validation | BLOCKED | Bergantung jalur update/installer yang tidak ada. |
| 101.15 | Performance Comparison | DEFERRED | Tidak ada artefak baseline v1.0.0 terukur; perbandingan tanpa baseline = karangan. Profil benchmark dev-only ada (Sprint 26) untuk dipakai nanti. |
| 101.16 | Security Review | VERIFIED | Checklist runbook diterapkan pertama kali pada diff riil sprint (`origin/master...HEAD`, +1414/−1): tanpa pelemahan path/input, tanpa secret baru (satu-satunya hit regex = fixture uji), izin platform & jalur update N/A struktural, perilaku lokal-saja terjaga oleh guard otomatis. Bukti per butir: `docs/release/sprint-101-security-review.md`; satu utang eksplisit (penyaringan konten cerita dalam artefak diagnostik). |
| 101.17 | Privacy Regression | VERIFIED | Aplikasi lokal-saja kini dijaga test otomatis: 8 test membuktikan artefak hanya lahir di direktori diagnostics yang diinjeksikan, skema JSON tanpa field telemetri, tanpa marker endpoint/provider remote, layer bootstrap bebas dependensi jaringan, secret teredaksi `[REDACTED]` sebelum ke disk, dan `purge()` tersedia untuk penghapusan data (`privacy_regression_test.dart`). Tanpa transfer keluar by design. |
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

VERIFIED: 101.1*, 101.4–101.10, 101.16, 101.17, 101.20, 101.21 (12)
PARTIAL: 101.2, 101.3, 101.11 (3)
BLOCKED: 101.12–101.14, 101.22–101.25 (7; 3 otoritas D6)
DEFERRED: 101.15 (1)
PENDING: 101.18, 101.19, 101.26 (3)

Status sprint: **IN_PROGRESS** — fondasi stabilisasi terbangun dan teruji;
penutupan menunggu keputusan rilis (D6) dan subsistem installer/update yang
memang di luar kontrak v1.
