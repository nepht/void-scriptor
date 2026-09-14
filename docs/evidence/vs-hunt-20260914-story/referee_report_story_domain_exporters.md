# Referee Report — Story Domain & Exporters

- **Repository:** `D:\VoidScriptor\void_scriptor_multiplatform`
- **Branch:** `master`
- **HEAD at verdict:** `9a549f4d8c7ffb5a53419db4bd78b96728625209`
- **Scope:** the 14 files listed in `scope_files.txt`
- **Method:** independent read of the implementation, callers, tests, and documented contracts. No target code was executed. The parent-supplied Windows Dart rename probe is considered runtime evidence for BUG-STORY-04..06.

---

## BUG-STORY-01

- **Hunter's claim:** `ContradictionAnalysisPipeline.scan` silently discards all but the last `SubjectSnapshot` when two records share a `subjectId`.
- **Skeptic's response:** ACCEPT; the public `Iterable<SubjectSnapshot>` boundary does not enforce uniqueness, and tests only use unique IDs.
- **Your analysis:** **REAL BUG.** The claim is directly established by the implementation. `scan` is a public reachable method (`lib/features/story/domain/contradiction_analysis.dart:173`) and is called by the story contradiction tests/application-facing pipeline. At `:178-180` it constructs a map keyed only by ID:
  > `final byId = <String, SubjectSnapshot>{`
  > `  for (final subject in subjects) subject.subjectId: subject,`
  > `};`
  Dart map construction retains only the later value for a duplicate key. The subsequent full scan iterates `byId.values` (`:181-182`), and incremental lookup also reads `byId[id]` (`:184-186`), so the earlier snapshot is unreachable. `SubjectSnapshot` documents a stable ID (`:43-44`) but does not enforce uniqueness, and no repository/schema guarantee was found for this arbitrary iterable API. Existing callers/tests supply unique IDs, which is coverage absence, not a guarantee at this boundary.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **File:line:** `lib/features/story/domain/contradiction_analysis.dart:173-180`
- **Suggested fix:** In `ContradictionAnalysisPipeline.scan`, validate IDs while consuming `subjects` and throw `ArgumentError` identifying the duplicate, or explicitly merge duplicate snapshots under a documented deterministic policy. Do not silently overwrite the earlier record.

## BUG-STORY-02

- **Hunter's claim:** `ContradictionInbox.fromJson` restores a dismissed status but not the shared dismissal record, so default restoration cannot reapply suppression or restore the finding.
- **Skeptic's response:** ACCEPT for the default restoration path; supplying the separately persisted shared store avoids the problem.
- **Your analysis:** **REAL BUG.** The class documentation makes the coupling explicit: the dismissal store is shared with `ContradictionAnalysisPipeline` (`lib/features/story/domain/contradiction_inbox.dart:69-73`). Yet `fromJson` creates a new store when no store is supplied:
  > `final inbox = ContradictionInbox(dismissals: dismissals, clock: clock);`
  It then restores the status alone at `:225-234`:
  > `if (status != null) inbox._statuses[key.toString()] = status;`
  `toJson` persists statuses and events (`:211-217`) but not dismissal records. `restore` requires the corresponding store record and returns false otherwise (`:186-194`):
  > `if (_dismissals.remove(findingId) == null) return false;`
  Thus a standalone JSON round-trip can show `dismissed` while the pipeline's suppression store is empty and `restore` cannot remove the missing record. The existing round-trip test (`test/features/story/contradiction_inbox_test.dart:278-300`) checks status, history, and open filtering only; it does not verify restore or pipeline suppression. This is not disproved by the documented optional injected-store path; that path is precisely the workaround absent from default restoration.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **File:line:** `lib/features/story/domain/contradiction_inbox.dart:211-246` (failure manifests in `:186-194`)
- **Suggested fix:** Make `ContradictionInbox.toJson/fromJson` persist and reconstruct the dismissal records, or require a non-null restored `ContradictionDismissalStore` and reject a dismissed-status JSON without its matching record. The minimal consistent fix is to serialize the shared store alongside inbox state and hydrate it before restoring `_statuses`.

## BUG-STORY-03

- **Hunter's claim:** `recordWords` accepts blank `scopeKey`, creates an invalid scope, and mutates it although `setTarget` rejects blank keys.
- **Skeptic's response:** ACCEPT; the gap is direct and reachable, and `_stateFor` inserts the blank key.
- **Your analysis:** **REAL BUG.** `WordTargetTracker.recordWords` is a public method and has callers in the story feature (`lib/features/story/domain/word_targets.dart:127`). It checks only the count:
  > `if (count <= 0) {`
  > `  throw ArgumentError('count must be positive');`
  > `}`
  > `final state = _stateFor(level, scopeKey);`
  (`:132-135`). `_stateFor` uses `putIfAbsent(scopeKey, ...)` (`:163-164`), so `''` and whitespace create persistent in-memory scope entries and history events. In contrast, `setTarget` explicitly rejects `scopeKey.trim().isEmpty` (`:102-115`), and its test covers blank input (`test/features/story/word_targets_test.dart:31-37`). The contract calls the key the scope identity, so recording against an unnamed scope is inconsistent rather than a harmless read.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **File:line:** `lib/features/story/domain/word_targets.dart:125-143`
