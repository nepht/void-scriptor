# Sprint 102 — VOID SCRIPTOR v1.1 Planning & Release Train Foundation

Sumber kanonik: `sprint_102.json` (arsip resmi 2026-08-22, direktori
`referenced-chatgpt-conversation-this-is-an-2/outputs`). Basis rilis:
`v1.0.1` stable (tag object `68fb79a`, commit `42b30c0`). Sprint 101
COMPLETE per `sprint-101-step-ledger.md` → start condition terpenuhi.

Status: **APPROVED** — Planning Approval Gate (102.29) disetujui Choirudin
pada 2026-08-24: "setuju semua kedepannya tanpa revisi, jalankan".
Scope lock final; izin bump `1.1.0-dev` diberikan. Freeze date kalender
tidak ditetapkan dalam approval ini dan tetap menunggu pernyataan
eksplisit D6. Pemilik keputusan rilis akhir: Choirudin (otoritas D6).

## Bukti intake (dasar seluruh scope)

| Sumber | Kondisi terverifikasi |
|---|---|
| GitHub issues | **0 issue** (`gh issue list --state all` kosong) |
| Telemetri/crash eksternal | Tidak ada — desain lokal-saja (privacy regression test) |
| Crash lokal | Artefak diagnostik tersedia di disk pengguna; belum ada kanal laporan masuk |
| Baseline performa v1.0.x | Tidak ada pengukuran baseline (utang 101.15) |
| Utang tercatat Sprint 101 | installer/update/rollback BLOCKED; a11y baseline nihil (101.18); l10n infrastruktur nihil (101.19); diagnostic browser UI belum ada; penyaringan konten cerita pada artefak diagnostik |
| Proposal historis | `docs/sprints/sprint-27..42-*.md` = kandidat visi jangka panjang, bukan permintaan terbukti |
| Kontrak live @v1.0.1 | project format schema **16** (`VoidProjectFormat.currentSchema`), database schema **53** (`ProjectDatabase.currentSchemaVersion`), plugin API semver berpasangan |

Prinsip yang mengikat paket ini: *evidence before scope*. Karena bukti
permintaan pengguna nyata belum ada, tema dan MUST dipilih dari utang
terstruktur + kontrak rilis, BUKAN dari fitur impian. Setiap klaim
"pengguna butuh X" dilarang tanpa sumber.

## 102.1 Release Objective

- **release_objective:** Menjadikan v1.1 sebagai *minor release konsolidasi*:
  menutup utang struktural v1.0.1 (diagnostik, a11y, l10n, performa) dan
  meletakkan fondasi release train (RC berkala + artifact lock otomatis)
  tanpa breaking change.
- **success_definition:**
  1. Seluruh utang Sprint 101 yang bisa ditangani minor release selesai dengan bukti.
  2. Baseline performa v1.0.1 TERUKUR dan v1.1.0 tidak meregresinya melebihi budget.
  3. Release train berjalan: setiap rilis punya RC + manifest checksum otomatis.
  4. 100% teks UI melewati l10n infrastruktur; a11y baseline pertama tercatat.
- **non_goals:** cloud sync, kolaborasi realtime, plugin marketplace,
  rendering 3D/XR, AI agent platform, auto-update service produksi,
  signing infrastruktur. (Semua tetap proposal sprint 27–42.)

## 102.2 Post-v1 Evidence Intake

- support_issues: 0 (repo bersih).
- crash_data: hanya artefak lokal; tidak ada agregat.
- performance_data: tidak ada baseline terukur.
- workflow_feedback: tidak ada kanal; tidak dikarangkan.
- known_issues: daftar resmi = Known Issues di
  `docs/release/v1.0.1-release-notes.md` (8 butir).

Implikasi jujur: evidence intake v1.1 bertumpu pada known issues internal +
utang terstruktur. Pengumpulan bukti pengguna menjadi DELIVERABLE v1.1
(issue template sudah ada; diisi saat pengguna nyata memakai aplikasi),
bukan input perencanaan.

## 102.3 User Feedback Classification

Taksonomi disiapkan (bug / friction / feature_request / documentation /
performance / compatibility) dan akan diterapkan pada issue GitHub yang
masuk. Saat ini jumlah item per kategori = 0/0/0/0/0/0 — dicatat apa adanya;
tidak ada kandidat fitur yang dibenarkan oleh "feedback".

