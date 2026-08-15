import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/resizable_panel.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('ResizablePanel renders child at the given width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: (_) {},
          onToggleCollapse: () {},
          child: const Text('EXPLORER'),
        ),
      ),
    );

    expect(find.text('EXPLORER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResizablePanel reports resize via onResize', (tester) async {
    double? resizedWidth;
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: (w) => resizedWidth = w,
          onToggleCollapse: () {},
          child: const SizedBox(),
        ),
      ),
    );

    // Drag the resize handle horizontally.
    final handle = find.byKey(const Key('resize-handle'));
    expect(handle, findsOneWidget);

    await tester.drag(handle, const Offset(80, 0));
    await tester.pump();

    expect(resizedWidth, isNotNull);
    expect(resizedWidth, greaterThan(245));
  });

  testWidgets('ResizablePanel invokes onToggleCollapse', (tester) async {
    var collapsed = false;
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: (_) {},
          onToggleCollapse: () => collapsed = true,
          child: const SizedBox(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('collapse-toggle')));
    expect(collapsed, isTrue);
  });

  testWidgets('CollapsiblePanel collapses to a thin strip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CollapsiblePanel(
          collapsed: true,
          onToggleCollapse: () {},
          collapsedLabel: 'EXPLORER',
          child: const Text('content'),
        ),
      ),
    );

    expect(find.text('content'), findsNothing);
    expect(find.text('EXPLORER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CollapsiblePanel shows child when expanded', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CollapsiblePanel(
          collapsed: false,
          onToggleCollapse: () {},
          collapsedLabel: 'EXPLORER',
          child: const Text('content'),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
  });
}
