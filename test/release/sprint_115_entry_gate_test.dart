import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_115_entry_gate.dart';

void main() {
  group('115.1 Sprint Entry Gate', () {
    test('declares the canonical evidence and source boundaries', () {
      expect(Sprint115EntryGateContract.canonicalStep, '115.1');
      expect(Sprint115EntryGateContract.requiredEvidence, <String>[
        'sprint_114_readiness',
        'approved_scope',
        'product_spec',
        'security_constraints',
        'privacy_constraints',
        'provider_feasibility',
      ]);
      expect(
        Sprint115EntryGateContract.requiredSources,
        containsAll(<String>[
          'docs/planning/v1.2/sprint_115_readiness_gate.json',
          'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json',
          'docs/roadmap/ROADMAP_POLICY.json',
          'docs/planning/v1.2/sprint_114_security_privacy_maintenance.json',
        ]),
      );
      expect(
        Sprint115EntryGateContract.manifestPath,
        'docs/planning/v1.2/sprint_115_entry_gate.json',
      );
    });

    test('manifest binds every required evidence item to a source file', () {
      final manifest = _readManifest();

      expect(manifest['canonical_step'], '115.1');
      expect(manifest['title'], 'Sprint Entry Gate');
      expect(
        manifest['required_evidence'],
        Sprint115EntryGateContract.requiredEvidence,
      );
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['verdict'], 'CORRECTIVE_ENTRY_READY');
      expect(manifest['active_scope'], 'CORRECTIVE_SCOPE_APPROVED');
      expect(manifest['full_scope_approved'], isFalse);
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');

      final evidence = _asObject(manifest['evidence']);
      expect(evidence.keys.toSet(), {
        'sprint_114_readiness',
        'approved_scope',
        'product_spec',
        'security_constraints',
        'privacy_constraints',
        'provider_feasibility',
      });
      for (final item in Sprint115EntryGateContract.requiredEvidence) {
        final record = _asObject(evidence[item]);
        expect(record, isNotNull, reason: 'Missing evidence: $item');
        expect(record['status'], isNotEmpty, reason: 'Missing status: $item');
        final sources = record['sources'];
        expect(sources, isA<List<dynamic>>(), reason: 'Missing sources: $item');
        expect(sources, isNotEmpty, reason: 'Missing sources: $item');
        for (final source in sources.whereType<String>()) {
          expect(File(source).existsSync(), isTrue, reason: 'Missing $source');
        }
      }
    });

    test('live source inventory is valid and provider claims stay bounded', () {
      final report = Sprint115EntryGate().evaluate();

      expect(report.state, Sprint115EntryGateState.pass);
      expect(report.verdict, 'CORRECTIVE_ENTRY_READY');
      expect(report.missingEvidence, isEmpty);
      expect(report.invalidEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.activeScope, 'CORRECTIVE_SCOPE_APPROVED');
      expect(report.fullScopeApproved, isFalse);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.deferredProviderFeasibility,
        contains('live_provider_certification'),
      );
      expect(
        report.deferredProviderFeasibility,
        contains('public_billing_certification'),
      );
    });

    test('missing evidence blocks and names the canonical field', () {
      final report = Sprint115EntryGate().evaluate(
        <String, Sprint115EntryEvidence>{
          'sprint_114_readiness': Sprint115EntryEvidence(
            status: 'VERIFIED-LOCAL',
            sources: <String>[
              'docs/planning/v1.2/sprint_115_readiness_gate.json',
            ],
          ),
        },
      );

      expect(report.state, Sprint115EntryGateState.blocked);
      expect(
        report.missingEvidence,
        containsAll(<String>[
          'approved_scope',
          'product_spec',
          'security_constraints',
          'privacy_constraints',
          'provider_feasibility',
        ]),
      );
      expect(report.verdict, 'SPRINT_115_ENTRY_BLOCKED');
    });

    test(
      'blank status, source, or explicit full-scope approval fail closed',
      () {
        final malformed = Sprint115EntryGate().evaluate(
          <String, Sprint115EntryEvidence>{
            for (final item in Sprint115EntryGateContract.requiredEvidence)
              item: Sprint115EntryEvidence(
                status: item == 'product_spec' ? ' ' : 'VERIFIED-LOCAL',
                sources: <String>[if (item != 'approved_scope') 'pubspec.yaml'],
              ),
          },
        );
        final unsupportedScope = Sprint115EntryGate().evaluate(
          <String, Sprint115EntryEvidence>{
            for (final entry in _completeEvidence().entries)
              entry.key: entry.key == 'approved_scope'
                  ? Sprint115EntryEvidence(
                      status: 'FULL_SCOPE_APPROVED',
                      sources: <String>[
                        'docs/planning/v1.2/sprint_115_entry_gate.json',
                      ],
                    )
                  : entry.value,
          },
        );

        expect(malformed.state, Sprint115EntryGateState.fail);
        expect(malformed.invalidEvidence, contains('product_spec'));
        expect(malformed.invalidEvidence, contains('approved_scope'));
        expect(unsupportedScope.state, Sprint115EntryGateState.fail);
        expect(
          unsupportedScope.violations,
          contains('full_scope_not_approved_on_delayed_entry_gate'),
        );
      },
    );

    test('product spec and security policy forbid fabricated availability', () {
      final spec =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final delivery = _asObject(spec['delivery_rules']);
      final acceptance = spec['acceptance_invariants'] as List<dynamic>;

      expect(delivery['fabricated_provider_availability_allowed'], isFalse);
      expect(delivery['mock_quota_in_production_allowed'], isFalse);
      expect(delivery['mock_credit_in_production_allowed'], isFalse);
      expect(delivery['plaintext_secret_storage_allowed'], isFalse);
      expect(delivery['feature_flags_default'], 'OFF');
      expect(
        acceptance,
        contains('provider_availability_comes_from_connector_manifest'),
      );
      expect(
        acceptance,
        contains('secrets_are_never_stored_or_displayed_in_plaintext'),
      );
      expect(
        acceptance,
        contains('reference_mock_values_never_reach_production_state'),
      );
    });

    test(
      'entry gate explicitly defers public readiness and provider proof',
      () {
        final manifest = _readManifest();

        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['provider_feasibility'], 'DEFERRED-EXTERNAL');
        expect(manifest['limitations'], isNotEmpty);
        final deferred = manifest['deferred_checks'] as List<dynamic>;
        expect(deferred, contains('live_provider_certification'));
        expect(deferred, contains('public_billing_certification'));
        expect(deferred, contains('hosted_ci_validation'));
        expect(deferred, contains('publication'));
      },
    );
  });
}

Map<String, dynamic> _readManifest() {
  return jsonDecode(
        File(Sprint115EntryGateContract.manifestPath).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

Map<String, dynamic> _asObject(Object? value) {
  expect(value, isA<Map<String, dynamic>>());
  return value as Map<String, dynamic>;
}

Map<String, Sprint115EntryEvidence> _completeEvidence() {
  return <String, Sprint115EntryEvidence>{
    for (final item in Sprint115EntryGateContract.requiredEvidence)
      item: Sprint115EntryEvidence(
        status: 'VERIFIED-LOCAL',
        sources: <String>['pubspec.yaml'],
      ),
  };
}