## 102.4 Known-Issue Carryover

Dari `v1.0.1-release-notes.md` + ledger 101, kandidat carryover dengan
owner/prioritas awal:

| # | Masalah | Owner | Prioritas |
|---|---|---|---|
| K1 | Penyaringan konten cerita pada artefak diagnostik | nephthys | P2 |
| K2 | Diagnostic browser UI belum ada (petunjuk path saja) | nephthys | P2 |
| K3 | A11y baseline belum ada | Choirudin (arah) / nephthys (eksekusi) | P2 |
| K4 | l10n infrastruktur (ARB en/id) belum ada | idem | P2 |
| K5 | Performance baseline v1.0.1 belum diukur | nephthys | P1 (prasyarat budget) |
| K6 | WSLg presentation butuh restart session sesekali | Choirudin | P3 (environment, bukan produk) |

K6 tidak menjadi pekerjaan kode; didokumentasikan di troubleshooting.

## 102.5 Version Contract

- Versi target: **1.1.0** (development `1.1.0-dev`, build number lanjutan).
- backward_compatibility_expected: YA — project format v1 (schema 16),
  DB schema 53, plugin API v1 tetap terbuka & terbaca penuh oleh v1.1.0.
- breaking_changes_allowed: TIDAK.
- silent_contract_changes_allowed: TIDAK — setiap perubahan kontrak wajib
  lewat langkah data model (102.17–102.18) dengan migrasi eksplisit.
- Perubahan pubspec version ke `1.1.0-dev` = otoritas D6, dieksekusi setelah
  approval gate, bukan sebelumnya.

## 102.6 Compatibility Baseline

Beku pada nilai terverifikasi tag `v1.0.1`:

- `project_format_v1`: `VoidProjectFormat.currentSchema = 16`; nama paket
  `voidproject`; kompatibel maju-minor.
- `database_schema_v1`: `ProjectDatabase.currentSchemaVersion = 53`;
  migrasi Drift berurutan tanpa rewrite riwayat.
- `plugin_api_v1`: API semver berpasangan dengan host; deprecation butuh
  notice satu siklus minor.
- `installer_upgrade_path`: BELUM ADA (installer di luar v1). Baseline
  upgrade path = "proyek dibuka lintas versi minor via format v1"; jalur
  binary upgrade tetap non-goal sampai sprint installer.

Aturan regresi: test suite wajib membuka proyek fixture schema-16/DB-53
yang dibuat v1.0.1 pada setiap CI master.

## 102.7 Release Theme Selection

**Tema tunggal (theme_count=1): "Trustworthy Foundation".**

Evidence_required: tema ini satu-satunya yang sepenuhnya didukung bukti
yang ada — utang struktural tercatat resmi di ledger 101 dan known issues
rilis, sedangkan kandidat fitur lain tidak punya bukti permintaan. Tema
mengunci semua MUST pada kategori kualitas/diagnostik/i18n/perf, bukan fitur baru.

## 102.8 Feature Candidate Registry

Format wajib: candidate_id / problem / target_user / expected_value /
risk / dependencies / estimated_effort.

| ID | Problem | Target user | Expected value | Risk | Dependencies | Effort |
|---|---|---|---|---|---|---|
| C1 | Artefak diagnostik menyertakan konten cerita mentah | Penulis yang melapor crash | Laporan crash aman dibagikan | MEDIUM (redaksi selektif) | crash_diagnostics | M |
| C2 | Crash sulit dipahami pengguna awam | Semua pengguna lokal | Browser diagnostik in-app | LOW-MED | C1 | M |
| C3 | Tidak ada baseline performa | Maintainer | Keputusan regresi berbasis angka | LOW | benchmark dev-only (Sprint 26) | M |
| C4 | UI tak bisa diterjemahkan | Pengguna non-EN (id/en target) | ARB infra + ekstraksi key | MEDIUM (luas sentuh UI) | — | L |
| C5 | Keyboard/screen-reader tidak terukur | Pengguna a11y | Baseline a11y + fix prioritas | MEDIUM | audit manual | M-L |
| C6 | Rilis manual rawan lupa checksum | Maintainer | Workflow RC+manifest otomatis | LOW-MED | CI existing | M |

Registry ini LENGKAP untuk tema; tidak ada kandidat fitur konten baru
karena nol bukti permintaan (anti *fabricated user demand*).

