import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import '../application/backup_location_policy.dart';
import '../application/backup_retention_service.dart';
import '../application/portable_project_service.dart';
import 'project_integrity_service.dart';
import 'project_recovery_services.dart';
import 'project_resilience_repository.dart';
import 'project_session_manager.dart';
import 'project_storage_analyzer.dart';

class ProjectResilienceSnapshot {
  const ProjectResilienceSnapshot({
    required this.integrity,
    required this.storage,
    required this.backupItems,
    required this.trashItems,
    required this.orphanPaths,
    this.backups = const [],
  });

  final ProjectIntegrityReport integrity;
  final ProjectStorageReport storage;
  final int backupItems;
  final int trashItems;
  final Set<String> orphanPaths;

  /// Recorded backup rows, newest first (Step 145.34 restore wiring).
  final List<ProjectBackup> backups;
}

class ProjectResilienceController {
  ProjectResilienceController(
    this.session, {
    this.retentionPolicy = const BackupRetentionPolicy(),
    BackupLocationPolicy? backupLocationPolicy,
  }) : backupLocationPolicy = backupLocationPolicy ?? BackupLocationPolicy();

  final ProjectSession session;

  /// Retention budgets enforced after each backup is recorded
  /// (Step 24.26 service wired for Step 145.34).
  final BackupRetentionPolicy retentionPolicy;

  /// Destination policy for local backups (Step 145.34 configurable
  /// location). Defaults to the package-internal backups directory.
  final BackupLocationPolicy backupLocationPolicy;

  /// Attaches (or clears with `null`) a custom backup root at runtime.
  void configureCustomBackupRoot(Directory? root) =>
      backupLocationPolicy.configureCustomBackupRoot(root);

  Future<ProjectResilienceSnapshot> scan() async {
    final referencedPaths = await _referencedAssetPaths(session.database);
    final external = await session.database.projectResilienceRepository
        .externalFor(session.package.projectId);
    var databaseHealthy = false;
    try {
      final result = await session.database
          .customSelect('PRAGMA quick_check')
          .getSingle();
      databaseHealthy = result.data.values.first == 'ok';
    } on Object {
      databaseHealthy = false;
    }
    final integrity = await ProjectIntegrityService(session.package).scan(
      referencedPaths: referencedPaths,
      databaseHealthy: databaseHealthy,
      externalFiles: external.length,
    );
    final storage = await ProjectStorageAnalyzer(session.package).analyze();
    final actual = storage.files
        .where((file) => file.relativePath.startsWith('assets/'))
        .map((file) => file.relativePath)
        .toSet();
    final trashItems = (await _trashMetadata()).length;
    final backupRows = (await session.database.projectResilienceRepository
        .backupsFor(session.package.projectId));
    backupRows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // vs-hunt-20260915-BUG-7: the count comes from recorded rows whose
    // storage currently exists — the package-internal scan alone missed
    // backups written to a configured custom (external) root.
    var availableBackups = 0;
    for (final row in backupRows) {
      if (await _resolveBackupDirectory(row.relativePath).exists()) {
        availableBackups++;
      }
    }
    return ProjectResilienceSnapshot(
      integrity: integrity,
      storage: storage,
      backupItems: availableBackups,
      trashItems: trashItems,
      orphanPaths: actual.difference(referencedPaths),
      backups: backupRows,
    );
  }

  Future<Directory> createBackup({String note = ''}) async {
    _requireWritable();
    await session.database.customStatement('PRAGMA wal_checkpoint(FULL)');
    final backup = await ProjectBackupService().create(
      package: session.package,
      type: 'manual',
      note: note,
      destinationRoot: backupLocationPolicy.resolveBackupRoot(session.package),
    );
    final metadata =
        jsonDecode(
              await File(p.join(backup.path, 'backup.json')).readAsString(),
            )
            as Map<String, dynamic>;
    await session.database.projectResilienceRepository.addBackup(
      ProjectBackupsCompanion.insert(
        id: metadata['id'] as String,
        projectId: session.package.projectId,
        type: 'manual',
        relativePath:
            BackupLocationPolicy.isExternalBackup(session.package, backup.path)
            ? backup.path
            : p
                  .relative(backup.path, from: session.package.root.path)
                  .replaceAll('\\', '/'),
        schemaVersion: metadata['schemaVersion'] as int,
        sizeBytes: await _directorySize(backup),
        createdAt: DateTime.parse(metadata['createdAt'] as String),
        note: Value(note),
      ),
    );
    await _enforceBackupRetention();
    return backup;
  }

