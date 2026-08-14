import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

void main() {
  testWidgets('top bar exposes project resilience navigation', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoidTopBar(onMenuSelected: (value) => selected = value),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Project resilience'));
    expect(selected, 'resilience');
  });
}
