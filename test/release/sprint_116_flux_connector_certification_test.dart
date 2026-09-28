import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_flux_connector_certification.dart';

void main() {
  group('116.24 FLUX Connector Certification', () {
    test('requires the nine FLUX connector certification fields', () {
      expect(Sprint116FluxContract.requiredFields, <String>[
        'provider_id',
        'endpoint_provider_path',
        'image_jobs',
        'progress',
        'cancellation',
        'usage',
        'cost',
        'content_safety',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live FLUX claims', () {
      final report = Sprint116FluxCertification().evaluate([
        Sprint116FluxRecord(
          providerId: 'flux',
          endpointProviderPath: 'synthetic endpoint fixture',
          imageJobs: 'synthetic image jobs fixture',
          progress: 'synthetic progress fixture',
          cancellation: 'synthetic cancellation fixture',
          usage: 'synthetic usage fixture',
          cost: 'synthetic cost fixture',
          contentSafety: 'synthetic content safety fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116FluxState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing FLUX controls fail closed', () {
      final report = Sprint116FluxCertification().evaluate([
        Sprint116FluxRecord(
          providerId: 'flux',
          endpointProviderPath: '',
          imageJobs: '',
          progress: '',
          cancellation: '',
          usage: '',
          cost: '',
          contentSafety: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116FluxState.fail);
      expect(report.invalidRecords, contains('endpoint_provider_path:flux'));
      expect(report.invalidRecords, contains('image_jobs:flux'));
      expect(report.invalidRecords, contains('progress:flux'));
      expect(report.invalidRecords, contains('cancellation:flux'));
      expect(report.invalidRecords, contains('usage:flux'));
      expect(report.invalidRecords, contains('cost:flux'));
      expect(report.invalidRecords, contains('content_safety:flux'));
      expect(report.invalidRecords, contains('errors:flux'));
      expect(report.invalidRecords, contains('limitations:flux'));
    });

    test('manifest is local-only and does not claim certified FLUX access', () {
      final manifest =
          jsonDecode(
                File(Sprint116FluxContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.24');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['records'], isNotEmpty);
      for (final record in manifest['records'] as List<dynamic>) {
        expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
      }
    });
  });
}
