import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/presentation/hud_designer_screen.dart';

/// HUD Designer (Game) — 8 kartu HUD, tiap kartu punya tepat satu stop fokus
/// yang dapat dicapai lewat Tab: Switch di sisi kanan ListTile. AppBar tidak
/// punya tombol back sehingga tidak ada stop sebelum Health.
/// Urutan diukur dengan probe pada viewport 1536x1024 / dpr 1.0.
const _expectedLabels = <String>[
  'Health',
  'Energy',
  'Ability',
  'Weapon',
  'Minimap',
  'Quest',
  'Interaction',
  'Boss Health',
];

/// Ambil label kartu: Text pertama di bawah ListTile terdekat milik stop fokus.
String _labelOf(BuildContext context) {
  final element = context as Element;
  Element? tile;
  element.visitAncestorElements((candidate) {
    if (candidate.widget is ListTile) {
      tile = candidate;
      return false;
    }
    return true;
  });
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

  visit(tile ?? element);
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

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 24; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    final key =
        '${stop.rect.left}|${stop.rect.top}|'
        '${stop.rect.width}|${stop.rect.height}';
    if (!seen.add(key)) break;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: HudDesignerScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HUD Designer — kontrak focus order 2.4.3', () {
    testWidgets('1. delapan stop dengan urutan label kartu HUD', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(8));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason: 'Tab must walk the eight HUD cards in visual order.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. area fokus non-zero dan ditumpuk atas-bawah', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].rect.top,
          greaterThan(stops[i - 1].rect.top),
          reason: 'Focus must move top-to-bottom across the card list.',
        );
        expect(
          stops[i].rect.left,
          stops[0].rect.left,
          reason: 'All Switch stops share the trailing action column.',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Tab setelah kartu terakhir kembali ke kartu pertama', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(8));
      // _stops berhenti tepat saat rect berulang, jadi fokus sudah kembali
      // ke kartu pertama (Health) dengan rect yang sama.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi melanjutkan ke kartu kedua — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
    });
  });
}
