# Referee Report: Studio Domain (`vs-hunt-20260913-studio`)

As the independent referee, I have evaluated all 8 bug findings reported by the Bug Hunter and challenged by the Bug Skeptic, after inspecting the actual domain source code and unit tests in `lib/features/studio/domain/` and `test/features/studio/domain/`.

## Summary Statistics

- Total reported by Hunter: 8
- Dismissed as false positives / deliberate design: 2 (`STU-BUG-04`, `STU-BUG-05`)
- Confirmed as real bugs: 6 (`STU-BUG-01`, `STU-BUG-02`, `STU-BUG-03`, `STU-BUG-06`, `STU-BUG-07`, `STU-BUG-08`)
- Stats: **CONFIRMED REAL: 6 / Critical: 1 | Medium: 2 | Low: 3**

---

## Verdict Table

| # | Verdict | True Severity | Production-Reachable? | One-Line Reason |
|---|---|---|---|---|
| STU-BUG-01 | REAL BUG | Medium | No (domain-only) | `firstWhere` without `orElse` throws `StateError` on missing IDs. |
| STU-BUG-02 | REAL BUG | Critical | No (domain-only) | Case-sensitive check against `'delete'` allows command bypass via `'DELETE'`. |
| STU-BUG-03 | REAL BUG | Medium | No (domain-only) | Map-keyed repository overwrites previous department leads, discarding history. |
| STU-BUG-04 | NOT A BUG | N/A | No (domain-only) | Deliberate lightweight heuristic check explicitly pinned and tested by unit tests. |
| STU-BUG-05 | NOT A BUG | N/A | No (domain-only) | Deliberate domain architecture rejecting chat messages to enforce structured communication. |
| STU-BUG-06 | REAL BUG | Low | No (domain-only) | `EvaluationMetrics.composite` sums unscaled quality, safety, and latency metrics. |
| STU-BUG-07 | REAL BUG | Low | No (domain-only) | `AttentionQueue.next()` re-sorts all items on every call ($O(N \log N)$). |
| STU-BUG-08 | REAL BUG | Low | No (domain-only) | `ModelRouter.select` uses strict case-sensitive matching and returns static `'local'`. |

---

## Detailed Evaluations

---
**BUG-01**
- **Hunter's claim:** `ProductionBreakdown.isBlocked` and related methods use `firstWhere` without an `orElse` handler, causing uncaught `StateError` crashes when querying non-existent task IDs or missing dependency IDs.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection confirms `_tasks.firstWhere(...)` is called without `orElse`. Querying an invalid ID throws a raw `StateError`. While production reachability is currently restricted to domain tests, public domain APIs should handle missing IDs gracefully or throw a domain-specific exception.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Provide `orElse` handlers or check existence prior to querying, throwing a typed domain exception or returning safe defaults.
---

---
**BUG-02**
- **Hunter's claim:** `AutopilotControl.canExecute` performs a case-sensitive inequality check against `'delete'`, allowing uppercase or mixed-case deletion commands (e.g. `'DELETE'`) to bypass autopilot safety controls.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection shows `command != 'delete'`. Passing `'DELETE'` or `'Delete'` evaluates to true and bypasses the guard. This is a real governance loophole in security/safety validation.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Normalize command input using `.toLowerCase().trim() != 'delete'`.
---

---
**BUG-03**
- **Hunter's claim:** `InMemoryDepartmentLeadRepository` uses a simple map keyed by `departmentId` (`_leads[lead.departmentId] = lead`), overwriting previous department leads on every save call and discarding lifecycle history.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection confirms `_leads[lead.departmentId] = lead;` replaces existing entries per department. This discards historical department lead assignments.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Maintain an append-only log or list of leads per department rather than single-entry map replacement.
---

---
**BUG-04**
- **Hunter's claim:** `PromptInjectionBoundary.accept` uses basic substring matching (`contains('ignore previous')`), which fails to detect prompt injection attempts using extra spacing, alternative phrasings, or obfuscation.
- **Skeptic's response:** DISPROVE (Deliberate design, explicitly tested and pinned by unit tests).
- **Your analysis:** Examination of `operations_safety_test.dart` confirms that `PromptInjectionBoundary` is a lightweight heuristic stub with specific test expectations pinned in the test suite. It is not intended as an exhaustive LLM security guardrail. Skeptic is correct.
- **VERDICT: NOT A BUG**
- **Confidence:** High
---

