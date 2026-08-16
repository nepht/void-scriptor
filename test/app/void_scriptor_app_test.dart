import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

import '../shared/theme_test_overrides.dart';

void main() {
  testWidgets('mengganti routerConfig ketika parent memberikan router baru', (
    tester,
  ) async {
    final firstRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Router Pertama')),
        ),
      ],
    );
    final secondRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Router Kedua')),
        ),
      ],
    );
    addTearDown(firstRouter.dispose);
    addTearDown(secondRouter.dispose);

    Widget app(GoRouter router) => ProviderScope(
      overrides: themeTestOverrides(),
      child: VoidScriptorApp(routerConfig: router),
    );

    await tester.pumpWidget(app(firstRouter));
    await tester.pumpAndSettle();
    expect(find.text('Router Pertama'), findsOneWidget);

    await tester.pumpWidget(app(secondRouter));
    await tester.pumpAndSettle();
    expect(find.text('Router Kedua'), findsOneWidget);
    expect(find.text('Router Pertama'), findsNothing);
  });
}
