# Skeptic Report — Wardrobe + Weapon

Target: `D:\VoidScriptor\void_scriptor_multiplatform`
HEAD reviewed: `b17dd6e9968af71018fd14b20472c1be29e795f0`
Scope: six findings in `hunter_report.md`; all quoted finding locations were read directly.

---
**BUG-1** | Original: 5 pts (Medium) | Verdict: **DISPROVED**
- **Counter-argument:** The mechanism is present, but it is the established project-asset creation convention rather than an independently demonstrated integrity defect. `CreateWardrobeService` commits the normalized DB records in a transaction, then materializes the project-relative asset package and deletes any partial package on failure. The same ordering and cleanup are used by the existing environment create service, and the environment precedent explicitly documents this as the Sprint 14 convention. A missing package directory does not make the asset row unreadable: workspace/repository reads are database-backed, while package files are optional pipeline-owned artifacts.
- **Evidence:** Independently read `create_wardrobe_service.dart:27-75`:
  ```dart
  await database.transaction(() async {
    ... assets ...
    ... wardrobes ...
    ... wardrobeVariants ...
  });
  for (final folder in ['references', 'materials', 'thumbnails', 'generated', 'exports']) {
    await Directory('${wardrobeDirectory.path}...$folder').create(recursive: true);
  }
  ...
  if (await wardrobeDirectory.exists()) {
    await wardrobeDirectory.delete(recursive: true);
  }
  ```
  The same structure is in `create_environment_service.dart:28-100`, and `ProjectPaths` defines each asset package as a project-relative filesystem location while `ProjectDatabaseService`/`ProjectPaths.database` define the SQLite database as `.../<projectId>.voidproject/database/project.db`. The prior environment report records this exact DB-then-folder behavior as documented design, not a bug.
- **Confidence:** 86%
- **Risk calc:** EV = (86% x 5) - (14% x 10) = 4.30 - 1.40 = **+2.90**
- **Decision:** DISPROVE. Corrected severity: none / design limitation, not a defect.

---
**BUG-2** | Original: 5 pts (Medium) | Verdict: **DISPROVED**
- **Counter-argument:** As with BUG-1, the code-level ordering is real but the finding treats the documented package-materialization convention as requiring DB rollback. The weapon service's transaction protects the DB insert set from DB failures; filesystem creation is a subsequent, separately cleaned-up step. The same convention is used by environment creation. No code reviewed establishes that every asset directory must exist for a persisted weapon row to be valid, and the weapon workspace itself is routed and populated from the DB model.
- **Evidence:** Independently read `create_weapon_service.dart:28-86`:
  ```dart
  await database.transaction(() async {
    ... assets ...
    ... weapons ...
    ... weaponVariants ...
    ... weaponPreservationProfiles ...
  });
  for (final folder in ['references/orthographic', ... 'exports']) {
    await Directory('${weaponDirectory.path}...$folder').create(recursive: true);
  }
  ...
  if (await weaponDirectory.exists()) {
    await weaponDirectory.delete(recursive: true);
  }
  ```
  `ProjectPaths.database()` independently resolves the per-project DB to `database/project.db`; the environment create service uses the identical transaction-then-folder pattern. This is also the pattern recorded in the existing environment evidence as an intentional convention.
- **Confidence:** 84%
- **Risk calc:** EV = (84% x 5) - (16% x 10) = 4.20 - 1.60 = **+2.60**
- **Decision:** DISPROVE. Corrected severity: none / design limitation, not a defect.

---
**BUG-3** | Original: 5 pts (Medium) | Verdict: **DISPROVED**
- **Counter-argument:** The repository and DAO do omit `projectId` from single-asset lookup/deletion predicates, but the claimed cross-project exposure is not reachable through the repository architecture reviewed. A `ProjectDatabase` is opened for one project package, and `ProjectPaths.database(projectId)` resolves one `project.db` beneath that package. The repository is constructed with that session's `projectId`; production workspace wiring passes `session.database` and `session.manifest.id`. Thus another project's asset ID belongs to another database handle, not the current repository's DB. This is a latent defensive-scoping weakness only if the per-project DB invariant is violated or a caller manually co-mingles projects in one database, neither of which is the claimed production path.
- **Evidence:** `wardrobe_repository_impl.dart:8-26,30-56` was read directly:
  ```dart
  final ProjectDatabase database;
  final String projectId;
  ...
  Future<WardrobeModel?> getWardrobe(String assetId) async {
    final row = await database.wardrobeDao.getWardrobe(assetId);
    return row == null ? null : _map(row);
  }
  ```
  The DAO is indeed ID-only at `wardrobe_dao.dart:25-27`, and deletion predicates are ID-only at repository lines 32-50. However, `ProjectPaths.database()` resolves `.../$projectId.voidproject/database/project.db`, while workspace/inspector construction passes the active session database and manifest project ID. The repository's list path also explicitly scopes by project: `getWardrobe(projectId)` at lines 20-21. The independent architecture evidence describes project persistence as per-project SQLite.
- **Confidence:** 82%
- **Risk calc:** EV = (82% x 5) - (18% x 10) = 4.10 - 1.80 = **+2.30**
- **Decision:** DISPROVE. Corrected severity: latent hardening opportunity (Low at most), not the claimed reachable Medium cross-project defect.

