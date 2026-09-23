// 113.42 — Release Health Monitoring.
//
// Contract for the seven privacy-safe signals plus the privacy block
// that keeps identifiers out of the collection design.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_health_monitoring.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_release_health_monitoring.json',
  );

  group('113.42 release health monitoring', () {
    test('declares the seven canonical signals', () {
      expect(kReleaseHealthSignals, <String>[
        'install_success',
        'upgrade_success',
        'crash_rate',
        'migration_failure',
        'restore_failure',
        'performance_regression',
        'support_severity',
      ]);
      expect(kReleaseHealthSignals.toSet().length, 7);
    });

    test(
      'planning manifest defines every signal with threshold and privacy',
      () {
        expect(
          manifestFile.existsSync(),
          isTrue,
          reason:
              'missing docs/planning/v1.2/'
              'sprint_113_release_health_monitoring.json',
        );
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        expect(manifest['canonical_step'], '113.42');
        expect(manifest['status'], 'VERIFIED-LOCAL');

        final signals = manifest['signals'] as Map<String, dynamic>;
        expect(signals.keys.toSet(), kReleaseHealthSignals.toSet());
        for (final name in kReleaseHealthSignals) {
          final signal = signals[name] as Map<String, dynamic>;
          expect((signal['threshold'] as String).trim(), isNotEmpty);
          expect(
            signal['direction'],
            isIn(<String>['higher_is_better', 'lower_is_better']),
          );
          expect((signal['window_hours'] as int) > 0, isTrue);
          expect(
            signal['privacy_safe'],
            isTrue,
            reason: '$name must be privacy-safe',
          );
          expect(
            (signal['collection'] as String).trim(),
            isNotEmpty,
            reason: '$name needs a collection method',
          );
          expect(
            signal['observed_status'],
            isNull,
            reason: 'no live telemetry yet — must not fake observations',
          );
          expect(
            signal['implementation'],
            'definition_ready_pipeline_deferred',
          );
        }
      },
    );

    test('privacy block captures no identifiers', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final privacy = manifest['privacy'] as Map<String, dynamic>;
      expect(privacy['pii_captured'], isFalse);
      expect(privacy['identifiers'], 'none');
      expect(
        privacy['mode'],
        contains('aggregate'),
        reason: 'collection must be aggregate-only',
      );
      expect(
        privacy['note'],
        contains('no PII'),
        reason: 'privacy note must state no PII explicitly',
      );
      expect(privacy['retention'], isNotEmpty);

      // The raw manifest must not carry identifier field names.
      final serialized = manifestFile.readAsStringSync().toLowerCase();
      for (final banned in <String>[
        'device_id',
        'deviceid',
        'user_id',
        'userid',
        'email',
        'ip_address',
        'phone',
      ]) {
        expect(
          serialized.contains(banned),
          isFalse,
          reason: 'manifest must not reference $banned',
        );
      }
    });

    test('domain evaluation: blocked, missing, breach, and pass', () {
      expect(
        ReleaseHealthMonitoring.evaluate(null).state,
        ReleaseHealthState.blocked,
      );
      expect(
        ReleaseHealthMonitoring.evaluate(const ReleaseHealthMonitoring()).state,
        ReleaseHealthState.blocked,
      );

      HealthSignal wellDefined(String name) => HealthSignal(
        signal: name,
        threshold: 'within threshold',
        direction: 'higher_is_better',
        privacySafe: true,
        collection: 'aggregate counters',
      );

      // One missing canonical signal -> fail naming it.
      final missingOne = ReleaseHealthMonitoring(
        signals: kReleaseHealthSignals
            .take(kReleaseHealthSignals.length - 1)
            .map(wellDefined)
            .toList(),
        privacyMode: 'aggregate no PII',
      );
      final missingEval = ReleaseHealthMonitoring.evaluate(missingOne);
      expect(missingEval.state, ReleaseHealthState.fail);
      expect(missingEval.notes.single, contains('support_severity'));

      // A leaking signal -> fail naming it.
      final leaky = ReleaseHealthMonitoring(
        signals: kReleaseHealthSignals
            .map(
              (name) => name == 'crash_rate'
                  ? HealthSignal(
                      signal: name,
                      threshold: '<= 0.5%',
                      direction: 'lower_is_better',
                      privacySafe: false,
                      collection: 'per-user session stream',
                    )
                  : wellDefined(name),
            )
            .toList(),
        privacyMode: 'aggregate no PII',
      );
      final leakyEval = ReleaseHealthMonitoring.evaluate(leaky);
      expect(leakyEval.state, ReleaseHealthState.fail);
      expect(leakyEval.notes.single, contains('crash_rate'));

      // Observed breach -> fail naming the breaching signal.
      final breached = ReleaseHealthMonitoring(
        signals: kReleaseHealthSignals
            .map(
              (name) => name == 'upgrade_success'
                  ? HealthSignal(
                      signal: name,
                      threshold: '>= 99%',
                      direction: 'higher_is_better',
                      privacySafe: true,
                      collection: 'aggregate counters',
                      observedStatus: HealthStatus.breach,
                    )
                  : wellDefined(name),
            )
            .toList(),
        privacyMode: 'aggregate no PII',
      );
      final breachEval = ReleaseHealthMonitoring.evaluate(breached);
      expect(breachEval.state, ReleaseHealthState.fail);
      expect(breachEval.notes.single, contains('upgrade_success'));

      // Complete + privacy-safe + no breach -> pass with counts.
      final complete = ReleaseHealthMonitoring(
        signals: kReleaseHealthSignals.map(wellDefined).toList(),
        privacyMode: 'aggregate no PII',
      );
      final passed = ReleaseHealthMonitoring.evaluate(complete);
      expect(passed.state, ReleaseHealthState.pass);
      expect(passed.notes.join(' '), contains('signals defined: 7'));
      expect(passed.notes.join(' '), contains('observed: 0/7'));
      expect(passed.notes.join(' '), contains('aggregate no PII'));
    });
  });
}
