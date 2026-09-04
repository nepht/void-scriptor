import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/project_package/project_package.dart';
import '../../../core/project_package/void_project_format.dart';
import '../../../database/project/project_database.dart';

class ProjectSessionLock {
  ProjectSessionLock(this.package);
  final ProjectPackage package;
  String? _ownedSessionId;
  Timer? _heartbeat;

  /// A session marker older than [staleAfter] is treated as evidence that the
  /// previous process died without closing. A live Void Scriptor refreshes
  /// the marker mtime via [startHeartbeat], so staleness implies the process
  /// is gone (a suspended machine re-touches on its next heartbeat).
  static const Duration staleAfter = Duration(seconds: 60);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  Future<void> acquire({String? appVersion}) async {
    if (await package.sessionFile.exists()) {
      final recovered = await _recoverStaleMarker();
      if (!recovered) {
        throw StateError('Project has an active or stale session');
      }
    }
    final sessionId = const Uuid().v4();
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': sessionId,
        'projectId': package.projectId,
        'openedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion ?? VoidProjectFormat.applicationVersion,
      }),
    );
    _ownedSessionId = sessionId;
    startHeartbeat();
  }

  /// Moves an expired session marker into the project recovery directory so a
  /// crashed previous run cannot wedge the project shut. Fail-safe: any error
  /// leaves the marker in place and keeps the project closed.
  Future<bool> _recoverStaleMarker() async {
    try {
      final marker = package.sessionFile;
      final modified = await marker.lastModified();
      final age = DateTime.now().difference(modified);
      if (age < staleAfter) return false;
      final snapshotDir = Directory(
        p.join(
          package.recoveryDirectory.path,
          'stale-session-${DateTime.now().toUtc().millisecondsSinceEpoch}',
        ),
      );
      await snapshotDir.create(recursive: true);
      await marker.copy(p.join(snapshotDir.path, 'session.lock'));
      await File(
        p.join(snapshotDir.path, 'recovered.json'),
      ).writeAsString(
        jsonEncode(<String, Object?>{
          'recoveredAt': DateTime.now().toUtc().toIso8601String(),
          'markerAgeSeconds': age.inSeconds,
          'marker': jsonDecode(await marker.readAsString()),
        }),
      );
      await marker.delete();
      return true;
    } on Object {
      return false;
    }
  }

  /// Keeps the owned marker mtime fresh so concurrent-open detection can
  /// distinguish a live session from a crashed one. Started only while a
  /// project session is open.
  void startHeartbeat() {
    _heartbeat ??= Timer.periodic(heartbeatInterval, (_) {
      _touchMarker();
    });
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _touchMarker() async {
    try {
      if (await package.sessionFile.exists()) {
        await package.sessionFile.setLastModified(DateTime.now());
      }
    } on Object {
      // A missed heartbeat only lets the marker age toward recovery.
    }
  }

  Future<void> release() async {
    stopHeartbeat();
    final owned = _ownedSessionId;
    if (owned == null) return;
    if (await package.sessionFile.exists()) {
      final marker = jsonDecode(await package.sessionFile.readAsString());
      if (marker is! Map || marker['sessionId'] != owned) return;
      await package.sessionFile.delete();
    }
    _ownedSessionId = null;
  }

  Future<bool> get hasCrashMarker async => package.sessionFile.exists();
}

class BackupIntegrityException implements Exception {
  const BackupIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'BackupIntegrityException: $message';
}

class BackupRollbackException implements Exception {
  BackupRollbackException({
    required this.emergencyBackupPath,
    required this.restoreError,
    required Map<String, Object> rollbackErrors,
  }) : rollbackErrors = Map.unmodifiable(rollbackErrors);

  final String emergencyBackupPath;
  final Object restoreError;
  final Map<String, Object> rollbackErrors;

  @override
  String toString() =>
      'BackupRollbackException: restore failed and rollback is incomplete '
      'for ${rollbackErrors.keys.join(', ')}. Emergency backup retained at '
      '$emergencyBackupPath';
}

class ProjectBackupService {
  /// Path of the most recent emergency backup created during restore,
  /// retained for the user even when the rollback itself fails.
  String? lastEmergencyBackupPath;

