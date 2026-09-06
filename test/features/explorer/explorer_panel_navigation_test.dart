import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';

void main() {
  testWidgets('ExplorerPanel navigates fixed destinations', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.workspace,
      routes: [
        GoRoute(
          path: AppRoutes.workspace,
          builder: (_, __) => const Scaffold(body: ExplorerPanel()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    expect(find.byTooltip('Create Asset'), findsOneWidget);
    expect(find.text('Novel Workspace'), findsOneWidget);
    expect(find.text('CAST & CHARACTERS'), findsOneWidget);
    expect(find.text('WORLD & CREATURES'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('OBJECTS & LOADOUT'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('OBJECTS & LOADOUT'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Projects'), findsNothing);
    expect(find.text('AI Studio'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
