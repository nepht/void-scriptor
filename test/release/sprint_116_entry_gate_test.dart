import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_entry_gate.dart';

void main() {
  group('116.1 Sprint Entry Gate', () {
    test('declares the canonical evidence and source boundaries', () {
      expect(Sprint116EntryGateContract.canonicalStep, '116.1');
      expect(Sprint116EntryGateContract.requiredEvidence, <String>[
        'sprint_115_acceptance',
        'provider_registry',
        'connector_manifests',
        'test_environment_plan',
        'security_plan',
        'brand_review_plan',
      ]);
      expect(
        Sprint116EntryGateContract.requiredSources,
        containsAll(<String>[
          'docs/planning/v1.2/sprint_115_alpha_acceptance.json',
          'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
          'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
          'docs/planning/v1.2/sprint_115_automated_test_matrix.json',
          'docs/planning/v1.2/sprint_115_security_billing_verification.json',
          'docs/planning/v1.2/sprint_114_security_privacy_maintenance.json',
        ]),
      );
      expect(
        Sprint116EntryGateContract.manifestPath,
        'docs/planning/v1.2/sprint_116_entry_gate.json',
      );
    });

    test('manifest binds every required evidence item to a source file', () {
      final manifest = _readManifest();

      expect(manifest['canonical_step'], '116.1');
      expect(manifest['title'], 'Sprint Entry Gate');
      expect(
        manifest['required_evidence'],
        Sprint116EntryGateContract.requiredEvidence,
      );
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['verdict'], 'CERTIFICATION_ENTRY_READY');
      expect(manifest['active_scope'], 'CERTIFICATION_SCOPE_APPROVED');
      expect(manifest['full_scope_approved'], isFalse);
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');

      final evidence = _asObject(manifest['evidence']);
      expect(evidence.keys.toSet(), {
        'sprint_115_acceptance',
        'provider_registry',
        'connector_manifests',
        'test_environment_plan',
        'security_plan',
        'brand_review_plan',
      });
      for (final item in Sprint116EntryGateContract.requiredEvidence) {
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
      final report = Sprint116EntryGate().evaluate();

      expect(report.state, Sprint116EntryGateState.pass);
      expect(report.verdict, 'CERTIFICATION_ENTRY_READY');
      expect(report.missingEvidence, isEmpty);
      expect(report.invalidEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.activeScope, 'VERIFIED-LOCAL');
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
      final report = Sprint116EntryGate().evaluate(
        <String, Sprint116EntryEvidence>{
          'sprint_115_acceptance': Sprint116EntryEvidence(
            status: 'VERIFIED-LOCAL',
            sources: <String>[
              'docs/planning/v1.2/sprint_115_alpha_acceptance.json',
            ],
          ),
        },
      );

      expect(report.state, Sprint116EntryGateState.blocked);
      expect(
        report.missingEvidence,
        containsAll(<String>[
          'provider_registry',
          'connector_manifests',
          'test_environment_plan',
          'security_plan',
          'brand_review_plan',
        ]),
      );
      expect(report.verdict, 'SPRINT_116_ENTRY_BLOCKED');
    });

    test(
      'blank status, source, or explicit full-scope approval fail closed',
      () {
        final malformed = Sprint116EntryGate().evaluate(
          <String, Sprint116EntryEvidence>{
            for (final item in Sprint116EntryGateContract.requiredEvidence)
              item: Sprint116EntryEvidence(
                status: item == 'provider_registry' ? ' ' : 'VERIFIED-LOCAL',
                sources: <String>[
                  if (item != 'sprint_115_acceptance') 'pubspec.yaml',
                ],
              ),
          },
        );
        final unsupportedScope = Sprint116EntryGate().evaluate(
          <String, Sprint116EntryEvidence>{
            for (final entry in _completeEvidence().entries)
              entry.key: entry.key == 'sprint_115_acceptance'
                  ? Sprint116EntryEvidence(
                      status: 'FULL_SCOPE_APPROVED',
                      sources: <String>[
                        'docs/planning/v1.2/sprint_116_entry_gate.json',
                      ],
                    )
                  : entry.value,
          },
        );

        expect(malformed.state, Sprint116EntryGateState.fail);
        expect(malformed.invalidEvidence, contains('provider_registry'));
        expect(malformed.invalidEvidence, contains('sprint_115_acceptance'));
        expect(unsupportedScope.state, Sprint116EntryGateState.fail);
        expect(
          unsupportedScope.violations,
          contains('full_scope_not_approved_on_certification_entry_gate'),
        );
      },
    );

    test(
      'provider registry and connector manifests forbid fabricated availability',
      () {
        final registry =
            jsonDecode(
                  File(
                    'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final connector =
            jsonDecode(
                  File(
                    'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;

        expect(registry['schema_version'], isNotEmpty);
        expect(connector['schema_version'], isNotEmpty);
        expect(connector['required_fields'], isA<List<dynamic>>());
        expect(
          (connector['required_fields'] as List<dynamic>).contains(
            'availability',
          ),
          isTrue,
        );
      },
    );

    test(
      'entry gate explicitly defers public readiness and provider proof',
      () {
        final manifest = _readManifest();

        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
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
        File(Sprint116EntryGateContract.manifestPath).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

Map<String, dynamic> _asObject(Object? value) {
  expect(value, isA<Map<String, dynamic>>());
  return value as Map<String, dynamic>;
}

Map<String, Sprint116EntryEvidence> _completeEvidence() {
  return <String, Sprint116EntryEvidence>{
    for (final item in Sprint116EntryGateContract.requiredEvidence)
      item: Sprint116EntryEvidence(
        status: 'VERIFIED-LOCAL',
        sources: <String>['pubspec.yaml'],
      ),
  };
}
