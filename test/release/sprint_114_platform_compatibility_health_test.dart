import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/platform_compatibility_health.dart';

void main() {
  group('114.19 Platform Compatibility Health', () {
    test('absent observations are blocked without health claims', () {
      final report = PlatformCompatibilityHealth().evaluate(null);

      expect(report.state, PlatformCompatibilityState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete dimension coverage fails with signals invalid field', () {
      final report = PlatformCompatibilityHealth()
          .evaluate(<PlatformObservation>[
            const PlatformObservation(
              signal: PlatformSignal.platform,
              outcome: PlatformOutcome.ok,
              note: 'Windows 11 x64 incident parity within baseline.',
            ),
          ]);

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <PlatformSignal>[PlatformSignal.platform]);
    });

    test('observation without a note is invalid evidence', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.ok,
          renderingNote: '',
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('claiming ok dimensions while packaging failed is ignored', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.failed,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('package_recovery_ignored'));
    });

    test('failed rendering with broken package is unrecovered', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.failed,
          package: PlatformOutcome.failed,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('rendering_unrecovered'));
      expect(report.violations, contains('package_recovery_ignored'));
    });

    test('failed filesystem with healthy package is unrecovered', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.failed,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.ok,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('filesystem_unrecovered'));
      expect(report.violations, isNot(contains('package_recovery_ignored')));
    });

    test('failed os_version with healthy package is unrecovered', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.failed,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.ok,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('os_version_unrecovered'));
      expect(report.violations, isNot(contains('package_recovery_ignored')));
    });

    test('failed input with honestly recovered package passes', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.failed,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.recovered,
        ),
      );

      expect(report.state, PlatformCompatibilityState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('failed hardware with honestly recovered package passes', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.failed,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.recovered,
        ),
      );

      expect(report.state, PlatformCompatibilityState.pass);
      expect(report.violations, isEmpty);
    });

    test('failed platform with healthy package is unrecovered', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.failed,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.ok,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('platform_unrecovered'));
    });

    test('failed os_version while platform claims ok ignores packaging', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.failed,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.failed,
        ),
      );

      expect(report.state, PlatformCompatibilityState.fail);
      expect(report.violations, contains('package_recovery_ignored'));
      expect(report.violations, contains('os_version_unrecovered'));
    });

    test('fully covered consistent record verifies all seven dimensions', () {
      final report = PlatformCompatibilityHealth().evaluate(
        _observations(
          platform: PlatformOutcome.ok,
          osVersion: PlatformOutcome.ok,
          hardware: PlatformOutcome.ok,
          filesystem: PlatformOutcome.ok,
          input: PlatformOutcome.ok,
          rendering: PlatformOutcome.ok,
          package: PlatformOutcome.ok,
        ),
      );

      expect(report.state, PlatformCompatibilityState.pass);
      expect(report.coveredSignals, <PlatformSignal>[
        PlatformSignal.platform,
        PlatformSignal.osVersion,
        PlatformSignal.hardware,
        PlatformSignal.filesystem,
        PlatformSignal.input,
        PlatformSignal.rendering,
        PlatformSignal.package,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_platform_compatibility_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.19');
      expect(document['required_evidence'], <dynamic>[
        'platform',
        'os_version',
        'hardware',
        'filesystem',
        'input',
        'rendering',
        'package',
      ]);
      expect(document['root_recovery_signal'], 'package');
      expect(document['native_platform_validation'], 'DEFERRED-EXTERNAL');
      expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<PlatformObservation> _observations({
  required PlatformOutcome platform,
  required PlatformOutcome osVersion,
  required PlatformOutcome hardware,
  required PlatformOutcome filesystem,
  required PlatformOutcome input,
  required PlatformOutcome rendering,
  required PlatformOutcome package,
  String? renderingNote,
}) {
  return <PlatformObservation>[
    PlatformObservation(
      signal: PlatformSignal.platform,
      outcome: platform,
      note: 'Incident and performance parity per supported platform.',
    ),
    PlatformObservation(
      signal: PlatformSignal.osVersion,
      outcome: osVersion,
      note: 'Supported OS versions open, migrate, and export correctly.',
    ),
    PlatformObservation(
      signal: PlatformSignal.hardware,
      outcome: hardware,
      note: 'Hardware profiles stay within memory and storage budgets.',
    ),
    PlatformObservation(
      signal: PlatformSignal.filesystem,
      outcome: filesystem,
      note: 'Path, permission, and case-sensitivity behavior is consistent.',
    ),
    PlatformObservation(
      signal: PlatformSignal.input,
      outcome: input,
      note: 'Keyboard, mouse, and high-DPI input behave consistently.',
    ),
    PlatformObservation(
      signal: PlatformSignal.rendering,
      outcome: rendering,
      note: renderingNote ?? 'Window and surface rendering stay artifact-free.',
    ),
    PlatformObservation(
      signal: PlatformSignal.package,
      outcome: package,
      note: 'Package installs, upgrades, and rolls back per platform.',
    ),
  ];
}
