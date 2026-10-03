import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/advanced_ai_studio_screen.dart';

class _FocusStop {
  _FocusStop(this.label, this.rect);
  final String? label;
  final Rect rect;
}

Future<List<_FocusStop>> _walkFocusOrder(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AdvancedAiStudioScreen(
        onOpenImageGenerator: () {},
        onOpenVideoGenerator: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  final stops = <_FocusStop>[];
  final seen = <String>{};
  for (var i = 0; i < 10; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    String? label;
    void visit(Element element) {
      if (label != null) return;
      final widget = element.widget;
      if (widget is Icon) return;
      if (widget is Text && widget.data?.trim().isNotEmpty == true) {
        label = widget.data!.trim();
        return;
      }
      element.visitChildren(visit);
    }

    visit(context as Element);
    final key = '${rect.top}|${rect.left}';
    if (!seen.add(key)) break;
    stops.add(_FocusStop(label, rect));
  }
  return stops;
}

Future<void> main() async {
  testWidgets(
    'Advanced AI Studio: urutan fokus Tab stabil, kiri-ke-kanan lalu ke bawah',
    (tester) async {
      final stops = await _walkFocusOrder(tester);

      expect(tester.takeException(), isNull);
      expect(stops, hasLength(3), reason: 'harus ada tepat 3 stop fokus');

      expect(stops[0].label, 'Image Generator');
      expect(stops[1].label, 'Video Generator');
      expect(
        stops[2].label,
        isNull,
        reason: 'stop ketiga TextField tidak punya Text data',
      );
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(EditableText),
        ),
        findsOneWidget,
      );

      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0), reason: 'area fokus non-zero');
        expect(stop.rect.height, greaterThan(0), reason: 'area fokus non-zero');
      }

      expect(
        stops[1].rect.left,
        greaterThan(stops[0].rect.left),
        reason: 'tombol kedua di kanan tombol pertama (kiri-ke-kanan)',
      );
      expect(
        stops[1].rect.top,
        closeTo(stops[0].rect.top, 1),
        reason: 'kedua tombol berada pada baris yang sama',
      );
      expect(
        stops[2].rect.top,
        greaterThan(stops[1].rect.top),
        reason: 'TextField berada di bawah toolbar tombol',
      );
      expect(
        stops[2].rect.left,
        greaterThan(stops[0].rect.left),
        reason: 'TextField mulai setelah kolom tombol pertama',
      );
    },
  );
}
