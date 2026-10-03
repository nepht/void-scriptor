import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/agent_permission_screen.dart';

/// WCAG 2.2 - 2.4.3 Focus Order (Agent Permission Screen).
///
/// Kontrak ini membekukan urutan fokus yang SEBENARNYA diukur lewat traversal
/// `LogicalKeyboardKey.tab` pada viewport desktop 1536x1024 dpr 1.0.
///
/// Fakta terverifikasi dari `lib/features/marketplace/presentation/agent_permission_screen.dart`:
/// - `_permissions` berisi 3 entri; `File Access` dan `Network` bertanda
///   `isRequired: true` sehingga tile-nya merender `Text('Required')`, bukan
///   `Switch` (lihat baris 105-110).
/// - Hanya `AI Provider` (`isRequired: false`) yang merender `Switch`, maka
///   hanya dia yang bisa menerima fokus di dalam daftar permission.
/// - Aksi di kaki layar adalah `FilledButton` 'Allow All' lalu
///   `OutlinedButton` 'Deny Optional' di dalam `Row` dua `Expanded` (baris 50-66).
///
/// Urutan fokus yang terkontrak: Switch (AI Provider) -> Allow All ->
/// Deny Optional. Tombol 'Deny Optional' WAJIB berada setelah 'Allow All'
/// secara horizontal, bukan vertikal, karena keduanya berada di satu `Row`.
String _labelOf(BuildContext context) {
  var text = '';
  void visit(Element element) {
    if (text.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  (context as Element).visitAncestorElements((ancestor) {
    if (text.isEmpty) visit(ancestor);
    return text.isEmpty;
  });
  if (text.isEmpty) visit(context);
  return text.isEmpty ? 'widget:${context.widget.runtimeType}' : text;
}

Future<List<({String label, Rect rect})>> _tabStops(WidgetTester tester) async {
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
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void _noop() {}

void main() {
  const expectedLabels = ['AI Provider', 'Allow All', 'Deny Optional'];

  testWidgets(
    'AgentPermissionScreen focus order is Switch -> Allow All -> Deny Optional',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: AgentPermissionScreen(onAllowAll: _noop, onDenyOptional: _noop),
        ),
      );
      await tester.pumpAndSettle();

      final stops = await _tabStops(tester);

      expect(tester.takeException(), isNull);
      expect(stops.map((s) => s.label).toList(), expectedLabels);

      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0));
        expect(stop.rect.height, greaterThan(0));
      }
    },
  );

  testWidgets(
    'hanya permission optional yang punya stop fokus di dalam daftar',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: AgentPermissionScreen(onAllowAll: _noop, onDenyOptional: _noop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('AI Provider'), findsOneWidget);

      final stops = await _tabStops(tester);
      final inList = stops.where((s) => s.rect.top < 340).toList();
      expect(inList.length, 1);
      expect(inList.single.label, 'AI Provider');
    },
  );

  testWidgets(
    'urutan posisional: tile di atas baris tombol, tombol kiri-ke-kanan',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: AgentPermissionScreen(onAllowAll: _noop, onDenyOptional: _noop),
        ),
      );
      await tester.pumpAndSettle();

      final stops = await _tabStops(tester);
      final toggle = stops[0].rect;
      final allow = stops[1].rect;
      final deny = stops[2].rect;

      expect(
        toggle.top,
        lessThan(allow.top),
        reason: 'toggle tile di atas tombol',
      );
      expect(allow.left, lessThan(deny.left), reason: 'Allow All di kiri Deny');
      expect(allow.top, deny.top, reason: 'keduanya satu Row action');
      expect(allow.right, lessThanOrEqualTo(deny.left));
      expect(
        toggle.right,
        greaterThan(allow.left),
        reason: 'toggle di trailing tile',
      );
    },
  );
}
