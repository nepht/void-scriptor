import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/void_adaptive_scaffold.dart';
import 'package:void_scriptor/app/adaptive/void_breakpoints.dart';

void main() {
  group('VoidAdaptiveScaffold', () {
    testWidgets('renders phone layout for width < 600', (tester) async {
      tester.view.physicalSize = Size(VoidBreakpoints.phone - 1, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset); // Reset view after test

      await tester.pumpWidget(
        const MaterialApp(
          home: VoidAdaptiveScaffold(
            body: Text('Body'),
            desktopSidebar: Text('Sidebar'),
            mobileNavigation: Text('BottomNav'),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Pump and settle after layout changes

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('BottomNav'), findsOneWidget);
      expect(find.text('Sidebar'), findsNothing);
      expect(find.text('Inspector'), findsNothing);
    });

    testWidgets('renders tablet layout for width 600 to 899', (tester) async {
      tester.view.physicalSize = Size(VoidBreakpoints.tablet - 1, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: VoidAdaptiveScaffold(
            body: Text('Body'),
            desktopSidebar: Text('Sidebar'),
            mobileNavigation: Text('BottomNav'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('BottomNav'), findsNothing);
      expect(find.text('Inspector'), findsNothing);
    });

    testWidgets('renders compact desktop layout for width 900 to 1199', (tester) async {
      tester.view.physicalSize = Size(VoidBreakpoints.compactDesktop - 1, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: VoidAdaptiveScaffold(
            body: Text('Body'),
            desktopSidebar: Text('Sidebar'),
            mobileNavigation: Text('BottomNav'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('BottomNav'), findsNothing);
      expect(find.text('Inspector'), findsNothing);
    });

    testWidgets('renders desktop layout for width 1200 to 1919', (tester) async {
      tester.view.physicalSize = Size(VoidBreakpoints.largeDesktop - 1, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: VoidAdaptiveScaffold(
            body: Text('Body'),
            desktopSidebar: Text('Sidebar'),
            mobileNavigation: Text('BottomNav'),
            inspector: Text('Inspector'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('Inspector'), findsOneWidget);
      expect(find.text('BottomNav'), findsNothing);
    });

    testWidgets('renders large desktop layout for width >= 1920', (tester) async {
      tester.view.physicalSize = Size(VoidBreakpoints.largeDesktop + 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: VoidAdaptiveScaffold(
            body: Text('Body'),
            desktopSidebar: Text('Sidebar'),
            mobileNavigation: Text('BottomNav'),
            inspector: Text('Inspector'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('Inspector'), findsOneWidget);
      expect(find.text('BottomNav'), findsNothing);
    });
  });
}