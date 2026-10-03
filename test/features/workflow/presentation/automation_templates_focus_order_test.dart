import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

/// Automation Templates (Workflow) — 3 template ListTile, tiap tile punya
/// tepat satu stop fokus lewat onTap. Screen ini berdiri sendiri tanpa
/// Scaffold/AppBar, jadi tidak ada stop sebelum template pertama.
/// Urutan diukur dengan probe pada viewport 1536x1024 / dpr 1.0.
const _expectedLabels = <String>[
  'Export after job completes',
  'Backup at startup',
  'Thumbnail pipeline on import',
];

/// Ambil label tile: Text pertama di bawah ListTile terdekat milik stop fokus.
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
  for (var i = 0; i < 16; i++) {
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
    MaterialApp(
      home: Scaffold(body: AutomationTemplatesScreen(onInstantiate: (_) {})),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Automation Templates — kontrak focus order 2.4.3', () {
    testWidgets('1. tiga stop dengan urutan label template', (tester) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason: 'Tab must walk the three templates in list order.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. area fokus non-zero dan ditumpuk atas-bawah', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].rect.top,
          greaterThan(stops[i - 1].rect.top),
          reason: 'Focus must move top-to-bottom down the template list.',
        );
        expect(
          stops[i].rect.left,
          stops[0].rect.left,
          reason: 'Every template row spans the same left edge.',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Tab setelah template terakhir kembali ke template '
        'pertama', (tester) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      // _stops berhenti tepat saat rect berulang, jadi fokus sudah kembali
      // ke template pertama (Export after job completes) dengan rect sama.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi melanjutkan ke template kedua — siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
      expect(tester.takeException(), isNull);
    });
  });
}