## 102.9 Prioritization Model

Model weighted: user_value (0–5), strategic_value (0–5), confidence (0–1,
berbasis bukti), effort (S/M/L/XL), risk (L/M/H), maintenance_cost (L/M/H).
Urutan keputusan: confidence rendah → butuh bukti dulu (turun tier);
risk HIGH pada kontrak data → wajib 102.17/102.18 dulu.

Skor draft (confidence mencerminkan bukti intake):

- C3 perf-baseline: value 4, strategic 5, conf 0.9, effort M, risk L, maint L
- C1 redaksi diagnostik: 4 / 4 / 0.9 / M / M / L
- C6 release train: 3 / 5 / 0.9 / M / M / M
- C4 l10n infra: 4 / 4 / 0.7 / L / M / M
- C2 diag browser: 3 / 3 / 0.8 / M / L / M
- C5 a11y baseline: 4 / 4 / 0.6 / L-XL / M / M

## 102.10 User-Value Validation

problem_statement_required + target_workflow_required:

- C3: problem "tak bisa membuktikan tidak-ada-regresi"; workflow
  "maintainer menjalankan benchmark sebelum/sesudah perubahan".
- C1: problem "pengguna ragu membagikan artefak karena isi cerita ikut";
  workflow "generate diagnostics → review redaksi → attach ke issue".
- C6: problem "checksum/manifest manual"; workflow "tag RC → CI menghasilkan
  manifest → release page".
- C4/C5/C2 serupa (dirinci di dokumen implementasi wave). Kandidat tanpa
  kedua field otomatis gugur ke DEFERRED.

## 102.11 Technical Risk Assessment

| ID | Risiko | Level | Mitigasi |
|---|---|---|---|
| R1 | Redaksi C1 salah menyaring (data loss konteks crash atau bocor konten) | HIGH | Test matriks konten + golden file; default-deny untuk field naratif |
| R2 | l10n ekstraksi merusak layout (text expansion) | MEDIUM | Key-by-key adopsi + widget golden untuk layar inti |
| R3 | Benchmark flaky di shared runner | MEDIUM | Jalankan lokal-perangkat, simpan hasil sebagai artefak, toleransi eksplisit |
| R4 | Migrasi apapun ke DB >53 | CRITICAL bila dilakukan | v1.1 TIDAK menaikkan schema; inventory kosong dikunci |
| R5 | a11y fix menyentuh banyak file UI | MEDIUM | Wave terpisah, urut prioritas semantik (focus order dulu) |
| R6 | CI release workflow gagal saat tagging | LOW-MED | Dry-run workflow + retry policy |

## 102.12 Dependency Mapping

dependency_graph (draft):

```
C3(perf baseline) ──> budget enforcement (CI gate opsional)
C1(redaksi) ──> C2(browser diagnostik tampil hasil redaksi)
C4(l10n infra) ──> C5(a11y: label semantik berbagi key string)
C6(release train) ── independen ──> milestone rilis v1.1.0
```

critical_path: **C3 → (implementasi waves) → hardening → C6 → release**.
external_dependencies: tidak ada baru (tanpa layanan eksternal; konsisten
lokal-saja). Platform dependency: Linux build via WSLg untuk smoke test.

## 102.13 Scope Tiers

- CORE: C3, C1, C6, C4-infra (ARB skeleton + ekstraksi key layar utama).
- OPTIONAL: C2 (browser diagnostik), C4-lanjutan (semua layar).
- EXPERIMENTAL: C5-audit (hasil audit menentukan fix list v1.2).
- DEFERRED: semua kandidat sprint 27–42; auto-update service; installer.

## 102.14 MoSCoW Scope Lock

- MUST: C3 (baseline terukur + laporan), C1 (redaksi konten), C6 (workflow
  RC→manifest→release terotomasi), C4-infra (l10n skeleton en/id + ≥1 layar
  penuh ter-lokalize sebagai bukti pola), regression fixture schema-16/DB-53.
- SHOULD: C2 browser diagnostik; perluasan l10n layar sekunder; dokumentasi
  troubleshooting WSLg.
- COULD: C5 audit awal (tanpa janji fix); CI perf gate advisory.
- WONT (v1.1): installer/update/rollback, signing, cloud, kolaborasi,
  plugin marketplace, renderer 3D/XR, AI agent, schema migration.

