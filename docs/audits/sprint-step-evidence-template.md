# Sprint Step Evidence Protocol

Every sprint step must be represented individually before sprint closeout.

## Required fields

| Field | Requirement |
|---|---|
| Step ID | Stable identifier such as `S3.confirmed.01` or canonical ID when available |
| Requirement | Exact recovered requirement text; never paraphrase away acceptance detail |
| Source | Production file/class/route or explicit `MISSING` |
| Domain test | Test path and result |
| UI/integration test | Test path/result or `N/A` with reason |
| Persistence/restart | Evidence or `N/A` with reason |
| Platform/build | Evidence or `BLOCKED` with environment reason |
| Status | `DONE`, `PARTIAL`, `MISSING`, `DEFERRED`, `BLOCKED`, or `UNVERIFIABLE` |
| Gap action | Concrete implementation or evidence task |

## Closeout rule

A sprint cannot be reported as fully complete while any recovered step is `MISSING` or `PARTIAL`. `BLOCKED` and `UNVERIFIABLE` must remain visible in the final report and must include the exact blocker or missing source provenance.

## Evidence rule

A passing aggregate test suite does not close individual steps automatically. Each test must be mapped to the step(s) it actually exercises. Historical commits and roadmap checkmarks are context only, not implementation evidence.

## Protected changes

Do not modify or stage unrelated user changes listed in the project completion ledger.