  Future<String> _sha256(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  Future<Map<String, String>> _directoryChecksums(Directory directory) async {
    if (!await directory.exists()) return const {};
    final files = <File>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) files.add(entity);
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    final checksums = <String, String>{};
    for (final file in files) {
      final relative = p
          .relative(file.path, from: directory.path)
          .split(p.separator)
          .join('/');
      checksums[relative] = await _sha256(file);
    }
    return checksums;
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await source.exists()) return;
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final destination = FileSystemEntity.isDirectorySync(entity.path)
          ? Directory(p.join(target.path, p.basename(entity.path)))
          : File(p.join(target.path, p.basename(entity.path)));
      if (entity is Directory) {
        await _copyDirectory(entity, destination as Directory);
      } else if (entity is File) {
        await entity.copy(destination.path);
      }
    }
  }

  Future<void> _restoreFileSnapshot(File source, File target) async {
    // Unchanged files need no write. This also preserves readable files held
    // open by another process when the original restore failed on Windows.
    if (await target.exists() &&
        await _sha256(source) == await _sha256(target)) {
      return;
    }
    await target.parent.create(recursive: true);
    await source.copy(target.path);
  }

  Future<void> _restoreDirectorySnapshot(
    Directory source,
    Directory target,
  ) async {
    final expected = <String, FileSystemEntity>{};
    if (await source.exists()) {
      await for (final entry in source.list(followLinks: false)) {
        if (entry is Link) {
          throw const BackupIntegrityException(
            'Rollback snapshot contains a link',
          );
        }
        expected[p.basename(entry.path)] = entry;
      }
    }
    if (await target.exists()) {
      await for (final entry in target.list(followLinks: false)) {
        final original = expected[p.basename(entry.path)];
        final sameKind =
            (entry is Directory && original is Directory) ||
            (entry is File && original is File);
        if (!sameKind) await entry.delete(recursive: entry is Directory);
      }
    }
    if (!await source.exists()) {
      if (await target.exists()) await target.delete();
      return;
    }
    await target.create(recursive: true);
    for (final entry in expected.values) {
      final destination = p.join(target.path, p.basename(entry.path));
      if (entry is Directory) {
        await _restoreDirectorySnapshot(entry, Directory(destination));
      } else if (entry is File) {
        await _restoreFileSnapshot(entry, File(destination));
      }
    }
  }

  Future<Directory> create({
    required ProjectPackage package,
    required String type,
    String note = '',
    Directory? destinationRoot,
  }) async {
    final id = const Uuid().v4();
    final root = destinationRoot ?? package.backupDirectory;
    final target = Directory(p.join(root.path, id));
    await target.create(recursive: true);
    await File(
      p.join(target.path, 'project.json'),
    ).writeAsBytes(await package.manifestFile.readAsBytes());
    await File(
      p.join(target.path, 'project.db'),
    ).writeAsBytes(await package.databaseFile.readAsBytes());
    final manifest = File(p.join(target.path, 'project.json'));
    final database = File(p.join(target.path, 'project.db'));
    await _copyDirectory(
      package.assetsDirectory,
      Directory(p.join(target.path, 'assets')),
    );
    await _copyDirectory(
      Directory(p.join(package.root.path, 'workspaces')),
      Directory(p.join(target.path, 'workspaces')),
    );
    await File(p.join(target.path, 'backup.json')).writeAsString(
      jsonEncode({
        'id': id,
        'projectId': package.projectId,
        'type': type,
        'schemaVersion': ProjectDatabase.currentSchemaVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'note': note,
        'files': {
          'project.json': await _sha256(manifest),
          'project.db': await _sha256(database),
        },
        'workspaceFiles': await _directoryChecksums(
          Directory(p.join(target.path, 'workspaces')),
        ),
        'assetFiles': await _directoryChecksums(
          Directory(p.join(target.path, 'assets')),
        ),
      }),
    );
    return target;
  }

  Future<void> restore({
    required ProjectPackage package,
    required Directory backup,
  }) async {
    final metadata = File(p.join(backup.path, 'backup.json'));
    final manifest = File(p.join(backup.path, 'project.json'));
    final database = File(p.join(backup.path, 'project.db'));
    if (!await metadata.exists() ||
        !await manifest.exists() ||
        !await database.exists()) {
      throw const BackupIntegrityException('Backup is incomplete');
    }
    final decoded = jsonDecode(await metadata.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const BackupIntegrityException('Invalid backup metadata');
    }
    final files = decoded['files'];
    if (files is! Map<String, dynamic> ||
        files['project.json'] != await _sha256(manifest) ||
        files['project.db'] != await _sha256(database)) {
      throw const BackupIntegrityException('Backup checksum mismatch');
    }
    final expectedWorkspaceFiles = decoded['workspaceFiles'];
    final actualWorkspaceFiles = await _directoryChecksums(
      Directory(p.join(backup.path, 'workspaces')),
    );
    if (expectedWorkspaceFiles is! Map<String, dynamic> ||
        expectedWorkspaceFiles.length != actualWorkspaceFiles.length ||
        expectedWorkspaceFiles.entries.any(
          (entry) => actualWorkspaceFiles[entry.key] != entry.value,
        )) {
      throw const BackupIntegrityException(
        'Workspace backup checksum mismatch',
      );
    }
    final expectedAssetFiles = decoded['assetFiles'];
    final actualAssetFiles = await _directoryChecksums(
      Directory(p.join(backup.path, 'assets')),
    );
    // Legacy backups without assets remain usable. A non-empty asset payload
    // without integrity evidence must never overwrite live project files.
    final legacyEmptyAssets =
        !decoded.containsKey('assetFiles') && actualAssetFiles.isEmpty;
    if (!legacyEmptyAssets &&
        (expectedAssetFiles is! Map<String, dynamic> ||
            expectedAssetFiles.length != actualAssetFiles.length ||
            expectedAssetFiles.entries.any(
              (entry) => actualAssetFiles[entry.key] != entry.value,
            ))) {
      throw const BackupIntegrityException(
        'Asset backup checksum missing or mismatched; live project unchanged',
      );
    }
    final emergency = await create(
      package: package,
      type: 'pre-restore',
      note: 'Emergency backup before restore',
    );
    lastEmergencyBackupPath = emergency.path;
    return restoreWithRollback(
      package: package,
      backup: backup,
      emergencyBackup: emergency,
    );
  }

  /// Restores the backup payload with a rollback guarantee, using the
  /// already-created emergency snapshot when provided. Every payload area
  /// is restored independently; a failing area rolls back from the
  /// emergency backup without aborting the other areas.
  @visibleForTesting
  Future<void> restoreWithRollback({
    required ProjectPackage package,
    required Directory backup,
    Directory? emergencyBackup,
  }) async {
    final emergency =
        emergencyBackup ??
        await create(
          package: package,
          type: 'pre-restore',
          note: 'Emergency backup before restore',
        );
    lastEmergencyBackupPath = emergency.path;
    try {
      await package.manifestFile.writeAsBytes(
        await File(p.join(backup.path, 'project.json')).readAsBytes(),
      );
      await package.databaseFile.writeAsBytes(
        await File(p.join(backup.path, 'project.db')).readAsBytes(),
      );
      await _copyDirectory(
        Directory(p.join(backup.path, 'assets')),
        package.assetsDirectory,
      );
      final workspaceTarget = Directory(
        p.join(package.root.path, 'workspaces'),
      );
      if (await workspaceTarget.exists()) {
        await workspaceTarget.delete(recursive: true);
      }
      await _copyDirectory(
        Directory(p.join(backup.path, 'workspaces')),
        workspaceTarget,
      );
    } catch (restoreError) {
      final failures = await rollbackPayloadAreas(
        package,
        emergency,
        manifest: () => _restoreFileSnapshot(
          File(p.join(emergency.path, 'project.json')),
          package.manifestFile,
        ),
        database: () => _restoreFileSnapshot(
          File(p.join(emergency.path, 'project.db')),
          package.databaseFile,
        ),
        assets: () => _restoreDirectorySnapshot(
          Directory(p.join(emergency.path, 'assets')),
          package.assetsDirectory,
        ),
        workspaces: () => _restoreDirectorySnapshot(
          Directory(p.join(emergency.path, 'workspaces')),
          Directory(p.join(package.root.path, 'workspaces')),
        ),
      );
      if (failures.isNotEmpty) {
        throw BackupRollbackException(
          emergencyBackupPath: emergency.path,
          restoreError: restoreError,
          rollbackErrors: failures,
        );
      }
      rethrow;
    }
  }

  /// Restores every payload area from [emergency] independently so a
  /// failing area cannot prevent the others from returning to their
  /// pre-restore state. Returns per-area rollback failures keyed by area.
  @visibleForTesting
  Future<Map<String, Object>> rollbackPayloadAreas(
    ProjectPackage package,
    Directory emergency, {
    Future<void> Function()? manifest,
    Future<void> Function()? database,
    Future<void> Function()? assets,
    Future<void> Function()? workspaces,
  }) async {
    final failures = <String, Object>{};
    Future<void> attempt(String area, Future<void> Function()? restore) async {
      if (restore == null) return;
      try {
        await restore();
      } catch (error) {
        failures[area] = error;
      }
    }

    await attempt('manifest', manifest);
    await attempt('database', database);
    await attempt('assets', assets);
    await attempt('workspaces', workspaces);
    return failures;
  }
}