Lock berarti: penambahan ke MUST setelah approval hanya via exception policy (102.15).

## 102.15 Feature Freeze Definition

- freeze_criteria: seluruh MUST merged + green CI; SHOULD yang belum selesai
  turun ke v1.1.1/v1.2 tanpa debat ulang.
- freeze_date: **disetujui Choirudin pada 102.29**, diekspresikan sebagai
  tanggal kalender + commit SHA di dokumen final (placeholder sengaja tidak
  diisi karena tanggal rilis adalah keputusan pemilik).
- exception_policy: hanya bug-P0/P1 atau risiko-regresi yang lolos review
  arsitek; fitur baru tidak pernah lolos exception pasca-freeze.

## 102.16 Architecture Impact Review

review_scope:

- modules: perubahan terpusat di `lib/app/bootstrap/*` (C1/C2),
  `tool/`+`benchmark` (C3), `lib/l10n/*` baru (C4), `.github/workflows`
  (C6). Tidak menyentuh boundary domain story/project.
- services: tidak ada servis baru; tidak ada servis yang hilang.
- runtime: benchmark dev-only tidak masuk bundle rilis; redaksi berjalan
  di path bootstrap yang sudah ada.
- event_contracts: tidak berubah.
- ownership: bootstrap = area sprint101 (sekarang bebas konflik di master);
  l10n = area baru; workflows = area CI.

Vonis arsitektur: scope tema tidak melintasi boundary modul besar; risiko
arsitektural terbesar adalah luas sentuhan l10n → dikendalikan via wave.

## 102.17 Data Model Impact

schema_change_inventory_required:

- Project format: **tidak berubah** (tetap 16).
- Database: **tidak berubah** (tetap 53). Inventory perubahan persisten: KOSONG.
- Artefak diagnostik: skema JSON dapat bertambah field redaksi-metadata —
  artefak bukan kontrak lintas-versi (lokal-saja, regenerable), perubahan
  diizinkan dengan test skema terkunci.

migration_required_for_persistent_change: tidak ada persistent change →
tidak ada migrasi. (Catatan konkuren: skema v54 creature / v55 novel links
milik worktree lain, di luar scope v1.1 dan tidak boleh terbangin sini.)

## 102.18 Migration Strategy

Karena inventory kosong: strategy = **no-migration guarantee** + guard:

1. upgrade: buka proyek v1.0.1 di v1.1.0 harus zero-write pada schema.
2. backup_before_migration: N/A (tidak ada migrasi), tetap dijaga oleh
   backup retention yang sudah ada.
3. failure_recovery: tidak berubah dari v1.0.1 (recovery startup + autosave).
4. rollback: proyek yang tersentuh v1.1.0 tetap terbaca v1.0.1 (uji
   bolak-balik dengan fixture).

Test penerimaan: open-save-close proyek fixture di v1.1.0 → byte-level
schema fields identik; dibuka lagi di v1.0.1 → sukses.

## 102.19 Security & Privacy Impact

Per kandidat:

- C1: security review wajib (checklist runbook) sebelum merge; privacy =
  perbaikan langsung (mengurangi konten sensitif di disk); external_transfer
  = tetap NOL.
- C2: browser diagnostik hanya-baca lokal; tanpa telemetry.
- C3: benchmark dev-only, tidak mengubah permission.
- C4/C5: tidak menambah permission/data flow.
- C6: workflow CI hanya push manifest teks ke release page; secret GH
  bawaan Actions, tanpa secret baru.

data_classification: semua data tetap kelas lokal-pribadi; tidak ada
kelas baru. required_reviews (security, privacy, data_classification,
external_transfer) direkam per-PR dengan template checklist runbook.

## 102.20 Accessibility & Localization Impact

required_reviews sejak desain:

- keyboard: C2 wajib navigasi keyboard penuh; C5 mengukur focus order.
- screen_reader: Semantics label wajib pada kontrol baru; baseline audit
  mencatat gap.
- scaling: text scale 1.0–2.0 masuk matrix uji visual minimal (layar utama).
- contrast: palet existing dicek terhadap WCAG AA pada warna teks utama
  (audit, bujan redesign).
- localization_keys: SEMUA string UI baru wajib lewat ARB sejak C4-infra
  merged (guard analyzer opsional).
