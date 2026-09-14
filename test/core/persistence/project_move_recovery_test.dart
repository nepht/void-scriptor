import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_move_service.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

// 145.42 interrupted-move failure matrix: a package move is journaled with
// `move-pending.marker` before the rename opens the crash window. Process
// kill / power loss inside that window must be recoverable without data
// loss: roll-forward to the recorded destination, or a clean stay-at-source
// when the rename itself failed.
void main() {
  late Directory tempRoot;
  late Directory sourceRoot;
  late Directory destinationRoot;
  late Directory package;
  const projectId = 'move-test-project';

  ProjectManifest buildManifest() => ProjectManifest(
    schemaVersion: 1,
    id: projectId,
    name: 'Move Test',
    description: '',
    projectVersion: '1.0.0',
    createdAt: DateTime.utc(2026, 9, 6),
    updatedAt: DateTime.utc(2026, 9, 6),
    appVersion: 'test',
  );

  String markerPath(String packagePath) =>
      p.join(packagePath, ProjectRecoveryService.movePendingMarkerName);

  Future<void> seedCompletePackage(Directory pkg) async {
    Directory(p.join(pkg.path, 'manifest')).createSync();
    await File(
      p.join(pkg.path, 'manifest', 'project.json'),
    ).writeAsString(jsonEncode(buildManifest().toJson()), flush: true);
    // Package completeness (run94/core-hunt BUG-6): admission requires an
    // on-disk manifest AND the database file, so a partial package moved
    // out from under a journal is never surfaced.
    Directory(p.join(pkg.path, 'database')).createSync();
    await File(
      p.join(pkg.path, 'database', 'project.db'),
    ).writeAsString('sqlite fixture', flush: true);
  }

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vs_move_recovery_');
    sourceRoot = Directory(p.join(tempRoot.path, 'source'))..createSync();
    destinationRoot = Directory(p.join(tempRoot.path, 'destination'))
      ..createSync();
    package = Directory(p.join(sourceRoot.path, '$projectId.voidproject'))
      ..createSync();
    Directory(p.join(package.path, 'manifest')).createSync();
    await File(
      p.join(package.path, 'manifest', 'project.json'),
    ).writeAsString(jsonEncode(buildManifest().toJson()), flush: true);
  });

  tearDown(() {
    try {
      tempRoot.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort: a lingering temp dir must not fail the suite.
    }
  });

  test('movePackage relocates the package and leaves the landed journal for '
      'durable-state consumption (bug-hunt vs-hunt-20260911 BUG-3)', () async {
    final target = await const ProjectMoveService().movePackage(
      package: package,
      destinationRoot: destinationRoot,
    );

    expect(p.basename(target.path), '$projectId.voidproject');
    expect(await package.exists(), isFalse);
    expect(
      await File(p.join(target.path, 'manifest', 'project.json')).exists(),
      isTrue,
    );
    // BUG-3 contract change: the old code deleted the travelled journal
    // inside movePackage, while the registry entry was still stale.
    // Durability first (the registry's own move-recovery rule): the
    // journal survives until a caller has made the repointed listing
    // durable; the relocation service consumes it right after the
    // upsert and the registry's landed-marker sweep is the safety net.
    expect(await File(markerPath(target.path)).exists(), isTrue);
  });

  test('the move journal survives while the registry entry is still stale '
      '(bug-hunt vs-hunt-20260911 BUG-3)', () async {
    // Reproduces the exact crash window: the probe observes disk state
    // after movePackage returned and before ProjectRelocationService's
    // registry.upsert ran (production seam moveService, real services).
    // Old order: journal already deleted there — a process kill at that
    // point left a healthy package with zero journal and a stale entry,
    // invisible to every documented safety net.
    final registry = ProjectRegistryService(rootDirectory: tempRoot);
    await seedCompletePackage(package);
    final model = ProjectModel(
      id: projectId,
      name: 'Move Test',
      description: '',
      createdAt: DateTime.utc(2026, 9, 6),
      updatedAt: DateTime.utc(2026, 9, 6),
      lastOpenedAt: DateTime.utc(2026, 9, 6),
      localPath: package.path,
      version: '1.0.0',
    );
    await registry.save([model]);

    Object? journalAtCrashWindow;
    final service = ProjectRelocationService(
      registry: registry,
      moveService: _CrashWindowProbeMoveService((moved) async {
        journalAtCrashWindow = await File(markerPath(moved.path)).exists();
      }),
    );
    final moved = await service.relocateProject(
      projectId: projectId,
      destinationRoot: destinationRoot,
    );

    expect(
      journalAtCrashWindow,
      isTrue,
      reason:
          'the journal must still be on disk while the entry names the old location',
    );
    final entry = (await registry.load()).firstWhere(
      (project) => project.id == projectId,
    );
    expect(entry.localPath, moved.path, reason: 'entry repointed');
    expect(
      await File(markerPath(moved.path)).exists(),
      isFalse,
      reason: 'once the repoint is durable the stale journal is drained',
    );
  });

  test(
    'a process kill before the rename rolls forward to the recorded destination',
    () async {
      // Simulated crash window: the journal marker is durable on disk, the
      // rename never happened. Recovery scans the source root.
      await File(markerPath(package.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': package.path,
          'destination': p.join(destinationRoot.path, '$projectId.voidproject'),
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );

      final moved = await const ProjectRecoveryService()
          .recoverInterruptedMoves(sourceRoot);

      expect(moved, 1);
      expect(await package.exists(), isFalse);
      final restored = Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      );
      expect(await restored.exists(), isTrue);
      expect(
        await File(p.join(restored.path, 'manifest', 'project.json')).exists(),
        isTrue,
      );
      expect(await File(markerPath(restored.path)).exists(), isFalse);
    },
  );

  test(
    'a marker at the destination is stale and consumed without moving',
    () async {
      // Crash between the successful rename and marker consumption: the
      // package is already at the destination and still carries the marker.
      final target = Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      )..createSync(recursive: true);
      Directory(p.join(target.path, 'manifest')).createSync();
      await File(
        p.join(target.path, 'manifest', 'project.json'),
      ).writeAsString(jsonEncode(buildManifest().toJson()), flush: true);
      await File(markerPath(target.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': sourceRoot.path,
          'destination': target.path,
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );

      final moved = await const ProjectRecoveryService()
          .recoverInterruptedMoves(destinationRoot);

      expect(moved, 0);
      expect(await target.exists(), isTrue);
      expect(await File(markerPath(target.path)).exists(), isFalse);
    },
  );

  test(
    'a failed rename keeps the package at the source and consumes the journal',
    () async {
      // Obstacle occupies the destination path: rename fails, marker consumed,
      // source package untouched.
      await File(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      ).writeAsString('not a directory', flush: true);

      await expectLater(
        const ProjectMoveService().movePackage(
          package: package,
          destinationRoot: destinationRoot,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await package.exists(), isTrue);
      expect(
        await File(p.join(package.path, 'manifest', 'project.json')).exists(),
        isTrue,
      );
      expect(await File(markerPath(package.path)).exists(), isFalse);
    },
  );

  test(
    'registry load consumes a move marker left at the destination',
    () async {
      final service = ProjectRegistryService(rootDirectory: tempRoot);
      final model = ProjectModel(
        id: projectId,
        name: 'Move Test',
        description: '',
        createdAt: DateTime.utc(2026, 9, 6),
        updatedAt: DateTime.utc(2026, 9, 6),
        lastOpenedAt: DateTime.utc(2026, 9, 6),
        localPath: package.path,
        version: '1.0.0',
      );
      await service.save([model]);
      // Crash after the move into the registry root, before consumption.
      await File(markerPath(package.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': sourceRoot.path,
          'destination': package.path,
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );

      final loaded = await service.load();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, projectId);
      expect(await File(markerPath(package.path)).exists(), isFalse);
    },
  );

  // Bug-hunt run197 BUG-7: the roll-forward half of the interrupted-move
  // contract was never wired into production. `_loadUnlocked` consumed
  // landed destination markers of REGISTERED projects, but a package
  // stranded at its source (crash BEFORE the rename) or landed without a
  // registry entry (crash AFTER the rename, before the entry persisted)
  // was invisible: unregistered packages are never discovered. The
  // documented contract in project_move_service.dart promises the
  // registry's roll-forward scan; 145.42 acceptance `interrupted_move`
  // requires recovery to actually run. Referee fix direction: wire the
  // recovery into `_loadUnlocked` — the two halves must ship together.
  test(
    'registry load rolls a source-stranded package forward and admits it',
    () async {
      // Process kill BEFORE the rename: the package sits in the registry
      // root's legacy `Projects` subdirectory (an owner directory of the
      // file-branch wiring) carrying its durable journal; the destination
      // never materialized; the registry has no entry for the project.
      final stranded = Directory(
        p.join(destinationRoot.path, 'Projects', '$projectId.voidproject'),
      )..createSync(recursive: true);
      await seedCompletePackage(stranded);
      await File(markerPath(stranded.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': stranded.path,
          'destination': p.join(destinationRoot.path, '$projectId.voidproject'),
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      await File(
        p.join(destinationRoot.path, 'projects.json'),
      ).writeAsString(jsonEncode({'schemaVersion': 1, 'projects': []}));

      final service = ProjectRegistryService(rootDirectory: destinationRoot);
      final loaded = await service.load();

      // The stranded package must be rolled forward, admitted, and visible.
      final destination = Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      );
      expect(await destination.exists(), isTrue);
      expect(
        await File(
          p.join(destination.path, 'manifest', 'project.json'),
        ).exists(),
        isTrue,
      );
      expect(await stranded.exists(), isFalse);
      expect(await File(markerPath(destination.path)).exists(), isFalse);
      expect(loaded.map((project) => project.id), contains(projectId));
      expect(
        loaded.firstWhere((project) => project.id == projectId).localPath,
        destination.path,
      );
    },
  );

  test(
    'registry load repoints the registered entry of a rolled-forward package',
    () async {
      // A registered project whose move was interrupted BEFORE the rename:
      // the registry entry still points at the source. Recovery must roll
      // the package forward AND repoint the entry, or the project opens
      // into a path that no longer exists.
      final service = ProjectRegistryService(rootDirectory: tempRoot);
      final inHomePackage = Directory(
        p.join(tempRoot.path, '$projectId.voidproject'),
      );
      // Move the setUp package into the registry home (an owner directory).
      await package.rename(inHomePackage.path);
      final archivedRoot = Directory(p.join(tempRoot.path, 'Archived'))
        ..createSync();
      final model = ProjectModel(
        id: projectId,
        name: 'Move Test',
        description: '',
        createdAt: DateTime.utc(2026, 9, 6),
        updatedAt: DateTime.utc(2026, 9, 6),
        lastOpenedAt: DateTime.utc(2026, 9, 6),
        localPath: inHomePackage.path,
        version: '1.0.0',
      );
      await service.save([model]);
      await File(markerPath(inHomePackage.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': inHomePackage.path,
          'destination': p.join(archivedRoot.path, '$projectId.voidproject'),
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );

      final loaded = await service.load();

      final destination = Directory(
        p.join(archivedRoot.path, '$projectId.voidproject'),
      );
      expect(await destination.exists(), isTrue);
      expect(await inHomePackage.exists(), isFalse);
      expect(
        loaded.firstWhere((project) => project.id == projectId).localPath,
        destination.path,
      );
      // The repoint is durable: a fresh service reads the healed listing.
      final reloaded = await ProjectRegistryService(
        rootDirectory: tempRoot,
      ).load();
      expect(
        reloaded.firstWhere((project) => project.id == projectId).localPath,
        destination.path,
      );
      // The travelled journal is consumed once the healed entry is durable.
      expect(await File(markerPath(destination.path)).exists(), isFalse);
    },
  );

  test(
    'registry load consumes a landed journal of an unregistered package without resurrecting it',
    () async {
      // Crash AFTER the successful rename, BEFORE the registry entry was
      // persisted. BUG-7's fix scope is the roll-forward half; this case
      // pins the pre-existing contract around it: the landed journal is
      // stale state and is consumed, and the package is NOT admitted —
      // folders without an explicit creation marker are deliberately
      // unregistered state and must never be resurrected by a listing
      // (the same posture protects explicit removals, run197 BUG-19).
      final landed = Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      )..createSync(recursive: true);
      await seedCompletePackage(landed);
      await File(markerPath(landed.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': p.join(sourceRoot.path, '$projectId.voidproject'),
          'destination': landed.path,
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      await File(
        p.join(destinationRoot.path, 'projects.json'),
      ).writeAsString(jsonEncode({'schemaVersion': 1, 'projects': []}));

      final loaded = await ProjectRegistryService(
        rootDirectory: destinationRoot,
      ).load();

      expect(loaded, isEmpty);
      expect(await File(markerPath(landed.path)).exists(), isFalse);
      expect(await landed.exists(), isTrue);
    },
  );

  test(
    'registry load leaves an occupied-destination journal untouched',
    () async {
      // A destination already occupied by a same-name directory is never
      // guessed around: the journal and the stranded package stay for
      // inspection (the non-guessing contract of
      // recoverInterruptedMoves).
      final inHomePackage = Directory(
        p.join(tempRoot.path, '$projectId.voidproject'),
      );
      await package.rename(inHomePackage.path);
      final archivedRoot = Directory(p.join(tempRoot.path, 'Archived'))
        ..createSync();
      final service = ProjectRegistryService(rootDirectory: tempRoot);
      await service.save([
        ProjectModel(
          id: projectId,
          name: 'Move Test',
          description: '',
          createdAt: DateTime.utc(2026, 9, 6),
          updatedAt: DateTime.utc(2026, 9, 6),
          lastOpenedAt: DateTime.utc(2026, 9, 6),
          localPath: inHomePackage.path,
          version: '1.0.0',
        ),
      ]);
      await File(markerPath(inHomePackage.path)).writeAsString(
        jsonEncode({
          'projectId': projectId,
          'source': inHomePackage.path,
          'destination': p.join(archivedRoot.path, '$projectId.voidproject'),
          'writtenAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      // Obstacle: the recorded destination is already occupied.
      Directory(
        p.join(archivedRoot.path, '$projectId.voidproject'),
      ).createSync();

      final loaded = await service.load();

      // Nothing was destroyed by the load: the stranded package and its
      // journal remain at the source for inspection; the entry still
      // points at the source.
      expect(await inHomePackage.exists(), isTrue);
      expect(await File(markerPath(inHomePackage.path)).exists(), isTrue);
      expect(
        loaded.firstWhere((project) => project.id == projectId).localPath,
        inHomePackage.path,
      );
    },
  );
}

/// Crash-window probe (bug-hunt vs-hunt-20260911 BUG-3): a production
/// [ProjectMoveService] that observes the journal state at the exact
/// moment the old code consumed it — after the rename landed and before
/// the caller's registry.upsert made the repoint durable.
class _CrashWindowProbeMoveService implements ProjectMoveService {
  _CrashWindowProbeMoveService(this._onMoved);

  final Future<void> Function(Directory moved) _onMoved;

  // The probe never injects a rename; it delegates to the real service and
  // only observes the journal after the move lands.
  @override
  final Future<Directory> Function(String from, String to)? renameOverride =
      null;

  @override
  Future<Directory> movePackage({
    required Directory package,
    required Directory destinationRoot,
  }) async {
    final moved = await const ProjectMoveService().movePackage(
      package: package,
      destinationRoot: destinationRoot,
    );
    await _onMoved(moved);
    return moved;
  }
}
