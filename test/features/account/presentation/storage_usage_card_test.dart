import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/account/presentation/storage_usage_card.dart';

void main() {
  testWidgets(
    'renders usage, freshness, accessible progress, and manage action',
    (tester) async {
      var managed = false;
      final data = StorageUsageCardData.fromBytes(
        providerId: 'drive',
        accountLabel: 'Work account',
        usedBytes: 25,
        quotaBytes: 100,
        measuredAt: DateTime.utc(2026, 9, 25, 10),
        now: DateTime.utc(2026, 9, 25, 11),
        icon: StorageUsageCardIcon.hardDrive,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StorageUsageCard(data: data, onManage: () => managed = true),
          ),
        ),
      );

      expect(find.text('Work account'), findsOneWidget);
      expect(find.text('25 B used'), findsOneWidget);
      expect(find.text('25% used, 75 B available of 100 B'), findsOneWidget);
      expect(find.text('Fresh'), findsOneWidget);
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);

      await tester.tap(find.text('Manage storage'));
      expect(managed, isTrue);
    },
  );
}
