# Workflow — Panduan Singkat (Sprint 103)

Semua modul workflow hidup di `lib/workflow/` sebagai **Dart murni** (tanpa
dependensi Flutter), kecuali layar UI di `lib/features/workflow/presentation/`.
Tidak ada engine kedua: eksekusi berjalan DI ATAS `BackgroundJobQueue` Sprint 26.

## Peta modul

| Modul | Isi | Langkah |
|---|---|---|
| `workflow_feature_flag.dart` | flag default-OFF + audited override | 103.1–103.3 |
| `workflow_definition.dart` | definisi versioned + step typed + grammar binding (`in.*`, `step.*`) | 103.4–103.5 |
| `workflow_validation.dart` | 5 rule kanonik + unknown dependency/command | 103.6, 103.9 |
| `workflow_execution.dart` | state machine 9 status + resolver Kahn deterministik | 103.7, 103.12 |
| `workflow_policies.dart` | retry ≤5, timeout wajib, failure policy | 103.17–103.19 |
| `workflow_bindings.dart` | command/input/output binding + capability check | 103.8–103.11 |
| `workflow_runner.dart` | runner di atas job queue: retry, timeout, skip/fail, cancel/pause/resume, checkpoint atomik, resume-from-checkpoint | 103.8, 103.13–103.16 |
| `workflow_security.dart` | permission deny-by-default + privacy local-only | 103.20–103.21 |
| `workflow_recovery.dart` | deteksi interrupted, resume-from-checkpoint, cleanup; accessor sinkron untuk boot awal | 103.16 |
| `workflow_templates.dart` | registry template tervalidasi; instantiate = identitas baru | 103.23 |
| `workflow_audit.dart` | audit trail identifier-only (detail dibuang) | 103.27 |
| `workflow_limits.dart` | batas concurrency/steps/checkpoint | 103.28 |

## Alur minimal

```dart
final queue = BackgroundJobQueue(maxConcurrentJobs: 2);
final runner = WorkflowRunner(queue: queue, checkpointDirectory: dir);
final plan = WorkflowDependencyResolver().plan(workflow);
final handle = runner.start(workflow: workflow, plan: plan, work: (step, ctx, attempt) async {
  return 'hasil-langkah';
});
final result = await handle.result;
```

Crash recovery: baca checkpoint non-terminal via `WorkflowRecoveryService`,
tawarkan opsi ke pengguna, lalu `resumeFromCheckpoint` — langkah yang sudah
selesai TIDAK dijalankan ulang.

## Batasan desain (disengaja)

- Cancel bekerja instan pada antrean dan kooperatif di dalam step
  (`JobContext.isCancelled`); step yang sedang memblokir IO tanpa cek
  context selesai dulu di boundary.
- Pause hanya pada boundary langkah — tidak ada freeze proses.
- Audit trail tidak pernah menyimpan konten cerita atau detail bebas.
- Konten workflow tak tepercaya tidak pernah dieksekusi otomatis.

## Contoh end-to-end

Lihat test sebagai spesifikasi hidup:
`test/workflow/` (unit) dan `test/features/workflow/` (widget).
