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

  test(
    'movePackage relocates the package and consumes the journal marker',
    () async {
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
      expect(await File(markerPath(target.path)).exists(), isFalse);
    },
  );

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
}
