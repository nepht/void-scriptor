# Sprint 103 — v1.1 Implementation Wave 1: Workflow Intelligence

Sumber kanonik: `sprint_103.json` (arsip resmi 2026-08-22). 32 langkah,
target milestone `1.1.0-alpha.1`. Start condition TERPENUHI: Sprint 101
COMPLETE + Sprint 102 planning approval (2026-08-24).

Kontrak kompatibilitas: format major 1, plugin API major 1, NO breaking
change, proyek lama wajib tetap terbuka.

## Titik koordinasi (dicatat sejak hari pertama)

- **103.22 Workflow Persistence** mensyaratkan migrasi skema project
  database. File `lib/database/project/project_database.dart` SAAT INI
  membawa modifikasi konkuren milik Choirudin (skema v54/v55, belum
  di-commit). nephthys TIDAK menyentuh file itu; langkah persistensi
  dieksekusi setelah koordinasi kepemilikan skema jelas.
- Urutan aman yang diambil: domain murni (103.2–103.7, 103.12, 103.17–103.19)
  → binding & resolver → policies → [koordinasi] persistensi → UI →
  test matrix → alpha.

## Ledger

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 103.1 | Wave Scope Confirmation | VERIFIED | Scope MUST = paket 102 APPROVED (`docs/sprints/sprint-102-v1.1-planning.md`, §102.14); owner engineering=nephthys, rilis=Choirudin; acceptance per langkah = test eksplisit |
| 103.2 | Workflow Feature Flag | VERIFIED | TDD RED→GREEN `test/workflow/workflow_feature_flag_test.dart`; default OFF, override ter-audit via `WorkflowAuditSink`; 4 test hijau |
| 103.3 | Workflow Domain Boundary | VERIFIED | Modul baru `lib/workflow/`; aturan dependensi tertulis di doc header `workflow_feature_flag.dart`: hanya boleh bergantung ke `core/`, konsumsi fitur lain lewat interface modul |
| 103.4 | Workflow Definition Model | VERIFIED | `lib/workflow/workflow_definition.dart`: field kanonik lengkap (workflowId/name/version/steps/inputs/outputs/policy/createdAt/updatedAt) |
| 103.5 | Workflow Step Model | VERIFIED | `WorkflowStep`: commandType, bindings typed (`WorkflowBinding` grammar in./step./out.), retryPolicy+timeout+failurePolicy, optional semantics |
| 103.6 | Workflow Validation Service | VERIFIED | TDD 8 test hijau; kelima rule kanonik + unknown_dependency delegasi ke resolver |
| 103.7 | Workflow Execution State | VERIFIED | State machine 9 status, transisi eksplisit (queued→cancelled instan mengikuti preseden Sprint 26), terminal tertutup; 6 test |
| 103.8 | Workflow Runner | VERIFIED | `workflow_runner.dart` di ATAS `BackgroundJobQueue` existing (reuse wajib 103.8; tanpa engine kedua): retry/timeout/skip/fail per policy, drain pump, event stream; 9 test |
| 103.9 | Command Binding | VERIFIED | `CommandBindingValidator`: command harus terdaftar & capability-nya muat policy; 2 test |
| 103.10 | Input Binding | VERIFIED | `InputBindingResolver`: hanya sumber deklaratif (`in.*`, `step.*`); implicit global ditolak; 3 test |
| 103.11 | Output Binding | VERIFIED | `OutputCapture` typed + provenance; output tak dideklarasikan ditolak; 2 test |
| 103.13 | Cancellation Propagation | VERIFIED | Kooperatif via `JobContext.isCancelled`; antrean mati instan lewat `queue.cancel`; cancel-before-start menang balapan (deferred launch); limitasi boundary didokumentasikan |
| 103.14 | Pause & Resume | VERIFIED | Pause hanya pada boundary step (tanpa freeze proses); resume meluncurkan ulang step siap; 1 test |
| 103.15 | Workflow Checkpoint | VERIFIED | Tulis atomik (tmp unik + rename) tiap step selesai DAN saat terminal state; field kanonik lengkap; roundtrip JSON; 1 test |
| 103.16 | Crash Recovery | VERIFIED | `workflow_recovery.dart`: detect interrupted (non-terminal), resume-from-checkpoint e2e (completed steps TIDAK dieksekusi ulang), cancel-and-cleanup, inspect-only; 4 test |
| 103.12 | Dependency Resolver | VERIFIED | Kahn + tie declaration-order, cycle detection (termasuk self-dep) dengan anggota siklus dilaporkan; `readyAt` deterministik; 5 test |
| 103.17 | Retry Policy | VERIFIED | `workflow_policies.dart`: maxAttempts≤5, hanya error retryable, non-idempotent tidak pernah auto-retry; 3 test |
| 103.18 | Timeout Policy | VERIFIED | per-step wajib & positif, workflow-level opsional; audit timeout di runner (103.8) |
| 103.19 | Failure Policy | VERIFIED | 5 policy kanonik; default turun dari optional→skipIfOptional, mandatory→stop; 2 test |
| 103.20 | Permission Evaluation | VERIFIED | `workflow_security.dart`: deny-by-default (irisan requested∩granted), eskalasi struktural mustahil; 3 test |
| 103.21 | Privacy Evaluation | VERIFIED | local_only enforced, transfer eksternal wajib audit, data minimization via declared kinds; 4 test |
| 103.22 | Workflow Persistence | BLOCKED (koordinasi skema) | Menunggu kejelasan kepemilikan v54/v55 pada project_database.dart |
| 103.23 | Template Registry | VERIFIED | `workflow_templates.dart`: validasi saat register, re-register versi sama ditolak, instantiate identitas baru, konten tak tepercaya tidak pernah auto-exec; 4 test |
| 103.24 | Workflow Library UI | VERIFIED | `lib/features/workflow/presentation/workflow_library_screen.dart`: daftar template registry, instantiate identitas baru via callback; widget test list+instantiate+empty; 2 test |
| 103.25 | Workflow Editor UI | VERIFIED | `workflow_editor_screen.dart`: edit field kanonik sebagai teks, validasi live via service ter-inject, Save hanya saat draft lengkap & bersih; widget test happy-path+duplicate-id; 2 test |
| 103.26 | Execution Monitor UI | VERIFIED | `execution_monitor_screen.dart`: proyeksi snapshot murni (tanpa timer/polling), progress bar per eksekusi, ikon per state; widget test render+empty; 2 test |
| 103.27 | Workflow Audit Trail | VERIFIED | `workflow_audit.dart`: 9 kind kanonik, entri identifier-only (detail dibuang — konten cerita/secrets tak bisa bocor), mapper event runner; 3 test |
| 103.28 | Performance & Resource Limits | VERIFIED | `workflow_limits.dart`: batas concurrent executions (default 4, ≤8), max steps/workflow 64, cap checkpoint; slot tracker acquire/release; 3 test |
| 103.29 | Automated Test Matrix | PENDING | — |
| 103.30 | Documentation & Examples | PENDING | — |
| 103.31 | Alpha Artifact | PENDING | — |
| 103.32 | Sprint Closure | PENDING | — |

Hosted CI: DEFERRED sesuai keputusan D6 2026-08-24; gerbang lokal wajib
per slice (focused tests + analyze + diff check).
