import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_openai_connector_certification.dart';

void main() {
  group('116.21 OpenAI Connector Certification', () {
    test('requires the eight OpenAI connector certification fields', () {
      expect(Sprint116OpenAiContract.requiredFields, <String>[
        'provider_id',
        'supported_modalities',
        'models',
        'auth',
        'cancellation',
        'usage_metadata',
        'cost_labels',
        'privacy',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live OpenAI claims', () {
      final report = Sprint116OpenAiCertification().evaluate([
        Sprint116OpenAiRecord(
          providerId: 'openai',
          supportedModalities: 'synthetic text and image fixture',
          models: 'synthetic model fixture',
          auth: 'synthetic credential reference fixture',
          cancellation: 'synthetic cancellation fixture',
          usageMetadata: 'synthetic usage fixture',
          costLabels: 'synthetic cost-label fixture',
          privacy: 'synthetic privacy fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116OpenAiState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing OpenAI controls fail closed', () {
      final report = Sprint116OpenAiCertification().evaluate([
        Sprint116OpenAiRecord(
          providerId: 'openai',
          supportedModalities: '',
          models: '',
          auth: '',
          cancellation: '',
          usageMetadata: '',
          costLabels: '',
          privacy: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116OpenAiState.fail);
      expect(report.invalidRecords, contains('supported_modalities:openai'));
      expect(report.invalidRecords, contains('models:openai'));
      expect(report.invalidRecords, contains('auth:openai'));
      expect(report.invalidRecords, contains('cancellation:openai'));
      expect(report.invalidRecords, contains('usage_metadata:openai'));
      expect(report.invalidRecords, contains('cost_labels:openai'));
      expect(report.invalidRecords, contains('privacy:openai'));
      expect(report.invalidRecords, contains('errors:openai'));
      expect(report.invalidRecords, contains('limitations:openai'));
    });

    test(
      'manifest is local-only and does not claim certified OpenAI access',
      () {
        final manifest =
            jsonDecode(
                  File(Sprint116OpenAiContract.manifestPath).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.21');
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
