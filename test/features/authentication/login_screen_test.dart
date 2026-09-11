import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('Space Grotesk')
      ..addFont(
        rootBundle.load('assets/fonts/SpaceGrotesk/SpaceGrotesk-Variable.ttf'),
      );
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> show(WidgetTester tester, Size size, {double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(
            const AuthSession.loggedOut(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Space Grotesk',
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: LoginScreen(onRegister: () {}, onForgotPassword: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LoginScreen));
      await precacheImage(
        const AssetImage('assets/backgrounds/auth_background.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/logos/void_scriptor_logo.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
  }

  testWidgets('desktop composition validates credentials before submission', (
    tester,
  ) async {
    await show(tester, const Size(1440, 1000));
    expect(find.text('Give your stories\na world to live in.'), findsOneWidget);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_desktop.png'),
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow large text keeps local access reachable without overflow',
    (tester) async {
      await show(tester, const Size(390, 844), scale: 2);
      expect(find.text('Give your stories\na world to live in.'), findsNothing);
      await tester.ensureVisible(find.text('Work Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Work Offline').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
