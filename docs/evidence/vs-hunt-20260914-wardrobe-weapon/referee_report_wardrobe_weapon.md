# Referee Report — Wardrobe + Weapon

- **Target repo:** `D:\VoidScriptor\void_scriptor_multiplatform`
- **head_at_verdict:** `b17dd6e9968af71018fd14b20472c1be29e795f0`
- **date:** 2026-09-14 (SE Asia Standard Time)
- **Scope:** wardrobe + weapon findings BUG-1 through BUG-6
- **Authority:** independent code review of the cited implementation, DAOs, persistence boundary, callers, and routing

---

**BUG-1**
- **Hunter's claim:** Wardrobe creation commits database rows and can then fail to create the filesystem package, leaving an orphaned database asset.
- **Skeptic's response:** DISPROVE — the DB-then-folder sequence and cleanup are the documented asset-creation convention; package files are optional pipeline artifacts.
- **Your analysis:** The claimed ordering is present: `create_wardrobe_service.dart:27-59` commits `assets`, `wardrobes`, and the default variant in one transaction, then `:60-70` creates package subdirectories. The catch at `:72-76` deletes any partial directory and rethrows, but does not undo committed rows. However, the same sequence and cleanup are used by the environment creator at `create_environment_service.dart:28-78,80-101`, and the repository precedent explicitly records DB-then-folder as the accepted convention. The persistence boundary is also explicit: `ProjectPaths.database` returns one project package's `database/project.db` at `project_paths.dart:154-155,176-180`. Nothing in the reviewed wardrobe read path requires the package directory to exist; the workspace reads the model through the repository/controller. This is a tolerated materialization gap, not a demonstrated integrity defect.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **Suggested fix:** None required for this finding; optional future hardening could add compensating cleanup/repair semantics.

---

**BUG-2**
- **Hunter's claim:** Weapon creation can leave committed database rows without a filesystem directory when post-transaction folder creation fails.
- **Skeptic's response:** DISPROVE — this matches the established creation convention and the weapon workspace is database-backed.
- **Your analysis:** `create_weapon_service.dart:28-66` commits the asset, weapon, default variant, and preservation profile transaction; `:68-80` then materializes the package folders. The catch at `:82-86` removes only an existing partial folder and rethrows. The same accepted pattern is directly visible in `create_environment_service.dart:28-78,80-101`, and no reviewed weapon caller treats package-folder existence as a prerequisite for the persisted weapon model. The weapon workspace controller obtains the model from the session database at `weapon_workspace_controller.dart:7-16`. Therefore the mechanism is real but the reported consequence is not a defect under this repository's documented contract.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **Suggested fix:** None required for this finding; optional repair tooling may reconcile missing packages.

---

**BUG-3**
- **Hunter's claim:** Wardrobe lookup and deletion omit `projectId` predicates, allowing a cross-project wardrobe ID to be read or deleted.
- **Skeptic's response:** DISPROVE — each repository instance uses a project-bound database handle, and each project has its own SQLite file.
- **Your analysis:** The omission is confirmed locally: `wardrobe_repository_impl.dart:24-26` calls `getWardrobe(assetId)` without `projectId`, and deletion at `:30-50` predicates only on the asset/wardrobe ID. The DAO lookup is likewise ID-only at `wardrobe_dao.dart:25-27`, while list access is project-scoped at `wardrobe_dao.dart:29-31`. But the claimed cross-project path is blocked by the storage architecture: `ProjectPaths.database` resolves `.../<projectId>.voidproject/database/project.db` at `project_paths.dart:154-155,176-180`; the production workspace controller constructs the repository with the active session database and manifest project ID at `wardrobe_workspace_controller.dart:7-14`. A different project's UUID is not present in that database. This is defense-in-depth debt, not the claimed reachable cross-project exposure.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **Suggested fix:** Optional hardening: add project predicates and validate asset ownership before reads/deletes.

---

