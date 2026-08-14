# Sprint 26 — Performance, Background Jobs, and Large Project Optimization

**Status:** Development-only, vertical slice 26.2–26.13 implemented. Release readiness remains blocked by external macOS/iOS and hosted-CI evidence.

## Scope contract

Sprint 26 improves runtime scalability without changing the core project architecture. Heavy work must be represented as a background task so UI code can observe lifecycle state instead of performing hashing, thumbnail generation, scanning, export, or parsing inline.

## Verified vertical slice 1: job foundation

Implemented:

- `BackgroundJob` immutable state model;
- `BackgroundJobStatus`: queued, running, completed, failed, cancelled;
- `BackgroundJobPriority`: low, normal, high, critical;
- `BackgroundJobType` for thumbnail, waveform, indexing, hashing, integrity, cache, import/export, backup, AI download, and custom work;
- `JobContext` with progress reporting and cooperative cancellation;
- `BackgroundTask` contract with task identity, job metadata, task key, resources, execution, and cancellation;
- `BackgroundJobQueue` with priority scheduling;
- bounded global concurrency;
- per-resource concurrency limits for CPU, disk, network, GPU, and database;
- duplicate task-key suppression while a matching task is active;
- queued and running cancellation;
- synchronous broadcast job updates for future Task Center consumers.

## Tests

`test/core/jobs/background_job_queue_test.dart` verifies:

1. priority order;
2. bounded concurrency;
3. task-key deduplication;
4. queued cancellation;
5. cooperative cancellation of running work;
6. resource-specific concurrency limits.

## Explicit non-claims for this slice

The following remain subsequent Sprint 26 slices and are not claimed as implemented:

- Drift persistence for durable jobs;
- Task Center UI;
- isolate-backed thumbnail/hash/waveform workers;
- thumbnail cache and viewport priority;
- asset/reference pagination;
- debounced/cancellable search;
- FTS indexing;
- timeline viewport queries and virtualization;
- startup fast path and performance metrics;
- large-project benchmark dataset;
- project-session task ownership and disposal integration.

## Acceptance boundary

This slice is `development-ready` after focused and full local gates. It is not `integration-ready` or `release-ready` until hosted CI and native macOS/iOS evidence are available.
