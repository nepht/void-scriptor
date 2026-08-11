import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

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

    await tester.pumpWidget(VoidScriptorApp(routerConfig: firstRouter));
    await tester.pumpAndSettle();
    expect(find.text('Router Pertama'), findsOneWidget);

    await tester.pumpWidget(VoidScriptorApp(routerConfig: secondRouter));
    await tester.pumpAndSettle();
    expect(find.text('Router Kedua'), findsOneWidget);
    expect(find.text('Router Pertama'), findsNothing);
  });
}
