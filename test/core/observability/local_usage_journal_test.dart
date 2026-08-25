import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/observability/local_usage_journal.dart';

void main() {
  group('LocalUsageJournal', () {
    test('default state is DISABLED and records nothing', () {
      final journal = LocalUsageJournal();
      expect(journal.enabled, isFalse);
      journal.record('app_open');
      expect(journal.entries, isEmpty);
    });

    test('when enabled, whitelisted metadata fields are kept', () {
      final journal = LocalUsageJournal()..enabled = true;
      journal.record(
        'flag_changed',
        fields: {'flag': 'vs12_plot_board', 'outcome': 'enabled'},
      );
      // enabled=true itself appends the journal_opted_in audit event first.
      expect(journal.entries.length, 2);
      final entry = journal.entries.last;
      expect(entry.eventType, 'flag_changed');
      expect(entry.fields['flag'], 'vs12_plot_board');
      expect(entry.fields['outcome'], 'enabled');
    });

    test(
      'ANTI-LEAKAGE: non-whitelisted fields are dropped even when enabled',
      () {
        final journal = LocalUsageJournal()..enabled = true;
        journal.record(
          'feature_surface_viewed',
          fields: {
            'title': 'Secret Novel Chapter 1',
            'excerpt': 'once upon a time in the void...',
            'durationMs': 1200,
          },
        );
        expect(journal.entries.length, 2);
        final fields = journal.entries.last.fields;
        expect(
          fields.containsKey('title'),
          isFalse,
          reason: 'content-ish field must never be stored',
        );
        expect(
          fields.containsKey('excerpt'),
          isFalse,
          reason: 'content-ish field must never be stored',
        );
        expect(
          fields['durationMs'],
          1200,
          reason: 'metadata within whitelist is fine',
        );
      },
    );

    test('unknown event types are rejected', () {
      final journal = LocalUsageJournal()..enabled = true;
      expect(() => journal.record('not_a_real_event'), throwsArgumentError);
    });

    test('clear() wipes history', () {
      final journal = LocalUsageJournal()..enabled = true;
      journal.record('app_open');
      expect(journal.entries, isNotEmpty);
      journal.clear();
      expect(journal.entries, isEmpty);
    });
  });
}
