import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_local_ai_certification.dart';

void main() {
  group('116.26 Local AI Certification', () {
    test('requires the seven local AI certification fields', () {
      expect(Sprint116LocalAiContract.requiredFields, <String>[
        'provider_id',
        'model_discovery',
        'hardware_limits',
        'storage',
        'lifecycle',
        'privacy',
        'offline_use',
        'failure_isolation',
      ]);
    });

    test(
      'synthetic local manifest passes without hardware or live-model claims',
      () {
        final report = Sprint116LocalAiCertification().evaluate([
          Sprint116LocalAiRecord(
            providerId: 'local_ai',
            modelDiscovery: 'synthetic model discovery fixture',
            hardwareLimits: 'synthetic hardware limits fixture',
            storage: 'synthetic storage fixture',
            lifecycle: 'synthetic lifecycle fixture',
            privacy: 'synthetic privacy fixture',
            offlineUse: 'synthetic offline fixture',
            failureIsolation: 'synthetic failure isolation fixture',
          ),
        ]);
        expect(report.state, Sprint116LocalAiState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing local AI controls fail closed', () {
      final report = Sprint116LocalAiCertification().evaluate([
        Sprint116LocalAiRecord(
          providerId: 'local_ai',
          modelDiscovery: '',
          hardwareLimits: '',
          storage: '',
          lifecycle: '',
          privacy: '',
          offlineUse: '',
          failureIsolation: '',
        ),
      ]);
      expect(report.state, Sprint116LocalAiState.fail);
      expect(report.invalidRecords, contains('model_discovery:local_ai'));
      expect(report.invalidRecords, contains('hardware_limits:local_ai'));
      expect(report.invalidRecords, contains('storage:local_ai'));
      expect(report.invalidRecords, contains('lifecycle:local_ai'));
      expect(report.invalidRecords, contains('privacy:local_ai'));
      expect(report.invalidRecords, contains('offline_use:local_ai'));
      expect(report.invalidRecords, contains('failure_isolation:local_ai'));
    });

    test(
      'manifest is local-only and does not claim certified local AI access',
      () {
        final manifest = Sprint116LocalAiCertification.readManifestForTest();
        expect(manifest['canonical_step'], '116.26');
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
