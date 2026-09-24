/// Test for Provider & External Dependency Health (Step 114.25).
///
/// Validates the seven canonical dependency-health signals and the
/// fail-closed rules for missing evidence, recovery, fallback, and consent.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/provider_external_dependency_health.dart';

const String _manifestPath =
    'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json';

ProviderObservation _observation(
  ProviderSignal signal, {
  ProviderOutcome outcome = ProviderOutcome.ok,
  String note = 'Recorded local review evidence.',
}) => ProviderObservation(signal: signal, outcome: outcome, note: note);

List<ProviderObservation> _complete({
  ProviderOutcome availability = ProviderOutcome.ok,
  ProviderOutcome timeout = ProviderOutcome.ok,
  ProviderOutcome throttling = ProviderOutcome.ok,
  ProviderOutcome authExpiry = ProviderOutcome.ok,
  ProviderOutcome costVisibility = ProviderOutcome.ok,
  ProviderOutcome fallback = ProviderOutcome.ok,
  ProviderOutcome consent = ProviderOutcome.ok,
}) => <ProviderObservation>[
  _observation(ProviderSignal.providerAvailability, outcome: availability),
  _observation(ProviderSignal.timeout, outcome: timeout),
  _observation(ProviderSignal.throttling, outcome: throttling),
  _observation(ProviderSignal.authExpiry, outcome: authExpiry),
  _observation(ProviderSignal.costVisibility, outcome: costVisibility),
  _observation(ProviderSignal.fallbackSuccess, outcome: fallback),
  _observation(ProviderSignal.consentFailure, outcome: consent),
];

void main() {
  group('114.25 Provider & External Dependency Health', () {
    test('canonical signals are ordered and complete', () {
      expect(ProviderHealth.canonicalSignals, <ProviderSignal>[
        ProviderSignal.providerAvailability,
        ProviderSignal.timeout,
        ProviderSignal.throttling,
        ProviderSignal.authExpiry,
        ProviderSignal.costVisibility,
        ProviderSignal.fallbackSuccess,
        ProviderSignal.consentFailure,
      ]);
    });

    test('absent observations are blocked without health claims', () {
      final report = ProviderExternalDependencyHealth().evaluate(null);
      expect(report.state, ProviderHealthState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
    });

    test('incomplete coverage fails closed', () {
      final report = ProviderExternalDependencyHealth().evaluate(
        <ProviderObservation>[_observation(ProviderSignal.timeout)],
      );
      expect(report.state, ProviderHealthState.fail);
      expect(report.invalidFields, contains('signals'));
    });

    test('blank evidence note is invalid', () {
      final observations = _complete();
      observations[0] = _observation(
        ProviderSignal.providerAvailability,
        note: ' ',
      );
      final report = ProviderExternalDependencyHealth().evaluate(observations);
      expect(report.state, ProviderHealthState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('timeout or throttling requires successful fallback', () {
      final report = ProviderExternalDependencyHealth().evaluate(
        _complete(
          timeout: ProviderOutcome.failed,
          fallback: ProviderOutcome.failed,
        ),
      );
      expect(report.state, ProviderHealthState.fail);
      expect(report.violations, contains('fallback_success_unrecovered'));
    });

    test('recovered fallback closes provider failure honestly', () {
      final report = ProviderExternalDependencyHealth().evaluate(
        _complete(
          availability: ProviderOutcome.failed,
          fallback: ProviderOutcome.recovered,
        ),
      );
      expect(report.state, ProviderHealthState.pass);
      expect(report.violations, isEmpty);
    });

    test('expired authentication requires consent-safe recovery', () {
      final report = ProviderExternalDependencyHealth().evaluate(
        _complete(
          authExpiry: ProviderOutcome.failed,
          consent: ProviderOutcome.failed,
        ),
      );
      expect(report.state, ProviderHealthState.fail);
      expect(report.violations, contains('consent_failure_unrecovered'));
    });

    test('failed consent cannot be hidden by a healthy provider', () {
      final report = ProviderExternalDependencyHealth().evaluate(
        _complete(consent: ProviderOutcome.failed),
      );
      expect(report.state, ProviderHealthState.fail);
      expect(report.violations, contains('consent_failure_unrecovered'));
    });

    test('complete healthy evidence passes and preserves observations', () {
      final observations = _complete();
      final report = ProviderExternalDependencyHealth().evaluate(observations);
      expect(report.state, ProviderHealthState.pass);
      expect(report.coveredSignals, ProviderHealth.canonicalSignals);
      expect(report.observations, hasLength(7));
      expect(report.notes.join(' '), contains('no credential'));
    });

    test('manifest records the canonical external boundaries', () {
      final manifest =
          jsonDecode(File(_manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '114.25');
      expect(manifest['signals'], hasLength(7));
      expect(manifest['credential_collection'], 'DISABLED-BY-CONTRACT');
      expect(manifest['external_transfer_consent'], 'DEFERRED-EXTERNAL');
    });
  });
}
