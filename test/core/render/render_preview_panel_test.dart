import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/render/presentation/render_preview_panel.dart';

void main() {
  testWidgets('RenderPreviewPanel shows stats and empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RenderPreviewPanel(
            drawCalls: 3,
            culledCount: 1,
            width: 320,
            height: 180,
          ),
        ),
      ),
    );
    expect(find.text('Render Preview'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
