# 109.46 — Performance & Scale Validation

**Required outputs:** `datasets`, `baselines`, `budgets`, `results`,
`bottlenecks`, `mitigations`.

## Existing benchmark contract

`LargeProjectBenchmarkProfile` defines a repeatable development-only dataset:
50 characters, 2,000 references, 1,000 generations, 500 scenes, and 10,000
timeline clips by default. `generate()` exposes a countable dataset contract.

`ProjectBenchmarkRunner` seeds references and timeline clips into an in-memory
Drift database and measures reference-list and timeline-range query duration in
microseconds. `ProjectBenchmarkReport` preserves counts and measured results.

## Validation

`test/core/performance/sprint_109_scale_validation_test.dart` validates a small
bounded profile (10/40/20/15/100) and a runnable profile (1/20/1/1/50):

- datasets have deterministic declared record counts;
- profiles are explicitly development-only;
- reference and timeline data counts match the requested scale;
- measured query results are non-negative and observable.

## Bottlenecks and mitigations

- **Bottleneck:** large reference/timeline tables can make list/range queries
  expensive. **Mitigation:** benchmark isolates the two query paths and reports
  microseconds; existing DAO/query indexes remain the optimization seam.
- **Bottleneck:** default dataset is too large for every unit test.
  **Mitigation:** focused test uses bounded counts; default profile remains
  available for deliberate benchmark runs.
- **Bottleneck:** benchmark database lifecycle can leak resources.
  **Mitigation:** runner uses an in-memory database and closes it in `finally`.

This step validates development benchmark infrastructure, not a production
SLO. Hardware-specific latency thresholds and native release profiling remain
follow-up evidence.

No media files, external service, or credentials are required.
