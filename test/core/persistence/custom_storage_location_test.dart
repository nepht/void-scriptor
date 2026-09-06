import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

class _TightHealth implements StorageHealthProbe {
  const _TightHealth();

  @override
  Future<StorageHealth> check(String location) async {
    return const StorageHealth(
      writable: false,
      freeBytes: 0,
      reason: StorageProbeReason.permissionDenied,
    );
  }
}

/// Writes a legacy registry file with a relative activeLocation (test-only
/// seam): simulates registry content produced by an older build so tests
/// can prove the load path stays readable without round-tripping through
/// the store write API.
void _writeLegacyRegistrySync(Directory root) {
  File(p.join(root.path, 'storage_locations.json')).writeAsStringSync(
    '{"schemaVersion":1,"activeLocation":"legacy-relative-store","boundProjectId":null}\n',
  );
}

void main() {
  late Directory tempRoot;
  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('cust_storage');
  });
  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  group('CustomStorageLocation domain contract', () {
    test(
      'normalizeLocation trims whitespace and trailing separators, rejects empty',
      () {
        final padded = '  ${tempRoot.path}${p.separator}  ';
        final cleaned = CustomStorageLocation.normalizeLocation(padded);
        expect(cleaned, tempRoot.path);
        expect(
          () => CustomStorageLocation.normalizeLocation('   '),
          throwsArgumentError,
        );
        expect(
          () => CustomStorageLocation.normalizeLocation(''),
          throwsArgumentError,
        );
      },
    );

    test('probe reports missing drive for absent root', () async {
      final missing = p.join(tempRoot.path, 'not-there');
      final results = await CustomStorageLocation.probe(missing);
      expect(results.exists, isFalse);
      expect(results.writable, isFalse);
      expect(results.reason, StorageProbeReason.driveMissing);
    });

    test('probe accepts a writable directory and reports free space', () async {
      final results = await CustomStorageLocation.probe(tempRoot.path);
      expect(results.exists, isTrue);
      expect(results.writable, isTrue);
      expect(results.freeBytes, greaterThanOrEqualTo(0));
    });

    test(
      'probe delegates health to injected probe (permission denied seam)',
      () async {
        final results = await CustomStorageLocation.probe(
          tempRoot.path,
          health: const _TightHealth(),
        );
        expect(results.exists, isTrue);
        expect(results.writable, isFalse);
        expect(results.reason, StorageProbeReason.permissionDenied);
      },
    );

    test(
      'setActiveLocation validates then persists, rejects truly missing drive',
      () async {
        final store = CustomStorageLocationStore(
          registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
        );
        final target = p.join(tempRoot.path, 'NovelStore');
        await store.setActiveLocation(target);
        var loaded = await store.load();
        expect(loaded.activeLocation, target);
        expect(loaded.schemaVersion, 1);

        // A drive letter with no ancestor is rejected
        final noDrive = 'Z:${p.separator}SomeDir';
        await expectLater(store.setActiveLocation(noDrive), throwsStateError);
        loaded = await store.load();
        expect(loaded.activeLocation, target);
      },
    );

    test(
      'missing persisted drive reports missingDrive and relink restores health',
      () async {
        final store = CustomStorageLocationStore(
          registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
        );
        final target = p.join(tempRoot.path, 'NovelStore');
        await store.setActiveLocation(target);

        // Simulate missing drive by deleting the target
        await Directory(target).delete(recursive: true);
        final after = await store.load();
        expect(after.status, StorageLocationStatus.missingDrive);

        // Recreate to simulate relink
        await Directory(target).create(recursive: true);
        await store.relinkLocation(target);
        final healed = await store.load();
        expect(healed.status, StorageLocationStatus.healthy);
        expect(healed.activeLocation, target);
      },
    );

    test('relink refuses location without bound project', () async {
      final store = CustomStorageLocationStore(
        registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
      );
      final target = p.join(tempRoot.path, 'NovelStore');
      await store.setActiveLocation(target);
      await store.bindProject('proj-1');

      final stranger = p.join(tempRoot.path, 'SomeOtherStore');
      Directory(stranger).createSync(recursive: true);
      await expectLater(store.relinkLocation(stranger), throwsStateError);
    });

    test(
      'nearestExistingAncestor returns null for absent drive and existing dir for usable path',
      () async {
        final ancestor = await CustomStorageLocation.nearestExistingAncestor(
          tempRoot.path,
        );
        expect(ancestor, isNotNull);

        final noAncestor = await CustomStorageLocation.nearestExistingAncestor(
          'Z:${p.separator}NoSuchDir',
        );
        expect(noAncestor, isNull);
      },
    );
  });

  group('PlatformDriveSpaceReader (bug-hunt run94 BUG-09)', () {
    test('freeBytes call returns before the host probe completes', () async {
      const reader = PlatformDriveSpaceReader();
      final sw = Stopwatch()..start();
      final pending = reader.freeBytes(tempRoot.path);
      final callLatencyMs = sw.elapsedMilliseconds;
      await pending;
      // Process.runSync blocked the caller for the whole PowerShell spawn
      // (~500 ms on this host). Process.run yields a pending future fast.
      expect(callLatencyMs, lessThan(200));
    });

    test(
      'freeBytes still resolves a live budget or the unknown signal',
      () async {
        const reader = PlatformDriveSpaceReader();
        final free = await reader.freeBytes(tempRoot.path);
        if (Platform.isWindows) {
          expect(free, greaterThan(0));
        } else {
          expect(free, -1);
        }
      },
    );
  });

  group(
    'normalizeLocation absolute-path rejection (bug-hunt run94 BUG-10)',
    () {
      test('rejects relative paths instead of CWD-anchoring storage', () {
        expect(
          () => CustomStorageLocation.normalizeLocation('relative-store'),
          throwsArgumentError,
        );
        expect(
          () => CustomStorageLocation.normalizeLocation('./relative-store'),
          throwsArgumentError,
        );
      });

      test('rejects drive-relative Windows paths that shift with the CWD', () {
        expect(
          () => CustomStorageLocation.normalizeLocation('C:relative-store'),
          throwsArgumentError,
        );
      });

      test(
        'still accepts absolute roots including a bare drive root unstripped',
        () {
          final driveRoot = p.rootPrefix(tempRoot.path);
          expect(CustomStorageLocation.normalizeLocation(driveRoot), driveRoot);
          expect(
            CustomStorageLocation.normalizeLocation(tempRoot.path),
            tempRoot.path,
          );
        },
      );

      test(
        'setActiveLocation rejects a relative location without touching state',
        () async {
          final registryFile = File(
            p.join(tempRoot.path, 'storage_locations.json'),
          );
          final store = CustomStorageLocationStore(registryFile: registryFile);
          // The buggy path creates the CWD-relative directory before failing;
          // the teardown keeps the repo worktree clean either way.
          final stray = Directory('relative-store');
          addTearDown(() {
            if (stray.existsSync()) stray.deleteSync();
          });
          await expectLater(
            store.setActiveLocation('relative-store'),
            throwsArgumentError,
          );
          expect(registryFile.existsSync(), isFalse);
          final loaded = await store.load();
          expect(loaded.activeLocation, isNull);
        },
      );
    },
  );

  group('legacy registry compatibility (bug-hunt run94 BUG-10 follow-up)', () {
    test(
      'load keeps a legacy relative activeLocation readable without throwing',
      () async {
        _writeLegacyRegistrySync(tempRoot);
        final store = CustomStorageLocationStore(
          registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
        );
        final loaded = await store.load();
        expect(loaded.activeLocation, 'legacy-relative-store');
      },
    );
  });
}
