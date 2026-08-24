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
| 103.8 | Workflow Runner | PENDING | — |
| 103.9 | Command Binding | PENDING | — |
| 103.10 | Input Binding | PENDING | — |
| 103.11 | Output Binding | PENDING | — |
| 103.12 | Dependency Resolver | VERIFIED | Kahn + tie declaration-order, cycle detection (termasuk self-dep) dengan anggota siklus dilaporkan; `readyAt` deterministik; 5 test |
| 103.13 | Cancellation Propagation | PENDING | — |
| 103.14 | Pause & Resume | PENDING | — |
| 103.15 | Workflow Checkpoint | PENDING | — |
| 103.16 | Crash Recovery | PENDING | — |
| 103.17 | Retry Policy | VERIFIED | `workflow_policies.dart`: maxAttempts≤5, hanya error retryable, non-idempotent tidak pernah auto-retry; 3 test |
| 103.18 | Timeout Policy | VERIFIED | per-step wajib & positif, workflow-level opsional; audit timeout di runner (103.8) |
| 103.19 | Failure Policy | VERIFIED | 5 policy kanonik; default turun dari optional→skipIfOptional, mandatory→stop; 2 test |
| 103.20 | Permission Evaluation | PENDING | — |
| 103.21 | Privacy Evaluation | PENDING | — |
| 103.22 | Workflow Persistence | BLOCKED (koordinasi skema) | Menunggu kejelasan kepemilikan v54/v55 pada project_database.dart |
| 103.23 | Template Registry | PENDING | — |
| 103.24 | Workflow Library UI | PENDING | — |
| 103.25 | Workflow Editor UI | PENDING | — |
| 103.26 | Execution Monitor UI | PENDING | — |
| 103.27 | Workflow Audit Trail | PENDING | — |
| 103.28 | Performance & Resource Limits | PENDING | — |
| 103.29 | Automated Test Matrix | PENDING | — |
| 103.30 | Documentation & Examples | PENDING | — |
| 103.31 | Alpha Artifact | PENDING | — |
| 103.32 | Sprint Closure | PENDING | — |

Hosted CI: DEFERRED sesuai keputusan D6 2026-08-24; gerbang lokal wajib
per slice (focused tests + analyze + diff check).
