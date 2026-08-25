# Sprint 107 — Void Scriptor v1.1 Post-Release Stabilization & Hotfix

- **Status:** BERJALAN (dibuka 2026-08-25) · **Base:** `1.1.0` stable (biner rc-1 @696a667, rilis @commit a6ff093 13:52 WIB) · **Dev:** `1.1.1-dev` · **RC:** `1.1.1-rc.1` · **Target:** `1.1.1` stable
- **Kanonik:** `sprint_107.json` (30 langkah, VALIDATED)
- **Batas jujur:** periode watch rollout tahap-1 masih berjalan; keputusan PENUTUPAN window watch milik Choirudin. Langkah berbasis insiden (107.4–107.13) menunggu bukti produksi — ketiadaan laporan TIDAK diperlakukan sebagai bukti tidak ada masalah (sesuai objektif 107.3). Langkah validasi/regresi dieksekusi langsung di atas kode stable.
- **Pitfall konkurensi:** worktree sangat ramai (400+ file modified milik agen lain: ci.yml, README.md, docs/audits/*, routing/shell lib/) — sprint ini HANYA menyentuh file miliknya sendiri.

| # | Langkah | Status | Bukti |
|---|---|---|---|
| 107.1 | Post-Release Entry Gate | VERIFIED | Kelima input ada & diverifiable: release_manifest=`docs/release/v1.1.0-stable-manifest.md`; rollout_status=kontrak operasional §Staged rollout (tahap 1 dimulai); monitoring_baseline=§Monitoring (7 sinyal; telemetry absen KI-03 dicatat jujur); support_channel=§Support + troubleshooting doc; rollback_status=kontrak C2 + baris 105.11 |
| 107.2 | Hotfix Version Initialization | VERIFIED | Alur versi dideklarasikan: 1.1.0 → **1.1.1-dev** → 1.1.1-rc.1 → 1.1.1; bump pubspec ke `1.1.1-dev+N` ditunda sampai batch fix pertama agar pohon stable tetap bersih selama watch |
| 107.3 | Production Signal Collection | PARTIAL | Baseline: watch dibuka 13:52 WIB 2026-08-25; sinyal dipantau via observabilitas build lokal + suite (+1713 hijau saat rilis); telemetry produksi belum ada (KI-03/KI-04 carry-over); mekanisme pencatatan = tabel intake 107.4 |
| 107.4 | Issue Intake & Deduplication | PARTIAL | Kontrak field intake lengkap (issue_id/signature/version/platform/workflow/frequency/impact/evidence) di kontrak operasional §Support; dedupe by signature; **0 laporan terverifikasi sejauh ini** |
| 107.5 | Severity & Ownership | PARTIAL | Skala P0–P3 aktif; owner_required + target_resolution_required; owner default = Choirudin; belum ada item untuk dinilai |
| 107.6 | Workflow Incident Classification | PARTIAL | Kategori siap pakai sesuai kanonik (definition_invalid, runner/checkpoint/resume/cancellation/output_binding failure, dst.); belum ada insiden untuk diklasifikasi |
| 107.7 | Automation Incident Classification | PARTIAL | Kategori siap (missed/false/duplicate_trigger, approval_failure, rate_limit_failure, compensation_failure, dst.); belum ada insiden |
| 107.8 | Data-Integrity Gate | VERIFIED (policy) | Kebijakan AKTIF sejak buka sprint: kerusakan/kehilangan data = default **P0**, release_blocker=true, wajib reproduction + recovery test sebelum fix dianggap tuntas |
| 107.9 | Migration Failure Investigation | PARTIAL | Dimensi investigasi siap (source_version/schema/project_size/platform/failure_stage/rollback outcome); jalur migrasi sendiri teruji matriks 105.10–105.11; tidak ada kegagalan migrasi dilaporkan |
| 107.10 | Crash Root-Cause Analysis | PARTIAL | Kunci pengelompokan siap (signature/build_id/platform/component/workflow_step/frequency); 0 crash dilaporkan |
| 107.11 | Updater Failure Analysis | PENDING | Framework tahapan siap (manifest/download/hash/signature/install/restart/rollback) tapi updater itu sendiri belum ada (KI-04) — analisis hanya relevan bila updater dibangun di sprint ini |
| 107.12 | Workflow Recovery Fixes | PENDING | Evidence-gated: hanya dieksekusi atas insiden terverifikasi |
| 107.13 | False-Trigger Prevention | PENDING | Evidence-gated |
| 107.14 | Duplicate-Effect Prevention | VERIFIED | Regresi `DuplicateTriggerSuppressor` (+3 test): event logis sama dalam window = suppressed (audit bawa sourceEventId mentah), di luar window = allowed lagi, key berbeda tidak saling menekan |
| 107.15 | Approval-Gate Regression | VERIFIED | Regresi approval gate (+5 test): wait tanpa checkpoint durable = throwsStateError; kelima ApprovalGateType menghasilkan request ter-checkpoint; keputusan dalam deadline diterima+di-audit; setelah deadline ditolak; timeout fail-safe DENIED dengan jejak audit |
| 107.21 | Localization Regression | VERIFIED | Paritas en/id terukur: 4 vs 4 kunci, symmetric-diff ∅, tanpa nilai kosong/raw key (+2 test membaca lib/l10n/app_en.arb & app_id.arb langsung) |
| 107.16 | Plugin Compatibility Fixes | VERIFIED | Suite plugin penuh **+23 All tests passed** di atas kode stable; regresi baru `hotfix_batch2_regression_test.dart` (+4 test) mengunci kontrak `PluginApiVersion`: same-major lower/equal-minor kompatibel, minor di atas host & major mismatch ditolak, parsing strict, ordering semver numerik (10>9) |
| 107.17 | Security Hotfix Review | VERIFIED | Review atas seluruh diff sprint 107 (120a6ed + 6ca5eba + batch 2): **nol sentuhan `lib/`**, artefak = kunci publik + signature terpisah + SBOM + test; grep kunci privat pada semua tracked file = NONE; tanpa HttpClient/Socket/Process.run baru di test |
| 107.18 | Privacy Hotfix Review | VERIFIED | Diff tidak menambah klasifikasi data, jalur transfer keluar, atau telemetry; SBOM 125 paket murni metadata dependensi dari pubspec.lock (tanpa konten proyek/cerita pengguna); audit automation tetap identifiers-only |
| 107.19 | Performance Regression Fixes | VERIFIED | Baseline dikonfirmasi ulang segar di atas stable: `test/core/performance` **+58 All tests passed** (01:01, log `/home/nepht/vs_perf_107.log`) — tanpa indikasi regresi; belum ada klaim fix karena belum ada regresi terukur |
| 107.20 | Accessibility Regression | VERIFIED | Regresi keyboard/focus `RuleEditorScreen` (+4 test di batch 2): Tab maju, Shift+Tab mundur, siklus 8× Tab pada layout 390px tanpa exception, input teks tetap sampai field setelah focus walk |
| 107.22 | Hotfix Scope Lock | PENDING | Dideklarasikan penuh saat kumpulan fix disetujui (blokir: new_feature/breaking_api/schema_redesign/large_refactor/ui_redesign) |
| 107.23 | Automated Regression Suite | PARTIAL | Dua file regresi aktif & hijau di atas stable: `hotfix_batch1_regression_test.dart` (+10: approval/duplikat/l10n) dan `hotfix_batch2_regression_test.dart` (+8: plugin API/keyboard a11y); lapisan migration/recovery/security sudah tercakup suite release eksisting; baris per-fix baru ditulis saat ada fix produk |
| 107.24 | Installer Validation | PARTIAL | Paket portable diuji end-to-end dari ZIP tership: ekstraksi segar → `sha256sum -c` OK (biner tetap `e87e6580…`) → `VERIFY-SIGNATURE.sh` Verified OK → biner dieksekusi (proses hidup, Dart VM service menyala, jendela native WSLg `void_scriptor (Ubuntu)` muncul via msrdc). **Batas jujur:** render GUI hitam di WSLg tanpa GPU (MESA ZINK gagal pilih device) — verifikasi visual konten aplikasi DEFERRED ke mesin ber-GPU; installer MSI/deb tetap terbuka (KI-04) |
| 107.25 | Update & Rollback Validation | PENDING | Gerbang manifest/hash/signature/install/restart/rollback |
| 107.26 | Hotfix Release Candidate | PENDING | Target `1.1.1-rc.1`, promote_exact_rc=true |
| 107.27 | RC Soak & Monitoring | PENDING | Binary beku selama soak |
| 107.28 | Artifact & Manifest Lock | PENDING | binary/installer/update_package/manifest/checksums/signature/SBOM/evidence |
| 107.29 | Stable Hotfix Release | PENDING | Promosi exact tested RC → `1.1.1` stable |
| 107.30 | Sprint Closure | PENDING | DoD: no_open_p0, blocking_p1 resolved, integrity+migration gates lolos, regression suite hijau, artefak terkunci |