- text_expansion: layout uji dengan locale en + id + pseudo-expansion pada
  layar pilot.

## 102.21 Performance Budget

Baseline v1.0.1 belum ada → langkah pertama MUST C3 adalah MENGUKUR
baseline di mesin referensi (WSL Ubuntu, build profile) sebelum budget
final. Budget relatif terhadap baseline terukur:

| Metrik | Regresi maksimum vs baseline v1.0.1 |
|---|---|
| startup (cold, first frame) | ≤ +10% |
| project_open | ≤ +10% |
| save | ≤ +10% |
| interaction_latency (p95 frame) | ≤ +8% |
| render (frame time p95) | ≤ +8% |
| memory peak | ≤ +15% |
| vram | ≤ +15% (bila metrik tersedia di platform) |

Angka absolut dicatat di `docs/benchmarks/baseline-v1.0.1.md` (dibuat C3).
Budget final dikunci saat C3 selesai; perubahan budget = keputusan arsitek.

## 102.22 Platform Support Matrix

| Platform | Status v1.1 |
|---|---|
| Linux (Ubuntu/WSLg dev) | SUPPORTED + TESTED (smoke hidup tiap rilis) |
| Windows desktop | SUPPORTED (build CI debug hijau; TESTED runtime menyusul toolchain Windows) |
| macOS | SUPPORTED (build CI simulator hijau) |
| iOS simulator | TESTED (CI simulator saja) |
| Android | EXPERIMENTAL (build CI hijau, tanpa device QA) |
| Web | EXPERIMENTAL (build CI hijau, tanpa QA browser matrix) |

DEFERRED: distribusi store apapun. Status naik-turun platform = keputusan
arsitek berbasis bukti QA, bukan asumsi CI-hijau.

## 102.23 Plugin API Evolution

plugin_api_major tetap **1**; breaking_changes_allowed=false;
deprecation_notice_required=true. v1.1 hanya boleh MENAMBAH API additive
dengan anotasi @experimental; setiap perubahan API wajib:
(1) test kompatibilitas plugin contoh lama, (2) changelog terpisah
`docs/plugin-api-changelog.md` (dibuat bila ada perubahan pertama).
Jika v1.1 tidak menyentuh plugin API sama sekali, deliverable-nya adalah
pernyataan "no-change" + test compat tetap hijau.

## 102.24 Observability Plan

Signals lokal-saja (tanpa telemetri eksternal):

- health: startup-decision.json distribution (mode normal/safe/recovery)
  dibaca manual via diagnostics.
- errors/crashes: crash JSON + signature (existing), plus hitung redaksi C1.
- performance: hasil benchmark C3 sebagai artefak repo `docs/benchmarks/`.
- jobs: job status existing (dev-only).
- migration: no-op guard log (102.18).
- update: N/A (tanpa update service).

Definisi keberhasilan v1.1 terukur via: baseline vs v1.1.0 benchmark diff,
jumlah layar ter-localize, a11y audit report, workflow RC otomatis sukses.

## 102.25 Test Strategy

test_layers dan penerimaan minimal:

- unit: redaksi C1 (matriks konten), l10n loader, budget parser.
- component: RecoveryShell dengan hasil redaksi; diagnostik browser.
- integration: open-save-roundtrip fixture schema16/DB53 lintas v1.0.1↔v1.1.0.
- migration: guard no-schema-change (test yang membuktikan currentSchemaVersion==53).
- end_to_end: smoke boot normal + recovery path di Linux (existing pattern).
- performance: benchmark script + laporan diff vs baseline.
- security: checklist runbook per-PR + privacy regression suite existing.
- release: dry-run workflow RC → manifest checksum cocok → release page.

Regression penuh (analyze + flutter test + linux build) tetap gerbang tiap wave.

## 102.26 Rollout Strategy

rollout_stages (channel Git/GitHub, tanpa update service):

1. `1.1.0-dev` di master (continuous).
2. `v1.1.0-rc.N` prerelease (≥1 RC wajib; RC terakhir = commit yang sama
   dengan stable kecuali bump versi).
3. `v1.1.0` stable GitHub Release.

stop_conditions: P0/P1 baru pada RC; regresi performa melewati budget
102.21; kegagalan roundtrip kompatibilitas.