---
**BUG-05**
- **Hunter's claim:** `StudioMessageChannel.send` explicitly rejects messages of type `StudioMessageType.chat`, preventing chat messages from being transmitted through the communication channel.
- **Skeptic's response:** DISPROVE (Deliberate design enforcing structured communication over free-form chat, verified by unit tests).
- **Your analysis:** Examination of `studio_communication_test.dart` shows an explicit unit test asserting `channel.send(..., StudioMessageType.chat)` returns `false`. This is intentional domain design enforcing structured task/status/decision messaging over free-form chat. Skeptic is correct.
- **VERDICT: NOT A BUG**
- **Confidence:** High
---

---
**BUG-06**
- **Hunter's claim:** `EvaluationMetrics.composite` calculates the mean of quality, safety, and latency without scaling latency (e.g. in milliseconds vs 0-1 scores), distorting the composite evaluation metric.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection confirms `(quality + safety + latency) / 3`. Summing 0-1 scores with millisecond latency values without normalization creates a distorted metric dominated by latency.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Normalize latency into a 0-1 range or exclude/weight it correctly in composite scoring.
---

---
**BUG-07**
- **Hunter's claim:** `AttentionQueue.next()` re-sorts all items by priority on every retrieval call instead of maintaining a sorted order or heap, causing unnecessary $O(N \log N)$ overhead.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection confirms `_items.sort(...)` executed on every `next()` call. While inefficient ($O(N \log N)$), it functions correctly for small item lists.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Maintain sorted order on insertion or use an efficient priority queue data structure.
---

---
**BUG-08**
- **Hunter's claim:** `ModelRouter.select` uses a case-sensitive `.contains('local')` check, failing to recognize local models registered with uppercase or mixed-case names.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Code inspection shows `_models.contains('local')` checks exact equality (not substring) and returns static `'local'` rather than the matched model name. Case variations or non-exact names fail.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Use case-insensitive matching (`model.toLowerCase().contains('local')`) and return the matching model name.
---

## Low-confidence items (flagged for manual review)
None. All 8 items were evaluated with High confidence based on direct code and test inspection.

---

## Catatan verifikator (parent, run289 — bukan verdict)

- Reachability di luar region diverifikasi independen: `grep -rln "features/studio" lib` di luar region = hanya
  `lib/app/routing/app_router.dart` (impor `studio_command_center.dart`; rute `AppRoutes.studioCommandCenter`
  dibangun dari `DemoStudio.registry` — data demo, nol akses kelas domain). Domain classes `ProductionBreakdown`,
  `AutopilotControl`, `InMemoryDepartmentLeadRepository`, `EvaluationMetrics`, `AttentionQueue`, `ModelRouter`
  TIDAK punya caller produksi di luar `lib/features/studio` + test-nya. Semua verdict "No (domain-only)" terkonfirmasi.
- STU-BUG-02 (satu-satunya Critical): diperbaiki run289 via TDD. RED
  `test/features/studio/domain/autopilot_delete_guard_normalization_test.dart` gagal tepat pada
  `'DELETE'` (Expected false, Actual true) -> GREEN `trim().toLowerCase()` sebelum perbandingan.
  Regression test lama `canExecute('delete') == false` tetap hijau (intent dipertahankan).
  Gates: test/features/studio 33 PASS / 0 FAIL; dart analyze scoped No issues; flutter analyze full No issues;
  format gate 0 changed; diff-check 0; build windows debug PASS 21,7s. Full suite berjalan di run ini (dicatat terpisah).
- ANTREAN terbuka (belum diperbaiki, semua domain-only): STU-BUG-01 (Medium, firstWhere tanpa orElse di
  `production_pipeline.dart:41,44,49`), STU-BUG-03 (Medium, map overwrite lead di `organization_agent.dart`),
  STU-BUG-06 (Low, composite tanpa normalisasi latency), STU-BUG-07 (Low, re-sort tiap next()),
  STU-BUG-08 (Low, `_models.contains('local')` exact-match + return string statis).
- STU-BUG-04 dan STU-BUG-05: dismissed (desain dipin test) — JANGAN di-re-fix sebagai bug.
