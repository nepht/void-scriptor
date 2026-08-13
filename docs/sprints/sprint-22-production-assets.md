# Sprint 22 — Creature, Vehicle, Prop, and Scene Asset Instances

## Status

Implemented against the live project database schema. The Sprint 22 migration sequence is **v24 → v28**, not the blueprint's historical v14 → v15 example.

## Schema

- v24 → v25: `Creatures`, `CreaturePhysicalProfiles`, `CreatureAbilities`, `CreatureModes`
- v25 → v26: `Vehicles`, `VehicleSpecifications`, `VehicleComponents`, `VehicleWeaponMounts`, `VehicleVariants`
- v26 → v27: `Props`, `PropSpecifications`, `PropStates`
- v27 → v28: `SceneAssetInstances`, `SceneInstanceTransforms`, `SceneInstanceProperties`, `SceneContinuitySnapshots`

Every Creature, Vehicle, and Prop is backed by the universal `Assets` table and a UUID asset package directory resolved through `ProjectPaths`.

## Creature

- Non-animal categories including companion, dragon, spirit, synthetic, biological, and hybrid.
- Structured physical profile.
- Normalized abilities optionally linked to a Sprint 21 power system.
- Modes optionally linked to Sprint 20 reference sets.
- Restart persistence coverage using Byte with Cube, Companion, and Combat modes.

## Vehicle

- Structured category and technical specifications.
- Normalized components, weapon mounts by weapon asset ID, and variants.
- Variants optionally link to reference sets.
- Restart persistence coverage using Neo Interceptor and its Combat variant.

## Prop

- Structured category, physical specification, and continuity states.
- `storyCritical` metadata promotes a prop to at least high AI context priority.
- States optionally link to reference sets.
- Restart persistence coverage using Coffee Cup with Full, Half, and Empty states.

## Scene Asset Instances and Continuity

Master assets and scene instances remain separate. A scene instance stores:

- master asset ID and semantic type;
- scene-local state and optional parent attachment;
- bounded AI context priority;
- transform foundation for spatial continuity;
- dynamic properties for scene-only state;
- JSON continuity snapshots.

Inheritance creates new target-scene instances and copies final state, transform, and dynamic properties without mutating the master asset. The deterministic continuity validator reports unexplained state transitions.

## Timeline, Reference, Relation, and AI Integration

- Timeline default tracks now include Character, Creature, Vehicle, Camera, Action, Dialogue, Prop, VFX, Audio, Environment, and Continuity.
- Prompt targets and detail-sheet presets include Creature, Vehicle, and Prop.
- Preservation locks include creature, vehicle, and prop geometry.
- Relation direction convention:
  - actor/owner is the source;
  - related production asset is the target;
  - examples: `Qowner → companionOf → Byte`, `Qowner → pilots → Vehicle`, `Vehicle → equippedWith → Weapon`.
- AI scene asset context is sorted deterministically by critical/high/normal/optional priority and bounded by asset/reference budgets.
- Story-critical props are promoted to at least high priority.

## UI and Search

- Collection/detail routes: `/creatures`, `/creatures/:id`, `/vehicles`, `/vehicles/:id`, `/props`, `/props/:id`.
- Responsive production workspace with navigator, preview, inspector, and reusable scale comparison.
- Scene Workspace reads persisted instances and exposes an Add Asset action to the global Asset Browser.
- Search parser supports `type:creature`, `type:vehicle`, and `type:prop`.
- Reusable command catalog exposes open/create commands with injected navigation and creation callbacks.

## Honest Scope Boundary

The Sprint 05 Dashboard is still static and is not wired to an active project database, so live per-type dashboard counts are not claimed here. The production workspaces are tested responsive integration surfaces; full editable inspectors and richer per-family CRUD orchestration remain future UI slices. No 3D editor is claimed. Dynamic instance properties are limited to scene-local state, not primary domain data.

## Verification

Required closeout gates:

```text
dart format --set-exit-if-changed lib test
dart run build_runner build
flutter analyze
flutter test
flutter build web --release
git diff --check
```

An ad-hoc Windows Local Temp verification additionally exercises Byte, Neo Interceptor, Coffee Cup continuity inheritance, bounded AI context priority, restart persistence, and temporary-file cleanup.
