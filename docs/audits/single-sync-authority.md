# Sprint 145.32 — Single Sync Authority Rule

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.32`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Mencegah app cloud plus external folder sync from concurrently owning one live project until conflict behavior is proven; surface clear warning/state.`

## Evidence awal

Implementasi existing di `lib/features/collaboration/` memiliki:

- `CloudSyncService`;
- `InMemoryCloudSyncService`;
- `FolderCloudSyncService`;
- `SyncStatus`, `SyncResult`, dan `SyncChangeSet`;
- `SyncConflictRepository` untuk menyimpan base/ours/theirs dan resolution.

Namun sebelum slice ini tidak ditemukan guard eksplisit yang mencegah cloud dan external folder menjadi owner aktif bersamaan. `CloudSyncService` dan `FolderCloudSyncService` dapat digunakan terpisah tanpa authority arbitration.

## TDD vertical slice

RED test:

```text
sync_authority_policy_test.dart gagal compile karena
sync_authority_policy.dart, SingleSyncAuthorityPolicy, dan SyncAuthority belum ada.
```

GREEN implementation:

- `lib/features/collaboration/domain/sync_authority_policy.dart`
  - `SyncAuthority.cloud`;
  - `SyncAuthority.externalFolder`;
  - `SingleSyncAuthorityPolicy.claim()`;
  - idempotent claim untuk authority yang sama;
  - denial untuk authority berbeda;
  - warning eksplisit yang menyebut cloud dan external folder;
  - `release()` untuk melepas ownership.

Regression test:

- `test/features/collaboration/domain/sync_authority_policy_test.dart`
  - claim cloud berhasil;
  - claim external folder kedua ditolak;
  - decision membawa authority aktif;
  - message warning dapat dibaca user.

## Verification terbaru

Command:

```bash
flutter test \
  test/features/collaboration/domain/sync_authority_policy_test.dart \
  test/features/collaboration/domain/sync_models_test.dart \
  test/features/collaboration/application/cloud_sync_service_test.dart \
  test/features/collaboration/application/sync_conflict_repository_test.dart
```

Result:

```text
All tests passed! — 10 tests
```

Scoped analyzer:

```bash
dart analyze \
  lib/features/collaboration/domain/sync_authority_policy.dart \
  test/features/collaboration/domain/sync_authority_policy_test.dart
```

Result:

```text
No issues found!
```

## Gap terhadap acceptance

| Acceptance | Status | Reason |
|---|---|---|
| Authority model | VERIFIED | Cloud/external-folder enum dan policy arbitration lulus test |
| Concurrent ownership prevention | PARTIAL | Policy menolak claim kedua, tetapi belum dipasang pada service runtime |
| Cloud + external folder integration | BLOCKED | Kedua service existing belum menerima/inject policy |
| Conflict behavior | PARTIAL | `SyncChangeSet` dan conflict repository ada; conflict flow antar authority belum terhubung |
| Clear warning/state | VERIFIED (domain) | Denial message eksplisit dan tested |
| Persisted authority across restart | BLOCKED | Belum ada persistence contract atau schema untuk active authority |
| UI sync status | PARTIAL | `SyncStatusIndicator` ada; authority-denied state belum terbukti di UI |

## Safety boundary

Tidak ada cloud call, external folder mutation, file synchronization, atau perubahan database/schema. Test menggunakan domain object dan existing local test services.

## Verdict

**PARTIAL — authority policy dan warning domain sudah terbukti, tetapi belum menjadi single runtime authority untuk cloud/folder sync.**

Next implementation slice:

1. tetapkan owner lifecycle per project/session;
2. inject policy ke cloud dan external-folder sync entry points;
3. expose denied/conflict status ke `SyncStatus` dan UI;
4. tambahkan restart persistence hanya setelah contract authority storage disepakati.

145.42 tetap tidak disentuh karena berada di bawah eksekutor lain.

## Update 2026-09-03 (nephthys cron: persisted authority)

Slice: persistensi ownership authority per proyek, melengkapi policy
in-memory 2026-08-27 yang ternyata masih untracked di working tree.

- `SingleSyncAuthorityPolicy` + `SyncAuthorityDecision` diadopsi commit
  `00a9041` bersama test domain-nya (sebelumnya tidak pernah masuk git).
- `SyncAuthorityStore` (`lib/features/collaboration/application/sync_authority_store.dart`):
  JSON v1 per proyek `sync_authority_<projectId>.json`, atomic tmp+rename,
  file hilang/rusak = tanpa ownership (bukan error), projectId kosong atau
  mengandung pemisah path ditolak `ArgumentError`.
- `PersistedSyncAuthority`: `claim()` tetap lewat policy (denial tidak
  menulis), ownership yang diizinkan dipersist; `restore()` memuat
  ownership tersimpan sehingga authority kedua yang berbeda ditolak
  lintas proses; `release()` menghapus file.

RED terverifikasi: `Method not found: 'PersistedSyncAuthority'` sebelum
implementasi. Bukti: `flutter test test/features/collaboration/application/sync_authority_store_test.dart`
6 PASS; suite collaboration 38 PASS; scoped analyze No issues;
`git diff --check` PASS; windows debug build PASS 31,0s.

Sisa 145.32: runtime service wiring (cloud_sync_service.dart concurrent),
conflict flow integration, UI denied state, native interaction.
