import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_bootstrap.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

void main() {
  testWidgets('bootstrap memasang ProviderScope dan membuka splash', (
    tester,
  ) async {
    await tester.pumpWidget(const AppBootstrap());
    await tester.pumpAndSettle();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(VoidScriptorApp), findsOneWidget);
    expect(find.text('SPLASH'), findsOneWidget);
  });
}
