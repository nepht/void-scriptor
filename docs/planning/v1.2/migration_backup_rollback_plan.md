# 109.5 — Migration, Backup & Rollback Plan

> Kanonik 109.5: "Menjamin project lama dapat dibuka, dimigrasikan, dicadangkan,
> dan dipulihkan." Disusun nephthys 2026-08-26 dari audit live.
> Temuan utama: rencana migrasi workspace ADR-WS-001 SUDAH terimplementasi sebagai
> `WorkspaceMigrationRunner` (lib/features/workspaces/application/) dengan
> `WorkspaceMigrationReport` yang memetakan 1:1 ke 9 langkah `migration_plan` ADR;
> diuji `workspace_migration_runner_test.dart`.

## P1 — Migrasi workspace lama → terpisah (ADR 9 langkah vs live)

| ADR action | Implementasi live |
|---|---|
| 1 backup_mixed_workspace | fase backup runner (`report.backupCreated`) |
| 2 inventory_novel_and_character_records | `inventoriedStories` / `inventoriedCharacters` |
| 3 assign_stable_workspace_and_character_ids | parameter `storyWorkspaceIds` + `CharacterNovelAssignment`, identifier tervalidasi (tes menolak identifier berbahaya SEBELUM mutasi apa pun) |
| 4 move_character_owned_records_to_character_namespace | copy file via `WorkspaceFileNamespace.characterDirectory` (`copiedCharacterFiles`) |
| 5 retain_novel_owned_projection_in_novel_namespace | copy file novel (`copiedStoryFiles`) |
| 6 create_novel_character_links | `createdLinks` via repository |
| 7 rebuild_projection_caches_and_indexes | `projectionRebuilt` |
| 8 validate_counts_links_permissions_checksums | `validatedCounts` (+ checksum via package:crypto di runner) |
| 9 perform_restore_and_rollback_drill | `rollbackDrillPassed` |

Prinsip fase 1 runner mengikat semua pekerjaan migrasi mendatang: **validasi penuh
sebelum satu byte pun bermutasi**; gagal validasi = tidak ada efek samping.

## P2 — Protokol evolusi skema Drift v56 → v57+

Berlaku untuk setiap tabel BARU Wave 1 (satu langkah fitur = satu increment):

1. **Pra-upgrade otomatis**: sebelum blok migrasi pertama dieksekusi pada DB versi <57,
   salinan paket dibuat lewat mekanisme backup resiliensi yang ada
   (`backup_retention_service.dart`, WAL-checkpoint dulu sesuai disiplin
   project-resilience-hardening); backup gagal = migrasi TIDAK jalan.
2. Blok guarded `if (from < N)` berurutan, ADDITIVE ONLY (S5 shared_data_schema):
   `createTable`/`addColumn`; nol drop/rename/tipe-ubah.
3. Setelah upgrade: buka-baca-tulis minimal dijalankan oleh test restart persistence
   milik fitur tersebut (proyek lama tetap terbuka).
4. Regenerasi build_runner + update assertion skema seluruh `test/` dalam commit sama.
5. **Rollback data = restore paket dari backup pra-upgrade** (bukan downgrade skema;
   SQLite turun versi tidak didukung dan tidak akan dicoba). App-level: operasi
   destruktif tetap behind review gate (FISO-01), bukan dibalikkan manual.

## P3 — Lapisan backup yang berlaku (yang sudah ada, bukan janji)

| Lapisan | Mekanisme live |
|---|---|
| In-app | `ProjectVersionControlService` + `BackupRetentionService` + recovery services (project_resilience) + Resilience Center UI |
| Portable export/import | `PortableProjectService` + workspaces import/export dengan pilihan collision (link/snapshot/fork/skip — tanpa overwrite diam-diam) |
| OS/host | backup harian host `D:\Hermes_Storage\Backups\Void_Scriptor` (di luar aplikasi, dilaporkan tanpa diklaim) |

## P4 — Drill & acceptance

Acceptance kanonik dipetakan ke bukti wajib saat pertama kali dieksekusi nyata:
- "dibuka" → test open proyek pra-v57 di build pasca-migrasi (restart test fitur pertama yang naikkan skema).
- "dimigrasikan" → jalankan runner pada fixture proyek campuran; report semua field true.
- "dicadangkan" → artifact backup terverifikasi (ukuran>0 + checksum) sebelum upgrade.
- "dipulihkan" → restore drill runner (`rollbackDrillPassed`) + buka hasil restore.
Status langkah ini: RENCANA VERIFIED terhadap infrastruktur live; eksekusi drill pertama
terjadi bersama migrasi v57 pertama (langkah fitur pertama yang membuat tabel) dan buktinya
ditempel di ledger langkah itu.
