import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/observability/local_usage_journal.dart';

void main() {
  group('LocalUsageJournal persistence', () {
    late LocalUsageJournal journal;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vs12_journal_test');
      journal = LocalUsageJournal(storageDirectory: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'save + reload round trip preserves entries and disabled state',
      () async {
        expect(journal.enabled, isFalse);
        journal.enabled = true; // appends the journal_opted_in audit event
        journal.record('app_open');
        journal.record(
          'flag_changed',
          fields: {'flag': 'vs12_export', 'outcome': 'enabled'},
        );
        await journal.save();

        final reloaded = LocalUsageJournal(storageDirectory: tempDir);
        await reloaded.load();
        expect(reloaded.enabled, isTrue);
        // opted_in + app_open + flag_changed
        expect(reloaded.entries.length, 3);
        expect(reloaded.entries.first.eventType, 'journal_opted_in');
        expect(reloaded.entries[1].eventType, 'app_open');
        expect(reloaded.entries.last.fields['flag'], 'vs12_export');
      },
    );

    test('load with missing file yields fresh disabled journal', () async {
      final reloaded = LocalUsageJournal(storageDirectory: tempDir);
      await reloaded.load();
      expect(reloaded.enabled, isFalse);
      expect(reloaded.entries, isEmpty);
    });

    test('corrupt file degrades to empty state, not crash', () async {
      await File(
        '${tempDir.path}/usage_journal.json',
      ).writeAsString('{not valid json');
      final reloaded = LocalUsageJournal(storageDirectory: tempDir);
      await reloaded.load();
      expect(reloaded.enabled, isFalse);
      expect(reloaded.entries, isEmpty);
    });
  });
}
