# Hunter Report — Wardrobe + Weapon

Target: `D:\VoidScriptor\void_scriptor_multiplatform`
Branch: `master`
HEAD: `b17dd6e9968af71018fd14b20472c1be29e795f0`
Scope: all 16 listed non-generated Dart files; each was read completely.

---
**BUG-1** | Severity: Medium | Points: 5
- **File:** `lib/features/wardrobe/application/create_wardrobe_service.dart`
- **Line(s):** 27-70
- **Category:** data-integrity
- **Claim:** Wardrobe creation can leave a committed database asset with no filesystem directory when directory creation fails after the database transaction commits.
- **Evidence:** `await database.transaction(() async { ... });` followed by `for (final folder in [ ... ]) { ... ).create(recursive: true); }`; the cleanup only deletes `wardrobeDirectory` and never rolls back the already-committed database rows: `} catch (_) { if (await wardrobeDirectory.exists()) { await wardrobeDirectory.delete(recursive: true); } rethrow; }`
---

---
**BUG-2** | Severity: Medium | Points: 5
- **File:** `lib/features/weapon/application/create_weapon_service.dart`
- **Line(s):** 28-80
- **Category:** data-integrity
- **Claim:** Weapon creation can leave committed database rows with no filesystem directory when post-transaction folder creation fails.
- **Evidence:** `await database.transaction(() async { ... });` completes before `for (final folder in [ ... ]) { await Directory(...).create(recursive: true); }`; on failure the handler removes only the directory: `} catch (_) { if (await weaponDirectory.exists()) { await weaponDirectory.delete(recursive: true); } rethrow; }`
---

---
**BUG-3** | Severity: Medium | Points: 5
- **File:** `lib/features/wardrobe/data/wardrobe_repository_impl.dart`
- **Line(s):** 24-26, 30-56
- **Category:** data-integrity
- **Claim:** Wardrobe lookup and deletion accept an asset ID without constraining database operations to this repository's project, allowing a cross-project ID to expose or delete another project's wardrobe.
- **Evidence:** The repository stores `final String projectId;` (line 16), but lookup passes only the caller-provided ID: `final row = await database.wardrobeDao.getWardrobe(assetId);`; deletion likewise uses only `assetId` in every database predicate, e.g. `..where((row) => row.assetId.equals(assetId))`, and then deletes the asset with `..where((row) => row.id.equals(assetId))`. The DAO query is also ID-only: `..where((row) => row.assetId.equals(assetId))).getSingleOrNull()` (`lib/database/project/daos/wardrobe_dao.dart:25-27`).
---

---
**BUG-4** | Severity: Medium | Points: 5
- **File:** `lib/features/weapon/data/weapon_repository_impl.dart`
- **Line(s):** 24-26, 30-65
- **Category:** data-integrity
- **Claim:** Weapon lookup and deletion do not enforce the repository project ID, so a weapon ID from another project can be read or deleted through the current project repository.
- **Evidence:** Despite `final String projectId;` (line 16), lookup is `final row = await database.weaponDao.getWeapon(assetId);`; deletion predicates use only `assetId`, including `..where((row) => row.assetId.equals(assetId))` and `..where((row) => row.id.equals(assetId))`. The DAO lookup is ID-only: `..where((row) => row.assetId.equals(assetId))).getSingleOrNull()` (`lib/database/project/daos/weapon_dao.dart:31-33`).
---

---
**BUG-5** | Severity: Medium | Points: 5
- **File:** `lib/features/wardrobe/presentation/wardrobe_workspace_screen.dart`
- **Line(s):** 69-89, 113-117
- **Category:** logic
- **Claim:** The wardrobe workspace renders hardcoded component, palette, material, variant, and reference data rather than the persisted asset data.
- **Evidence:** The screen passes persisted scalar fields only to the specification card (`category: model?.category`, `material: model?.primaryMaterial`, etc.), while the remaining cards are always const instances: `const WardrobeComponentsCard()`, `const WardrobeColorPaletteCard()`, `const WardrobeMaterialCard()`, `const WardrobeVariantsCard()`, `const WardrobeReferencesCard()`. Those cards contain fixed values such as `_Chip(label: 'Outer Coat')` and `_Chip(label: 'Normal')` (`lib/features/wardrobe/presentation/widgets/wardrobe_detail_cards.dart:62-80, 119-135`).
---

---
**BUG-6** | Severity: Medium | Points: 5
- **File:** `lib/features/weapon/presentation/weapon_workspace_screen.dart`
- **Line(s):** 91-119, 115-118, 154-155
- **Category:** logic
- **Claim:** The weapon workspace displays hardcoded component, dimension subparts, energy metadata, variants, and references instead of persisted child records.
- **Evidence:** The workspace constructs only a scalar `WeaponSpecificationData` from the model, then uses const/static cards: `const Expanded(child: WeaponComponentsCard())`, `const WeaponVariantsCard()`, and `const WeaponReferencesCard()`. `WeaponDimensionsCard` hardcodes `const _PropertyRow(label: 'Blade', value: '260 mm')` and `const _PropertyRow(label: 'Handle', value: '145 mm')`, while `WeaponEnergyCard` hardcodes `Emission` and `Activation` (`lib/features/weapon/presentation/widgets/weapon_detail_cards.dart:94-121`).
---

**TOTAL FINDINGS:** 6
**TOTAL SCORE:** 30
