import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_anthropic_connector_certification.dart';

void main() {
  group('116.23 Anthropic Connector Certification', () {
    test('requires the eight Anthropic connector certification fields', () {
      expect(Sprint116AnthropicContract.requiredFields, <String>[
        'provider_id',
        'models',
        'auth',
        'streaming',
        'cancellation',
        'usage_metadata',
        'cost_labels',
        'privacy',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live Anthropic claims', () {
      final report = Sprint116AnthropicCertification().evaluate([
        Sprint116AnthropicRecord(
          providerId: 'anthropic',
          models: 'synthetic model fixture',
          auth: 'synthetic credential reference fixture',
          streaming: 'synthetic streaming fixture',
          cancellation: 'synthetic cancellation fixture',
          usageMetadata: 'synthetic usage fixture',
          costLabels: 'synthetic cost-label fixture',
          privacy: 'synthetic privacy fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116AnthropicState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing Anthropic controls fail closed', () {
      final report = Sprint116AnthropicCertification().evaluate([
        Sprint116AnthropicRecord(
          providerId: 'anthropic',
          models: '',
          auth: '',
          streaming: '',
          cancellation: '',
          usageMetadata: '',
          costLabels: '',
          privacy: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116AnthropicState.fail);
      expect(report.invalidRecords, contains('models:anthropic'));
      expect(report.invalidRecords, contains('auth:anthropic'));
      expect(report.invalidRecords, contains('streaming:anthropic'));
      expect(report.invalidRecords, contains('cancellation:anthropic'));
      expect(report.invalidRecords, contains('usage_metadata:anthropic'));
      expect(report.invalidRecords, contains('cost_labels:anthropic'));
      expect(report.invalidRecords, contains('privacy:anthropic'));
      expect(report.invalidRecords, contains('errors:anthropic'));
      expect(report.invalidRecords, contains('limitations:anthropic'));
    });

    test(
      'manifest is local-only and does not claim certified Anthropic access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116AnthropicContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.23');
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
