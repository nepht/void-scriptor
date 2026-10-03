import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';

const _expectedLabels = <String>[
  'Scan Again',
  'Export Project',
  'Delete Cache',
];

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
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
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

Future<void> _noop() async {}

Widget _screen() => MaterialApp(
  home: ProjectResilienceCenterScreen(
    title: 'Recovery',
    items: const ['Database healthy'],
    onAction: () async {},
    actions: const [
      ProjectResilienceAction(
        label: 'Export Project',
        icon: Icons.upload,
        onPressed: _noop,
      ),
      ProjectResilienceAction(
        label: 'Delete Cache',
        icon: Icons.delete,
        onPressed: _noop,
        destructive: true,
      ),
    ],
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('mengunci urutan focus order 2.4.3', (tester) async {
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
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(stops[1].rect.top, stops[2].rect.top);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[1].rect.left, lessThan(stops[2].rect.left));
    expect(tester.takeException(), isNull);
  });
}
