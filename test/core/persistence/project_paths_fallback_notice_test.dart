import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';

/// core-hunt-20260906 BUG-12, option 1: the missingDrive→Documents fallback
/// is a codified contract (wiring test) and is preserved; consumers get an
/// explicit typed signal (lastFallbackNotice) so the silent split-brain
/// becomes observable instead of invisible.
void main() {
  late Directory tempRoot;
  late Directory customDrive;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('core-hunt-20260906-bug12-');
    customDrive = Directory(p.join(tempRoot.path, 'drive'));
    await customDrive.create(recursive: true);
  });
  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<CustomStorageLocationStore> activatedStore() async {
    final registryFile = File('${tempRoot.path}/storage_locations.json');
    final store = CustomStorageLocationStore(registryFile: registryFile);
    await store.setActiveLocation(customDrive.path);
    return store;
  }

  group('core-hunt-20260906 fallback signal (BUG-12)', () {
    test('fallback keeps working and records a typed notice', () async {
      final store = await activatedStore();
      final paths = ProjectPaths(
        customStorageStore: store,
        fallbackRootDirectory: tempRoot,
      );
      await customDrive.delete(recursive: true);

      final root = await paths.root();

      expect(root.path, tempRoot.path);
      final state = await store.load();
      expect(state.status, StorageLocationStatus.missingDrive);
      final notice = paths.lastFallbackNotice;
      expect(notice, isNotNull);
      expect(notice!.reason, StorageFallbackReason.missingDrive);
      expect(notice.requestedLocation, customDrive.path);
      expect(notice.effectiveRoot.path, tempRoot.path);
    });

    test('healthy custom location produces no notice', () async {
      final store = await activatedStore();
      final paths = ProjectPaths(
        customStorageStore: store,
        fallbackRootDirectory: tempRoot,
      );

      await paths.root();

      expect(paths.lastFallbackNotice, isNull);
    });

    test('notice is cleared once the drive returns', () async {
      final store = await activatedStore();
      final paths = ProjectPaths(
        customStorageStore: store,
        fallbackRootDirectory: tempRoot,
      );
      await customDrive.delete(recursive: true);
      await paths.root();
      expect(paths.lastFallbackNotice, isNotNull);

      await customDrive.create(recursive: true);
      await paths.root();
      expect(paths.lastFallbackNotice, isNull);
    });

    test('no custom store configured: no notice', () async {
      final paths = ProjectPaths(
        fallbackRootDirectory: tempRoot,
      );
      await paths.root();
      expect(paths.lastFallbackNotice, isNull);
    });
  });
}
