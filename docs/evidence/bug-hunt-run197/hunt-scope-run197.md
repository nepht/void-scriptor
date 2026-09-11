# Bug-hunt run197 scope manifest

repo: D:\VoidScriptor\void_scriptor_multiplatform
branch: master
HEAD at hunt start: b5d8bba8550fb8629f1e3feb62dc6ceb3e847c03
mode: scan-only static analysis (branch-diff: none)
git status at hunt start: clean (4 untracked non-source docs: .hermes/AUTONOMOUS_ROADMAP_PROMPT.md, docs/MASTER_SPRINT.md, docs/backlog/, docs/evidence/website-source-reconciliation-2026-09-08.json)

## Justification (new scope rule: changed-region delta)

- Terakhir hunt region persistence/resilience/database = run94 @ 074c5a1
  (2026-09-06). Sejak itu region berubah substansial:
  - rollback payload restore penuh (BackupRollbackException, 2026-09-04 handoff)
  - heal interrupted-restore staging artifacts on write-mode session open (76a211d)
  - explicit_disk_full engine evidence (f685ecf), drive removal lifecycle (b5d8bba)
  - companionWritten guard BUG-18 fix (839c9a2), adoption wave 5efa2bd
  - schema v59->v60, project_database.g.dart regenerated, platform seams
- Region selection/shell/explorer/theme SUDAH dihunt run171 @ f72a265 (6 file,
  16 REAL BUG, semua CLOSED) - tidak dipindai ulang.
- Region narrative/support SUDAH dihunt run157 (6 file, semua tertutup atau
  keputusan scope). Tidak dipindai ulang.
- Region autosave/draft SUDAH dihunt run128 (6 file, sisa Low dgn preseden
  fix; sisa Medium BUG-18/1 sudah dipatch run133). Tidak dipindai ulang.

## Files in scope (18, masing-masing dibaca penuh)

lib/core/persistence/async_mutex.dart
lib/core/persistence/custom_storage_location.dart
lib/core/persistence/project_health_service.dart
lib/core/persistence/project_paths.dart
lib/core/persistence/project_recovery_service.dart
lib/core/persistence/project_registry_service.dart
lib/core/persistence/storage_location_registry_resolver.dart
lib/database/project/daos/asset_dao.dart
lib/database/project/project_database.dart
lib/database/project/project_database.g.dart (generated - verifikasi konsistensi)
lib/database/project/project_database_platform.dart
lib/database/project/project_database_platform_io.dart
lib/database/project/project_database_platform_web.dart
lib/database/project/project_database_service.dart
lib/database/project/tables/character_narrative_assignments.dart
lib/features/project_resilience/application/backup_location_policy.dart
lib/features/project_resilience/application/durable_draft_journal.dart
lib/features/project_resilience/application/project_session_manager.dart

## Trace-only files (dibaca seperlunya untuk verifikasi klaim)

- lib/features/project_resilience/application/project_recovery_services.dart
- lib/features/project_resilience/application/portable_project_*.dart
- lib/core/persistence/project_manifest*.dart, project_file_service.dart,
  project_move_service.dart, project_open_service.dart (stabil sejak run94)
- test/features/project_resilience/* (pola perilaku yang dijanjikan)