---
**BUG-4** | Original: 5 pts (Medium) | Verdict: **DISPROVED**
- **Counter-argument:** The quoted omission is real in isolation, but the asserted cross-project read/delete path is unreachable under the per-project database contract. Weapon repositories are built from the active project session's database and manifest ID, and each package owns its own `database/project.db`. A weapon from another project therefore cannot be selected through this repository's database. As in BUG-3, adding project predicates would be useful defense-in-depth, but the hunter's claimed cross-project consequence is not established for production use.
- **Evidence:** `weapon_repository_impl.dart:8-26,30-65` was read directly:
  ```dart
  final ProjectDatabase database;
  final String projectId;
  ...
  final row = await database.weaponDao.getWeapon(assetId);
  ```
  `weapon_dao.dart:31-36` confirms the single lookup is ID-only, while `getWeapons(projectId)` is project-scoped. Production controller wiring constructs `WeaponRepositoryImpl(database: session.database, projectId: session.manifest.id)` and the workspace resolver routes the selected weapon through `WeaponWorkspaceScreen`. `ProjectPaths.database(projectId)` confirms the DB boundary is one SQLite file per project package.
- **Confidence:** 82%
- **Risk calc:** EV = (82% x 5) - (18% x 10) = 4.10 - 1.80 = **+2.30**
- **Decision:** DISPROVE. Corrected severity: latent hardening opportunity (Low at most), not the claimed reachable Medium cross-project defect.

---
**BUG-5** | Original: 5 pts (Medium) | Verdict: **CONFIRMED**
- **Counter-argument:** The workspace receives a persisted `WardrobeModel` and uses its scalar fields for the specification card, but every other reported detail card is parameterless and therefore cannot consume persisted child rows. The repository maps only scalar `Wardrobe` columns; the screen does not call the wardrobe DAO's existing child readers for components, colors, variants, or references. The resulting hardcoded values are visible on the routed production wardrobe workspace, not dead code.
- **Evidence:** `wardrobe_workspace_screen.dart:69-88,106-117` contains:
  ```dart
  WardrobeSpecificationCard(... model?.category ... model?.style ...),
  const WardrobeComponentsCard(),
  const WardrobeColorPaletteCard(),
  const WardrobeMaterialCard(),
  const WardrobeVariantsCard(),
  const WardrobeReferencesCard(),
  ```
  `wardrobe_detail_cards.dart:62-80,83-98,101-135,138-148` hardcodes `Outer Coat`, `Inner Shirt`, `Pants`, `Gloves`, `Boots`, `Belt`, three color swatches, materials, variants, and a fixed references string. In contrast, `wardrobe_dao.dart:42-61` has `getComponents`, `getColors`, `getVariants`, and `getReferences`, proving persisted child data is available but unused. `workspace_resolver.dart:190-192` routes `AssetType.wardrobe` to this screen.
- **Confidence:** 98%
- **Risk calc:** ACCEPT does not claim points in the skeptic scoring model; disproof EV was not applicable because confidence in the defect is above the acceptance threshold.
- **Decision:** ACCEPT / CONFIRMED. Corrected severity: Medium.

---
**BUG-6** | Original: 5 pts (Medium) | Verdict: **CONFIRMED**
- **Counter-argument:** The screen does bind some persisted scalar values (type, overall length, weight, primary material, energy type, and core), but the reported child-detail portions remain hardcoded. The parameterless components, variants, and references cards cannot render persisted rows; dimensions hardcode blade/handle subparts; energy hardcodes emission/activation. The routed production workspace makes these cards reachable.
- **Evidence:** `weapon_workspace_screen.dart:18-24,95-118,141-155` shows only a scalar `WeaponSpecificationData` is derived from `WeaponModel`, while `WeaponComponentsCard`, `WeaponVariantsCard`, and `WeaponReferencesCard` are const. `weapon_detail_cards.dart:65-82` hardcodes six component labels; lines 98-101 hardcode:
  ```dart
  const _PropertyRow(label: 'Blade', value: '260 mm'),
  const _PropertyRow(label: 'Handle', value: '145 mm'),
  ```
  and lines 116-120 hardcode `Emission: Violet` and `Activation: Grip Recognition`. Yet `weapon_dao.dart:47-77` provides persisted readers for variants, components, measurements, colors, energy profile, and references. `workspace_resolver.dart:193` routes `AssetType.weapon` to this screen.
- **Confidence:** 98%
- **Risk calc:** ACCEPT does not claim points in the skeptic scoring model; disproof EV was not applicable because confidence in the defect is above the acceptance threshold.
- **Decision:** ACCEPT / CONFIRMED. Corrected severity: Medium.

---

**SUMMARY:**
- Bugs disproved: **4** (BUG-1, BUG-2, BUG-3, BUG-4; total points claimed: **20**)
- Bugs accepted as real: **2** (BUG-5, BUG-6)
- Final skeptic score: **+20 net points**

**ACCEPTED BUG LIST:**
- BUG-5 — Medium
- BUG-6 — Medium