  /// Restores the recorded backup snapshot over the live package files
  /// (Step 145.34 user-controlled restore). Uses the same
  /// [ProjectBackupService.restore] rollback guarantee as the domain tests:
  /// an emergency pre-restore backup is created first and retained on disk
  /// when anything fails. Sessions open in read-only mode are rejected
  /// fail-closed.
  ///
  /// Replacing project.db while its session is still open is a corruption
  /// hazard, so callers that own a live session must go through
  /// [ProjectBackupRestoreFlow.restoreBackupAndReopen], which closes the
  /// session before invoking this restore path. WAL is flushed when the
  /// session's database connection closes, so this method works purely on
  /// package files and must never touch a (possibly already closed) live
  /// database connection.
  Future<void> restoreBackup(ProjectBackup backup) async {
    _requireWritable();
    final directory = _resolveBackupDirectory(backup.relativePath);
    await ProjectBackupService().restore(
      package: session.package,
      backup: directory,
    );
  }

  Future<File> exportPortable() async {
    await session.database.customStatement('PRAGMA wal_checkpoint(FULL)');
    return PortableProjectExporter().exportPortable(session.package);
  }

  Future<void> clearCache() async {
    _requireWritable();
    await ProjectCacheService(session.package).clear();
    await session.database.projectResilienceRepository.clearCache();
  }

  Future<int> moveOrphansToTrash() async {
    _requireWritable();
    final snapshot = await scan();
    var moved = 0;
    for (final relative in snapshot.orphanPaths) {
      final source = File(session.package.resolve(relative));
      if (await source.exists()) {
        await ProjectTrashService(session.package).moveToTrash(source);
        moved++;
      }
    }
    return moved;
  }

  Future<bool> restoreLatestTrash() async {
    _requireWritable();
    final metadata = await _trashMetadata();
    if (metadata.isEmpty) return false;
    metadata.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    final latest = metadata.first;
    final trashed = File(session.package.resolve(latest.trashPath));
    if (!await trashed.exists()) return false;
    await ProjectTrashService(
      session.package,
    ).restore(trashed, session.package.resolve(latest.originalPath));
    await latest.metadata.delete();
    return true;
  }

  Future<int> emptyTrash() async {
    _requireWritable();
    final items = await _trashMetadata();
    if (await session.package.trashDirectory.exists()) {
      await session.package.trashDirectory.delete(recursive: true);
    }
    await session.package.trashDirectory.create(recursive: true);
    return items.length;
  }

  void _requireWritable() {
    if (session.mode == ProjectOpenMode.readOnly) {
      throw StateError('Project is open read-only');
    }
  }

  Future<Set<String>> _referencedAssetPaths(ProjectDatabase database) async {
    const excludedTables = {
      'external_files',
      'project_backups',
      'cache_entries',
      'trash_entries',
      'project_migration_history',
    };
    final references = <String>{};
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    for (final tableRow in tables) {
      final table = tableRow.data['name'] as String;
      if (excludedTables.contains(table)) continue;
      final columns = await database
          .customSelect('PRAGMA table_info("$table")')
          .get();
      final pathColumns = columns
          .map((row) => row.data['name'] as String)
          .where(
            (name) =>
                name == 'path' ||
                name.endsWith('_path') ||
                name.endsWith('_file'),
          );
      for (final column in pathColumns) {
        final values = await database
            .customSelect(
              'SELECT "$column" AS value FROM "$table" WHERE "$column" IS NOT NULL',
            )
            .get();
        for (final row in values) {
          final value = row.data['value'];
          if (value is String &&
              value.startsWith('assets/') &&
              !p.isAbsolute(value)) {
            references.add(value.replaceAll('\\', '/'));
          }
        }
      }
    }
    return references;
  }

