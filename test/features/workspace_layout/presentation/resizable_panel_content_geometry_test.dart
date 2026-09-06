import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/resizable_panel.dart';

// Regression contract: the resizable shell must hand the panel child the
// full declared panel width. The previous Row layout squeezed content to
// width - 48, so fixed-width panels (ExplorerPanel is designed for 245)
// rendered narrower and their hit targets shifted on native Windows.
class _WidthProbe extends StatelessWidget {
  const _WidthProbe();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          Center(child: Text(constraints.maxWidth.toStringAsFixed(1))),
    );
  }
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('panel child receives the full declared panel width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: _noopResize,
          onToggleCollapse: _noopToggle,
          child: _WidthProbe(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('245.0'), findsOneWidget);
  });

  testWidgets('resize still works with full-width content layout', (
    tester,
  ) async {
    double? resizedWidth;
    await tester.pumpWidget(
      _host(
        ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: (w) => resizedWidth = w,
          onToggleCollapse: _noopToggle,
          child: const _WidthProbe(),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const Key('resize-handle')),
      const Offset(80, 0),
    );
    await tester.pump();
    expect(resizedWidth, isNotNull);
    expect(resizedWidth, greaterThan(245));
  });

  testWidgets('collapse toggle still reachable with full-width layout', (
    tester,
  ) async {
    var toggled = false;
    await tester.pumpWidget(
      _host(
        ResizablePanel(
          width: 245,
          minWidth: 200,
          maxWidth: 400,
          onResize: _noopResize,
          onToggleCollapse: () => toggled = true,
          child: const SizedBox(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('collapse-toggle')));
    expect(toggled, isTrue);
  });
}

void _noopResize(double _) {}
void _noopToggle() {}
