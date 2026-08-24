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
| 104.8 | Event Bus Integration | VERIFIED | `lib/automation/trigger_event_bridge.dart`: bridge SATU-satunya subscription ke `CommandEventBus` existing (tanpa bus kedua), validasi skema event sebelum firing, fail-closed untuk trigger disabled/unregistered/tanpa eventName (`attachIssues`), dispose idempotent dengan cleanup subscription; hanya menjawab tipe projectEvent (schedule/asset/job/plugin milik 104.9/104.12/104.13/104.17); 7 test baru di `test/automation/trigger_event_bridge_test.dart`; suite automation penuh 24/24 PASS; analyzer scoped bersih; format+diff-check PASS |
| 104.9 | Scheduler Integration | VERIFIED | `schedule_spec.dart`: spec kanonik dailyAt/every dengan offset timezone eksplisit (menit), next_run terhitung di dinding lokal, enabled flag; factory fail-closed (ArgumentError); catatan jujur: zona IANA/DST di luar cakupan inti — pemanggil resolve offset saat konfigurasi; 6 test |
| 104.10 | Missed-Run Policy | VERIFIED | `missed_run_policy.dart`: 4 kebijakan kanonik SKIP/RUN_ONCE_AT_STARTUP/REQUIRE_CONFIRMATION/DISABLE_AND_WARN sebagai fungsi murni deterministik; tepat waktu tak pernah dihitung miss untuk semua kebijakan; 5 test |
| 104.11 | Project Lifecycle Triggers | VERIFIED | `lifecycle_triggers.dart`: 5 event kanonik (PROJECT_OPENED/SAVED/CLOSED/RECOVERY_COMPLETED/HEALTH_ISSUE_DETECTED), facts identifier-only tanpa payload diagnostik; 3 test |
| 104.12 | Asset Pipeline Triggers | VERIFIED | `asset_triggers.dart`: 5 event kanonik (ASSET_IMPORTED/UPDATED/THUMBNAIL_READY/ASSET_MISSING/ASSET_RELINKED), path thumbnail relatif opsional; 3 test |
| 104.13 | Job Runtime Triggers | VERIFIED | `job_triggers.dart` (kosakata 4 event) + `job_event_bridge.dart`: terminal status stream `BackgroundJobQueue.updates` kanonik → jobSucceeded/jobFailed/jobCancelled (tanpa bus kedua); queued/running tak pernah menembak; rule disabled diam; dispose idempoten; 4 test (`job_event_bridge_test.dart`); suite automation +47 hijau, analyze bersih |
| 104.14 | AI Provider Workflow Integration | VERIFIED | `external_integrations.dart` `AiWorkflowIntegration`: generate WAJIB lewat `ProviderRouter.generateWithFallback` (tanpa bypass provider langsung), cek `external_transfer_check` SEBELUM panggilan (dibuktikan probe tak tersentuh saat ditolak), cost visibility via callback, cancel mendelegasikan ke `AiProvider.cancel`; 3 test |
| 104.15 | Render Pipeline Integration | VERIFIED | `WorkflowRenderRequest` + `describeRenderJob`: kosakata render canonical, resource budget WAJIB (kosong → RenderBudgetException), output provenance rule+trigger terbawa; 2 test |
| 104.16 | Publishing Integration | VERIFIED | `PublishingWorkflowAdapter`: destination allowlist eksplisit, human confirmation DEFAULT required, audit record identifier-only per keputusan; 2 test |
| 104.17 | Plugin Workflow Steps | VERIFIED | `evaluatePluginStep`: apiVersion major wajib ==1 (selain itu rejectedApiVersion), declared capabilities dicek terhadap host grants (permission_check), uninstall terdefinisi via namespacing `plugin.<id>.<step>`; 4 test |
| 104.18 | Capability Registry Integration | VERIFIED | `preflightCapabilities`: preflight sebelum aktivasi, capability hilang = hasil TERLIHAT (`report()`), tanpa silent fallback; 2 test |
| 104.19 | Secret Reference Model | VERIFIED | `SecretReference.fromStore`: hanya kunci store yang berpindah (plaintext structurally impossible), toString selalu `[REDACTED]`, kunci kosong/multiline ditolak; 2 test |
| 104.20 | Network Policy | VERIFIED | `AutomationNetworkPolicy.checkRequest`: deny-by-default di luar allowlist, entri audit per keputusan (destination+capability); 1 test |
| 104.21 | Approval Gate Model | VERIFIED | `safety_runtime.dart`: 5 tipe gate kanonik (INFORMATIONAL/CONFIRMATION/REAUTHENTICATION/REVIEW_OUTPUT/APPROVE_EXTERNAL_TRANSFER); 1 test |
| 104.22 | Human-in-the-Loop Runtime | VERIFIED | `HumanDecisionRuntime`: jeda TANPA checkpoint ditolak (checkpoint_before_wait), keputusan ter-audit, request kadaluarsa DENY by default (fail-safe); 2 test |
| 104.23 | Rate Limiting | VERIFIED | `RateLimiter`: fixed-window per scope kanonik rule/workflow/provider/project/user; lewat budget → RateLimitExceeded, window baru mengizinkan lagi; 1 test |
| 104.24 | Concurrency Control | VERIFIED | `ConcurrencyController`: project_lock tanpa syarat (1 run aktif per project), budget global max_concurrent_runs, conflict policy eksplisit; 2 test |
| 104.25 | Idempotency Contract | VERIFIED | `IdempotencyStore.execute`: efek tercatat per idempotency_key, retry dengan kunci sama = StateError terlihat (bukan re-run senyap), effect record ber-timestamp; 1 test |
| 104.26 | Duplicate Trigger Suppression | VERIFIED | `DuplicateTriggerSuppressor`: deduplication_key + window + source_event_id + decision; dalam window ditekan, lewat window diizinkan; 1 test |
| 104.27 | Workflow Saga | VERIFIED | `WorkflowSaga`: commit record per langkah, kompensasi reverse-order, TANPA klaim transaksi global (eksplisit di kontrak); 3 test |
| 104.28 | Compensation Actions | VERIFIED | kompensasi eksplisit per registrasi; langkah tanpa compensator → CompensationUnsupported TERLIHAT (bukan skip senyap); kegagalan kompensasi ter-audit; (tercakup test saga) |
| 104.29 | Automation Observability | VERIFIED | `AutomationMetrics`: 8 sinyal kanonik (trigger/run/success_rate/failure_rate/duration/approval_wait/retry/resource_usage) identifier-only, snapshot aman log; 1 test |
| 104.30 | Automation Center UI | PENDING | — |
| 104.31 | Rule Editor UI | PENDING | — |
| 104.32 | Automation Templates | PENDING | — |
| 104.33 | Import & Export | PENDING | — |
| 104.34 | Beta Validation & Artifact | PENDING | — |
| 104.35 | Sprint Closure | PENDING | — |

Hosted CI: tetap DEFERRED (keputusan D6); gerbang lokal wajib per slice.
