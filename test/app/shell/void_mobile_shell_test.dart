import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/shell/mobile/void_mobile_shell.dart';

void main() {
  testWidgets('mobile shell destinations navigate and expose More actions', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/studio/p1',
      routes: [
        GoRoute(
          path: '/studio/:projectId',
          builder: (_, _) => const VoidMobileShell(projectId: 'p1'),
        ),
        for (final entry in {
          AppRoutes.projects: 'Projects Page',
          AppRoutes.workspace: 'Workspace Page',
          AppRoutes.assets: 'Assets Page',
          AppRoutes.dashboard: 'Dashboard Page',
          AppRoutes.projectBackups: 'Backup Page',
          AppRoutes.settings: 'Settings Page',
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (_, _) => Scaffold(body: Text(entry.value)),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.tap(find.text('Novels'));
    await tester.pumpAndSettle();
    expect(find.text('Projects Page'), findsOneWidget);

    router.go('/studio/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('World')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Search')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Backup & Export')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Optional tools')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Diagnostics')),
      findsNothing,
    );

    await tester.tap(find.text('Optional tools'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('Diagnostics')),
      findsOneWidget,
    );
  });
}
