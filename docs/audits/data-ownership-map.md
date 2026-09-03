# Sprint 145.11 — Data Ownership Map

Tanggal audit: 2026-08-27  
Sumber: live worktree `/home/nepht/Projects/void_scriptor_multiplatform`  
Metode: inspeksi read-only terhadap model, tabel, service, repository, dan generated database map.

## Prinsip ownership

- Registry dan manifest menjawab proyek apa yang tersedia dan metadata paketnya.
- Project database menjawab data terstruktur milik satu project yang sedang dibuka.
- Filesystem menyimpan paket project, binary assets, backup, export, dan file pendukung sesuai service.
- Feature repository/service memiliki aturan domain; widget tidak boleh menjadi pemilik durable data.
- Account, cloud, publication, payment, dan provider state tidak boleh menjadi prasyarat kepemilikan Core local-first.

## Ownership matrix

| Data/domain | Canonical owner live | Storage boundary | Access seam | Invariant/no-break rule | Status |
|---|---|---|---|---|---|
| Project identity and registry | `ProjectRegistryService`, `ProjectModel` di `features/projects` | Registry file via `ProjectPaths.registry()` / injected root | `ProjectRegistryService.load/save/upsert/remove` | Registry schema version 1; UUID identity; atomic write/recovery | VERIFIED local |
| Project manifest/package | `ProjectManifestService`, `ProjectPackageService` | Project package filesystem and `project.json` | `ProjectPaths`, manifest/package services | Manifest ID must match requested project ID before DB open; paths remain project-relative | VERIFIED local |
| Open project session | `ProjectOpenService`, `ProjectSession` provider/runtime | In-memory lifecycle over project DB and services | `projectSessionProvider`, `ProjectOpenService.open/close` | One lock-aware session; close releases DB/runtime; open failure must not create empty replacement | VERIFIED local boundary |
| Project database and schema | `ProjectDatabase` / Drift migration owner | Per-project SQLite database | `ProjectDatabaseService`, DAOs, repositories | Live schema v59 (`currentSchemaVersion = 59`, lib/database/project/project_database.dart) with guarded additive migrations and future-schema DB open guard (d76d596); fixture matrix CURRENT v59 / OLD v53 / HALF-APPLIED / per-version invariants v1..v58 proven | VERIFIED local; fixture coverage CERTIFIED per 145.40/145.12 |
| Universal assets | `Assets` table, asset repository/services | Project SQLite; binary files remain filesystem-owned | `AssetRepository`, `DriftAssetRepository`, asset services | Asset row is universal metadata; typed feature data remains in feature tables | VERIFIED local |
| Characters and identity | Character services/repositories; `Characters`, identity/mode/reference tables | Project SQLite plus referenced files | Character repository/create service/mode services | UUID identity; typed character selection; Base Mode and mode/loadout relations remain consistent | VERIFIED source/test; native flow UNVERIFIABLE |
| Stories, arcs, chapters, scenes, beats | Story services/repositories; normalized story tables | Project SQLite; manuscript/export files via workspace services | Story repository/create service/workspace | Hierarchy remains normalized; scene context is not collapsed into ad-hoc JSON; selected Story opens Story workspace | VERIFIED local/source-test |
| Environments/world locations | Environment repository/create service; environment table family | Project SQLite plus project-relative references/assets | Environment repository/services and World workspace | Universal asset plus environment defaults created transactionally; zone/weather/lighting/physics remain structured | VERIFIED local/source-test |
| Timeline/cinematic data | Timeline services/DAOs; `Timelines`, `TimelineTracks`, `TimelineClips` | Project SQLite | Timeline application services | `TimelineClip.sourceId` refers to narrative beat; persist drag result on drop/end, not every pointer move | VERIFIED local boundary |
| Relationships and lore/Bible | Relation services; Bible repositories; relation/Bible table families | Project SQLite | Feature repositories and canon/lore services | Relation direction and canon status remain explicit; no silent canonical mutation | VERIFIED local boundary |
| References and identity files | Reference repositories/services; reference table family | Project SQLite metadata + copied project-relative files | Reference import/health/bundle services | Hash/primary/reference-version invariants; never canonicalize Desktop/Downloads path | VERIFIED local boundary |
| AI context/history/generation | AI application services and AI table family | Project SQLite for metadata/history; provider outputs/filesystem for artifacts | Context resolver, prompt composer/compiler, generation services | AI optional; no credentials in DB; UI does not query Drift to concatenate context | VERIFIED local/provider boundary; external providers UNVERIFIABLE |
| Autosave, recovery, snapshots | Project recovery services, mutation runtime, background jobs | Filesystem backups/journals/snapshots plus DB mutation state | `ProjectRecoveryService`, mutation runtime, job queue | Atomic writes, explicit restore, transient jobs cancelled on close; failure matrix incomplete | PARTIAL |
| Backup and export artifacts | Project package/recovery/workspace export services | Configured filesystem destination (custom root fail-safe), package `backups/`/export paths | Backup retention/export services | Archive checksum hashing (b805ffe), retention enforcement (5ce2c93), restore preview (6e70a95), configurable destination with fail-safe (d8b99a8), free-access journey (51e1610) landed and fresh-proven 2026-09-04: 13 PASS / 0 FAIL | VERIFIED(domain) per 145.34/145.33 |
| Account/session credentials | Auth/core auth layer and credential stores | Local secure/config boundary, not project DB | Auth controller/providers | Core MVP must work Guest/Offline; secrets never enter project artifacts or reports | VERIFIED boundary; external auth UNVERIFIABLE |
| Cloud/collaboration sync state | Collaboration/cloud feature services | External/provider or explicit local sync logs | Cloud sync/conflict repositories | Must not concurrently own one live project with external folder sync until conflict contract is proven | DEFERRED / PARTIAL |
| Publication/payment/marketplace state | Feature-specific repositories/services | External or feature-owned local metadata | Publishing/payment/marketplace boundaries | Non-Core and payment remain feature-gated; no Core startup dependency | DEFERRED / UNVERIFIABLE |
| Migration history and compatibility | `ProjectDatabase` migrations plus `ProjectMigrationHistory` | Project SQLite | Database open/migration runner | Never downgrade destructively; old/current/future/corrupt fixtures preserved and enforced (schema_migration_fixtures_test 64 PASS fresh 2026-09-04) | VERIFIED schema presence; fixture coverage CERTIFIED per 145.40/145.12 |