- **Suggested fix:** Add the same `scopeKey.trim().isEmpty` guard at the start of `WordTargetTracker.recordWords`, before `_stateFor`, throwing `ArgumentError('scopeKey must not be blank')`; add a regression test for both empty and whitespace keys.

## BUG-STORY-04

- **Hunter's claim:** Markdown re-export over an existing destination can fail because the staging file is renamed without an explicit replacement step.
- **Skeptic's response:** ACCEPT based on an OS-dependent rename theory and a format-specific test gap.
- **Your analysis:** **NOT A BUG.** The code stages and closes the file before publication (`lib/features/story/application/story_markdown_exporter.dart:77-86`):
  > `final staging = File('${file.path}.tmp');`
  > `await sink.close();`
  > `await staging.rename(file.path);`
  The parent-supplied runtime probe on the targeted Windows Dart SDK demonstrated the relevant behavior: with `dest.txt='OLD'` and `dest.txt.tmp='NEW'`, `staging.rename(dest.path)` exited 0, produced `dest=NEW`, and left staging absent. Therefore the specific claimed normal overwrite failure is false for this repository's targeted SDK/platform. A destination held open/locked by another process, a read-only destination, or a cross-volume path may still fail, but those are ordinary filesystem errors and are not established by this finding. The existing TXT overwrite test also pins the intended behavior, while the lack of a Markdown-specific duplicate test is only a coverage gap.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** No fix required for the claimed issue. Optionally add a Markdown existing-destination regression test; do not add an unnecessary delete-before-rename sequence, which would weaken atomic preservation.

## BUG-STORY-05

- **Hunter's claim:** TXT re-export over an existing destination can fail at direct staging rename.
- **Skeptic's response:** ACCEPT based on the absence of an explicit replacement step.
- **Your analysis:** **NOT A BUG.** `StoryTxtExporter.writeExport` closes the staged stream and calls `staging.rename(file.path)` (`lib/features/story/application/story_txt_exporter.dart:86-95`). The parent-supplied runtime probe exercised the same Dart `File.rename` operation on the targeted Windows SDK and verified replacement: exit 0, destination became `NEW`, staging no longer existed. The repository test explicitly exercises successful re-export replacement (`test/features/story/story_export_interrupt_safety_test.dart:153-180`) and verifies new content plus no `.tmp` leftovers. Locked/read-only destinations remain possible external filesystem failures, but they do not validate the reported "rename cannot overwrite" claim.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** No fix for the reported issue. Retain the stage-close-then-rename sequence; optionally add a Windows-specific regression test if portability documentation requires it.

## BUG-STORY-06

- **Hunter's claim:** DOCX re-export over an existing destination can fail at direct staging rename.
- **Skeptic's response:** ACCEPT based on the same OS-dependent rename theory and missing DOCX overwrite test.
- **Your analysis:** **NOT A BUG.** DOCX uses the same safe publication sequence (`lib/features/story/application/story_docx_exporter.dart:74-83`):
  > `final staging = File('${output.path}.tmp');`
  > `await sink.close();`
  > `await staging.rename(output.path);`
  The supplied Windows Dart SDK probe verified that `File.rename` replaces an existing target, so absence of an explicit delete/replace call does not create the claimed failure. Existing DOCX-specific tests cover valid ZIP publication and interruption safety (`test/features/story/story_export_interrupt_safety_test.dart:120-150`); a missing overwrite test does not turn the disproved runtime premise into a bug. Other filesystem conditions such as an open destination can legitimately make publication fail, but are outside the reported claim.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** No fix required for the claimed behavior. Add a DOCX re-export regression test only as additional contract coverage.

## BUG-STORY-07

