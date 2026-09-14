# Stage 2 Skeptic Report — Story Domain & Exporters

Repository: `D:\VoidScriptor\void_scriptor_multiplatform`
HEAD reviewed: `9a549f4d8c7ffb5a53419db4bd78b96728625209`
Method: independent read of every reported implementation location, surrounding contracts, and matching tests under `test/features/story`. No target code was executed. Findings are judged against the live source and explicit test/documentation contracts.

## Verdicts

---
**BUG-STORY-01** | Original: Medium | 5 pts
- **Counter-argument:** The reported data loss is not hypothetical in this API. `scan` accepts an arbitrary `Iterable<SubjectSnapshot>` and immediately converts it to a map keyed only by `subjectId`; no uniqueness validation or merge exists. The public `SubjectSnapshot` contract describes a stable ID, but does not enforce uniqueness. The matching tests use unique IDs and therefore do not cover duplicate input.
- **Evidence:** `contradiction_analysis.dart:178-180`:
  > `final byId = <String, SubjectSnapshot>{`  
  > `  for (final subject in subjects) subject.subjectId: subject,`  
  > `};`
  The subsequent full scan uses `byId.values`, and incremental lookup uses `byId[id]`, so an earlier duplicate is unreachable after map construction. `contradiction_analysis_pipeline_test.dart:84-85` supplies a list, while all listed IDs are unique; no duplicate-ID assertion or rejection is present.
- **User/data consequence:** A duplicate source record can silently remove attributes, citations, and findings represented by the earlier snapshot; the final result can differ from the supplied records without an error.
- **Corrected severity:** Medium remains appropriate. Duplicate IDs may be invalid upstream, but this domain boundary silently accepts and discards them.
- **Confidence:** 96%
- **Risk calc:** EV = (96% x 5) - (4% x 10) = 4.40
- **Decision:** CONFIRMED
---

---
**BUG-STORY-02** | Original: Medium | 5 pts
- **Counter-argument:** The finding is real for the default restoration path. `fromJson` reconstructs `_statuses` but does not reconstruct a dismissal record or otherwise derive one from the serialized event. Consequently a restored inbox can display `dismissed` while its private/default `_dismissals` store is empty. `restore` then cannot remove the missing record and returns false. If the caller separately injects the original shared store, the issue is avoided, but JSON alone does not contain enough dismissal-record data to rebuild it.
- **Evidence:** `contradiction_inbox.dart:219-234`:
  > `final inbox = ContradictionInbox(dismissals: dismissals, clock: clock);`
  > `if (status != null) inbox._statuses[key.toString()] = status;`
  `restore` requires the store record:
  > `if (_dismissals.remove(findingId) == null) return false;`
  The round-trip test at `contradiction_inbox_test.dart:278-300` verifies status/history and open filtering only; it does not call `restore` or rescan the restored inbox through a pipeline. The module documentation explicitly says dismissal is suppression in the shared store, making status-only restoration inconsistent.
- **User/data consequence:** A default-restored dismissed finding remains hidden from `open`, but cannot be restored and does not suppress a pipeline scan unless the caller supplies the separately persisted dismissal store.
- **Corrected severity:** Medium remains appropriate because the persisted inbox state is internally inconsistent and recovery behavior is broken.
- **Confidence:** 97%
- **Risk calc:** EV = (97% x 5) - (3% x 10) = 4.55
- **Decision:** CONFIRMED
---

---
**BUG-STORY-03** | Original: Medium | 5 pts
- **Counter-argument:** The validation gap is direct and reachable. `setTarget` rejects a blank key, but `recordWords` validates only `count` and then calls `_stateFor`, which inserts a state under the untrimmed key. This creates progress/history for an unnamed scope even though the class contract says scope keys must not be blank for target setting and the domain's scope identity is the key.
- **Evidence:** `word_targets.dart:102-110` rejects blank keys in `setTarget`; `word_targets.dart:125-136` says:
  > `if (count <= 0) { throw ArgumentError('count must be positive'); }`
  > `final state = _stateFor(level, scopeKey);`
  `_stateFor` uses `putIfAbsent(scopeKey, ...)`, so `''` and whitespace are stored as actual scope identifiers. `word_targets_test.dart:31-37` covers blank `setTarget`, while no test covers blank `recordWords`.
- **User/data consequence:** Invalid writes silently create orphan progress that cannot correspond to a valid configured target and can pollute UI/history or later persistence.
- **Corrected severity:** Medium remains appropriate; it is persistent domain-state corruption rather than merely cosmetic input handling.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 5) - (1% x 10) = 4.85
- **Decision:** CONFIRMED
---

---
**BUG-STORY-04** | Original: Medium | 5 pts
- **Counter-argument:** The exporter stages to `<final>.tmp` and invokes `rename` directly over the final path. There is no explicit replacement. Dart's rename behavior when the destination already exists is OS-dependent; on the Windows platform targeted by this repository, replacement is not a safe guaranteed operation. Thus the implementation does not establish the documented successful re-export contract. The existing test asserts successful replacement for TXT only and cannot prove the Markdown path; the interruption tests deliberately avoid an existing final destination.
- **Evidence:** `story_markdown_exporter.dart:71-86`:
  > `final staging = File('${file.path}.tmp');`
  > `await staging.rename(file.path);`
  `story_export_interrupt_safety_test.dart:104-118` plants only the staging directory and checks no partial final; it does not test re-exporting Markdown over an existing final. The only explicit replacement test is `story_export_interrupt_safety_test.dart:153-180`, and it uses `StoryTxtExporter`.
