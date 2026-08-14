# Sprint 24 — Project Package, Import/Export, Backup, Recovery

## Scope

Sprint 24 hardens project persistence around a portable `.voidproject` package. A working package is a directory; transfer/export is a ZIP archive with the same `.voidproject` extension.

## Canonical working package

```text
<id>.voidproject/
├── manifest/project.json
├── database/project.db
├── assets/
├── cache/
├── backups/
└── exports/
```

`ProjectPackage` and `ProjectPackagePaths` are the canonical path abstractions. Domain file references use logical `/`-separated relative paths such as `assets/audio/<uuid>.wav`; absolute paths are only retained for explicitly external dependencies.

## Manifest format

`VoidProjectFormat.currentSchema` is `16`. This is the project format schema and is intentionally separate from `application.version` (`0.1.0`). Manifest writes are atomic using `.tmp` and `.bak` companions.

## Resilience services

- `ProjectPackageService`: creates the package structure transactionally and removes partial packages on failure.
- `ProjectResilienceRepository`: stores external files, backup records, cache entries, trash entries, and migration history in project-scoped Drift tables.
- `ProjectPathMigrator`: converts absolute paths inside the package to portable relative paths; external paths remain external.
- `ProjectIntegrityService`: validates manifest/database status and reports missing and orphan files.
- `ProjectSessionLock`: writes a secret-free session marker and detects unclean shutdowns.
- `ProjectBackupService`: quick backups contain manifest and database; cache remains disposable.
- `ProjectCacheService` and `ProjectTrashService`: clear disposable data and support reversible file deletion.

The project database schema is now v34, with the Sprint 24 resilience tables added in migration `v33 → v34`.

## Lifecycle hardening follow-up

`ProjectSessionManager` now owns the open lifecycle:

```text
read manifest
→ validate package identity
→ acquire session.lock + .project.lock
→ open database
→ expose ProjectSession
```

`ProjectSession.close()` closes Drift first and releases both lock markers. `ProjectOpenMode.readOnly` permits inspection without acquiring a write lock and rejects save attempts. `currentProjectSessionProvider` exposes this lifecycle to Riverpod consumers, including `open`, `save`, and `closeProject`.

Import-as-copy now rewrites both the manifest project ID and every SQLite table containing a `project_id` column. This prevents copied packages from retaining rows owned by the original project.

`ProjectStorageAnalyzer` performs an on-demand filesystem scan and classifies database, references, images, video, audio, generated, exports, backups, cache, and other files. It returns total/category bytes and deterministic largest-file results.

The follow-up hardening also wires the services into production UI and lifecycle:

- the Studio top bar opens Project Diagnostics;
- diagnostics, repair, backups, export, import, storage, cache, and trash have live routes backed by the active project session;
- orphan repair moves files to project trash, with restore-latest and permanent empty-trash actions;
- trash metadata stores package-relative paths instead of absolute internal paths;
- manual backup, WAL checkpoint, portable export, cache clearing, and import-as-copy are executable from UI;
- import-as-copy registers the relocated package in the project registry and rolls back the extracted package if registry persistence fails;
- every normal project open reads SQLite `user_version`; an older database receives a pre-migration backup before Drift migration;
- native read-only sessions use a genuinely read-only SQLite connection with migrations disabled, so repositories cannot mutate the database accidentally;
- desktop top-bar content scrolls adaptively at compact desktop widths instead of overflowing.

## Portable archive

`PortableProjectService` exports only manifest, database, and selected assets. Disposable cache and backups are excluded by default. The archive is reopened and checked for `manifest/project.json`, `database/project.db`, and the archive manifest before import. Import extracts to a working package and supports import-as-copy UUID rewriting.

## UI and routes

Added responsive resilience center screens and routes:

- `/project-diagnostics`
- `/project-repair`
- `/project-backups`
- `/project-export`

The screens are intentionally service-facing; future project-session providers can inject live scan reports without moving Drift queries into widgets.

## Verification

```text
dart format --set-exit-if-changed lib test       PASS
dart run build_runner build                      PASS
flutter analyze                                  PASS
flutter test                                     PASS — 214 tests
flutter build web --release                      PASS
git diff --check                                  PASS
AD_HOC_VERIFY_RESULT: PASS
TEMP_VERIFY_CLEAN
```

Flutter emitted the existing Material/Cupertino font warning during web build, but the release artifact completed successfully.
