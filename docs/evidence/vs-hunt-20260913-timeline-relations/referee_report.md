# Referee verdict — vs-hunt-20260913-timeline-relations (parent-merged Skeptic+Referee, PARTIAL chain)

Chain status: Stage 1 Hunter ran via delegate (gemini flash-lite) and completed
(5 findings, score 31) BEFORE quota exhaustion. Stage 2 Skeptic delegates failed
2x with HTTP 429 quota (attempt #1 died mid-run without writing its report;
attempt #2 same). Per anti-loop rule (run260 precedent), the main agent performed
the independent Skeptic+Referee pass itself: scan-only, every cited line plus
production callers re-read at HEAD 9ef59dd. No child verdicts were adopted without
independent code reading. Report chain is therefore labeled PARTIAL.

## Verdicts

### BUG-001 (Critical claim) — NOT A BUG
move_timeline_clip_command.dart:16-29,41-53. `fromRecord` reads
`record.payload` (keys oldStartSeconds/newStartSeconds — written by `payload`
getter at :41-46, persisted by project_mutation_runtime.dart:110 as `command.payload`).
The replay path never reads `undoPayload` — grep of all consumers
(project_session_manager.dart:349, command_history_repository.dart,
project_mutation_runtime.dart) shows the column is written and decoded but never
feeds fromRecord. `undo()` (:59) uses the in-memory field. The Hunter's claimed
mechanism is wrong. Residual: undoPayload shape (:51 key 'startSeconds') is
internally inconsistent and unused — cosmetic debt, not a reachable defect.

### BUG-002 (Critical claim) — NOT A BUG (design gap, not defect)
timeline_model.dart:92-109. Overlap absence is real, but `validateTimeline` has
ZERO production callers (grep: only test/features/timeline/timeline_model_test.dart).
Sprint 16 contract never specified overlap rejection; clips legitimately coexist
per beat import. No user-visible defect reachable. Report as design observation only.

### BUG-003 (Medium claim) — NOT A BUG
relation_command.dart:18-31. Command id and relation id are deliberately distinct
namespaces: undo/redo deletes via `relation.id` (:106) frozen inside `payload`
(:78-81), so restart hydration (fromRecord :54-67) restores the SAME relation id.
Correlation "mismatch" was never a contract.

### BUG-004 (Medium claim) — REAL BUG (confirmed, Medium)
timeline_workspace_screen.dart:36-42. Mechanism verified end-to-end:
- Reachability: create_timeline_service.dart:41 sets timeline durationSeconds =
  `scene.estimatedDurationSeconds ?? 10`, while :70 imports beats with
  `beat.durationSeconds ?? 1` with no cross-validation → clip longer than scene is
  persistable without any malformed DB (plain user data: a beat with duration 15 in
  a scene estimated at 10s).
- Trigger: `_moveClip` computes maxStart = duration - clipDuration = negative;
  `(x).clamp(0.0, negative)` throws. Empirically probed on this toolchain:
  `3.0.clamp(0.0,-5.0)` / `-2.0` / `4.25` ALL throw `ArgumentError: Invalid
  argument(s): 0.0` (disposable probe test, deleted after run).
- Consequence: drag-end on such a clip throws inside a GestureDetector callback →
  red-screen exception in the timeline workspace; repeated every drag. No data loss
  (setState/commit never reached), UI crash only, deterministic.
Severity Medium (not Critical): no data corruption, single screen, avoidable by not
dragging. Fix direction applied by parent (run267): pin upperBound to 0 when
maxStart < 0 — clip parks at 0 instead of throwing; RED reproduced the exact
ArgumentError via label-anchored drag gesture, GREEN with valid start assertion.
False-pass note: first RED attempt passed falsely (chip outside Stack hit-test
bounds + soft `if (updated != null)` assertion); corrected with start=0 geometry and
hard `expect(updated, isNotNull)` before trusting the loop.

### BUG-005 (Low claim) — NOT A BUG
create_timeline_service.dart:60-67. The action track is inserted in the SAME
transaction loop (:46-57) from `_defaultTracks` which unconditionally includes
TimelineTrackType.action, immediately before getSingle(). StateError requires a
corrupted DB mid-transaction — outside the local-first trust boundary.

## Stats
Findings reviewed: 5. REAL BUG: 1 (BUG-004, Medium). NOT A BUG: 4.
Critical count downgraded to 0 (both Critical claims failed mechanism verification).

TOTAL FINDINGS: 5
CONFIRMED REAL BUGS: 1
CRITICAL: 0
MEDIUM: 1
LOW: 0