- **User/data consequence:** A normal second Markdown export can throw instead of replacing the prior export, leaving the old file and potentially the staging artifact/error path.
- **Corrected severity:** Medium remains appropriate for a normal export workflow failure. The test gap is format-specific, not evidence that the implementation guarantees replacement.
- **Confidence:** 86%
- **Risk calc:** EV = (86% x 5) - (14% x 10) = 2.90
- **Decision:** CONFIRMED
---

---
**BUG-STORY-05** | Original: Medium | 5 pts
- **Counter-argument:** The same unsafe direct rename exists in TXT. The repository's own test labels the intended contract “successful re-export replaces the previous export,” but the implementation has no delete/replace step. The test is therefore a contract pin, not proof that the operation is portable or guaranteed; it may pass on an environment whose rename replaces, while failing on Windows or another filesystem configuration.
- **Evidence:** `story_txt_exporter.dart:82-95`:
  > `final staging = File('${file.path}.tmp');`
  > `await staging.rename(file.path);`
  `story_export_interrupt_safety_test.dart:153-180` explicitly expects a second export to replace the first, but no test plants an existing final and verifies the same operation under a Windows-specific failure condition. The catch block only cleans staging after an exception; it does not make rename replacement-safe.
- **User/data consequence:** Re-exporting an existing TXT file can fail rather than publish the new manuscript, despite the test/documented workflow requiring replacement.
- **Corrected severity:** Medium remains appropriate.
- **Confidence:** 86%
- **Risk calc:** EV = (86% x 5) - (14% x 10) = 2.90
- **Decision:** CONFIRMED
---

---
**BUG-STORY-06** | Original: Medium | 5 pts
- **Counter-argument:** DOCX repeats the same staging/direct-rename pattern and has no explicit replacement. The matching tests cover successful ZIP decoding and interrupted export with no final file, but do not pin a successful DOCX re-export over an existing destination. The implementation therefore cannot guarantee the normal overwrite contract on Windows.
- **Evidence:** `story_docx_exporter.dart:70-83`:
  > `final staging = File('${output.path}.tmp');`
  > `await staging.rename(output.path);`
  `story_export_interrupt_safety_test.dart:120-150` tests only a failed staged write and a first successful DOCX export; there is no existing-final DOCX re-export test.
- **User/data consequence:** A second DOCX export may fail at publication even though the previous valid document exists and the requested output should be replaced.
- **Corrected severity:** Medium remains appropriate.
- **Confidence:** 86%
- **Risk calc:** EV = (86% x 5) - (14% x 10) = 2.90
- **Decision:** CONFIRMED
---

---
**BUG-STORY-07** | Original: Low | 1 pt
- **Counter-argument:** The validator's title-count check is semantically broader than its stated contract. It counts raw title text anywhere in serialized output, rather than the first Markdown heading or the DOCX title paragraph. A valid Markdown export whose synopsis/draft repeats the title will fail solely on `titleCount`. For DOCX, XML escaping makes the false-positive case even clearer: a title containing `&`, `<`, `>`, quotes, or apostrophes is serialized escaped, so searching for the raw title can report zero even when `_parseParagraphs` correctly unescapes and validates the Title paragraph. The existing fixture uses special characters in synopsis/draft but not in the title and explicitly asserts raw title count one, so it does not cover this defect.
- **Evidence:** `story_export_fidelity.dart:50-52`:
  > `final titleCount = expectTitle.allMatches(markdown).length;`
  and `:110-112`:
  > `final titleCount = expectTitle.allMatches(documentXml).length;`
  The DOCX parser later performs structural parsing and `_unescape` at `:156-183`, demonstrating that structural/title-element validation is available but the count check does not use it. `story_export_fidelity_test.dart:121` and `:169` assert raw title occurrence one only for the plain title `Matrix Novel`.
- **User/data consequence:** Fidelity validation can reject valid exports when content repeats the title or when DOCX title text is XML-escaped.
- **Corrected severity:** Low remains appropriate: it is a validator false failure, not export data loss.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 1) - (1% x 2) = 0.97
- **Decision:** CONFIRMED
---

---
**BUG-STORY-08** | Original: Low | 1 pt
- **Counter-argument:** The function's contract is explicitly UTC-specific, but the implementation never checks `utcInstant.isUtc`. A local `DateTime` is accepted and arithmetic is performed on its local calendar fields, so the resulting day key is based on the caller's local value rather than a UTC instant plus the explicit offset. This is a reachable misuse at the public static method boundary. Existing tests pass UTC values only and therefore pin the intended path but not rejection/handling of local input.
- **Evidence:** `word_targets.dart:39-49` documents “instan UTC” and implements:
  > `final shifted = utcInstant.add(Duration(minutes: offsetMinutes));`
  with no `isUtc` assertion/conversion. `word_targets_test.dart:145-167` uses `DateTime.utc(...)` in every case; no local-DateTime case exists.
- **User/data consequence:** A caller passing a local DateTime can derive a day key from the wrong timezone basis, producing a wrong daily target partition near date boundaries.
- **Corrected severity:** Low remains appropriate because the API contract warns callers and the defect is an unchecked boundary precondition.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.85
- **Decision:** CONFIRMED
---

## SUMMARY

- Bugs confirmed: 8 (total original points: 32)
- Bugs disproved: 0 (total points: 0)
- Final skeptic score: 32 points accepted, 0 points disproved
- No finding met the required DISPROVE threshold with the available evidence. The duplicate-subject concern (BUG-STORY-01) is not demonstrated by current callers/tests, but the public iterable API still permits it and silently overwrites data, so it remains confirmed with the original Medium severity.

## ACCEPTED BUG LIST

- BUG-STORY-01 — Medium
- BUG-STORY-02 — Medium
- BUG-STORY-03 — Medium
- BUG-STORY-04 — Medium
- BUG-STORY-05 — Medium
- BUG-STORY-06 — Medium
- BUG-STORY-07 — Low
- BUG-STORY-08 — Low
