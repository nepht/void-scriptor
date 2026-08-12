import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/void_adaptive_scaffold.dart';

void main() {
  const phoneSize = Size(500, 800);
  const tabletSize = Size(800, 1000);
  const compactDesktopSize = Size(1200, 900);
  const desktopSize = Size(1600, 1000);

  Widget buildScaffold() {
    return const MaterialApp(
      home: VoidAdaptiveScaffold(
        body: Center(child: Text('Body')),
        desktopSidebar: SizedBox(
          width: 240,
          child: Center(child: Text('Sidebar')),
        ),
        mobileNavigation: SizedBox(
          height: 56,
          child: Center(child: Text('Nav')),
        ),
        inspector: SizedBox(
          width: 280,
          child: Center(child: Text('Inspector')),
        ),
      ),
    );
  }

  testWidgets('displays phone layout', (tester) async {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildScaffold());

    expect(find.byKey(const Key('scaffold-phone')), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Nav'), findsOneWidget);
    expect(find.text('Sidebar'), findsNothing);
    expect(find.text('Inspector'), findsNothing);
  });

  testWidgets('displays tablet/compact layout', (tester) async {
    tester.view.physicalSize = tabletSize;
    await tester.pumpWidget(buildScaffold());
    expect(find.byKey(const Key('scaffold-tablet-or-compact')), findsOneWidget);
    expect(find.text('Sidebar'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Nav'), findsNothing);
    expect(find.text('Inspector'), findsNothing);

    tester.view.physicalSize = compactDesktopSize;
    await tester.pumpWidget(buildScaffold());
    expect(find.byKey(const Key('scaffold-tablet-or-compact')), findsOneWidget);
  });

  testWidgets('displays desktop layout', (tester) async {
    tester.view.physicalSize = desktopSize;
    await tester.pumpWidget(buildScaffold());

    expect(find.byKey(const Key('scaffold-desktop')), findsOneWidget);
    expect(find.text('Sidebar'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Nav'), findsNothing);
  });
}
