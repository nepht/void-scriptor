import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/persistence/restore_staging_journal.dart';
import '../../../core/project_package/project_package.dart';
import '../../../core/project_package/void_project_format.dart';
import '../../../database/project/project_database.dart';

typedef ProcessLivenessProbe = Future<bool> Function(int processId);

/// Identity probe: wall-clock start time (epoch ms) of the process that
/// CURRENTLY holds [processId], or null when unknowable (vs-hunt-20260915-
/// resilience BUG-3). Liveness alone cannot distinguish the recorded owner
/// from an unrelated process that reused the PID; start time can, because a
/// PID reborn AFTER the marker was written cannot be the marker's author.
typedef ProcessStartProbe = Future<int?> Function(int processId);

class ProjectSessionLock {
  ProjectSessionLock(
    this.package, {
    ProcessLivenessProbe? isProcessAlive,
    ProcessStartProbe? processStartMs,
  }) : _isProcessAlive = isProcessAlive ?? _platformProcessIsAlive,
       _processStartMs = processStartMs ?? _platformProcessStartMs;

  final ProjectPackage package;
  final ProcessLivenessProbe _isProcessAlive;
  final ProcessStartProbe _processStartMs;
  String? _ownedSessionId;

  Future<void> acquire({String? appVersion}) async {
    // Atomic create: checking exists before writing allows concurrent writers.
    // Age alone is never evidence that an owner died. A marker may only be
    // recovered automatically when it carries a PID that the OS proves dead.
    try {
      await package.sessionFile.create(exclusive: true);
    } on FileSystemException {
      if (!await package.sessionFile.exists()) rethrow;
      if (!await _recoverDeadOwnerMarker()) {
        throw StateError('Project has an active or stale session');
      }
      await package.sessionFile.create(exclusive: true);
    }
    final sessionId = const Uuid().v4();
    // If metadata writing fails, preserve the marker and fail closed.
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': sessionId,
        'projectId': package.projectId,
        'processId': pid,
        'openedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion ?? VoidProjectFormat.applicationVersion,
      }),
      flush: true,
    );
    _ownedSessionId = sessionId;
  }

  /// vs-hunt-20260915-resilience BUG-3 (REAL BUG, Critical): liveness PID
  /// saja bukan bukti kepemilikan. Windows dapat mengembalikan sebuah PID ke
  /// proses lain setelah pemilik marker mati; tanpa identitas start-time,
  /// holder hasil reuse dianggap 'owner hidup' dan proyek terkunci selama
  /// proses tak terkait itu hidup. Sebaliknya, holder yang terbukti DIMULAI
  /// setelah marker ditulis tidak mungkin penulis marker itu — PID-nya
  /// direbut, jadi recovery sah. Ambiguitas (probe gagal, waktu tak diketahui,
  /// clock skew dalam [pidReuseGrace]) selalu berpihak pada pemilik:
  /// fail-closed.
  static const Duration pidReuseGrace = Duration(seconds: 60);

  Future<bool> _recoverDeadOwnerMarker() async {
    Map<String, dynamic> marker;
    try {
      marker =
          jsonDecode(await package.sessionFile.readAsString())
              as Map<String, dynamic>;
    } on Object {
      return false;
    }
    final ownerPid = marker['processId'];
    if (ownerPid is! int || ownerPid <= 0) {
      return false;
    }
    if (await _isProcessAlive(ownerPid) &&
        !await _holderProvesPidReuse(marker['openedAt'], ownerPid)) {
      return false;
    }

    final snapshot = Directory(
      p.join(
        package.recoveryDirectory.path,
        'stale-session-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      ),
    );
    await snapshot.create(recursive: true);
    await package.sessionFile.copy(p.join(snapshot.path, 'session.lock'));
    await package.sessionFile.delete();
    return true;
  }

  static Future<bool> _platformProcessIsAlive(int processId) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', [
          '/FI',
          'PID eq $processId',
          '/NH',
        ]);
        if (result.exitCode != 0) return true;
        return result.stdout.toString().contains(RegExp('\\s$processId\\s'));
      }
      final result = await Process.run('ps', [
        '-p',
        '$processId',
        '-o',
        'pid=',
      ]);
      if (result.exitCode != 0) return false;
      return result.stdout.toString().trim() == '$processId';
    } on Object {
      // Probe failure must never displace an owner.
      return true;
    }
  }

  /// True only when the OS proves the CURRENT holder of [ownerPid] started
  /// strictly after the marker's `openedAt` (+ [pidReuseGrace]) — i.e. the
  /// recorded PID was recycled by an unrelated process and the real owner is
  /// gone. Unknown times, unparsable markers, and results inside the grace
  /// window all return false so recovery stays fail-closed.
  Future<bool> _holderProvesPidReuse(Object? rawOpenedAt, int ownerPid) async {
    if (rawOpenedAt is! String) return false;
    final openedAt = DateTime.tryParse(rawOpenedAt);
    if (openedAt == null) return false;
    int? startMs;
    try {
      startMs = await _processStartMs(ownerPid);
    } on Object {
      return false;
    }
    if (startMs == null) return false;
    final threshold =
        openedAt.toUtc().millisecondsSinceEpoch + pidReuseGrace.inMilliseconds;
    // Clamp against the local clock: if the recorded write time is in the
    // future (clock skew), the comparison proves nothing — protect.
    if (openedAt.toUtc().millisecondsSinceEpoch >
        DateTime.now().toUtc().millisecondsSinceEpoch) {
      return false;
    }
    return startMs > threshold;
  }

  /// Platform start time (epoch ms) of the current holder of [processId],
  /// or null when unknowable. Windows CIM `CreationDate` is local wall-clock
  /// time with no UTC offset, so the rendered digits are parsed as local
  /// before converting to epoch UTC; the format string is numeric-only
  /// (no month names), so culture cannot garble the digits. Any failure
  /// reports null — never a guess. Non-Windows hosts report null: this
  /// session-lock failure mode is the Windows local-first path, and an
  /// unknown identity must stay fail-closed like the legacy behavior.
  static Future<int?> _platformProcessStartMs(int processId) async {
    if (!Platform.isWindows) return null;
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '\$ErrorActionPreference="SilentlyContinue";'
            "(Get-CimInstance Win32_Process -Filter 'ProcessId=$processId')"
            '.CreationDate.ToString("yyyyMMddHHmmss")',
      ]);
      if (result.exitCode != 0) return null;
      final out = result.stdout.toString().trim();
      final match = RegExp(
        r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$',
      ).firstMatch(out);
      if (match == null) return null;
      final local = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
      );
      return local.toUtc().millisecondsSinceEpoch;
    } on Object {
      return null;
    }
  }

  Future<void> release() async {
    final owned = _ownedSessionId;
    if (owned == null) return;
    try {
      if (await package.sessionFile.exists()) {
        final marker = jsonDecode(await package.sessionFile.readAsString());
        if (marker is! Map || marker['sessionId'] != owned) return;
        await _deleteWithTransientRetry(package.sessionFile);
      }
    } on PathNotFoundException {
      // A concurrent teardown can remove the package before exists, read, or
      // delete completes. In every case the owned marker is already absent.
    }
    _ownedSessionId = null;
  }

  /// Windows can transiently refuse a marker delete with a sharing
  /// violation (errno 32) while another closer, antivirus scan, or
  /// indexer still holds a read handle. The competing delete usually
  /// wins an instant later, so existence is re-checked between bounded
  /// retries; a hold that outlives the window is rethrown so release
  /// stays fail-closed instead of silently leaking the marker.
  Future<void> _deleteWithTransientRetry(File marker) async {
    const attempts = 5;
    const delays = [
      Duration(milliseconds: 10),
      Duration(milliseconds: 25),
      Duration(milliseconds: 50),
      Duration(milliseconds: 100),
    ];
    for (var attempt = 0; ; attempt++) {
      try {
        await marker.delete();
        return;
      } on PathNotFoundException {
        return;
      } on FileSystemException {
        if (attempt >= attempts - 1) rethrow;
        if (!await marker.exists()) return;
        await Future<void>.delayed(delays[attempt]);
      }
    }
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
      'for ${rollbackErrors.keys.join(', ')}. Restore error: $restoreError. '
      'Emergency backup retained at $emergencyBackupPath';
}

