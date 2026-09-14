import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_move_service.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

// 145.42 USB-real session finding (2026-09-14): Directory.rename refuses to
// cross volume boundaries (Windows errno 17, POSIX EXDEV 18), so "Move
// Project" to a USB drive — the primary use case of 145.42 — silently failed
// at the picker-confirm step on real hardware. The fix keeps the rename fast
// path on one volume and falls back to a staged copy-verify-delete when the
// rename reports a cross-device error. The rename is injectable so the
// fallback branch is deterministic on CI (no second volume needed).
void main() {
  late Directory tempRoot;
  late Directory sourceRoot;
  late Directory destinationRoot;
  late Directory package;
  const projectId = 'xvol-move-project';

  ProjectManifest buildManifest() => ProjectManifest(
    schemaVersion: 1,
    id: projectId,
    name: 'XVOL Move',
    description: '',
    projectVersion: '1.0.0',
    createdAt: DateTime.utc(2026, 9, 14),
    updatedAt: DateTime.utc(2026, 9, 14),
    appVersion: 'test',
  );

  String markerPath(String packagePath) =>
      p.join(packagePath, ProjectRecoveryService.movePendingMarkerName);

  Future<void> seedCompletePackage(Directory pkg) async {
    Directory(p.join(pkg.path, 'manifest')).createSync();
    await File(
      p.join(pkg.path, 'manifest', 'project.json'),
    ).writeAsString(jsonEncode(buildManifest().toJson()), flush: true);
    Directory(p.join(pkg.path, 'database')).createSync();
    await File(
      p.join(pkg.path, 'database', 'project.db'),
    ).writeAsString('sqlite fixture', flush: true);
    Directory(p.join(pkg.path, 'assets')).createSync();
    await File(
      p.join(pkg.path, 'assets', 'cover.png'),
    ).writeAsBytes(List.filled(4096, 7), flush: true);
  }

  Future<int> countFiles(Directory dir) async {
    var n = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) n++;
    }
    return n;
  }

  Future<int> totalBytes(Directory dir) async {
    var total = 0;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      total += await f.length();
    }
    return total;
  }

  FileSystemException crossVolumeError(String path) => FileSystemException(
    'Rename failed',
    path,
    const OSError('cannot move to a different disk drive', 17),
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vs_move_xvol_');
    sourceRoot = Directory(p.join(tempRoot.path, 'source'))..createSync();
    destinationRoot = Directory(p.join(tempRoot.path, 'destination'))
      ..createSync();
    package = Directory(p.join(sourceRoot.path, '$projectId.voidproject'))
      ..createSync();
    await seedCompletePackage(package);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test(
    'cross-volume rename error falls back to copy-move: package lands '
    'complete at destination, source is gone, journal travelled with it',
    () async {
      final service = ProjectMoveService(
        renameOverride: (from, to) => throw crossVolumeError(from),
      );

      final moved = await service.movePackage(
        package: package,
        destinationRoot: destinationRoot,
      );

      expect(
        moved.path,
        p.join(destinationRoot.path, '$projectId.voidproject'),
      );
      expect(await moved.exists(), isTrue);
      expect(await Directory(package.path).exists(), isFalse);

      // Content integrity of the staged copy.
      final db = File(p.join(moved.path, 'database', 'project.db'));
      expect(await db.readAsString(), 'sqlite fixture');
      final cover = File(p.join(moved.path, 'assets', 'cover.png'));
      expect((await cover.readAsBytes()).length, 4096);
      final manifestFile = File(p.join(moved.path, 'manifest', 'project.json'));
      expect(
        ProjectManifest.fromJson(
          jsonDecode(await manifestFile.readAsString()),
        ).id,
        projectId,
      );

      // The journal marker was inside the package before the move and must
      // travel with it, so a crash between copy-completion and the registry
      // repoint stays recoverable (same contract as the rename fast path).
      expect(
        await File(markerPath(moved.path)).exists(),
        isTrue,
        reason: 'move journal must land inside the moved package',
      );
    },
  );

  test('staged copy is verified before the source is removed: file count and '
      'total bytes must match the source tree', () async {
    final service = ProjectMoveService(
      renameOverride: (from, to) => throw crossVolumeError(from),
    );

    final sourceCount = await countFiles(package);
    final sourceBytes = await totalBytes(package);
    final moved = await service.movePackage(
      package: package,
      destinationRoot: destinationRoot,
    );

    // 3 content files + 1 journal marker travelled together.
    expect(await countFiles(moved), sourceCount + 1);
    expect(
      await totalBytes(moved),
      sourceBytes + (await File(markerPath(moved.path)).length()),
    );
    // No staging leftovers next to the final package.
    final strays = destinationRoot
        .listSync()
        .where((e) => !p.equals(e.path, moved.path))
        .toList();
    expect(strays, isEmpty);
  });

  test('occupied destination aborts the move before any copy: source and '
      'journal untouched at origin, error surfaces', () async {
    final target = Directory(
      p.join(destinationRoot.path, '$projectId.voidproject'),
    )..createSync();
    await File(p.join(target.path, 'occupant.txt')).writeAsString('x');

    final service = ProjectMoveService(
      renameOverride: (from, to) => throw crossVolumeError(from),
    );

    await expectLater(
      service.movePackage(package: package, destinationRoot: destinationRoot),
      throwsA(isA<FileSystemException>()),
    );

    expect(await Directory(package.path).exists(), isTrue);
    expect(
      await File(markerPath(package.path)).exists(),
      isFalse,
      reason: 'failed move must consume its journal, like the rename path',
    );
    expect(await countFiles(target), 1);
  });

  test('non-cross-device rename errors do NOT trigger the copy fallback: '
      'source stays, journal consumed, original error rethrown', () async {
    final service = ProjectMoveService(
      renameOverride: (from, to) => throw FileSystemException(
        'Rename failed',
        from,
        const OSError('Access is denied', 5),
      ),
    );

    await expectLater(
      service.movePackage(package: package, destinationRoot: destinationRoot),
      throwsA(isA<FileSystemException>()),
    );

    expect(await Directory(package.path).exists(), isTrue);
    expect(await File(markerPath(package.path)).exists(), isFalse);
    expect(
      await Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      ).exists(),
      isFalse,
      reason: 'errno 5 must never start a staged copy',
    );
  });

  // 145.42 failure matrix (kanonik: remaining disk_full, permission_loss):
  // the staged cross-volume copy must refuse BEFORE it touches the journal
  // or copies a single byte when the destination cannot hold or accept the
  // package. Source untouched, no staging, no marker, human-readable cause.
  test('disk-full destination refuses the move before writing the journal: '
      'source untouched, no staging, explicit cause', () async {
    final packageBytes = await totalBytes(package);
    final service = ProjectMoveService(
      renameOverride: (from, to) => throw crossVolumeError(from),
      spaceReader: _FixedSpaceReader(packageBytes - 1),
    );
    await expectLater(
      service.movePackage(package: package, destinationRoot: destinationRoot),
      throwsA(
        isA<FileSystemException>().having(
          (e) => e.message,
          'message',
          contains('space'),
        ),
      ),
    );
    expect(await Directory(package.path).exists(), isTrue);
    expect(
      await File(markerPath(package.path)).exists(),
      isFalse,
      reason: 'a refused preflight must not leave a journal behind',
    );
    expect(
      await Directory(
        p.join(destinationRoot.path, '$projectId.voidproject'),
      ).exists(),
      isFalse,
    );
    expect(
      await Directory(
        p.join(destinationRoot.path, '$projectId.voidproject.xvol-staging'),
      ).exists(),
      isFalse,
    );
  });

  test('space reader that cannot measure does NOT block the move', () async {
    final service = ProjectMoveService(
      renameOverride: (from, to) => throw crossVolumeError(from),
      spaceReader: const _FixedSpaceReader(-1),
    );
    final moved = await service.movePackage(
      package: package,
      destinationRoot: destinationRoot,
    );
    expect(await moved.exists(), isTrue);
  });

  test('write-permission probe on the destination refuses the move before '
      'any copy: source untouched, explicit permission cause', () async {
    // Simulate a read-only destination the way the matrix simulates disk
    // full: occupy the exact probe path with a directory so its create()
    // fails like an access denial would.
    await Directory(
      p.join(destinationRoot.path, ProjectMoveService.writeProbeName),
    ).create();
    final service = ProjectMoveService(
      renameOverride: (from, to) => throw crossVolumeError(from),
    );
    await expectLater(
      service.movePackage(package: package, destinationRoot: destinationRoot),
      throwsA(
        isA<FileSystemException>().having(
          (e) => e.message,
          'message',
          contains('permission'),
        ),
      ),
    );
    expect(await Directory(package.path).exists(), isTrue);
    expect(
      await File(markerPath(package.path)).exists(),
      isFalse,
      reason: 'a refused preflight must not leave a journal behind',
    );
  });

  test('default relocation wiring carries the platform space reader', () {
    final relocation = ProjectRelocationService(
      registry: ProjectRegistryService(rootDirectory: Directory('nowhere')),
    );
    expect(
      relocation.moveService.spaceReader,
      isA<PlatformDriveSpaceReader>(),
      reason:
          'production movePackage must run the disk-full preflight by '
          'default; a null reader here means the 145.42 preflight was '
          'silently dropped from the UI path',
    );
  });
}

class _FixedSpaceReader implements HostDriveSpaceReader {
  const _FixedSpaceReader(this.free);
  final int free;

  @override
  Future<int> freeBytes(String location) async => free;
}
