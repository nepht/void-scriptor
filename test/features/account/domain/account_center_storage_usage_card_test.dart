import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';

void main() {
  test('maps complete quota reading to accessible usage card data', () {
    final card = StorageUsageCardData.fromBytes(
      providerId: 'drive',
      accountLabel: 'Work account',
      usedBytes: 25,
      quotaBytes: 100,
      measuredAt: DateTime.utc(2026, 9, 25, 10),
      now: DateTime.utc(2026, 9, 25, 11),
    );

    expect(card.icon, StorageUsageCardIcon.cloud);
    expect(card.percentage, 0.25);
    expect(card.freshness, StorageUsageFreshness.fresh);
    expect(card.accessibleProgress, '25% used, 75 B available of 100 B');
    expect(card.statusLabel, 'Fresh');
  });

  test('keeps unknown quota explicit and does not invent percentage', () {
    final card = StorageUsageCardData.unknownQuota(
      providerId: 'drive',
      accountLabel: 'Work account',
      usedBytes: 25,
      measuredAt: DateTime.utc(2026, 9, 25, 10),
      now: DateTime.utc(2026, 9, 25, 11),
    );

    expect(card.percentage, isNull);
    expect(card.quotaLabel, 'Quota unavailable');
    expect(card.accessibleProgress, '25 B used; quota unavailable');
  });
}
