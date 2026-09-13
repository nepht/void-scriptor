# Adversarial Bug Hunt Report: Character Mode Region

- **Target Scope:** `lib/features/character_mode` (15 files)
- **HEAD Commit:** `058d7963049efb75675ba16ba71d711fb47448bc`
- **Status:** VERIFIED (all scope files read)

---

**BUG-01** | Severity: Medium | Points: 5
- **File:** `lib/features/character_mode/presentation/widgets/character_mode_identity_editor.dart`
- **Line(s):** 74
- **Category:** logic
- **Claim:** Invalidating `characterModesProvider` without family argument fails to target the specific family instance or causes a runtime error in Riverpod.
- **Evidence:** `ref.invalidate(characterModesProvider);`

---
**BUG-02** | Severity: Medium | Points: 5
- **File:** `lib/features/character_mode/presentation/widgets/character_mode_references_card.dart`
- **Line(s):** 43, 87
- **Category:** logic
- **Claim:** Invalidating `projectAssetsProvider` when removing or adding mode references does not update the mode references UI because references are loaded via `repository.getReferences(modeId)`.
- **Evidence:** `ref.invalidate(projectAssetsProvider);`

---
**BUG-03** | Severity: Medium | Points: 5
- **File:** `lib/features/character_mode/presentation/widgets/character_mode_section.dart`
- **Line(s):** 208-210, 360-365
- **Category:** data-integrity
- **Claim:** Multi-item loadout slots (such as `accessory` and `carried_item`) only track and edit a single asset because `_entryAssetId` and `selected` map only support single scalar values per slot.
- **Evidence:** 
  ```dart
  final selected = <LoadoutSlot, String?>{
    for (final slot in slots) slot: _entryAssetId(entries, slot),
  };
  ```

---
**BUG-04** | Severity: Medium | Points: 5
- **File:** `lib/features/character_mode/data/character_loadout_repository_impl.dart`
- **Line(s):** 121-124
- **Category:** data-integrity
- **Claim:** `removeSlot` checks if an asset is still used globally across all modes in the database rather than per character, preventing proper cleanup of derived asset relations when a character stops using an asset in a mode if another character also uses it.
- **Evidence:**
  ```dart
  final stillUsed = await (database.select(
    database.characterLoadoutEntries,
  )..where((row) => row.assetId.equals(assetId))).get();
  if (stillUsed.isNotEmpty) return;
  ```

---
**BUG-05** | Severity: Low | Points: 1
- **File:** `lib/features/character_mode/presentation/character_mode_controller.dart`
- **Line(s):** 35-37
- **Category:** type-safety
- **Claim:** `selectedCharacterModeProvider` is initialized as a nullable String family state provider defaulting to `null`, which requires downstream consumers to handle null states explicitly even when modes exist.
- **Evidence:**
  ```dart
  final selectedCharacterModeProvider = StateProvider.family<String?, String>(
    (ref, characterId) => null,
  );
  ```

---

**TOTAL FINDINGS:** 5
**TOTAL SCORE:** 21
