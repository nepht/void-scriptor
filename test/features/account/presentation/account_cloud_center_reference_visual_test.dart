import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// The supplied Account & Cloud Center artwork is the production desktop
/// baseline. Keep this contract separate from the legacy 115.45 frame tests:
/// the app route opts into the reference visual explicitly.
void main() {
  testWidgets(
    'reference visual fills the canvas without a duplicate left rail',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountCloudCenterScreen(referenceVisual: true),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('account-center-left-navigation')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-center-main-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-center-right-rail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-overview-card-authentication')),
        findsOneWidget,
      );

      final main = tester.getRect(
        find.byKey(const ValueKey('account-center-main-grid')),
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('account-center-right-rail')),
      );
      expect(main.left, closeTo(17, 0.5));
      expect(main.width, closeTo(1141, 0.5));
      expect(rail.left, closeTo(1177, 0.5));
      expect(rail.width, closeTo(342, 0.5));
      expect(tester.takeException(), isNull);
    },
  );
}
