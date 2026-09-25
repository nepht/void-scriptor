import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_local_storage_summary.dart';

void main() {
  group('115.20 Local Storage Summary', () {
    test('keeps local categories and free space separate from cloud', () {
      final summary = LocalStorageSummary.fromScan(
        scannedAt: _now,
        freeBytes: 9_000,
        categories: const {
          LocalStorageCategory.projects: 1_000,
          LocalStorageCategory.assets: 2_000,
          LocalStorageCategory.models: 3_000,
          LocalStorageCategory.archive: 4_000,
          LocalStorageCategory.cache: 5_000,
          LocalStorageCategory.temp: 6_000,
          LocalStorageCategory.backups: 7_000,
        },
        protectedCategories: const {
          LocalStorageCategory.projects,
          LocalStorageCategory.assets,
          LocalStorageCategory.models,
          LocalStorageCategory.archive,
          LocalStorageCategory.backups,
        },
      );

      expect(summary.totalBytes, 28_000);
      expect(summary.bytesFor(LocalStorageCategory.models), 3_000);
      expect(summary.freeBytes, 9_000);
      expect(summary.isFreshAt(_now.add(const Duration(minutes: 5))), isTrue);
      expect(summary.cloudBytes, isNull);
      expect(summary.isProtected(LocalStorageCategory.projects), isTrue);
      expect(summary.isRegenerable(LocalStorageCategory.cache), isTrue);
      expect(summary.isRegenerable(LocalStorageCategory.temp), isTrue);
    });

    test(
      'rejects invalid scan values and unknown categories remain explicit',
      () {
        expect(
          () => LocalStorageSummary.fromScan(
            scannedAt: _now,
            freeBytes: -1,
            categories: const {},
            protectedCategories: const {},
          ),
          throwsArgumentError,
        );

        final summary = LocalStorageSummary.fromScan(
          scannedAt: _now,
          freeBytes: 1,
          categories: const {LocalStorageCategory.other: 25},
          protectedCategories: const {},
        );
        expect(summary.bytesFor(LocalStorageCategory.other), 25);
        expect(summary.isFreshAt(_now.add(const Duration(hours: 25))), isFalse);
      },
    );
  });
}

final _now = DateTime.utc(2026, 9, 26, 8);