- **Hunter's claim:** Fidelity validation counts raw title occurrences across serialized Markdown/XML, causing false failures when content repeats the title or when DOCX encodes XML entities.
- **Skeptic's response:** ACCEPT; the check is broader than the documented structural contract, and DOCX parsing already unescapes text later.
- **Your analysis:** **REAL BUG.** The validator is reachable from story export fidelity tests/application code and its documented contract requires the title once at the first structural position (`lib/features/story/application/story_export_fidelity.dart:28-31`). Markdown uses a raw whole-document substring count (`:50-52`):
  > `final titleCount = expectTitle.allMatches(markdown).length;`
  DOCX does the same against XML (`:110-112`):
  > `final titleCount = expectTitle.allMatches(documentXml).length;`
  This is semantically wrong in both directions: a repeated title in synopsis/draft makes a structurally valid export fail, while a title containing `&`, `<`, `>`, quotes, or apostrophes is serialized escaped and can produce count zero despite `_parseParagraphs` decoding entities at `:156-183`. The existing test uses plain `Matrix Novel` as the title (`story_export_fidelity_test.dart:87-121,136-169`), so it cannot expose either case.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **File:line:** `lib/features/story/application/story_export_fidelity.dart:50-52,108-112`
- **Suggested fix:** In `markdownReport`, validate `lines.first == '# $expectTitle'` and let the expected-line/structure comparison enforce the single heading rather than counting substrings. In `docxReport`, remove the raw XML count and assert the first parsed paragraph has style `Title` and text `expectTitle`; retain the existing parsed structural comparison.

## BUG-STORY-08

- **Hunter's claim:** `WordTargetDayStamp.fromUtcInstant` accepts a local `DateTime` despite its UTC-only contract and can derive the wrong day key.
- **Skeptic's response:** ACCEPT; there is no `isUtc` precondition and tests cover only UTC values.
- **Your analysis:** **REAL BUG.** The public method's contract is explicit (`lib/features/story/domain/word_targets.dart:39-45`):
  > `Menurunkan kunci hari dari instan UTC plus offset menit eksplisit`
  The implementation immediately performs arithmetic and reads calendar fields without checking UTC:
  > `final shifted = utcInstant.add(Duration(minutes: offsetMinutes));`
  > `final y = shifted.year.toString().padLeft(4, '0');`
  (`:45-48`). For a local `DateTime`, Dart preserves localness through `add`, so the day key is derived from the caller's local calendar basis rather than a verified UTC instant. The method is a reachable public boundary, and every current test uses `DateTime.utc` (`test/features/story/word_targets_test.dart:145-167`); that validates the intended path but not enforcement of the precondition. The unchecked contract boundary can mispartition dates near midnight.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **File:line:** `lib/features/story/domain/word_targets.dart:39-49`
- **Suggested fix:** At the start of `WordTargetDayStamp.fromUtcInstant`, require `utcInstant.isUtc` and throw `ArgumentError.value(utcInstant, 'utcInstant', 'must be UTC')` when false. Add a regression test passing a local `DateTime` and asserting rejection; do not silently reinterpret it because that would conceal caller timezone mistakes.

---

# VERIFIED BUG REPORT

## Stats

- Total reported by Hunter: **8**
- Dismissed as false positives: **3**
- Confirmed as real bugs: **5**
- Critical: **0** | Medium: **3** | Low: **2**

## Confirmed bugs

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|---|---|---|---|---|
| BUG-STORY-01 | Medium | `lib/features/story/domain/contradiction_analysis.dart` | 173-180 | Duplicate subject IDs are silently collapsed, losing the earlier snapshot. | Reject duplicate IDs or merge them under an explicit deterministic policy. |
| BUG-STORY-02 | Medium | `lib/features/story/domain/contradiction_inbox.dart` | 211-246; failure at 186-194 | Standalone inbox JSON restores dismissed status without the shared suppression record. | Persist/hydrate dismissal records with inbox state, or reject incomplete restoration. |
| BUG-STORY-03 | Medium | `lib/features/story/domain/word_targets.dart` | 125-143 | `recordWords` creates progress for blank scope keys. | Apply the `scopeKey.trim().isEmpty` guard before `_stateFor`. |
| BUG-STORY-07 | Low | `lib/features/story/application/story_export_fidelity.dart` | 50-52, 108-112 | Raw serialized title counting rejects repeated-content or XML-escaped valid titles. | Validate structural first heading/title paragraph instead of raw substring counts. |
| BUG-STORY-08 | Low | `lib/features/story/domain/word_targets.dart` | 39-49 | UTC-only day-key API accepts local `DateTime`. | Require `isUtc` and throw `ArgumentError` otherwise. |

## Dismissed findings

- BUG-STORY-04 — NOT A BUG: the supplied targeted-Windows Dart probe verified overwrite-on-rename.
- BUG-STORY-05 — NOT A BUG: the supplied targeted-Windows Dart probe and existing TXT re-export test verify replacement.
- BUG-STORY-06 — NOT A BUG: the supplied targeted-Windows Dart probe disproves the claimed DOCX overwrite failure; missing DOCX coverage is not itself a defect.

## Low-confidence items

None. All five confirmed findings have direct static evidence; the three exporter dismissals additionally have parent-supplied runtime evidence.
