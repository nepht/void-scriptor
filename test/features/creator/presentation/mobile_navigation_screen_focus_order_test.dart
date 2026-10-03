import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/mobile_navigation_screen.dart';

/// Layar Mobile Navigation punya lima stop fokus yang dapat dicapai lewat Tab:
/// lima `NavigationDestination` pada `NavigationBar` di bagian bawah.
/// Urutannya kiri-ke-kanan sesuai urutan deklarasi destination
/// (Home, Projects, Create, AI, Profile) pada layout lebar 1536 px.
const _expectedLabels = ['Home', 'Projects', 'Create', 'AI', 'Profile'];

String _labelOf(BuildContext context) {
  var label = '';
  void visit(Element element) {
    if (label.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 12; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    final isRepeat = !seen.add(key);
    if (isRepeat) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void main() {
  testWidgets(
    'Mobile Navigation Screen follows the measured WCAG 2.4.3 focus order',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: MobileNavigationScreen()),
      );
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      // Lima destination bottom-nav, lalu traversal kembali ke stop pertama.
      expect(stops, hasLength(5));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason: 'Tab order must follow the declared destination order.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );

      // Kelima destination membentuk satu baris: tinggi sama, sejajar horizontal.
      final tops = stops.map((stop) => stop.rect.top).toSet();
      expect(
        tops,
        hasLength(1),
        reason: 'All destinations share one navigation bar row.',
      );
      expect(stops.first.rect.top, 944.0);
      expect(stops.first.rect.height, 80.0);

      // Urutan fokus kiri-ke-kanan, tidak tumpang tindih, mengisi lebar viewport.
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i - 1].rect.right,
          lessThanOrEqualTo(stops[i].rect.left),
          reason: 'Focus targets must not overlap horizontally.',
        );
        expect(
          stops[i - 1].rect.left,
          lessThan(stops[i].rect.left),
          reason: 'Focus must move left-to-right across the navigation bar.',
        );
      }
      expect(stops.first.rect.left, 0.0);
      expect(stops.last.rect.right, 1536.0);

      expect(tester.takeException(), isNull);
    },
  );
}
