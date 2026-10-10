import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_scriptor/features/platform/presentation/welcome_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan welcome experience', (tester) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('Welcome to Void Scriptor Studio'), findsOneWidget);
    expect(find.text('Create Project'), findsOneWidget);
    expect(find.text('Open Project'), findsOneWidget);
    expect(find.text('Explore Demo'), findsOneWidget);
  });

  testWidgets('welcome pilot renders Indonesian localization', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('id'),
          supportedLocales: [Locale('en'), Locale('id')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Selamat datang di Void Scriptor Studio'), findsOneWidget);
    expect(find.text('Buat Proyek'), findsOneWidget);
    expect(find.text('Buka Proyek'), findsOneWidget);
    expect(find.text('Jelajahi Demo'), findsOneWidget);
  });

  testWidgets('welcome actions notify the parent', (tester) async {
    var created = false;
    var opened = false;
    var explored = false;
    await tester.pumpWidget(
      wrap(
        WelcomeScreen(
          onCreateProject: () => created = true,
          onOpenProject: () => opened = true,
          onExploreDemo: () => explored = true,
        ),
      ),
    );

    await tester.tap(find.text('Create Project'));
    await tester.tap(find.text('Open Project'));
    await tester.tap(find.text('Explore Demo'));

    expect(created, isTrue);
    expect(opened, isTrue);
    expect(explored, isTrue);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(tester.takeException(), isNull);
  });
}
