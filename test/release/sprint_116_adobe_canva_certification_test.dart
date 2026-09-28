import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_adobe_canva_certification.dart';

void main() {
  group('116.33 Adobe & Canva Certification', () {
    test(
      'locks API, capability, licensing, scope, region and unavailable controls separately',
      () {
        expect(Sprint116AdobeCanvaContract.requiredFields, <String>[
          'provider_id',
          'actual_apis',
          'supported_capabilities',
          'licensing',
          'scopes',
          'region_plan_limits',
          'unavailable_states',
        ]);
      },
    );

    test(
      'synthetic local manifest passes without live Adobe or Canva claims',
      () {
        final report = Sprint116AdobeCanvaCertification().evaluate([
          Sprint116AdobeCanvaRecord(
            providerId: 'adobe',
            actualApis: 'synthetic actual api fixture',
            supportedCapabilities: 'synthetic supported capability fixture',
            licensing: 'synthetic licensing fixture',
            scopes: 'synthetic scope fixture',
            regionPlanLimits: 'synthetic region plan limit fixture',
            unavailableStates: 'synthetic unavailable state fixture',
          ),
          Sprint116AdobeCanvaRecord(
            providerId: 'canva',
            actualApis: 'synthetic actual api fixture',
            supportedCapabilities: 'synthetic supported capability fixture',
            licensing: 'synthetic licensing fixture',
            scopes: 'synthetic scope fixture',
            regionPlanLimits: 'synthetic region plan limit fixture',
            unavailableStates: 'synthetic unavailable state fixture',
          ),
        ]);
        expect(report.state, Sprint116AdobeCanvaState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing certification controls fail closed per provider', () {
      final report = Sprint116AdobeCanvaCertification().evaluate([
        Sprint116AdobeCanvaRecord(
          providerId: 'adobe',
          actualApis: '',
          supportedCapabilities: '',
          licensing: '',
          scopes: '',
          regionPlanLimits: '',
          unavailableStates: '',
        ),
        Sprint116AdobeCanvaRecord(
          providerId: 'canva',
          actualApis: 'synthetic actual api fixture',
          supportedCapabilities: 'synthetic supported capability fixture',
          licensing: 'synthetic licensing fixture',
          scopes: 'synthetic scope fixture',
          regionPlanLimits: 'synthetic region plan limit fixture',
          unavailableStates: '',
        ),
      ]);
      expect(report.state, Sprint116AdobeCanvaState.fail);
      expect(report.invalidRecords, contains('actual_apis:adobe'));
      expect(report.invalidRecords, contains('supported_capabilities:adobe'));
      expect(report.invalidRecords, contains('licensing:adobe'));
      expect(report.invalidRecords, contains('scopes:adobe'));
      expect(report.invalidRecords, contains('region_plan_limits:adobe'));
      expect(report.invalidRecords, contains('unavailable_states:adobe'));
      expect(report.invalidRecords, contains('unavailable_states:canva'));
      expect(report.invalidRecords.length, 7);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116AdobeCanvaCertification().evaluate([]);
      expect(report.state, Sprint116AdobeCanvaState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and does not claim certified Adobe or Canva access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116AdobeCanvaContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.33');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['provider_id'])
            .toList();
        expect(ids, containsAll(<String>['adobe', 'canva']));
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
