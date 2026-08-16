import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_bootstrap.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';

import '../../shared/theme_test_overrides.dart';

void main() {
  testWidgets(
    'bootstrap memasang ProviderScope dan menyelesaikan session check',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: themeTestOverrides(),
          child: const AppBootstrap(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProviderScope), findsWidgets);
      expect(find.byType(VoidScriptorApp), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
