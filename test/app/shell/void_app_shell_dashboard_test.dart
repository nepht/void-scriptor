import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:void_scriptor/app/shell/void_app_shell.dart";
import "package:void_scriptor/app/shell/desktop/void_top_bar.dart";

void main() {
  testWidgets(
    "desktop authenticated shell renders supplied dashboard content with top bar",
    (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VoidAppShell(content: Text("Dashboard content")),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoidTopBar), findsOneWidget);
      expect(find.text("Dashboard content"), findsOneWidget);
    },
  );
}
