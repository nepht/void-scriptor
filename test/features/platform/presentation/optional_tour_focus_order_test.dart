import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/platform/presentation/optional_tour_screen.dart';

/// Kontrak fokus WCAG 2.4.3 — Optional Tour.
///
/// Harness: layar dipush ke Navigator (cara rute aplikasi membuka layar), sehingga
/// affordance back pada AppBar ikut teraudit. Viewport desktop 1536x1024, dpr 1.0.

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

void _noOp() {}

Future<void> _pushScreen(WidgetTester tester) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navKey,
        home: const SizedBox.expand(child: Text('seed')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const OptionalTourScreen(onStartTour: _noOp),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'focus order 2.4.3: Back -> Start Tour, 2 stop pada rute yang dipush',
    (tester) async {
      _useDesktopViewport(tester);
      await _pushScreen(tester);

      final stops = await collectFocusStops(tester);

      expect(stops, hasLength(2));
      expect(stops.map((s) => s.label).toList(), <String>[
        'Back',
        'Start Tour',
      ]);
      expect(tester.takeException(), isNull);

      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0), reason: stop.label);
        expect(stop.rect.height, greaterThan(0), reason: stop.label);
        expect(stop.rect.width, lessThanOrEqualTo(_viewportWidth));
        expect(stop.rect.height, lessThanOrEqualTo(_viewportHeight));
      }

      // Atas-ke-bawah: affordance back di AppBar, aksi utama di badan layar.
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));
      expect(stops[0].rect.left, lessThanOrEqualTo(16));
      expect(stops[0].rect.top, lessThanOrEqualTo(16));

      // Start Tour: tombol full-width di dalam padding layar.
      expect(stops[1].rect.left, lessThanOrEqualTo(20));
      expect(stops[1].rect.right, lessThanOrEqualTo(_viewportWidth));
      expect(stops[1].rect.width, greaterThanOrEqualTo(_viewportWidth - 40));
      expect(stops[1].rect.top, greaterThan(400));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'focus order 2.4.3: Start Tour tetap satu-satunya stop tanpa rute induk',
    (tester) async {
      _useDesktopViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OptionalTourScreen(onStartTour: _noOp),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stops = await collectFocusStops(tester);

      expect(stops, hasLength(1));
      expect(stops.single.label, 'Start Tour');
      expect(stops.single.rect.width, greaterThan(0));
      expect(stops.single.rect.height, greaterThan(0));
      expect(stops.single.rect.left, lessThanOrEqualTo(20));
      expect(stops.single.rect.right, lessThanOrEqualTo(_viewportWidth));
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
