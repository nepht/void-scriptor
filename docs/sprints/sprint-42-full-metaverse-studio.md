# Sprint 42 — Full Metaverse Studio

> **STATUS: DONE** — 42.1–42.21 GREEN, 797 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S42 Full Metaverse Studio") — hanya judul.
> Fondasi audit: environment zones (`environment_zones.dart`, `scene_environment_contexts.dart`,
> `environment_props.dart`), XR S41 (session, spatial anchors, room scale), enterprise S37
> (studio, members), knowledge S38 (entities/relations). Belum ada metaverse engine.

## Tujuan

Membangun **Full Metaverse Studio** deterministic: world/region/zone hierarchy, avatar,
presence, teleport, world registry. Bukan server multiplayer / real network transport.

## Batas lingkup (jujur)

- **IN**: `MetaverseWorld` (id, name, description), `WorldRegion` (id, worldId, name),
  `WorldZone` (id, regionId, name, position), `Avatar` (id, name, appearance),
  `Presence` (avatarId + zoneId + lastSeen), `Teleport` (move presence across zones),
  `WorldRegistry` (register worlds/regions/zones + query), UI `MetaverseStudioPanel`
  + route `/metaverse`.
- **OUT**: real multiplayer server, network transport, live avatar sync.

## Step

### Blok A — World model (42.1–42.3)
- **42.1** `MetaverseWorld` (id, name, description).
- **42.2** `WorldRegion` (id, worldId, name).
- **42.3** `WorldZone` (id, regionId, name, x, y, z).

### Blok B — Avatar + presence (42.4–42.6)
- **42.4** `Avatar` (id, name, appearance).
- **42.5** `Presence` (avatarId, zoneId, lastSeen).
- **42.6** presence zone update.

### Blok C — World registry (42.7–42.9)
- **42.7** `WorldRegistry` (register world/region/zone).
- **42.8** query regions by world, zones by region.
- **42.9** zone lookup by id.

### Blok D — Teleport (42.10–42.12)
- **42.10** `Teleport` (move presence to target zone).
- **42.11** invalid target zone rejection.
- **42.12** teleport updates presence zone + timestamp.

### Blok E — Persistence (42.13–42.15)
- **42.13** Table `metaverse_worlds` (schema v52→**v53**).
- **42.14** Table `metaverse_zones`.
- **42.15** `MetaverseRepository` + restart persistence test.

### Blok F — UI (42.16–42.18)
- **42.16** `MetaverseStudioPanel` (world count + zone count).
- **42.17** `WorldList`.
- **42.18** `ZoneList`.

### Blok G — Demo + wire (42.19–42.21)
- **42.19** Wire route `/metaverse`.
- **42.20** `DemoMetaverse` built-in.
- **42.21** DoD: full regression gates + commit + tandai DONE.

## Schema v53
- `metaverse_worlds` (id PK, name, description).
- `metaverse_zones` (id PK, worldId, regionId, name, x, y, z).

## Risiko jujur
- Deterministic world/presence model; bukan multiplayer server atau network transport real.
