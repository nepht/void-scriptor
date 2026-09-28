import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_gemini_connector_certification.dart';

void main() {
  group('116.22 Gemini Connector Certification', () {
    test('requires the eight Gemini connector certification fields', () {
      expect(Sprint116GeminiContract.requiredFields, <String>[
        'provider_id',
        'supported_modalities',
        'models',
        'auth',
        'usage_metadata',
        'cost_labels',
        'privacy',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live Gemini claims', () {
      final report = Sprint116GeminiCertification().evaluate([
        Sprint116GeminiRecord(
          providerId: 'gemini',
          supportedModalities: 'synthetic text and image fixture',
          models: 'synthetic model fixture',
          auth: 'synthetic credential reference fixture',
          usageMetadata: 'synthetic usage fixture',
          costLabels: 'synthetic cost-label fixture',
          privacy: 'synthetic privacy fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116GeminiState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing Gemini controls fail closed', () {
      final report = Sprint116GeminiCertification().evaluate([
        Sprint116GeminiRecord(
          providerId: 'gemini',
          supportedModalities: '',
          models: '',
          auth: '',
          usageMetadata: '',
          costLabels: '',
          privacy: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116GeminiState.fail);
      expect(report.invalidRecords, contains('supported_modalities:gemini'));
      expect(report.invalidRecords, contains('models:gemini'));
      expect(report.invalidRecords, contains('auth:gemini'));
      expect(report.invalidRecords, contains('usage_metadata:gemini'));
      expect(report.invalidRecords, contains('cost_labels:gemini'));
      expect(report.invalidRecords, contains('privacy:gemini'));
      expect(report.invalidRecords, contains('errors:gemini'));
      expect(report.invalidRecords, contains('limitations:gemini'));
    });

    test('manifest is local-only and does not claim certified Gemini access', () {
      final manifest =
          jsonDecode(
                File(Sprint116GeminiContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.22');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['records'], isNotEmpty);
      for (final record in manifest['records'] as List<dynamic>) {
        expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
      }
    });
  });
}
