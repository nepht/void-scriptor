import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';

class _GatedProbe implements StorageHealthProbe {
  _GatedProbe({required this.entered, required this.release});

  final Completer<void> entered;
  final Completer<void> release;

  @override
  Future<StorageHealth> check(String location) async {
    entered.complete();
    await release.future;
    return const StorageHealth(
      writable: true,
      freeBytes: 10 * 1024 * 1024,
      reason: StorageProbeReason.ok,
    );
  }
}

class _GenerousProbe implements StorageHealthProbe {
  const _GenerousProbe();

  @override
  Future<StorageHealth> check(String location) async => const StorageHealth(
    writable: true,
    freeBytes: 10 * 1024 * 1024,
    reason: StorageProbeReason.ok,
  );
}

/// bug-hunt run197 BUG-9: the store's read-modify-write mutations ran
/// without serialization, so an overlapping mutation could build its
/// state from a stale load and clobber the other mutation's field.
Future<bool> _waitUntil(
  Future<bool> Function() condition, {
  required Duration timeout,
  required Duration poll,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return true;
    await Future<void>.delayed(poll);
  }
  return await condition();
}

void main() {
  late Directory tempRoot;
  late Directory otherRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('cust_mutex_active');
    otherRoot = await Directory.systemTemp.createTemp('cust_mutex_other');
  });

  tearDown(() async {
    for (final dir in <Directory>[tempRoot, otherRoot]) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException catch (_) {}
    }
  });

  test('concurrent mutation waits behind an in-flight activation', () async {
    final store = CustomStorageLocationStore(
      registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
    );
    final entered = Completer<void>();
    final release = Completer<void>();
    final probe = _GatedProbe(entered: entered, release: release);

    final activation = store.setActiveLocation(tempRoot.path, health: probe);
    await entered.future.timeout(const Duration(seconds: 5));

    final bind = store.bindProject('proj-9f2');

    // Give a non-serialized implementation a real chance to land its
    // write while the activation is parked mid-mutation.
    final wroteEarly = await _waitUntil(
      () async => store.registryFile.existsSync(),
      timeout: const Duration(milliseconds: 500),
      poll: const Duration(milliseconds: 10),
    );
    expect(
      wroteEarly,
      isFalse,
      reason:
          'bindProject must not write the registry while setActiveLocation '
          'holds the store mid-mutation (BUG-9 lost-update window)',
    );

    release.complete();
    await activation;
    await bind;

    final state = await store.load();
    expect(state.activeLocation, tempRoot.path);
    expect(state.boundProjectId, 'proj-9f2');
  });

  test(
    'queued failing mutation propagates its error and preserves state',
    () async {
      final store = CustomStorageLocationStore(
        registryFile: File(p.join(tempRoot.path, 'storage_locations.json')),
      );
      await store.setActiveLocation(
        tempRoot.path,
        health: const _GenerousProbe(),
      );
      await store.bindProject('proj-stays');

      // The relink target does not contain the bound project package.
      await expectLater(
        store.relinkLocation(otherRoot.path, health: const _GenerousProbe()),
        throwsStateError,
      );

      final state = await store.load();
      expect(state.activeLocation, tempRoot.path);
      expect(state.boundProjectId, 'proj-stays');
    },
  );
}
