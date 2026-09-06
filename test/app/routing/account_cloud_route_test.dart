import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

void main() {
  testWidgets('account and cloud center route renders the real screen', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.accountCloud);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
    expect(find.text('Local project storage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
