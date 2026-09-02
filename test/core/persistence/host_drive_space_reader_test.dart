import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

class _FixedReader implements HostDriveSpaceReader {
  const _FixedReader(this.bytes);

  final int bytes;

  @override
  Future<int> freeBytes(String location) async => bytes;
}

void main() {
  late Directory tempRoot;
  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('host_drive_space');
  });
  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  group('HostDriveSpaceReader contract', () {
    test(
      'default platform reader reports a non-negative value on this host',
      () async {
        const reader = PlatformDriveSpaceReader();
        final bytes = await reader.freeBytes(tempRoot.path);
        expect(bytes, greaterThanOrEqualTo(0));
      },
    );

    test(
      'probe reports notEnoughSpace when injected reader reports below minFreeBytes',
      () async {
        final results = await CustomStorageLocation.probe(
          tempRoot.path,
          health: const DefaultStorageProbe(
            spaceReader: _FixedReader(512 * 1024),
          ),
        );
        expect(results.exists, isTrue);
        expect(results.writable, isTrue);
        expect(results.freeBytes, 512 * 1024);
        expect(results.reason, StorageProbeReason.notEnoughSpace);
      },
    );

    test(
      'probe reports ok when injected reader reports sufficient space',
      () async {
        final results = await CustomStorageLocation.probe(
          tempRoot.path,
          health: const DefaultStorageProbe(
            spaceReader: _FixedReader(5 * 1024 * 1024),
          ),
        );
        expect(results.exists, isTrue);
        expect(results.writable, isTrue);
        expect(results.freeBytes, 5 * 1024 * 1024);
        expect(results.reason, StorageProbeReason.ok);
      },
    );

    test(
      'relink flow end-to-end restores health at a target containing the bound project',
      () async {
        final store = CustomStorageLocationStore(
          registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
        );
        final original = p.join(tempRoot.path, 'NovelStore');
        await store.setActiveLocation(original);
        await store.bindProject('proj-relink-1');

        // Simulate drive loss then a relink to a new drive that contains the package.
        await Directory(original).delete(recursive: true);
        final relocated = p.join(tempRoot.path, 'RelocatedStore');
        await Directory(
          p.join(relocated, 'proj-relink-1.voidproject'),
        ).create(recursive: true);

        await store.relinkLocation(relocated);
        final healed = await store.load();
        expect(healed.status, StorageLocationStatus.healthy);
        expect(healed.activeLocation, relocated);
        expect(healed.boundProjectId, 'proj-relink-1');
      },
    );
  });
}
