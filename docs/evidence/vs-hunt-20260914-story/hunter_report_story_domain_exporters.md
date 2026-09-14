# Stage 1 Hunter Report — Story Domain & Exporters

- **Repository:** `D:\VoidScriptor\void_scriptor_multiplatform`
- **Branch:** `master`
- **HEAD read:** `9a549f4d8c7ffb5a53419db4bd78b96728625209`
- **Scope:** fixed 14 files listed in `scope_files.txt`
- **Method:** static read-only inspection; matching story/export tests were read for contract pinning. No target code was executed.

---
**BUG-STORY-01** | Severity: Medium | Points: 5
- **File:** `lib/features/story/domain/contradiction_analysis.dart`
- **Line(s):** 178–180
- **Category:** data-integrity
- **Claim:** Scanning silently discards all but the last snapshot when two subjects share the same `subjectId`, so duplicate source records can make the analysis report incomplete or inconsistent.
- **Evidence:** `final byId = <String, SubjectSnapshot>{\n      for (final subject in subjects) subject.subjectId: subject,\n    };`
---
**BUG-STORY-02** | Severity: Medium | Points: 5
- **File:** `lib/features/story/domain/contradiction_inbox.dart`
- **Line(s):** 219–224, 229–234
- **Category:** data-integrity
- **Claim:** Restoring an inbox from JSON preserves a dismissed status without restoring or reconstructing the shared dismissal record, so a default-restored inbox cannot reapply that dismissal to the pipeline and cannot successfully restore it.
- **Evidence:** `final inbox = ContradictionInbox(dismissals: dismissals, clock: clock);` and `if (status != null) inbox._statuses[key.toString()] = status;`
---
**BUG-STORY-03** | Severity: Medium | Points: 5
- **File:** `lib/features/story/domain/word_targets.dart`
- **Line(s):** 125–136
- **Category:** error-handling
- **Claim:** `recordWords` validates the count but accepts a blank `scopeKey`, creating and mutating an invalid unnamed scope even though target creation rejects blank scope keys.
- **Evidence:** `if (count <= 0) {\n      throw ArgumentError('count must be positive');\n    }\n    final state = _stateFor(level, scopeKey);`
---
**BUG-STORY-04** | Severity: Medium | Points: 5
- **File:** `lib/features/story/application/story_markdown_exporter.dart`
- **Line(s):** 77–86
- **Category:** error-handling
- **Claim:** Re-exporting to an already-existing Markdown path can fail at the final rename because the staging file is renamed over the destination without an explicit replacement step, defeating normal overwrite behavior.
- **Evidence:** `final staging = File('${file.path}.tmp');` ... `await staging.rename(file.path);`
---
**BUG-STORY-05** | Severity: Medium | Points: 5
- **File:** `lib/features/story/application/story_txt_exporter.dart`
- **Line(s):** 86–95
- **Category:** error-handling
- **Claim:** Re-exporting to an already-existing TXT path can fail at the final rename because the staging file is renamed over the destination without an explicit replacement step, defeating normal overwrite behavior.
- **Evidence:** `final staging = File('${file.path}.tmp');` ... `await staging.rename(file.path);`
---
**BUG-STORY-06** | Severity: Medium | Points: 5
- **File:** `lib/features/story/application/story_docx_exporter.dart`
- **Line(s):** 74–83
- **Category:** error-handling
- **Claim:** Re-exporting to an already-existing DOCX path can fail at the final rename because the staging file is renamed over the destination without an explicit replacement step, defeating normal overwrite behavior.
- **Evidence:** `final staging = File('${output.path}.tmp');` ... `await staging.rename(output.path);`
---
**BUG-STORY-07** | Severity: Low | Points: 1
- **File:** `lib/features/story/application/story_export_fidelity.dart`
- **Line(s):** 50–52, 110–112
- **Category:** logic
- **Claim:** Fidelity validation counts raw occurrences of the expected title across the entire serialized output rather than checking the title element/paragraph, producing false failures when the title is repeated in synopsis/draft content or is XML-escaped in DOCX.
- **Evidence:** `final titleCount = expectTitle.allMatches(markdown).length;` and `final titleCount = expectTitle.allMatches(documentXml).length;`
---
**BUG-STORY-08** | Severity: Low | Points: 1
- **File:** `lib/features/story/domain/word_targets.dart`
- **Line(s):** 41–49
- **Category:** edge-case
- **Claim:** `fromUtcInstant` accepts a local `DateTime` despite its UTC-specific contract, so callers passing a non-UTC instant can derive a day key from the wrong timezone basis.
- **Evidence:** `static WordTargetDayStamp fromUtcInstant(\n    DateTime utcInstant, {\n    required int offsetMinutes,\n  }) {\n    final shifted = utcInstant.add(Duration(minutes: offsetMinutes));`
---

**TOTAL FINDINGS:** 8
**TOTAL SCORE:** 32
