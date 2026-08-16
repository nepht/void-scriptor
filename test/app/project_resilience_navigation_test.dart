import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

import '../shared/theme_test_overrides.dart';

void main() {
  testWidgets('top bar exposes project resilience navigation', (tester) async {
    String? selected;
    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: VoidTopBar(onMenuSelected: (value) => selected = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Project resilience'));
    expect(selected, 'resilience');
  });
}
