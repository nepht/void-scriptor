import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_workspace_section.dart';
import 'package:void_scriptor/features/creator/presentation/creator_workspace_screen.dart';

String _labelOf(BuildContext ctx) {
  var label = '?';
  void walk(Element e) {
    if (label != '?') return;
    final widget = e.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    e.visitChildren(walk);
  }

  walk(ctx as Element);
  return label;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final out = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 20; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) break;
    final renderObject = ctx.findRenderObject();
    final rect = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : Rect.zero;
    final key = '${rect.top}|${rect.left}';
    if (!seen.add(key)) break;
    out.add((label: _labelOf(ctx), rect: rect));
  }
  return out;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: CreatorWorkspaceScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CreatorWorkspaceScreen — kontrak focus order 2.4.3', () {
    testWidgets('1. sembilan seksi ditab row-major sesuai enum', (
      tester,
    ) async {
      await _pump(tester);

      final stops = await _stops(tester);
      final expected = CreatorWorkspaceSection.values
          .map((section) => section.label)
          .toList();

      expect(
        stops.length,
        expected.length,
        reason: 'harus ${expected.length} stop, dapat ${stops.length}',
      );
      expect(
        stops.map((stop) => stop.label).toList(),
        expected,
        reason: 'urutan fokus harus mengikuti grid row-major',
      );

      // Tiga kolom pertama berada pada baris pertama.
      expect(stops[0].rect.top, stops[1].rect.top);
      expect(stops[1].rect.top, stops[2].rect.top);
      expect(stops[0].rect.left, lessThan(stops[1].rect.left));
      expect(stops[1].rect.left, lessThan(stops[2].rect.left));

      // Baris kedua dan ketiga mengikuti urutan enum yang sama.
      expect(stops[3].rect.top, greaterThan(stops[0].rect.top));
      expect(stops[6].rect.top, greaterThan(stops[3].rect.top));
      for (var rowStart in [0, 3, 6]) {
        expect(
          stops[rowStart].rect.left,
          lessThan(stops[rowStart + 1].rect.left),
        );
        expect(
          stops[rowStart + 1].rect.left,
          lessThan(stops[rowStart + 2].rect.left),
        );
      }
    });

    testWidgets('2. setiap seksi adalah stop fokus InkWell yang terpisah', (
      tester,
    ) async {
      await _pump(tester);

      final stops = await _stops(tester);
      expect(stops.length, 9);

      // Semua card memiliki label yang dapat dibaca dan area fokus tidak nol.
      for (final stop in stops) {
        expect(stop.label, isNot('?'));
        expect(stop.rect.width, greaterThan(0));
        expect(stop.rect.height, greaterThan(0));
      }

      // Sembilan seksi benar-benar ditampilkan; test lama mengunci ini juga,
      // sedangkan test ini mengunci urutan keyboard-nya.
      for (final section in CreatorWorkspaceSection.values) {
        expect(find.text(section.label), findsOneWidget);
      }
    });

    testWidgets('3. traversal kembali ke seksi pertama setelah Archive', (
      tester,
    ) async {
      await _pump(tester);

      final stops = await _stops(tester);
      expect(stops.length, 9);
      expect(stops.first.label, 'My Projects');
      expect(stops.last.label, 'Archive');
      expect(stops.first.rect.top, lessThan(stops.last.rect.top));
    });
  });
}