## Ownership boundaries observed

### Registry versus project contents

`ProjectRegistryService` owns the project list and writes registry metadata. It must not become the owner of characters, stories, assets, or project SQLite content. `ProjectPaths` separates registry and project paths, while `ProjectOpenService` opens the selected package database.

### Database versus filesystem

Structured metadata and relations belong in the per-project Drift database. Binary references, exports, backups, and package files belong in the filesystem services. A database row containing a path must use a project-relative/canonical path contract where applicable; absolute user paths are not portable ownership.

### Feature repository versus UI

Create, update, delete, import, and recovery policies belong to repositories/services. Explorer, Dashboard, TopBar, Workspace, and Inspector are command/navigation surfaces. The shared selection state may identify the current entity but does not own the entity data.

### Core versus optional systems

Core local-first flows own project, novel/story, chapter/scene, character, world/lore, save/recovery, search, export, and backup contracts. Account, cloud, AI providers, community, payment, marketplace, publication, and hardware integrations remain optional or deferred until their evidence gates pass.

## No-break ownership rules

1. Do not move a table or repository between owners without a migration/restart test and explicit ownership record.
2. Do not let the registry duplicate project-content records; registry entries point to project packages.
3. Do not let widgets write SQLite/filesystem directly when an application repository/service exists.
4. Preserve typed selection and resolver ownership: selection identifies; resolver chooses workspace; repository/service persists.
5. Preserve project-relative paths for portable references, exports, and recovery artifacts.
6. Keep migration/version ownership in the database layer; never infer schema state from generated Dart output alone.
7. Keep Core independent from account/network/provider availability; Guest/Offline is a first-class boundary.
8. Treat snapshots/backups as recovery artifacts, not canonical project content, until restore verification establishes the result.
9. Do not implement failure-matrix scenarios owned by the other executor in 145.42.
10. Do not perform destructive cleanup or schema migration from this documentation step.

## Gaps and evidence limits

- `145.42` still owns process kill, power loss, disk full, permission loss, drive removal, interrupted transfer, and device validation scenarios.
- Native UI persistence/restart flow is not proven because native click-through is blocked by `snapshot_id_required`.
- Hosted CI, signing, installers, live providers, cloud/server behavior, payment, and hardware are outside local ownership evidence.
- Clean-clone build reproducibility retains the previously recorded uncommitted dependency-closure caveat.
- This map identifies current ownership; it does not certify that every repository has complete CRUD, UI integration, or restart coverage.

## Decision

`145.11 Data Ownership Map` berstatus **VERIFIED sebagai audit lokal**. Ownership dipisahkan antara registry/manifest, per-project database, filesystem artifacts, feature repositories/services, dan optional systems. Tidak ada code/schema/data yang diubah. Langkah aman berikutnya adalah `145.12 Existing User Data Compatibility`, dengan fixture dan sample-data audit read-only sebelum perubahan kompatibilitas.

## Evidence

- `lib/core/persistence/project_registry_service.dart` dibaca dari live source.
- `lib/core/persistence/project_open_service.dart` dibaca dari live source.
- `lib/database/project/project_database.dart` dan generated table map menunjukkan schema v56 serta keluarga Assets, Characters, Stories, Timelines, AI, References, Bible, dan resilience.
- Live repository/service inventory menunjukkan owner feature untuk Character, Story, Environment, Assets, References, AI, Workspace, and project resilience.
- `git diff --check` tetap menjadi gate sebelum closeout.

## Update 2026-09-04 (nephthys cron run10, stale rows reconciled)

- Row `Project database and schema`: the observed v56 figure is historical (audit date 2026-08-27); live `currentSchemaVersion = 59` at lib/database/project/project_database.dart. Future-schema database open guard landed at d76d596; the migration fixture matrix (CURRENT v59 / OLD v53 / HALF-APPLIED / invariants v1..v58) is CERTIFIED per 145.40.
- Row `Backup and export artifacts`: PARTIAL -> VERIFIED(domain). Every listed invariant item is now landed evidence: archive checksum hashing b805ffe, retention enforcement 5ce2c93, restore preview 6e70a95, configurable destination with fail-safe fallback d8b99a8, free-access journey 51e1610. Fresh execution 2026-09-04 @cc656a3: archive_integrity + backup_retention_enforcement + project_backup_restore_preview + backup_configurable_location + backup_free_access = 13 PASS / 0 FAIL.
- Row `Migration history and compatibility`: fixture coverage PARTIAL -> CERTIFIED per 145.40 (schema_migration_fixtures_test 64 PASS / 0 FAIL fresh 2026-09-04) and the 145.12 reconciliation.
- Remaining limits unchanged: 145.42 failure-matrix ownership, native UI proof, hosted CI / signing / live providers.
- Status of 145.11 stays VERIFIED as a local audit; this reconciliation changed documentation only, no code/schema/data.
