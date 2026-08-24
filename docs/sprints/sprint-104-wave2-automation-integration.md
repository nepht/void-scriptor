# Sprint 104 — Wave 2 "Workflow Automation & Integration" Step Ledger

Sumber kanonik: `sprint_104.json` (35 langkah). Base: `1.1.0-alpha.1`,
dev: `1.1.0-dev`, target milestone: `1.1.0-beta.1`, target: `1.1.0`.
Start condition Sprint 103 COMPLETE + alpha lolos validasi internal → terpenuhi
2026-08-25 (lihat 104.1).

## Status langkah

| Langkah | Judul | Status | Bukti |
|---|---|---|---|
| 104.1 | Wave 2 Entry Gate | VERIFIED | `alpha_artifact_verified` (manifest v1.1.0-alpha.1 @69f5557, semua gate PASS); `no_open_p0` (analyze bersih, full suite +1619 hijau @d19b80c); `migration_pass` (skema v56, 2 test migrasi/roundtrip); `recovery_pass` (4 test e2e recovery); `security_review_complete` (deny-by-default + privacy, 7 test) |
| 104.2 | Alpha Findings Reconciliation | VERIFIED | **Resolved**: infinite-loop retry runner (fix kontrak `_handleFailure` bool), semantik skipped≠completed, race checkpoint terminal, tabrakan `.tmp` antar eksekusi, 27 asersi skema basi 55→56 — semua fix masuk master Sprint 103. **Accepted risks**: artefak = bundle debug Linux tanpa installer/signing/SBOM (risiko sama diterima sejak v1.0.1); hosted CI waived (billing) sehingga gerbang lokal otoritatif. **Deferred**: packaging produksi lintas platform; wiring perintah nyata step workflow ke fitur aplikasi; penyambungan layar workflow ke router/navigasi utama |
| 104.3 | Workflow Trigger Model | VERIFIED | `lib/automation/workflow_trigger.dart`: trigger typed + versioned (7 field kanonik), policy bawaan (maxTriggersPerHour/cooldown), copyWith immutable; 3 test |
| 104.4 | Trigger Registry | VERIFIED | `trigger_registry.dart`: registry canonical tunggal dengan tepat 6 tipe awal (MANUAL/SCHEDULE/PROJECT_EVENT/ASSET_EVENT/JOB_EVENT/PLUGIN_EVENT); fail-closed untuk tipe tak terdaftar; 3 test |
| 104.5 | Automation Rule Model | VERIFIED | `automation_rule.dart`: rule_id+trigger+conditions+workflow_id+approval_policy+failure_policy+enabled dalam satu model; 2 test |
| 104.6 | Condition Engine | VERIFIED | `automation_condition.dart`: evaluasi deterministik murni, operator typed enum tertutup (equals/notEquals/greaterThan/lessThan/contains/inSet), TANPA injeksi kode, missing fact gagal tertutup termasuk negasi; 4 test |
| 104.7 | Expression Validation | VERIFIED | `rule_validation.dart`: known-fields per tipe trigger, kompatibilitas tipe literal, cap kompleksitas (maxConditionsPerRule), larangan struktural field `secret.*` di rule; 5 test |
| 104.8 | Event Bus Integration | PENDING | — |
| 104.9 | Scheduler Integration | PENDING | — |
| 104.10 | Missed-Run Policy | PENDING | — |
| 104.11 | Project Lifecycle Triggers | PENDING | — |
| 104.12 | Asset Pipeline Triggers | PENDING | — |
| 104.13 | Job Runtime Triggers | PENDING | — |
| 104.14 | AI Provider Workflow Integration | PENDING | — |
| 104.15 | Render Pipeline Integration | PENDING | — |
| 104.16 | Publishing Integration | PENDING | — |
| 104.17 | Plugin Workflow Steps | PENDING | — |
| 104.18 | Capability Registry Integration | PENDING | — |
| 104.19 | Secret Reference Model | PENDING | — |
| 104.20 | Network Policy | PENDING | — |
| 104.21 | Approval Gate Model | PENDING | — |
| 104.22 | Human-in-the-Loop Runtime | PENDING | — |
| 104.23 | Rate Limiting | PENDING | — |
| 104.24 | Concurrency Control | PENDING | — |
| 104.25 | Idempotency Contract | PENDING | — |
| 104.26 | Duplicate Trigger Suppression | PENDING | — |
| 104.27 | Workflow Saga | PENDING | — |
| 104.28 | Compensation Actions | PENDING | — |
| 104.29 | Automation Observability | PENDING | — |
| 104.30 | Automation Center UI | PENDING | — |
| 104.31 | Rule Editor UI | PENDING | — |
| 104.32 | Automation Templates | PENDING | — |
| 104.33 | Import & Export | PENDING | — |
| 104.34 | Beta Validation & Artifact | PENDING | — |
| 104.35 | Sprint Closure | PENDING | — |

Hosted CI: tetap DEFERRED (keputusan D6); gerbang lokal wajib per slice.
