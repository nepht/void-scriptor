import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_openrouter_connector_certification.dart';

void main() {
  group('116.25 OpenRouter Connector Certification', () {
    test('requires the eight OpenRouter connector certification fields', () {
      expect(Sprint116OpenRouterContract.requiredFields, <String>[
        'provider_id',
        'routing_metadata',
        'models',
        'provider_fallback',
        'usage',
        'cost',
        'privacy_destination',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live OpenRouter claims', () {
      final report = Sprint116OpenRouterCertification().evaluate([
        Sprint116OpenRouterRecord(
          providerId: 'openrouter',
          routingMetadata: 'synthetic routing metadata fixture',
          models: 'synthetic models fixture',
          providerFallback: 'synthetic provider fallback fixture',
          usage: 'synthetic usage fixture',
          cost: 'synthetic cost fixture',
          privacyDestination: 'synthetic privacy destination fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116OpenRouterState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing OpenRouter controls fail closed', () {
      final report = Sprint116OpenRouterCertification().evaluate([
        Sprint116OpenRouterRecord(
          providerId: 'openrouter',
          routingMetadata: '',
          models: '',
          providerFallback: '',
          usage: '',
          cost: '',
          privacyDestination: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116OpenRouterState.fail);
      expect(report.invalidRecords, contains('routing_metadata:openrouter'));
      expect(report.invalidRecords, contains('models:openrouter'));
      expect(report.invalidRecords, contains('provider_fallback:openrouter'));
      expect(report.invalidRecords, contains('usage:openrouter'));
      expect(report.invalidRecords, contains('cost:openrouter'));
      expect(report.invalidRecords, contains('privacy_destination:openrouter'));
      expect(report.invalidRecords, contains('errors:openrouter'));
      expect(report.invalidRecords, contains('limitations:openrouter'));
    });

    test(
      'manifest is local-only and does not claim certified OpenRouter access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116OpenRouterContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.25');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
