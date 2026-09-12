# Skeptic report — vs-hunt-20260913-bible
HEAD: 7ec14e5c5987f1f88191bf20eaf2e67f25946f7b
Delegated Skeptic (gemini/gemini-3.5-flash-lite), scan-only, independent per-finding file reads incl. test/features/bible/canon_validator_test.dart, canon_health_service_test.dart, faction_image_persistence_test.dart.

### BUG-1 (lore_backlink_service.dart:36) — CONFIRMED
Unbounded select of db.sceneBeats; contrast: retargetOccurrences correctly restricts via row.sceneId.isIn(sceneIds).

### BUG-2 (canon_validator.dart:41) — CONFIRMED
Uniqueness rules evaluate values['count']; expectedValue unset -> _message interpolates null -> misleading 'value "null" conflicts...'.

### BUG-3 (canon_health_service.dart:27-28) — CONFIRMED
info severity adds weight but CanonHealthSummary exposes no info count field (only critical/errors/warnings).

### BUG-4 (faction_image_importer.dart:71-73) — CONFIRMED
source.copy(target.path) before repo.save; save failure leaves orphan file in faction_images without DB reference.

CONFIRMED: 4 / UNCONFIRMED: 0 / DISPROVED: 0
