import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/observability/privacy_safe_metrics.dart';
import 'package:void_scriptor/features/world_logic/domain/release_health_monitoring.dart';

void main() {
  group('114.4 Privacy-Safe Monitoring Verification', () {
    test('PrivacySafeMetrics default opt-out prevents data leakage', () {
      // Default: optIn = false, so increment is silently dropped
      final m = PrivacySafeMetrics(knownFlags: {'test_flag'});
      m.increment(
        flag: 'test_flag',
        surface: 'test_surface',
        outcome: 'viewed',
      );
      expect(m.snapshot(), isEmpty);
    });

    test(
      'PrivacySafeMetrics opt-in with known flags only records aggregates',
      () {
        final m = PrivacySafeMetrics(knownFlags: {'vs12_lore_links'});
        m.optIn = true;
        m.increment(
          flag: 'vs12_lore_links',
          surface: 'workspace',
          outcome: 'viewed',
        );
        m.increment(
          flag: 'vs12_lore_links',
          surface: 'workspace',
          outcome: 'used',
        );
        final snap = m.snapshot();
        expect(snap.length, equals(2));
        // Verify no creative content leaked
        for (final entry in snap) {
          expect(entry['flag'], equals('vs12_lore_links'));
          expect(entry['surface'], equals('workspace'));
          expect(entry['outcome'], matches(r'^(viewed|used)$'));
          // No title, excerpt, or prompt fields
          expect(entry.keys, contains('count'));
          expect(entry.keys, isNot(contains('title')));
          expect(entry.keys, isNot(contains('excerpt')));
          expect(entry.keys, isNot(contains('prompt')));
        }
      },
    );

    test('PrivacySafeMetrics rejects unknown flags (deny-by-default)', () {
      final m = PrivacySafeMetrics(knownFlags: {'vs12_lore_links'});
      m.optIn = true;
      m.increment(flag: 'unknown_flag', surface: 'test', outcome: 'viewed');
      expect(m.snapshot(), isEmpty);
    });

    test('PrivacySafeMetrics rejects unknown outcomes', () {
      final m = PrivacySafeMetrics(knownFlags: {'vs12_lore_links'});
      m.optIn = true;
      m.increment(
        flag: 'vs12_lore_links',
        surface: 'test',
        outcome: 'unknown_outcome',
      );
      expect(m.snapshot(), isEmpty);
    });

    test('ReleaseHealthMonitoring all signals are privacy-safe by design', () {
      // Verify all canonical signals are defined
      expect(kReleaseHealthSignals.length, equals(7));
      expect(
        kReleaseHealthSignals,
        containsAll([
          'install_success',
          'upgrade_success',
          'crash_rate',
          'migration_failure',
          'restore_failure',
          'performance_regression',
          'support_severity',
        ]),
      );
    });

    test('ReleaseHealthSignal.isWellDefined requires privacySafe=true', () {
      // HealthSignal with privacySafe=false should not pass isWellDefined
      const unprivSignal = HealthSignal(
        signal: 'test_signal',
        threshold: '10',
        direction: 'lower_is_better',
        privacySafe: false,
        collection: 'test_collection',
      );
      expect(unprivSignal.isWellDefined, isFalse);
    });

    test(
      'ReleaseHealthSignal.isWellDefined requires all fields including privacySafe',
      () {
        // All required fields must be present and privacySafe must be true
        const signal = HealthSignal(
          signal: 'install_success',
          threshold: '5',
          direction: 'lower_is_better',
          privacySafe: true,
          collection: 'install_metrics',
        );
        expect(signal.isWellDefined, isTrue);
      },
    );

    test(
      'ReleaseHealthMonitoring.evaluate passes when all signals privacy-safe',
      () {
        const monitoring = ReleaseHealthMonitoring(
          signals: [
            HealthSignal(
              signal: 'install_success',
              threshold: '1',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'install',
            ),
            HealthSignal(
              signal: 'upgrade_success',
              threshold: '1',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'upgrade',
            ),
            HealthSignal(
              signal: 'crash_rate',
              threshold: '0.1',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'crash',
            ),
            HealthSignal(
              signal: 'migration_failure',
              threshold: '0',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'migration',
            ),
            HealthSignal(
              signal: 'restore_failure',
              threshold: '0',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'restore',
            ),
            HealthSignal(
              signal: 'performance_regression',
              threshold: '0',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'performance',
            ),
            HealthSignal(
              signal: 'support_severity',
              threshold: '0',
              direction: 'lower_is_better',
              privacySafe: true,
              collection: 'support',
            ),
          ],
          privacyMode: 'local-only-aggregate-no-PII',
        );
        final eval = ReleaseHealthMonitoring.evaluate(monitoring);
        expect(eval.state, equals(ReleaseHealthState.pass));
        expect(eval.notes, contains('privacy: local-only-aggregate-no-PII'));
      },
    );

    test('ReleaseHealthMonitoring.evaluate fails when signals missing', () {
      const monitoring = ReleaseHealthMonitoring(
        signals: [
          HealthSignal(
            signal: 'install_success',
            threshold: '1',
            direction: 'lower_is_better',
            privacySafe: true,
            collection: 'install',
          ),
        ],
      );
      final eval = ReleaseHealthMonitoring.evaluate(monitoring);
      expect(eval.state, equals(ReleaseHealthState.fail));
      expect(eval.notes, anyElement(contains('missing or not privacy-safe')));
    });

    test('Privacy-safe monitoring contract records all required controls', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_privacy_safe_monitoring.json',
      );
      expect(file.existsSync(), isTrue);
      final contract =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(contract['canonical_step'], equals('114.4'));
      expect(contract['path'], equals('DELAYED'));
      expect(contract['external_gates'], equals('DEFERRED-EXTERNAL'));
      expect(contract['content_excluded'], isTrue);
      expect(contract['secrets_excluded'], isTrue);
      expect(contract['consent_respected'], isTrue);
      expect(contract['data_minimized'], isTrue);
      expect(contract['disable_control'], isTrue);
      expect(contract['retention_documented'], isNotEmpty);
    });

    test(
      'Monitoring collects only aggregate counters, never creative content',
      () {
        final m = PrivacySafeMetrics(knownFlags: {'feature_usage'});
        m.optIn = true;
        // Only allowed outcomes: viewed, used, succeeded, failed, skipped, denied
        m.increment(flag: 'feature_usage', surface: 'menu', outcome: 'viewed');
        m.increment(flag: 'feature_usage', surface: 'menu', outcome: 'used');
        m.increment(
          flag: 'feature_usage',
          surface: 'toolbar',
          outcome: 'succeeded',
        );
        m.increment(
          flag: 'feature_usage',
          surface: 'toolbar',
          outcome: 'failed',
        );

        final snap = m.snapshot();
        // No creative content fields should ever appear
        for (final entry in snap) {
          // Each entry should only have: flag, surface, outcome, count
          expect(entry['flag'], isNotNull);
          expect(entry['surface'], isNotNull);
          expect(entry['outcome'], isNotNull);
          expect(entry['count'], isNotNull);
          // Exactly 4 keys
          expect(entry.keys.length, equals(4));
          // No extra creative fields
          expect(entry, isNot(contains('title')));
          expect(entry, isNot(contains('excerpt')));
          expect(entry, isNot(contains('prompt')));
          expect(entry, isNot(contains('content')));
        }
      },
    );
  });
}
