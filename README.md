# Void Scriptor

Void Scriptor is a Flutter creative-universe database studio.

## Project-level asset families

Each project owns an independent SQLite database and filesystem workspace. The current asset vertical slices are:

- Character: identity, references, tags, and relations.
- Wardrobe: garment metadata, components, colors, variants, references, and `wears` relations.
- Weapon: technical specifications, components, measurements, materials/colors, energy/core profiles, variants, references, preservation locks, and `uses` relations.

Asset selection is routed through the generic Selection Engine. Selected assets resolve to their dedicated workspace and Inspector:

```text
AssetType.character -> Character Workspace / Character Inspector
AssetType.wardrobe  -> Wardrobe Workspace / Wardrobe Inspector
AssetType.weapon    -> Weapon Workspace / Weapon Inspector
```

## Weapon vertical slice

Weapon data lives in the active project's `project.db` with schema version 5. A Weapon creation transaction creates:

1. the universal `Assets` row;
2. the technical `Weapons` row;
3. a default `Normal` variant;
4. a default preservation profile;
5. the UUID-based `assets/weapons/<id>/` directory tree.

Weapon relations use the existing project-level relation core. The primary scenario is:

```text
Qowner --uses--> Void Dual Dagger
```

The Weapon Workspace is responsive: wide layouts show technical view/specification side by side, while narrow layouts stack the detail cards vertically.

## Development verification

Canonical commands run from the WSL source tree:

```bash
dart format --set-exit-if-changed lib test
dart run build_runner build
flutter analyze
flutter test
flutter build linux --debug
flutter build web --release
git diff --check
```

The project uses per-project SQLite databases. Do not replace project contents with a global database.

## Sprint 1–12 completion audit

The current repository has verified vertical slices for the following areas:

| Area | Status | Evidence |
|---|---|---|
| Authentication and adaptive shell | Complete for local/guest/offline flows | `test/app/auth`, `test/app/adaptive`, `test/app/platform` |
| Project registry and project-local database lifecycle | Complete | `test/core/persistence`, `test/features/projects` |
| Universal Asset and Character | Complete for create/read/update/delete, identity, tags, references, and relations | `test/features/character`, `test/features/assets` |
| Generic Selection Engine | Complete | `test/core/selection`, resolver tests |
| Wardrobe asset family | Complete for create/read/delete, variants, components, colors, references, and `wears` persistence | `test/features/wardrobe` |
| Relation Core and Inspector relation management | Complete for create/read/delete, inverse labels, target selection, and selection navigation | `test/features/relations`, `RelationSection` |
| Weapon asset family | Complete for create/read/delete, technical child tables, variants, preservation, Explorer, Workspace, Inspector, and `uses` restart persistence | `test/features/weapon` |
| Character Mode + Loadout | Complete for schema v9, Base Mode creation, mode create/clone/update/delete safeguards, nullable identity overrides, all generic slot type validation, quantity semantics, searchable AssetPicker, mode selector, identity editor, mode references repository, and derived relation synchronization | `test/features/character_mode`, `test/features/assets` |
| Environment + Location | Complete for schema v10: environment asset/model, zones, architecture, weather, lighting, colors, props, continuity, physics, references, creation defaults, filesystem package, Explorer selection, Workspace, Inspector, and restart persistence | `test/features/environment` |
| Story Bible + Scene System | Complete for schema v11: Story asset, Story Bible sections, arcs, chapters, scenes, scene characters/modes, environment context, beats, continuity changes, Story/Scene workspace foundations, Explorer selection, Inspector, and restart persistence | `test/features/story` |

The following are deliberately deferred because they require additional product subsystems rather than missing persistence plumbing:

- cloud authentication and real email/password reset delivery;
- binary file picker/import pipeline and reference-image preview/editor;
- history/version timeline UI and favorite metadata;
- component/material/measurement editors for Wardrobe and Weapon;
- export to PNG/PDF and release packaging/signing;
- donation/payment integration.

Sprint 13 now supports the generic accessory/companion/vehicle/hair slot contract, quantity validation, mode identity editing, reference persistence, and derived relation origin tracking. Dedicated binary file picking/preview, thumbnail generation, accent/tags, and compare-mode visualization remain follow-up presentation slices.

Deferred items must not be represented as silent no-op actions; current UI shows explicit local-mode or not-configured feedback.
