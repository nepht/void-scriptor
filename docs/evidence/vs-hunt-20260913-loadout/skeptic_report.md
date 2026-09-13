# Skeptic report — vs-hunt-20260913-loadout (region lib/features/character_mode)

Chain note: Skeptic delegate attempts #1 and #2 failed with upstream 429 quota
(gemini flash-lite) AFTER reading all target files (transcripts under
AppData/Local/hermes/cache/delegation). Per preseden run262/267/270 the parent
(nephthys) performed the independent Skeptic+Referee audit itself; chain status
PARTIAL, label honest. Every line quoted below was re-read at HEAD
058d7963049efb75675ba16ba71d711fb47448bc by the parent.

- LDT-BUG-01 (identity_editor.dart:74): CLAIM "invalidate family without
  argument fails/no-ops or runtime-errors" — DISPROVE (high confidence).
  Riverpod 2.6 (pubspec flutter_riverpod ^2.6.1) supports invalidating an
  entire family by passing the family object; no runtime error, and the section
  rebuild path (character_mode_section.dart:63 watch -> :91 mount) refreshes
  the editor's own FutureBuilder. Wrong mechanism, not a reachable defect.
- LDT-BUG-02 (references_card.dart:43,87): CLAIM invalidate(projectAssetsProvider)
  does not refresh this card because its list comes from
  FutureBuilder(future: repository.getReferences(modeId)) (:17-18) — CONFIRM.
  projectAssetsProvider is watched only by _ModeLoadoutCard (:153 section) —
  a sibling Consumer; its rebuild does not rebuild CharacterModeReferencesCard.
  After add/remove the row list + 'N references' count stay stale until an
  unrelated parent rebuild. Real UI staleness, no data loss.
- LDT-BUG-03 (character_mode_section.dart:208-210,323-330 + loadout repo):
  CLAIM multi slots only edit one asset — CONFIRM with precise mechanism:
  editor maps slot->first entry (:360-365); Save replace branch calls
  setSlot(new) only; in character_loadout_repository_impl.dart:59-64 the
  delete-before-insert runs ONLY for LoadoutSlotMultiplicity.single, so
  replacing on accessory/carried_item (multiple, loadout_slot.dart:40-43)
  INSERTS a second row and silently leaves the old binding. User-visible list
  then shows both; summary renders all rows (:168-184). Silent accumulation =
  data-integrity defect, not reserved scope: multiplicity semantics are real
  and quantity tests exist.
- LDT-BUG-04 (character_loadout_repository_impl.dart:121-124): CLAIM stillUsed
  is global — CONFIRM mechanism (query filters assetId only, no join to
  CharacterModes.characterId), but severity Low: cleanup below it is already
  scoped sourceAssetId==mode.characterId (:131-138), so the defect is a ghost
  'uses'/'wears' derived relation surviving for THIS character when ANOTHER
  character also equips the same asset. No cross-character deletion.
- LDT-BUG-05: StateProvider.family<String?,String> default null — DISPROVE.
  Standard Riverpod idiom; _resolveMode (:68-74) handles null via
  selectedId ?? lastUsedId with explicit fallback chain. Not a bug.

TOTAL CONFIRMED: 3 (LDT-BUG-02, LDT-BUG-03, LDT-BUG-04)
TOTAL DISPROVED: 2 (LDT-BUG-01, LDT-BUG-05)
