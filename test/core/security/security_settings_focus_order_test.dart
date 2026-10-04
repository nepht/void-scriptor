import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/security/presentation/security_settings_screen.dart';
import 'package:void_scriptor/database/project/project_database.dart';

/// Kontrak fokus WCAG 2.4.3 — Security Settings (Keamanan & Enkripsi).
///
/// Harness: layar dipush ke Navigator (cara rute aplikasi membuka layar) sehingga
/// affordance back pada AppBar ikut teraudit. Viewport desktop 1536x1024, dpr 1.0.
///
/// Deviasi cakupan (dicatat di laporan fase 81): kolam kandidat di
/// `lib/features/*/presentation/*_screen.dart` terbukti habis (28 file sisa,
/// semuanya 0-1 stop terukur), sehingga pemilihan jatuh ke layar `lib/core`
/// yang memenuhi ambang "minimal 2 elemen interaktif" tanpa fixture jaringan.
const double _viewportWidth = 1536;
const double _viewportHeight = 1024;

/// Label fokus: pesan Tooltip > hint/label TextField > teks pertama non-icon.
String focusOrderLabel(BuildContext ctx) {
  final root = ctx as Element;
  final tooltip = root.findAncestorWidgetOfExactType<Tooltip>();
  final msg = tooltip?.message?.trim();
  if (msg != null && msg.isNotEmpty) return msg;
  final field = root.findAncestorWidgetOfExactType<TextField>();
  final hint =
      field?.decoration?.hintText ?? field?.decoration?.labelText ?? '';
  if (hint.trim().isNotEmpty) return hint.trim();
  final queue = <BuildContext>[root];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Icon) continue;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) return data.trim();
    }
    current.visitChildElements(queue.add);
  }
  return '<non-text:${ctx.widget.runtimeType}>';
}

/// Tekan Tab berulang, catat label + Rect tiap stop, berhenti saat Rect berulang.
Future<List<({String label, Rect rect})>> collectFocusStops(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 20; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    if (node == null) break;
    if (node.context?.widget is FocusScope) break;
    final ctx = node.context!;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) break;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final label = focusOrderLabel(ctx);
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}|$label';
    if (!seen.add(key)) break;
    stops.add((label: label, rect: rect));
  }
  return stops;
}

void _useDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(_viewportWidth, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Fixture minimal: database drift in-memory (tanpa file, tanpa jaringan).
/// Cukup membuat `onChanged` switch aktif; tidak ada derivasi kunci.
ProjectDatabase _memDb() {
  final db = ProjectDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Future<void> _pushScreen(WidgetTester tester, Widget screen) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      home: const SizedBox.expand(child: Text('seed')),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('focus order 2.4.3: Back -> Enkripsi Proyek -> Ubah Passphrase '
      '(3 stop, atas-ke-bawah) pada rute yang dipush', (tester) async {
    _useDesktopViewport(tester);
    final db = _memDb();
    await _pushScreen(
      tester,
      SecuritySettingsScreen(
        projectId: 'p1',
        database: db,
        onChangePassphrase: () {},
      ),
    );

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(3));
    expect(stops.map((s) => s.label).toList(), <String>[
      'Back',
      'Enkripsi Proyek',
      'Ubah Passphrase',
    ]);

    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0), reason: stop.label);
      expect(stop.rect.height, greaterThan(0), reason: stop.label);
      expect(stop.rect.width, lessThanOrEqualTo(_viewportWidth));
      expect(stop.rect.height, lessThanOrEqualTo(_viewportHeight));
    }

    // Back ada di AppBar, kiri-atas.
    expect(stops[0].rect.left, lessThanOrEqualTo(16));
    expect(stops[0].rect.top, lessThanOrEqualTo(16));

    // Urutan atas-ke-bawah mengikuti urutan visual (ListView), tanpa lompatan.
    expect(stops[1].rect.top, greaterThan(stops[0].rect.top));
    expect(stops[2].rect.top, greaterThan(stops[1].rect.top));

    // Kedua baris isi rata kiri pada padding yang sama dan melebar penuh.
    expect(stops[1].rect.left, stops[2].rect.left);
    expect(stops[1].rect.left, greaterThan(0));
    expect(
      stops[1].rect.right,
      greaterThanOrEqualTo(_viewportWidth - 16),
      reason: 'baris switch melebar sampai padding kanan',
    );
    expect(
      stops[2].rect.right,
      greaterThanOrEqualTo(_viewportWidth - 16),
      reason: 'baris passphrase melebar sampai padding kanan',
    );

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order 2.4.3: tanpa database switch disabled keluar dari '
      'tab order (1 stop: Ubah Passphrase)', (tester) async {
    _useDesktopViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: SecuritySettingsScreen(onChangePassphrase: () {})),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(1));
    expect(stops.single.label, 'Ubah Passphrase');
    expect(stops.single.rect.width, greaterThan(0));
    expect(stops.single.rect.height, greaterThan(0));
    expect(stops.single.rect.left, greaterThan(0));
    expect(stops.single.rect.top, greaterThan(16));

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'focus order 2.4.3: tanpa rute induk urutan isi tetap atas-ke-bawah '
    '(2 stop)',
    (tester) async {
      _useDesktopViewport(tester);
      final db = _memDb();
      await tester.pumpWidget(
        MaterialApp(
          home: SecuritySettingsScreen(
            projectId: 'p1',
            database: db,
            onChangePassphrase: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      final stops = await collectFocusStops(tester);

      expect(stops, hasLength(2));
      expect(stops.map((s) => s.label).toList(), <String>[
        'Enkripsi Proyek',
        'Ubah Passphrase',
      ]);
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));
      expect(stops[0].rect.left, stops[1].rect.left);
      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0), reason: stop.label);
        expect(stop.rect.height, greaterThan(0), reason: stop.label);
      }

      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