  /// Prunes oldest backups beyond retention budgets via
  /// BackupRetentionService (Step 24.26): removes both the on-disk
  /// backup directory and its ProjectBackups row. Manual and
  /// automatic categories are budgeted independently.
  ///
  /// vs-hunt-20260915-resilience BUG-8: the deletion is irreversible, so a
  /// durable pending marker is written BEFORE the directory delete and only
  /// removed after the row delete succeeds. [reconcileInterruptedPrunes]
  /// (run here at the start of every prune pass) finishes or unwinds any
  /// marker left behind by an interruption, so a row can never outlive its
  /// deleted directory indefinitely.
  Future<void> _enforceBackupRetention() async {
    await reconcileInterruptedPrunes();
    final repository = session.database.projectResilienceRepository;
    final rows = await repository.backupsFor(session.package.projectId);
    final candidates = rows
        .map(
          (row) =>
              BackupInfo(id: row.id, type: row.type, createdAt: row.createdAt),
        )
        .toList();
    final toPrune = BackupRetentionService(
      policy: retentionPolicy,
    ).selectForPrune(candidates);
    for (final victim in toPrune) {
      final row = rows.firstWhere((r) => r.id == victim.id);
      final directory = _resolveBackupDirectory(row.relativePath);
      final marker = _pruneMarkerFile(victim.id);
      await marker.parent.create(recursive: true);
      await marker.writeAsString(
        jsonEncode({
          'backupId': victim.id,
          'relativePath': row.relativePath,
          'stage': 'pending',
        }),
      );
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await debugFailRemoveBackupForTest?.call(victim.id);
      await repository.removeBackup(victim.id);
      await marker.delete();
    }
  }

  /// Scratch marker proving a retention prune for [backupId] is mid-flight.
  File _pruneMarkerFile(String backupId) => File(
    p.join(session.package.backupDirectory.path, '.prune-$backupId.json'),
  );

  /// Reconciles interrupted retention prunes (vs-hunt-20260915-resilience
  /// BUG-8). For every `.prune-<id>.json` marker in the backups directory:
  /// a still-present backup directory is deleted, the recorded row is
  /// removed, and the marker is cleared. Structurally invalid markers are
  /// swept without touching any recorded backup. Returns the number of
  /// markers repaired or swept.
  Future<int> reconcileInterruptedPrunes() async {
    if (!await session.package.backupDirectory.exists()) return 0;
    final repository = session.database.projectResilienceRepository;
    var repaired = 0;
    for (final entity in session.package.backupDirectory.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('.prune-') || !name.endsWith('.json')) continue;
      String? backupId;
      String? relativePath;
      try {
        final json = jsonDecode(await entity.readAsString());
        if (json is Map<String, dynamic>) {
          final id = json['backupId'];
          final path = json['relativePath'];
          if (id is String && id.isNotEmpty && path is String) {
            backupId = id;
            relativePath = path;
          }
        }
      } on Object {
        backupId = null;
      }
      if (backupId == null || relativePath == null) {
        // Inert scratch: never produced by a real prune or unreadable.
        await entity.delete();
        repaired++;
        continue;
      }
      final directory = _resolveBackupDirectory(relativePath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await repository.removeBackup(backupId);
      await entity.delete();
      repaired++;
    }
    return repaired;
  }

  /// Test-only seam: invoked with the victim id immediately BEFORE its
  /// ProjectBackups row is removed, to inject an interruption mid-prune.
  @visibleForTesting
  Future<void> Function(String backupId)? debugFailRemoveBackupForTest;

  /// Resolves a stored backup path: absolute paths are custom-location
  /// backups (read/written as-is), relative paths live inside the package.
  Directory _resolveBackupDirectory(String storedPath) {
    if (p.isAbsolute(storedPath)) return Directory(storedPath);
    return Directory(session.package.resolve(storedPath));
  }

  Future<List<_TrashMetadata>> _trashMetadata() async {
    if (!await session.package.trashDirectory.exists()) return const [];
    final result = <_TrashMetadata>[];
    await for (final entity in session.package.trashDirectory.list()) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      try {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        result.add(
          _TrashMetadata(
            metadata: entity,
            originalPath: json['originalPath'] as String,
            trashPath: json['trashPath'] as String,
            deletedAt: DateTime.parse(json['deletedAt'] as String),
          ),
        );
      } on Object {
        continue;
      }
    }
    return result;
  }

  Future<int> _directorySize(Directory directory) async {
    var bytes = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) bytes += await entity.length();
    }
    return bytes;
  }
}

class _TrashMetadata {
  const _TrashMetadata({
    required this.metadata,
    required this.originalPath,
    required this.trashPath,
    required this.deletedAt,
  });
  final File metadata;
  final String originalPath;
  final String trashPath;
  final DateTime deletedAt;
}
