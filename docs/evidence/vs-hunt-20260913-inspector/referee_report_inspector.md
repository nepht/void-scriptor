# Referee Report: Inspector Scope (vs-hunt-20260913-inspector)

---
**INS-BUG-01**
- **Hunter's claim:** CharacterInspector passes the raw characterId UUID string as the name parameter to InspectorBody instead of loading and displaying the character's actual display name.
- **Skeptic's response:** ACCEPT. The observation is entirely accurate; `CharacterInspector` invokes `InspectorBody(name: characterId, ...)` where `characterId` is the raw UUID string.
- **Your analysis:** Examination of `lib/features/inspector/presentation/inspectors/character_inspector.dart` confirms that `InspectorBody` is called directly with `characterId` (UUID) as the `name` argument, unlike `WardrobeInspector` and `WeaponInspector` which load their respective models to display the actual asset name (`model.name`). This results in the raw UUID being displayed in the inspector header.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Implement a `FutureProvider` family for character inspection (or query character repository) to fetch the character model and pass `model.name` (with fallback to `characterId`) to `InspectorBody`.
---

---
**INS-BUG-02**
- **Hunter's claim:** WardrobeInspector silently falls back to displaying the raw wardrobeId UUID when wardrobeInspectorProvider is loading or returns null, with no loading or error indicator.
- **Skeptic's response:** ACCEPT. When `wardrobeInspectorProvider` is loading or returns null, `WardrobeInspector` falls back to rendering a container with the raw UUID string (`wardrobeId`).
- **Your analysis:** Review of `lib/features/inspector/presentation/inspectors/wardrobe_inspector.dart` shows that when `data == null`, it renders `Text(wardrobeId, style: VoidTypography.title)` without checking loading or error states or rendering a loading indicator/error message.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Use `.when(...)` on `ref.watch(wardrobeInspectorProvider(wardrobeId))` to properly render a loading indicator (e.g. `CircularProgressIndicator` or loading text) and error state rather than falling back to the raw UUID string.
---

---
**INS-BUG-03**
- **Hunter's claim:** WeaponInspector silently falls back to displaying the raw weaponId UUID as customs title when weaponInspectorProvider is loading or returns null, with no loading indicator or error message.
- **Skeptic's response:** ACCEPT. `WeaponInspector` uses `data?.name ?? weaponId` to render the title, which silently falls back to the raw UUID string while loading or when data is null.
- **Your analysis:** Verification of `lib/features/inspector/presentation/inspectors/weapon_inspector.dart` confirms that `ref.watch(weaponInspectorProvider(weaponId)).valueOrNull` yields `null` during loading or error, causing `data?.name ?? weaponId` to render the raw UUID string without any loading state or error feedback.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Use `.when(...)` on `ref.watch(weaponInspectorProvider(weaponId))` to handle loading and error states explicitly.
---

---
**INS-BUG-04**
- **Hunter's claim:** RelationSection performs asynchronous dialog awaits without re-validating project session consistency afterwards, risking database operations against a stale or switched project session.
- **Skeptic's response:** ACCEPT. `RelationSection` awaits `confirmRelationDeletion` (and dialogs), but unlike `SupportRelationshipSection`, it does not re-validate project session consistency across the async gap before executing database commands.
- **Your analysis:** Inspection of `lib/features/inspector/presentation/widgets/relation_section.dart` confirms that both `onPressed` deletion handler and `_addRelation` await dialogs (`confirmRelationDeletion`, `showDialog`) and then execute database mutations against `session.database` without checking whether `projectSessionProvider` changed during the dialog await. This creates a real cross-project data mutation vulnerability if a project switch occurs while a confirmation or add dialog is open.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Capture the active project session id before async dialog awaits and re-validate session consistency after completion (similar to `SupportRelationshipSection._actionSessionStillCurrent()`) before executing mutations.
---

---
**INS-BUG-05**
- **Hunter's claim:** InspectorResolver falls back to EmptyInspector via a wildcard switch branch for unhandled asset types without logging or indication.
- **Skeptic's response:** DISPROVE. The wildcard switch branch (`_ => const EmptyInspector()`) in `InspectorResolver` is standard Dart pattern matching and exhaustiveness handling for asset types. Falling back to `EmptyInspector` when encountering unhandled or future asset types is robust and expected UI behavior.
- **Your analysis:** Review of `lib/features/inspector/presentation/inspector_resolver.dart` confirms that `switch (selection.assetType)` uses a standard exhaustive fallback (`_ => const EmptyInspector()`). This is correct Dart practice for handling open enums or unhandled types gracefully without crashing the UI. The Skeptic's counter-argument is spot on.
- **VERDICT:** NOT A BUG
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** None required.
---

---
**INS-BUG-06**
- **Hunter's claim:** SupportRelationshipSection _load method updates state asynchronously without verifying if the project session changed during the fetch, potentially mixing or overwriting state across project switches.
- **Skeptic's response:** ACCEPT. In `SupportRelationshipSection`, `_load()` performs asynchronous fetches without checking whether the active project session changed during the async gap before calling `setState`.
- **Your analysis:** Examination of `lib/features/inspector/presentation/widgets/support_relationship_section.dart` shows that while `build()` checks session changes and triggers reloads, `_load()` itself awaits `repository.listSupports(...)` and `session.database.assetDao.getAllAssets()` without re-checking if `ref.read(projectSessionProvider).valueOrNull?.manifest.id` is still the same session before calling `setState`. If a project switch occurs during the fetch, project A's fetched data can overwrite project B's state.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Capture the starting session ID at the beginning of `_load()` and verify that the active session has not changed before executing `setState`.
---

## Final Report

**VERIFIED BUG REPORT**

Stats:
- Total reported by Hunter: 6
- Dismissed as false positives: 1
- Confirmed as real bugs: 5
- Critical: 1 | Medium: 4 | Low: 0

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| INS-BUG-04 | Critical | `lib/features/inspector/presentation/widgets/relation_section.dart` | 120-147, 182-206 | Dialog awaits lack session consistency re-validation, risking cross-project mutations. | Capture session ID before dialog and re-validate active session before executing DB operations. |
| INS-BUG-01 | Medium | `lib/features/inspector/presentation/inspectors/character_inspector.dart` | 15 | Passes raw UUID string as character name to InspectorBody. | Query character data and pass display name instead of UUID. |
| INS-BUG-02 | Medium | `lib/features/inspector/presentation/inspectors/wardrobe_inspector.dart` | 72-78 | WardrobeInspector silently falls back to raw UUID when loading/null. | Use `.when(...)` on provider to show proper loading/error indicator. |
| INS-BUG-03 | Medium | `lib/features/inspector/presentation/inspectors/weapon_inspector.dart` | 66, 75 | WeaponInspector silently falls back to raw UUID when loading/null. | Use `.when(...)` on provider to show proper loading/error indicator. |
| INS-BUG-06 | Medium | `lib/features/inspector/presentation/widgets/support_relationship_section.dart` | 108-153 | `_load()` method updates state after async gaps without re-checking session consistency. | Capture starting session ID in `_load()` and verify before calling `setState`. |

Low-confidence items (flagged for manual review):
None (all confirmed/dismissed items evaluated with High confidence).
