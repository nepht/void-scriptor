import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

class _TightSpace implements StorageHealthProbe {
  const _TightSpace();

  @override
  Future<StorageHealth> check(String location) async => const StorageHealth(
    writable: true,
    freeBytes: 512 * 1024, // below CustomStorageLocation.minFreeBytes (1 MiB)
    reason: StorageProbeReason.notEnoughSpace,
  );
}

class _GenerousSpace implements StorageHealthProbe {
  const _GenerousSpace();

  @override
  Future<StorageHealth> check(String location) async => const StorageHealth(
    writable: true,
    freeBytes: 10 * 1024 * 1024,
    reason: StorageProbeReason.ok,
  );
}

void main() {
  late Directory tempRoot;
  late File registryFile;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('core-hunt-20260906-');
    registryFile = File(
      '${tempRoot.path}${Platform.pathSeparator}storage_locations.json',
    );
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  group('core-hunt-20260906 min-free-space enforcement (BUG-14)', () {
    test('setActiveLocation rejects a notEnoughSpace location without '
        'touching the registry', () async {
      final store = CustomStorageLocationStore(registryFile: registryFile);
      final target = p.join(tempRoot.path, 'TightStore');
      await Directory(target).create(recursive: true);

      await expectLater(
        store.setActiveLocation(target, health: const _TightSpace()),
        throwsA(isA<StateError>()),
      );

      // Rejection happens before any persistence: no registry file, and
      // a fresh load reports no active location.
      expect(await registryFile.exists(), isFalse);
      final state = await store.load();
      expect(state.activeLocation, isNull);
    });

    test('relinkLocation rejects a notEnoughSpace target and keeps the '
        'current binding', () async {
      final store = CustomStorageLocationStore(registryFile: registryFile);
      final good = p.join(tempRoot.path, 'GoodStore');
      await Directory(good).create(recursive: true);
      await store.setActiveLocation(good, health: const _GenerousSpace());
      await store.bindProject('proj-1');

      final tight = p.join(tempRoot.path, 'TightStore');
      await Directory(tight).create(recursive: true);

      await expectLater(
        store.relinkLocation(tight, health: const _TightSpace()),
        throwsA(isA<StateError>()),
      );

      final state = await store.load();
      expect(state.activeLocation, good);
      expect(state.boundProjectId, 'proj-1');
    });
  });
}
