import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('splash centers the Void Scriptor brand without a mascot', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('VOID SCRIPTOR STUDIO'), findsOneWidget);
    expect(find.bySemanticsLabel('Void Scriptor Studio logo'), findsOneWidget);
    expect(find.byKey(const Key('startup-byte-mascot')), findsNothing);
    expect(
      find.bySemanticsLabel('Byte, Void Scriptor assistant'),
      findsNothing,
    );
    expect(find.text('LIVING DATABASE FOR WORLDBUILDING'), findsOneWidget);
    expect(find.text('Opening your local workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup timer completes exactly once', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          displayDuration: const Duration(milliseconds: 400),
          onComplete: () => completions++,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 399));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
  });

  testWidgets('splash remains usable when motion is disabled', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('VOID SCRIPTOR STUDIO'), findsOneWidget);
    expect(find.byKey(const Key('startup-byte-mascot')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup reflows without overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.bySemanticsLabel('Void Scriptor Studio logo'), findsOneWidget);
    expect(find.byKey(const Key('startup-byte-mascot')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