class ProjectBackupService {
  /// Path of the most recent emergency backup created during restore,
  /// retained for the user even when the rollback itself fails.
  String? lastEmergencyBackupPath;

  /// 145.42 two-phase restore test seam: invoked once after every payload
  /// area has been staged and journaled but BEFORE any live byte is moved.
  /// Throwing here must leave the live payload byte-identical.
  @visibleForTesting
  Future<void> Function()? onStagingCompleteForTesting;

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
    // A previous restore killed inside the crash window leaves staging
    // artifacts behind. Heal them before touching the live payload so a
    // partial write can never be mistaken for restore output.
    await RestoreCrashRecovery.recover(package);
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

  /// Restores the backup payload in two phases with a rollback guarantee,
  /// using the already-created emergency snapshot when provided. Phase one
  /// stages every backup area inside the package and journals the staged
  /// fingerprints; phase two swaps each staged copy into its live position
  /// through a rename window. A hard kill therefore either leaves the live
  /// payload byte-intact (before placement) or a journaled, verifiable
  /// staged copy that the next [RestoreCrashRecovery.recover] rolls forward.
  /// Every payload area that fails mid-placement still rolls back
  /// independently from the emergency backup without aborting the others.
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
    // ---- Phase 1: stage + journal. No live byte changes here. ----
    final workspacesRoot = Directory(p.join(package.root.path, 'workspaces'));
    final stagedManifest = File('${package.manifestFile.path}.tmp');
    final stagedDatabase = File('${package.databaseFile.path}.tmp');
    final stagedAssets = Directory('${package.assetsDirectory.path}.tmp');
    final stagedWorkspaces = Directory('${workspacesRoot.path}.tmp');
    await stagedManifest.parent.create(recursive: true);
    await stagedDatabase.parent.create(recursive: true);
    await stagedManifest.writeAsBytes(
      await File(p.join(backup.path, 'project.json')).readAsBytes(),
      flush: true,
    );
    await stagedDatabase.writeAsBytes(
      await File(p.join(backup.path, 'project.db')).readAsBytes(),
      flush: true,
    );
    final backupAssets = Directory(p.join(backup.path, 'assets'));
    final hasBackupAssets = await backupAssets.exists();
    if (hasBackupAssets) {
      await _copyDirectory(backupAssets, stagedAssets);
    }
    final backupWorkspaces = Directory(p.join(backup.path, 'workspaces'));
    if (await backupWorkspaces.exists()) {
      await _copyDirectory(backupWorkspaces, stagedWorkspaces);
    } else if (await stagedWorkspaces.exists()) {
      await stagedWorkspaces.delete(recursive: true);
    }
    final staged = <String, FileSystemEntity>{
      RestoreStagingJournal.manifestArea: stagedManifest,
      RestoreStagingJournal.databaseArea: stagedDatabase,
      if (hasBackupAssets) RestoreStagingJournal.assetsArea: stagedAssets,
      RestoreStagingJournal.workspacesArea: stagedWorkspaces,
    };
    staged.removeWhere((area, entity) => !_entityOnDisk(entity.path));
    final journal = await RestoreStagingJournal.create(package, staged: staged);
    final seam = onStagingCompleteForTesting;
    if (seam != null) {
      try {
        await seam();
      } on Object {
        // The seam throws while the live payload is still untouched: drop
        // the scratch, never leave a journal that could be mistaken for an
        // interrupted placement.
        await _purgeStaging(package, journal);
        rethrow;
      }
    }
    // ---- Phase 2: place each journaled area through the rename window.
    try {
      for (final area in RestoreStagingJournal.areaOrder) {
        if (!journal.areas.containsKey(area)) continue;
        await placeStagedEntity(
          staged: journal.stagedEntity(area),
          live: _liveEntityFor(package, area),
        );
      }
      await journal.consume();
    } catch (restoreError) {
      // Undo any swap displacement left inside a placement window: each
      // area's `<live>.restore-old` (pre-placement content) returns to the
      // live path, after which the emergency rollback below rewrites every
      // area to the same durable state. No stray scratch may survive.
      for (final area in journal.areas.keys) {
        try {
          await restoreDisplacedOriginal(
            livePath: _liveEntityFor(package, area).path,
          );
        } on FileSystemException {
          // Best-effort: rollbackPayloadAreas still rebuilds the area from
          // the emergency snapshot; that failure is reported per-area.
        }
      }
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
          workspacesRoot,
        ),
      );
      await _purgeStaging(package, journal);
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

  static bool _entityOnDisk(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  static FileSystemEntity _liveEntityFor(ProjectPackage package, String area) =>
      restoreLiveEntityFor(package, area);

  /// Drops the journal and every staged scratch entity it names. Only ever
  /// called while the live payload is provably untouched or already fully
  /// rolled back.
  Future<void> _purgeStaging(
    ProjectPackage package,
    RestoreStagingJournal journal,
  ) async {
    for (final area in RestoreStagingJournal.areaOrder) {
      if (!journal.areas.containsKey(area)) continue;
      final entity = journal.stagedEntity(area);
      try {
        if (entity is Directory) {
          if (await entity.exists()) await entity.delete(recursive: true);
        } else if (entity is File) {
          if (await entity.exists()) await entity.delete();
        }
      } on FileSystemException {
        // Best-effort: RestoreCrashRecovery sweeps leftovers next open.
      }
    }
    await journal.consume();
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

/// Crash-window recovery for interrupted backup restores. A two-phase
/// restore that is killed leaves a `recovery/restore-staging.json` journal
/// naming its staged payload copies. On the next session open (or before
/// the next restore) recovery completes the interrupted operation: every
/// staged copy that still matches its journaled fingerprint is rolled
/// forward into the live payload; staged copies that diverged or vanished
/// are discarded scratch and can never overwrite live content. Without a
/// journal, legacy '<final>.tmp' staging residue is swept as before. The
/// emergency pre-restore snapshot is deliberately preserved for
/// user-driven recovery decisions.
class RestoreCrashRecovery {
  RestoreCrashRecovery(this.package);
  final ProjectPackage package;

  /// Removes or rolls forward staging artifacts from an interrupted
  /// [ProjectBackupService] restore. Returns the number of staging
  /// artifacts that were healed or swept.
  static Future<int> recover(ProjectPackage package) async {
    var removed = 0;
    final journal = await RestoreStagingJournal.load(package);
    if (journal != null) {
      for (final area in RestoreStagingJournal.areaOrder) {
        if (!journal.areas.containsKey(area)) continue;
        final staged = journal.stagedEntity(area);
        if (await journal.stagedMatches(area)) {
          // The corpse on disk is provably the exact copy the restore was
          // about to place: complete the interrupted restore.
          await placeStagedEntity(
            staged: staged,
            live: restoreLiveEntityFor(package, area),
          );
          removed++;
        } else if (await _stagedExists(staged)) {
          // Divergent scratch is never authoritative; live content stays.
          await _deleteStaged(staged);
          removed++;
        }
      }
      await journal.consume();
      return removed;
    }
    final journalFile = File(RestoreStagingJournal.journalPathFor(package));
    if (await journalFile.exists()) {
      // Structurally invalid journal: it cannot direct a roll-forward, and
      // leaving it would re-block every later restore. Sweep it with the
      // scratch below without counting it as a healed artifact.
      await journalFile.delete();
    }
    final manifestTmp = File('${package.manifestFile.path}.tmp');
    if (await manifestTmp.exists()) {
      await manifestTmp.delete();
      removed++;
    }
    final databaseTmp = File('${package.databaseFile.path}.tmp');
    if (await databaseTmp.exists()) {
      await databaseTmp.delete();
      removed++;
    }
    final assetsTmp = Directory('${package.assetsDirectory.path}.tmp');
    if (await assetsTmp.exists()) {
      await assetsTmp.delete(recursive: true);
      removed++;
    }
    final workspacesDir = Directory(p.join(package.root.path, 'workspaces'));
    final workspacesTmp = Directory('${workspacesDir.path}.tmp');
    if (await workspacesTmp.exists()) {
      await workspacesTmp.delete(recursive: true);
      removed++;
    }
    return removed;
  }

  static Future<bool> _stagedExists(FileSystemEntity staged) async =>
      FileSystemEntity.typeSync(staged.path) != FileSystemEntityType.notFound;

  static Future<void> _deleteStaged(FileSystemEntity staged) async {
    if (staged is Directory) {
      await staged.delete(recursive: true);
    } else if (staged is File) {
      await staged.delete();
    }
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