class ProjectCacheService {
  const ProjectCacheService(this.package);
  final ProjectPackage package;
  Future<void> clear() async {
    if (!await package.cacheDirectory.exists()) return;
    await for (final entity in package.cacheDirectory.list()) {
      await entity.delete(recursive: true);
    }
  }
}

class ProjectTrashService {
  const ProjectTrashService(this.package);
  final ProjectPackage package;
  Future<File> moveToTrash(File source, {String? entityId}) async {
    final sourceAbsolute = p.normalize(p.absolute(source.path));
    final packageRoot = p.normalize(p.absolute(package.root.path));
    if (!p.isWithin(packageRoot, sourceAbsolute)) {
      throw ArgumentError.value(
        source.path,
        'source',
        'must be inside project',
      );
    }
    final id = const Uuid().v4();
    final target = File(
      p.join(
        package.trashDirectory.path,
        'files',
        '$id${p.extension(source.path)}',
      ),
    );
    await target.parent.create(recursive: true);
    await source.rename(target.path);
    await File(p.join(package.trashDirectory.path, '$id.json')).writeAsString(
      jsonEncode({
        'id': id,
        'originalPath': p
            .relative(sourceAbsolute, from: packageRoot)
            .replaceAll('\\', '/'),
        'trashPath': p
            .relative(target.path, from: packageRoot)
            .replaceAll('\\', '/'),
        'entityId': entityId,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return target;
  }

  Future<void> restore(File trashed, String originalPath) async {
    final target = File(originalPath);
    await target.parent.create(recursive: true);
    await trashed.rename(target.path);
  }
}
