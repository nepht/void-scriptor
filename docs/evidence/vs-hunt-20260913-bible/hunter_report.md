# Hunter report — vs-hunt-20260913-bible
HEAD: 7ec14e5c5987f1f88191bf20eaf2e67f25946f7b
Scope: lib/features/bible/application (17 non-generated files, 2991 lines region incl. domain)
Delegated Hunter (gemini/gemini-3.5-flash-lite), scan-only, report received complete.

---
**BUG-1** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/application/lore_backlink_service.dart`
- **Line(s):** 36
- **Category:** performance
- **Claim:** `collectSources` performs an unbounded table scan loading all scene beats across the entire database without filtering by project scene IDs.
- **Evidence:** `final beats = await (db.select(db.sceneBeats)).get();`

---
**BUG-2** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/application/canon_validator.dart`
- **Line(s):** 41
- **Category:** logic
- **Claim:** Uniqueness rule violations generate misleading error messages stating `value "null" conflicts with the canon rule` because uniqueness conditions do not have an expected value.
- **Evidence:** `message: _message(rule, expected, actual),`

---
**BUG-3** | Severity: Low | Points: 1
- **File:** `lib/features/bible/application/canon_health_service.dart`
- **Line(s):** 27-28
- **Category:** logic
- **Claim:** `CanonHealthService` accumulates weight for `info` severity conflicts but does not track or report their count in `CanonHealthSummary`.
- **Evidence:**
```dart
        case CanonConflictSeverity.info:
          weight += 1;
```

---
**BUG-4** | Severity: Low | Points: 1
- **File:** `lib/features/bible/application/faction_image_importer.dart`
- **Line(s):** 71-73
- **Category:** edge-case
- **Claim:** If database persistence fails after successfully copying a new image file during import, an orphaned file is left behind in the asset directory.
- **Evidence:**
```dart
    await source.copy(target.path);

    await repo.save(faction.copyWith(imagePath: target.path));
```

TOTAL FINDINGS: 4
TOTAL SCORE: 12