**BUG-4**
- **Hunter's claim:** Weapon lookup and deletion omit `projectId` predicates, allowing a weapon ID from another project to be read or deleted.
- **Skeptic's response:** DISPROVE — the per-project SQLite boundary makes the cross-project consequence unreachable through a normal repository instance.
- **Your analysis:** The code does omit the field: `weapon_repository_impl.dart:24-26` performs ID-only lookup, and deletion at `:30-59` uses only weapon/asset IDs. `weapon_dao.dart:31-36` confirms ID-only single lookup and project-scoped list lookup. Nonetheless, `ProjectPaths.database` defines a separate `database/project.db` under each project package at `project_paths.dart:154-155,176-180`, and the production controller binds `WeaponRepositoryImpl` to the active session database at `weapon_workspace_controller.dart:7-16`. A weapon belonging to another project cannot be found through this handle absent an architectural invariant violation or deliberate database co-mingling. Thus the missing predicate is useful defense-in-depth but not a reachable Medium bug as reported.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **Suggested fix:** Optional hardening: scope lookup and every delete predicate by project ownership.

---

**BUG-5**
- **Hunter's claim:** The production wardrobe workspace displays hardcoded components, colors, materials, variants, and references instead of persisted child data.
- **Skeptic's response:** ACCEPT — the screen uses persisted scalar fields only; parameterless detail cards render fixed values despite available child readers.
- **Your analysis:** The screen is production-routed by `workspace_resolver.dart:185-193`, where `AssetType.wardrobe` creates `WardrobeWorkspaceScreen`. Its desktop path passes model fields only to the specification card at `wardrobe_workspace_screen.dart:69-75`, then instantiates all remaining cards as const at `:80-88`; the compact path does the same at `:106-117`. Those cards visibly contain fixed values: components at `wardrobe_detail_cards.dart:62-80`, colors at `:83-98`, materials at `:101-116`, variants at `:119-135`, and a fixed references string at `:138-148`. Persisted readers already exist for components, colors, variants, and references at `wardrobe_dao.dart:42-62`. Real saved child records can therefore be replaced by misleading sample data in a reachable production surface.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add repository/provider child-detail loading and pass persisted rows into data-driven cards.

---

**BUG-6**
- **Hunter's claim:** The production weapon workspace displays hardcoded components, measurement subparts, energy metadata, variants, and references instead of persisted child records.
- **Skeptic's response:** ACCEPT — scalar fields are bound, but the reported child-detail portions remain fixed and routed.
- **Your analysis:** The workspace is production-routed by `workspace_resolver.dart:185-193`, including the weapon branch at `:193`. The screen derives only scalar specification values from `WeaponModel` at `weapon_workspace_screen.dart:18-24`; its desktop and compact layouts instantiate the components, variants, and references cards as const at `:95-118` and `:142-155`. The cards hardcode component labels at `weapon_detail_cards.dart:65-82`, blade/handle dimensions at `:85-104`, and emission/activation at `:107-122`; only overall length/weight and energy/core values are passed in. The DAO exposes persisted readers for variants, components, measurements, colors, energy profile, and references at `weapon_dao.dart:47-77`. The mismatch is therefore user-visible fake data in real detail fields, not dead code.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Load weapon child records through repository/provider and render data-driven detail cards.

---

## Final Report

**VERIFIED BUG REPORT**

Stats:
- Total reported by Hunter: **6**
- Dismissed as false positives: **4**
- Confirmed as real bugs: **2**
- Critical: **0** | Medium: **2** | Low: **0**

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|---|---|---|---|---|
| BUG-5 | Medium | `lib/features/wardrobe/presentation/wardrobe_workspace_screen.dart:80-88,113-117` | 80-88, 113-117 | Reachable wardrobe detail cards show fixed child data instead of persisted rows. | Load child details and pass them into data-driven cards. |
| BUG-6 | Medium | `lib/features/weapon/presentation/weapon_workspace_screen.dart:95-118,142-155` | 95-118, 142-155 | Reachable weapon child-detail cards show hardcoded components and metadata. | Load child details and render data-driven cards. |

Dismissed findings:
- **BUG-1 — NOT A BUG:** DB-then-folder creation is the documented tolerated convention; no required folder invariant was established.
- **BUG-2 — NOT A BUG:** Same accepted convention applies to weapon package materialization.
- **BUG-3 — NOT A BUG:** ID-only operations are defense-in-depth debt, but per-project database handles block the claimed cross-project path.
- **BUG-4 — NOT A BUG:** Same per-project SQLite boundary blocks the claimed cross-project path.

Low-confidence items:
- None.
