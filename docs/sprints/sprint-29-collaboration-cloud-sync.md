# Sprint 29 — Collaboration + Cloud Sync

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S29 Collaboration+Cloud Sync") — hanya
> judul, tanpa step detail. Step di bawah **dirancang oleh nephthys** dari judul kanonik +
> audit repo nyata. Pola sama dengan S28: interface + impl lokal/mock, jujur soal batas cloud.

## Tujuan

Menambah fondasi **sinkronisasi cloud + kolaborasi** pada sistem project yang sudah ada
(`ProjectSession`, `ProjectPackage`, `ProjectVersionControlService`), TANPA backend cloud
nyata: semua jalur cloud lewat **interface** dengan impl in-memory untuk test + impl
filesystem-ke-folder untuk simulasi. Batas jujur: koneksi ke server cloud nyata dan
multi-user real-time adalah integrasi eksternal (di luar sprint ini).

## Batas lingkup (jujur)

- **IN**: sync primitives, sync service interface + local impl, conflict detection/resolution
  3-way, collaborator+role, comments, presence/activity, UI (indicator/share/comments).
- **OUT**: koneksi server cloud sungguhan, websocket multi-user, autentikasi remote, enkripsi
  (S30), plugin (S31).

## Step

### Blok A — Sync primitives (29.1–29.3)
- **29.1** `SyncState` enum + `SyncStatus` model (idle/syncing/synced/error/conflict, lastSyncAt, message).
- **29.2** `SyncChangeSet` (base/ours/theirs + changed entity keys).
- **29.3** `SyncResult` (status + applied/total + conflicts).

### Blok B — Cloud sync service (29.4–29.6)
- **29.4** `CloudSyncService` interface (`pull`, `push`, `sync`).
- **29.5** `InMemoryCloudSyncService` (deterministic test impl) + `FolderCloudSyncService` (filesystem impl).
- **29.6** Sync journal persistence (schema v40→**v41**: `sync_logs`).

### Blok C — Conflict detection & resolution (29.7–29.9)
- **29.7** `ConflictDetector` 3-way merge (base/ours/theirs).
- **29.8** `ConflictResolution` (keepOurs/keepTheirs/manual) + `ConflictResolver`.
- **29.9** Persistence conflict (schema v41: `sync_conflicts`).

### Blok D — Collaboration entities (29.10–29.12)
- **29.10** `CollaboratorRole` enum + `Collaborator` model.
- **29.11** `SharedProject` + `ProjectCollaborator` (schema v41: `project_collaborators`).
- **29.12** `ProjectComment` + repository (schema v41: `project_comments`).

### Blok E — Presence & activity (29.13–29.15)
- **29.13** `PresenceState` + `PresenceTracker` (in-memory).
- **29.14** `ActivityEvent` + `ActivityFeed`.
- **29.15** Persistence activity (schema v41: `activity_events`).

### Blok F — UI (29.16–29.18)
- **29.16** `SyncStatusIndicator` widget.
- **29.17** `ShareProjectDialog` (role picker + invite list).
- **29.18** `ProjectCommentsPanel` widget.

### Blok G — Wire + DoD (29.19–29.21)
- **29.19** Wire sync indicator ke status bar/shell.
- **29.20** Wire comments panel ke inspector/workspace route.
- **29.21** DoD: full regression gates + commit + push + tandai DONE.

## Schema v41
- `sync_logs` (id, projectId, kind, status, message, startedAt, finishedAt)
- `sync_conflicts` (id, projectId, entityKey, baseJson, oursJson, theirsJson, resolution, createdAt)
- `project_collaborators` (projectId, userId, role, invitedAt, acceptedAt)
- `project_comments` (id, projectId, authorId, targetType, targetId, body, createdAt)
- `activity_events` (id, projectId, actorId, kind, payload, createdAt)

## Risiko jujur
- Cloud = interface + local impl; koneksi server nyata adalah integrasi eksternal.
- Presence = in-memory (bukan websocket).
- Tidak ada enkripsi (S30).
