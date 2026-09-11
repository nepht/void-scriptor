import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/settings/presentation/storage_locations_screen.dart';

/// 145.38 storage settings wiring (plan 2026-09-11 Task 4 step 1).
///
/// Surfaces REAL store state (no invented numbers) via the production
/// [CustomStorageLocationStore] with an injected probe seam.
///
/// Harness contract (run140/run213 lesson): readiness is polled against the
/// WIDGET TREE, never against store internals — `cachedState` is assigned
/// inside `_read()` before the screen's `setState` continuation runs, so an
/// internal predicate can pass while the tree still shows the loading card.
/// Each poll iteration interleaves a real event-loop yield (`runAsync`,
/// delivers file IO) with a fake-zone `pump()` (delivers await resumptions
/// and the resulting rebuild).
void main() {
  late Directory tempRoot;
  late Directory customDrive;
  late File registryFile;
  late CustomStorageLocationStore store;
  late _RecordingProbe probe;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-storage-ui-');
    customDrive = Directory(
      '${tempRoot.path}${Platform.pathSeparator}custom-drive',
    );
    await customDrive.create(recursive: true);
    registryFile = File(
      '${tempRoot.path}${Platform.pathSeparator}storage_locations.json',
    );
    store = CustomStorageLocationStore(registryFile: registryFile);
    probe = _RecordingProbe(
      const StorageHealth(
        writable: true,
        freeBytes: 10485760,
        reason: StorageProbeReason.ok,
      ),
    );
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Widget wrap() => ProviderScope(
    overrides: [customStorageStoreProvider.overrideWith((ref) async => store)],
    child: MaterialApp(home: StorageLocationsScreen(healthProbe: probe)),
  );

  Future<void> drainUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 200; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      finder.evaluate().isNotEmpty,
      isTrue,
      reason: 'finder never appeared: $finder',
    );
  }

  Future<void> pumpReady(WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await drainUntil(tester, find.text('Belum ada lokasi kustom aktif'));
  }

  testWidgets('menampilkan state toko nyata saat belum ada lokasi aktif', (
    tester,
  ) async {
    await pumpReady(tester);

    expect(
      find.byKey(const ValueKey('storage-set-active-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('storage-set-active-submit')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('storage-relink-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('storage-relink-submit')), findsOneWidget);
    expect(find.byKey(const ValueKey('storage-probe-run')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menampilkan lokasi aktif dan bound project dari store nyata', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await store.setActiveLocation(customDrive.path, health: probe);
      await store.bindProject('proj-1');
    });

    await tester.pumpWidget(wrap());
    await drainUntil(tester, find.textContaining(customDrive.path));

    expect(find.textContaining('proj-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'set active lokasi valid memanggil store dengan probe terinjeksi',
    (tester) async {
      await pumpReady(tester);

      await tester.enterText(
        find.byKey(const ValueKey('storage-set-active-field')),
        customDrive.path,
      );
      await tester.tap(find.byKey(const ValueKey('storage-set-active-submit')));
      // Scope to the status card: the text field itself already contains the
      // typed path and would satisfy a naive textContaining finder.
      await drainUntil(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('storage-status-card')),
          matching: find.textContaining(customDrive.path),
        ),
      );
      // Ground truth via the mutex-free cached state (mutation completed).
      expect(store.cachedState?.activeLocation, customDrive.path);
      expect(probe.checkedPaths, contains(customDrive.path));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('set active gagal ketika probe menolak dan pesan error tampil', (
    tester,
  ) async {
    probe.next = const StorageHealth(
      writable: false,
      freeBytes: 0,
      reason: StorageProbeReason.permissionDenied,
    );

    await pumpReady(tester);

    await tester.enterText(
      find.byKey(const ValueKey('storage-set-active-field')),
      customDrive.path,
    );
    await tester.tap(find.byKey(const ValueKey('storage-set-active-submit')));
    await drainUntil(tester, find.textContaining('permissionDenied'));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(store.cachedState?.activeLocation, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('relink lokasi memanggil store', (tester) async {
    await tester.runAsync(
      () => store.setActiveLocation(customDrive.path, health: probe),
    );
    await tester.pumpWidget(wrap());
    await drainUntil(tester, find.textContaining(customDrive.path));

    final before = probe.checkedPaths.length;
    await tester.enterText(
      find.byKey(const ValueKey('storage-relink-field')),
      customDrive.path,
    );
    await tester.tap(find.byKey(const ValueKey('storage-relink-submit')));
    await drainUntil(
      tester,
      find.byKey(const ValueKey('storage-relink-result')),
    );

    expect(probe.checkedPaths.length, greaterThan(before));
    expect(store.cachedState?.activeLocation, customDrive.path);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'probe manual menampilkan hasil bertipe (writable + ruang bebas)',
    (tester) async {
      await pumpReady(tester);

      await tester.enterText(
        find.byKey(const ValueKey('storage-probe-field')),
        customDrive.path,
      );
      await tester.tap(find.byKey(const ValueKey('storage-probe-run')));
      await drainUntil(tester, find.textContaining('writable'));

      expect(find.textContaining('gratis'), findsOneWidget);
      expect(probe.checkedPaths, contains(customDrive.path));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tidak overflow di lebar sempit 390px', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpReady(tester);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingProbe implements StorageHealthProbe {
  _RecordingProbe(this.initial);

  StorageHealth initial;
  StorageHealth? next;
  final List<String> checkedPaths = [];

  @override
  Future<StorageHealth> check(String location) async {
    checkedPaths.add(location);
    return next ?? initial;
  }
}
