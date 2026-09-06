# Sprint 145.26 — Environment / Location Core

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.26 dan `core_mvp_scope_reset_spec.json`.  
Metode: inspeksi source/test live read-only dan focused Flutter test.

## Required contract

Environment / Location Core harus menyediakan structured overview, zones, weather, lighting, continuity, physics, references, scene relation, project-local folders, restart persistence, dan responsive workspace behavior.

## Live implementation evidence

- `lib/features/environment/domain/environment_model.dart` — structured environment metadata/overview.
- `lib/features/environment/domain/scene_environment_context.dart` — typed environment-to-scene context with optional zone, lighting, weather, and continuity references.
- `lib/features/environment/data/environment_repository_impl.dart` — project-scoped environment persistence.
- `lib/features/environment/application/create_environment_service.dart` — transactional creation, default weather/lighting/physics profiles, and project-local folder creation.
- `lib/features/environment/presentation/environment_workspace_screen.dart` — overview and zone workspace UI.
- `lib/features/environment/presentation/environment_inspector.dart` — environment inspector surface.
- `lib/features/workspace/presentation/workspace_resolver.dart` — environment selection/workspace resolution seam.

## Latest focused evidence

Command:

```text
wsl.exe -d Ubuntu -- bash -lc 'cd /home/nepht/Projects/void_scriptor_multiplatform && export PATH="$HOME/toolchain/flutter/bin:$PATH" && flutter test test/features/environment/environment_model_test.dart test/features/environment/environment_persistence_test.dart test/features/environment/environment_relation_test.dart test/features/environment/environment_workspace_test.dart test/features/workspace/workspace_resolver_wiring_test.dart'
```

Result:

```text
All tests passed! — 7 tests
```

Covered behaviors:

- structured environment overview fields remain available;
- environment creation creates universal asset, profiles, physics, and folders;
- environment schema survives database restart;
- scene environment relation has a stable serialized representation;
- Environment Workspace renders on a narrow viewport;
- Workspace Resolver wires live workspace actions.

## Evidence boundary

| Area | Status |
|---|---|
| Environment domain model | VERIFIED by focused test |
| Transactional creation/default profiles/folders | VERIFIED by focused test |
| Restart persistence | VERIFIED by focused test |
| Scene relation serialization | VERIFIED by focused test |
| Responsive Environment Workspace | VERIFIED by focused test |
| Zone/weather/lighting/continuity editor depth | PARTIAL; overview and data seams exist, complete editor contract not proven in this batch |
| Reference/media lifecycle | PARTIAL; folder/reference paths exist, full import/hash/missing-file journey remains open |
| Shared selection/resolver clean-device journey | PARTIAL; resolver wiring test passes, full native route journey remains open |
| Native Windows interaction | UNVERIFIABLE; driver previously returned `snapshot_id_required` |
| Full Core vertical journey | PENDING; depends on remaining 145.27–145.41 and 145.42 safety matrix |

## No-break conditions

1. Environment creation must be transactional: metadata/default profiles and required folders must not leave an orphan package on failure.
2. Scene context must retain typed environment/zone/weather/lighting/continuity IDs rather than collapsing context into free text.
3. Environment data must remain project-scoped and survive database restart.
4. Narrow layout must not produce RenderFlex overflow diagnostics.
5. Optional AI/Cloud/Network services must not be required to open or edit local Environment data.
6. Location/environment references must remain compatible with Character and Story context resolution.
7. Native build and native interaction remain separate evidence gates.

## Decision

`145.26 Environment / Location Core` berstatus **PARTIAL**. The current local implementation has solid evidence for structured data, transactional creation, defaults, project folders, restart persistence, scene relation serialization, narrow workspace rendering, and resolver wiring: 7 focused tests pass. Complete editor depth, reference/media lifecycle, full shared selection journey, native interaction, and clean-device end-to-end proof remain open.

Next: `145.27` (resolve from the canonical Sprint 145 step inventory before implementation).

## Evidence paths

- `lib/features/environment/domain/environment_model.dart`
- `lib/features/environment/domain/scene_environment_context.dart`
- `lib/features/environment/data/environment_repository_impl.dart`
- `lib/features/environment/application/create_environment_service.dart`
- `lib/features/environment/presentation/environment_workspace_screen.dart`
- `lib/features/environment/presentation/environment_inspector.dart`
- `lib/features/workspace/presentation/workspace_resolver.dart`
- `test/features/environment/environment_model_test.dart`
- `test/features/environment/environment_persistence_test.dart`
- `test/features/environment/environment_relation_test.dart`
- `test/features/environment/environment_workspace_test.dart`
- `test/features/workspace/workspace_resolver_wiring_test.dart`
- `docs/audits/core-mvp-vertical-slice-contract.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`

## Audit note

This is a scope/evidence audit. No production Environment code, schema, migration, or concurrent agent file was changed.
- 145.24: `docs/audits/novel-workspace-core.md`
- 145.25: `docs/audits/character-workspace-core.md`
- 145.26: `docs/audits/environment-location-core.md`

Current blockers remain: `145.19` dependency boundary, partial Core slices, `145.42` owned by another executor, and native Windows interaction blocked by `snapshot_id_required`. No commit, push, tag, cleanup, or destructive storage action was performed.