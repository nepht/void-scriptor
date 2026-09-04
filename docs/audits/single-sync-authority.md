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
| Concurrent ownership prevention | VERIFIED (persistence) | Policy menolak claim kedua + persisted owner meresist owner lain lintas proses (00a9041); runtime service wiring tetap terbuka |
| Cloud + external folder integration | BLOCKED | Kedua service existing belum menerima/inject policy |
| Conflict behavior | VERIFIED (domain) | Authority-conflict journal 2da4498 memarkir perubahan lokal yang ditolak, tahan restart, karantina korup, drain merge tiga-arah (5 PASS) + wiring decorator (2 PASS baru, guard total 8 PASS) |
| Clear warning/state | VERIFIED (domain) | Denial message eksplisit dan tested |
| Persisted authority across restart | VERIFIED | SyncAuthorityStore JSON v1 atomic tmp+rename per proyek; PersistedSyncAuthority claim/restore/release lintas proses (00a9041) |
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

## Update 2026-09-03 (nephthys cron: evidence-closure row stale)

- Row "Persisted authority across restart" di tabel Gap ternyata STALE:
  slice 00a9041 sudah menutupnya dengan `SyncAuthorityStore` (JSON v1
  atomic tmp+rename per proyek) + `PersistedSyncAuthority` (claim/restore/
  release). Baris BLOCKED diperbaiki menjadi VERIFIED.
- Bukti fresh run ini (HEAD b4b35d5):
  `flutter test test/features/collaboration/application/sync_authority_store_test.dart`
  = 6 PASS ("All tests passed!"), mencakup persisted authority denies
  concurrent owner after restore dan release clears ownership.
- Boundary tetap: runtime service wiring (cloud_sync_service.dart
  concurrent), conflict flow integration, UI denied state, native
  interaction tetap terbuka -> step 145.32 tetap PARTIAL.

## Update 2026-09-04 (nephthys cron run28): runtime service wiring CLOSED

- `AuthorityGuardedCloudSyncService`
  (`lib/features/collaboration/application/authority_guarded_cloud_sync_service.dart`,
  commit ab6e14a) menjadi jalur runtime yang menghormati single sync
  authority rule: `push`/`sync` di-gate lewat klaim `PersistedSyncAuthority`;
  denial push melempar `SyncAuthorityDeniedException` (pesan menyebut cloud
  dan external folder); denial sync mengembalikan `SyncState.error` dengan
  warning user-readable; `pull` tetap read-only selama ownership ditolak.
- Bukti: RED compile failure (simbol undefined) -> GREEN 6 PASS; regression
  collaboration+capabilities 56 PASS; scoped analyze No issues; full suite
  3604 PASS exit 0; windows debug build PASS 20,6s.
- Klarifikasi blocker: `lib/core/network/cloud_sync_service.dart` tidak
  pernah ada di repo; service runtime ada di
  `lib/features/collaboration/application/`.
- Sisa gap 145.32: conflict flow integration, UI denied state, native
  interaction.

## Update 2026-09-04 (nephthys cron run29: conflict flow integration CLOSED)

- `SyncAuthorityConflictJournal`
  (`lib/features/collaboration/application/sync_authority_conflict_journal.dart`,
  commit 2da4498) menutup gap "conflict flow integration": perubahan
  lokal yang ditolak authority diparkir sebagai entri JSONL atomik
  (tmp+rename), bertahan lintas restart, baris korup dikarantina ke
  `.quarantine.jsonl` tanpa pernah dibuang diam-diam, dan `drain()`
  melakukan merge tiga-arah terhadap base yang terekam - key divergen
  tetap pending, entri bersih diterapkan via callback dan dihapus dari
  jurnal hanya setelah apply selesai. `park()` mengembalikan
  `SyncResult` (`SyncState.conflict`, applied 0, pesan user-readable).
- `AuthorityGuardedCloudSyncService` menerima `conflictJournal`
  opsional (commit yang sama): sync yang ditolak kini menghasilkan
  `SyncState.conflict` dengan perubahan lokal terpreservasi; denial
  push tetap melempar `SyncAuthorityDeniedException`; `pull` tetap
  read-only.
- Bukti: RED terverifikasi dua lapis (undefined symbol journal, lalu
  undefined named parameter `conflictJournal`); journal 5 PASS + guard
  8 PASS; collaboration suite 51 PASS; FULL SUITE 3611 PASS / 0 FAIL
  exit 0 (delta +7 eksak dari baseline 3604); scoped analyze No issues;
  windows debug build PASS; `git diff --check` PASS; roadmap guard PASS
  pre+post (pointer tetap 145.27).
- Sisa gap 145.32: UI denied state, native interaction.

## Update 2026-09-04 (nephthys cron run30: UI denied state)

Slice: bukti UI denied state (baris "UI sync status") - melengkapi runtime
wiring ab6e14a dan conflict flow 2da4498. PASS-first: tidak ada kode
produksi baru; implementasi runtime denied -> `SyncState.error` /
`SyncState.conflict` sudah ada, yang hilang adalah bukti rendering UI-nya.

- `test/features/collaboration/presentation/sync_status_denied_ui_test.dart`
  (commit `4581cdb`, 2 testWidgets) menjalankan guard asli:
  `PersistedSyncAuthority` di-claim `externalFolder` lebih dulu, lalu
  `AuthorityGuardedCloudSyncService` kind `cloud` melakukan `sync` nyata
  (journal `SyncAuthorityConflictJournal` di systemTemp untuk skenario
  park). Hasil `SyncResult` runtime dirender sebagai
  `SyncStatus(state, message)` ke `SyncStatusIndicator`; asersi: ikon
  `error_outline` / `warning_amber` muncul dan
  `find.byTooltip(<pesan denial>)` menemukan tooltip-nya - bukti pesan
  user-readable benar-benar tampil di UI.
- Teknik: semua I/O file nyata (store claim, sync guard, journal park)
  dieksekusi via `tester.runAsync` - zona fake-async `testWidgets`
  menggantung future I/O file nyata tanpa error (terbukti: dua run
  bergantung >6 menit sebelum root cause ditemukan). `runAsync`
  mengembalikan nullable, wajib null-check.
- Bukti: presentation suite 8 PASS / 0 FAIL exit 0; collaboration suite
  53 PASS / 0 FAIL exit 0; `flutter analyze` No issues found! (9.9s);
  `flutter build windows --debug` PASS (19,9s, void_scriptor.exe);
  format 0 changed; `git diff --check` PASS; roadmap guard PASS
  pre+post-commit (pointer tetap 145.27, canonical_sha 86af6a5).
- Sisa gap 145.32: native interaction (UNVERIFIABLE dari cron) dan
  wiring indicator ke shell produksi (permukaan UI milik sibling
  145.37/145.38 - keputusan Choi).
