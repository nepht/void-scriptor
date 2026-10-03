import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/projects/presentation/create_project_screen.dart';

const _expectedLabels = <String>['widget:Focus', 'Cancel', 'Create Project'];

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

  visit(context as Element);
  return text.isEmpty ? 'widget:${context.widget.runtimeType}' : text;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < 4; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull);
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

Widget _screen() =>
    const ProviderScope(child: MaterialApp(home: CreateProjectScreen()));

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Create Project Screen — kontrak focus order 2.4.3', () {
    testWidgets('menyisir field dan action lalu mengulang', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);
      expect(stops.map((stop) => stop.label).toList(), [
        ..._expectedLabels,
        _expectedLabels.first,
      ]);
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus memiliki area non-zero.',
      );
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));
      expect(stops[1].rect.top, stops[2].rect.top);
      expect(
        stops[1].rect.left,
        lessThan(stops[2].rect.left),
        reason: 'Cancel dibaca sebelum Create Project dari kiri ke kanan.',
      );
      expect(stops[2].rect.bottom, lessThanOrEqualTo(1024));
      expect(tester.takeException(), isNull);
    });
  });
}
