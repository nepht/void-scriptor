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

      final authentication = tester.getRect(
        find.byKey(const ValueKey('account-overview-card-authentication')),
      );
      final quickConnect = tester.getRect(
        find.byKey(const ValueKey('account-overview-card-quick-connect')),
      );
      final storage = tester.getRect(
        find.byKey(const ValueKey('account-overview-card-storage')),
      );
      expect(
        authentication.width,
        greaterThan(quickConnect.width * 1.25),
        reason: 'the reference gives authentication room for the sign-in list',
      );
      expect(quickConnect.width, closeTo(storage.width, 0.5));

      final row2Keys = <String>[
        'account-overview-card-connected-services',
        'account-overview-card-api-providers',
        'account-overview-card-developer-tools',
        'account-overview-card-creative-tools',
        'account-overview-card-payment-methods',
      ];
      final row3Keys = <String>[
        'account-overview-card-api-keys-manager',
        'account-overview-card-team-collaboration',
        'account-overview-card-activity-log',
        'account-overview-card-backup-sync',
        'account-overview-card-security-center',
      ];
      final row2 = [
        for (final key in row2Keys)
          tester.getRect(find.byKey(ValueKey<String>(key))),
      ];
      final row3 = [
        for (final key in row3Keys)
          tester.getRect(find.byKey(ValueKey<String>(key))),
      ];
      for (final rect in row2.skip(1)) {
        expect(
          rect.top,
          closeTo(row2.first.top, 0.5),
          reason: 'reference row 2 must keep all five cards on one row',
        );
      }
      for (final rect in row3.skip(1)) {
        expect(
          rect.top,
          closeTo(row3.first.top, 0.5),
          reason: 'reference row 3 must keep all five cards on one row',
        );
      }
      for (final rect in [...row2, ...row3]) {
        expect(rect.width, closeTo(219.4, 0.5));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