rollback_plan: hapus/unlist release candidate; stable rollback = tag baru
patch (v1.1.1) — praktik yang sama seperti v1.0.1; tidak ada uninstaller
karena belum ada installer.

channel_policy: stable = tag non-prerelease di repo; prerelease = tag rc;
tidak ada kanal lain sampai sprint distribusi.

## 102.27 Documentation Plan

- user_guide: pembaruan bagian diagnostik (C1/C2) + troubleshooting WSLg.
- developer_guide: benchmark how-to, l10n how-to (ARB), release train SOP.
- migration_guide: "v1.0.x → v1.1.0: tidak ada aksi pengguna" + jaminan
  no-migration.
- release_notes: `docs/release/v1.1.0-release-notes.md` mengikuti pola v1.0.1.
- known_issues: dibawa + difilter dari v1.0.1 notes (K1..K5 diselesaikan/
  diperbarui per status wave).

Semua docs bahasa Indonesia (konsisten repo), istilah teknis English.

## 102.28 Milestone Decomposition

implementation_waves:

- W1 (fondasi): C3 baseline terukur + regression fixture schema16/DB53 + budget lock.
- W2 (privasi diagnostik): C1 redaksi (+security review) → C2 browser bila muat.
- W3 (i18n): C4-infra skeleton + layar pilot + text-expansion guard.
- W4 (release train): C6 workflow RC→manifest→release + dry-run.
- W5 (hardening): full regression + a11y audit awal (EXPERIMENTAL) + docs.

integration_milestones: akhir tiap wave = CI master hijau + demo bukti
(artefakt/log) di PR. hardening_milestone: freeze fitur → bugfix only.
release_milestone: RC → stable v1.1.0 oleh otoritas D6.

## 102.29 Planning Approval Gate

required_evidence status:

- scope_lock: §102.14 ✅ (draft)
- risk_register: §102.11 ✅ (draft)
- dependency_graph: §102.12 ✅ (draft)
- acceptance_criteria: per-kandidat dirinci per wave W1–W5 saat implementasi
  dimulai (pola acceptance = test eksplisit, konsisten sprint sebelumnya)
- owners: engineering=nephthys; approval/versi/tag=Choirudin (D6)
- test_strategy: §102.25 ✅ (draft)

**GERBANG INI MENUNGGU PERSETUJUAN CHOIRUDIN.** Persetujuan = scope lock
final + penetapan freeze date + izin bump `1.1.0-dev`.

## 102.30 Sprint Closure

DoD checklist (dinilai saat closure):

- [x] release_objective_approved (2026-08-24, Choirudin)
- [x] scope_locked (draft siap)
- [ ] compatibility_contract_recorded (§102.6)
- [ ] risk_register_complete (§102.11)
- [ ] architecture_and_data_reviews_complete (§102.16, §102.17)
- [ ] performance_budget_defined (relatif §102.21; absolut menunggu C3)
- [ ] test_and_rollout_strategies_defined (§102.25, §102.26)
- [ ] implementation_milestones_created (§102.28)

Closure hanya sah setelah persetujuan 102.29 tercatat di dokumen ini.

### Keputusan defer hosted CI master — 2026-08-24

Choirudin menetapkan bahwa hosted CI master **di-defer/waive sementara** sampai
aplikasi dianggap layak publish oleh Choirudin. Keputusan ini tidak mengubah,
menghapus, atau melemahkan workflow CI maupun acceptance criteria Sprint 102.

Batas keputusan:

- Run hosted CI pada SHA `8dad71d7ca258908251a01c5358eba8be10f1917` tercatat
  `completed/failure` karena seluruh job tidak dimulai akibat GitHub billing;
  ini bukan bukti kegagalan kode.
- Local gate tetap wajib: full `flutter test`, `flutter analyze`, target build
yang tersedia, focused regression, manifest/checksum, dan `git diff --check`.
- Status hosted CI tetap `DEFERRED/BLOCKED-EXTERNAL`, bukan `PASS` atau
  `VERIFIED-HOSTED`.
- RC/stable publish tetap memerlukan hosted CI green pada SHA kandidat yang
  sama, serta otorisasi D6 untuk tag, version bump, push, dan release page.
- Sprint berikutnya boleh dibuka setelah closeout lokal Sprint 102 dicatat;
  pembukaan Sprint berikutnya tidak mengubah status hosted CI menjadi green.
