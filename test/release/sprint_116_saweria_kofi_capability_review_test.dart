import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_saweria_kofi_capability_review.dart';

void main() {
  group('116.39 Saweria & Ko-fi Capability Review', () {
    test(
      'locks api contract, terms reference, region limits, webhook surface, connector verdict and evidence refs',
      () {
        expect(Sprint116CapabilityContract.requiredFields, <String>[
          'api_contract',
          'terms_reference',
          'region_limits',
          'webhook_surface',
          'connector_verdict',
          'evidence_refs',
        ]);
      },
    );

    test(
      'local capability review records pass without claiming a supported connector',
      () {
        final report = Sprint116CapabilityReview().evaluate([
          Sprint116CapabilityRecord(
            providerId: 'saweria',
            apiContract: 'UNVERIFIED no public API doc at probed paths',
            termsReference: 'https://saweria.co/terms reachable',
            regionLimits: 'region limits unverified external',
            webhookSurface:
                'outbound webhook strings observed in client bundle',
            connectorVerdict: 'BLOCKED',
            evidenceRefs: 'curl probes 2026-09-28',
          ),
          Sprint116CapabilityRecord(
            providerId: 'kofi',
            apiContract: 'UNVERIFIED no public API doc at probed paths',
            termsReference: 'https://ko-fi.com/terms reachable',
            regionLimits: 'region limits unverified external',
            webhookSurface: 'developer webhook tool auth gated behind login',
            connectorVerdict: 'LIMITED',
            evidenceRefs: 'curl probes 2026-09-28',
          ),
        ]);
        expect(report.state, Sprint116CapabilityState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test(
      'supported verdict without verified contract and terms fails closed',
      () {
        final report = Sprint116CapabilityReview().evaluate([
          Sprint116CapabilityRecord(
            providerId: 'synthetic_premium_flow',
            apiContract: 'UNVERIFIED',
            termsReference: 'UNVERIFIED',
            regionLimits: '',
            webhookSurface: '',
            connectorVerdict: 'SUPPORTED',
            evidenceRefs: '',
          ),
          Sprint116CapabilityRecord(
            providerId: 'synthetic_fake_flow',
            apiContract: 'VERIFIED',
            termsReference: 'VERIFIED',
            regionLimits: 'region fixture',
            webhookSurface: 'webhook fixture',
            connectorVerdict: 'FAKE_CONNECTOR',
            evidenceRefs: 'evidence fixture',
          ),
        ]);
        expect(report.state, Sprint116CapabilityState.fail);
        expect(
          report.invalidRecords,
          contains('connector_verdict:synthetic_premium_flow'),
        );
        expect(
          report.invalidRecords,
          contains('region_limits:synthetic_premium_flow'),
        );
        expect(
          report.invalidRecords,
          contains('webhook_surface:synthetic_premium_flow'),
        );
        expect(
          report.invalidRecords,
          contains('evidence_refs:synthetic_premium_flow'),
        );
        expect(
          report.invalidRecords,
          contains('connector_verdict:synthetic_fake_flow'),
        );
      },
    );

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116CapabilityReview().evaluate([]);
      expect(report.state, Sprint116CapabilityState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only, records BLOCKED/LIMITED verdicts and carries no secrets',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116CapabilityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.39');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        final records = manifest['records'] as List<dynamic>;
        expect(records, isNotEmpty);
        final byProvider = <String, dynamic>{
          for (final record in records)
            (record as Map<String, dynamic>)['provider_id'].toString(): record,
        };
        expect(byProvider.keys, containsAll(<String>['saweria', 'kofi']));
        expect(byProvider['saweria']!['connector_verdict'], 'BLOCKED');
        expect(byProvider['kofi']!['connector_verdict'], 'LIMITED');
        for (final record in records) {
          final map = record as Map<String, dynamic>;
          expect(map['status'], 'UNVERIFIED');
          expect(map['connector_verdict'], isNot('SUPPORTED'));
          expect(
            (map['evidence_refs'] as String).trim(),
            isNotEmpty,
            reason: 'every verdict needs evidence references',
          );
        }
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
