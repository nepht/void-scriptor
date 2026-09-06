# Character-Owned Assets and Isolated Visual References

Status: **ACCEPTED PRODUCT CONTRACT / PARTIAL IMPLEMENTATION**  
Product authority: Choirudin  
Recorded: 2026-09-06

## Decision

Void Scriptor separates four concepts that must never be conflated:

1. **Asset definition** — what a wardrobe, armor, accessory, weapon, or story item is.
2. **Canonical ownership** — who legally or narratively owns the asset.
3. **Current bearer/equipment** — which character currently carries or wears it.
4. **Scoped state** — the character mode, timeline, universe, and scene range in which the assignment applies.

Wardrobe, armor, accessories, weapons, and story items remain stand-alone project assets. Character Workspace is the primary workflow for assigning, equipping, removing, borrowing, stealing, inheriting, and transferring those assets. A project-level Asset Library is a catalogue, not evidence that every listed asset belongs to every character.

## Character loadout

Loadout is scoped to `CharacterMode`, which is already tied to one `characterId`. Supported domain slots include:

- `wardrobe` — single;
- `armor` — single for the MVP;
- `primary_weapon` — single assignment;
- `secondary_weapon` — single assignment;
- `accessory` — multiple;
- `carried_item` — multiple stand-alone `Prop` assets;
- existing hair, companion, and vehicle slots.

Armor is not collapsed into Wardrobe. Armor has distinct future behavior such as material, coverage, durability, damage, resistance, and movement cost. Accessories are not baked into Wardrobe because they can be reused, inherited, transferred, or story-critical. Story Items remain `Prop` assets because an item may be unowned, stored in an environment, controlled by a faction, lost, destroyed, or carried by a character.

## Ownership and continuity contract

The future persistence contract must represent at least:

- asset ID;
- owner character ID when applicable;
- current assigned/bearer character ID when applicable;
- character mode ID when equipped;
- relation: `owned`, `equipped`, `carried`, `borrowed`, `stolen`, `inherited`, or an explicitly versioned equivalent;
- timeline/universe scope;
- optional validity range by scene;
- quantity where applicable;
- narrative notes.

No schema or migration is authorized by this document. `D-SCHEMA-01` remains OPEN. Persistence and migration require a separate compatibility contract, existing-user fixture, backup/rollback evidence, and explicit product approval.

## Visual-reference contract

The primary visual reference for Character, Wardrobe, Armor, Accessory, Weapon, and Story Item uses an isolated subject by default:

- transparent background when the format supports alpha;
- no environment or unrelated object;
- no descriptive text burned into pixels;
- no decorative frame treated as part of the design;
- one primary subject with readable silhouette.

Description, ownership, mode, timeline, and other metadata belong below or beside the image in the UI. They remain editable, searchable, translatable, and accessible rather than being embedded permanently into the image.

Contextual images remain valid secondary references and must be typed explicitly, for example:

- `primary_cutout`;
- `detail_view`;
- `rear_view`;
- `scale_reference`;
- `in_use_reference`;
- `scene_reference`;
- `mood_reference`.

`primary_cutout` is the canonical isolated image. A contextual image must not silently replace it.

## Import and derivation policy

For an imported primary reference, Void Scriptor should eventually:

1. detect whether the source has an alpha channel;
2. show a warning—not destructive rejection—when a `primary_cutout` has a background;
3. render transparency using a checkerboard preview;
4. preserve the original source;
5. store any background-removed result as a derived asset rather than overwriting the original;
6. retain source credit, rights/license notes, and content hash.

## UI consequences

- Rename or explain global sidebar modules as Asset Library/catalogue surfaces.
- Character Workspace owns assignment/equipment workflows.
- Asset cards show image first, then name, asset type, owner/bearer, mode, and optional description below.
- Empty ownership is valid and must not be auto-assigned.
- Shared, borrowed, transferred, lost, and timeline-specific states must not be represented by duplicating the asset.

## Current implementation evidence

- `CharacterModes.characterId` scopes a mode to one character.
- `CharacterLoadoutEntries` links a stand-alone `assetId` to a `modeId` and slot.
- `References.ownerAssetId` and editable description fields already support stand-alone reference metadata at project level.
- Domain slot support for `armor` and `carried_item` was added without schema changes and is covered by `loadout_slot_ownership_contract_test.dart`.

## Deferred implementation

- ownership/bearer/history persistence;
- Armor asset persistence and repository/UI;
- standalone Accessory persistence if the current generic asset path is insufficient;
- Character Workspace assign/equip/transfer UI;
- typed reference UI and alpha-channel validation;
- original/derived media lineage;
- migration, fixture, backup, rollback, and native journey evidence.

These remain **PARTIAL/DEFERRED**, not completed by this contract document or the domain enum alone.
