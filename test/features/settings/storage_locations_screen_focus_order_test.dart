import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/settings/presentation/storage_locations_screen.dart';

/// Storage Locations — kontrak focus order WCAG 2.4.3.
///
/// Diverifikasi dengan probe pada viewport 1536x1024 / dpr 1.0 memakai
/// `customStorageStoreProvider` di-override ke store dengan registry file di
/// direktori temporer (tanpa database/network).
///
/// Urutan Tab:
///   storage-refresh (AppBar) -> Set lokasi aktif field -> Jalankan
///   -> Relink lokasi field -> Jalankan -> Probe lokasi field -> Jalankan
///   -> (wrap) storage-refresh ...
///
/// Catatan label: `Text` non-Icon pertama di subpohon fokus dipakai lebih
/// dulu (tiga tombol aksi sama-sama berlabel `Jalankan`). IconButton refresh
/// dan ketiga `TextField` tidak punya teks di dalam subpohon fokus (decoration
/// `labelText` dirender di luar node fokus), jadi label jatuh ke
/// `ValueKey<String>` terdekat pada rantai leluhur — kunci yang memang dipasang
/// layar ini (`storage-refresh`, `storage-*-field`).
const _expectedLabels = <String>[
  'storage-refresh',
  'storage-set-active-field',
  'Jalankan',
  'storage-relink-field',
  'Jalankan',
  'storage-probe-field',
  'Jalankan',
];

/// Ambil label stop: teks non-Icon pertama di subpohon fokus; jika tidak ada,
/// pakai `ValueKey<String>` terdekat pada rantai leluhur.
String _labelOf(BuildContext context) {
  final element = context as Element;
  var label = '';
  void visit(Element node) {
    if (label.isNotEmpty) return;
    final widget = node.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (label.isEmpty) {
    element.visitAncestorElements((ancestor) {
      final key = ancestor.widget.key;
      if (key is ValueKey<String> && key.value.isNotEmpty) {
        label = key.value;
        return false;
      }
      return true;
    });
  }
  return label.isEmpty ? 'widget:${element.widget.runtimeType}' : label;
}

({String label, Rect rect})? _currentStop() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final object = context.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(context), rect: rect);
}

/// Tekan Tab sampai rect pertama berulang; berhenti TEPAT pada stop pertama
/// siklus kedua sehingga `stops` memuat urutan lengkap satu putaran.
Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  Rect? first;
  for (var i = 0; i < 24; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    if (first != null && stop.rect == first) break;
    first ??= stop.rect;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pump(
  WidgetTester tester,
  CustomStorageLocationStore store,
) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customStorageStoreProvider.overrideWith((ref) async => store),
      ],
      child: const MaterialApp(home: StorageLocationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Directory tempRoot;
  late CustomStorageLocationStore store;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-fo-contract-');
    final registryFile = File(
      '${tempRoot.path}${Platform.pathSeparator}storage_locations.json',
    );
    store = CustomStorageLocationStore(registryFile: registryFile);
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  group('Storage Locations — kontrak focus order 2.4.3', () {
    testWidgets('1. tujuh stop dengan urutan label yang dikunci', (
      tester,
    ) async {
      await _pump(tester, store);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(FilledButton), findsNWidgets(3));
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason:
            'Tab must walk the AppBar refresh action, then each action card '
            'field -> submit button top-to-bottom.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. area fokus non-zero dan geometri per kartu aksi', (
      tester,
    ) async {
      await _pump(tester, store);
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      // Refresh AppBar ada di baris paling atas, di sisi kanan layar.
      expect(stops.first.rect.top, lessThan(stops[1].rect.top));
      expect(stops.first.rect.left, greaterThan(stops[1].rect.left));
      // Tiga kartu aksi turun atas-ke-bawah (top field: 244 -> 388 -> 532).
      for (final i in const [3, 5]) {
        expect(
          stops[i].rect.top,
          greaterThan(stops[i - 2].rect.top),
          reason: 'Action cards must stack top-to-bottom (stop $i).',
        );
      }
      // Di dalam tiap kartu aksi: field di kiri, tombol di kanan.
      for (final i in const [1, 3, 5]) {
        expect(
          stops[i].rect.left,
          lessThan(stops[i + 1].rect.left),
          reason:
              'Field must sit left of its submit button inside the action '
              'card (stop $i).',
        );
        // Field 24px dan tombol 40px dipusatkan pada baris yang sama.
        expect(
          (stops[i].rect.center.dy - stops[i + 1].rect.center.dy).abs(),
          lessThanOrEqualTo(1.0),
          reason:
              'Field and its submit button share one row (stop $i vs '
              '${i + 1}).',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Tab setelah stop terakhir kembali ke refresh AppBar', (
      tester,
    ) async {
      await _pump(tester, store);
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi lanjut ke field pertama — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
      expect(tester.takeException(), isNull);
    });
  });
}
