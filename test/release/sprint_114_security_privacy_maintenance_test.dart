import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/security_privacy_maintenance_v114.dart';

void main() {
  group('114.32 Security & Privacy Maintenance', () {
    test(
      'empty register is blocked without claiming security/privacy maintenance',
      () {
        final report = SecurityPrivacyMaintenanceRegister().evaluate();

        expect(report.state, SecurityPrivacyMaintenanceState.blocked);
        expect(report.maintenanceCount, 0);
        expect(report.limitations, isNotEmpty);
      },
    );

    test('complete maintenance records all seven canonical outputs', () {
      const plan = SecurityPrivacyMaintenancePlan(
        maintenanceId: 'SEC-MAINT-001',
        fixes: <String>[
          'Planned fix: reject untrusted archive paths before local writes.',
        ],
        securityTests: <String>[
          'test/release/sprint_113_security_revalidation_test.dart',
        ],
        privacyTests: <String>[
          'test/release/sprint_114_privacy_safe_monitoring_test.dart',
        ],
        threatUpdate:
            'Updated STRIDE threat model: untrusted workspace import path boundary.',
        dataFlowUpdate:
            'Documented data boundary: imported manifests remain in memory during pre-validation.',
        dependencyUpdate:
            'Local lockfile review recorded; live vulnerability lookup remains deferred.',
        advisory:
            'Internal security advisory SECADV-2026-001 recorded for v1.2.1.',
      );

      expect(SecurityPrivacyMaintenancePlan.requiredFields(plan), isEmpty);
      final report = SecurityPrivacyMaintenanceRegister()..add(plan);
      final evaluation = report.evaluate();
      expect(evaluation.state, SecurityPrivacyMaintenanceState.pass);
      expect(evaluation.maintenanceCount, 1);
    });

    test('incomplete maintenance names every missing output', () {
      final report = SecurityPrivacyMaintenanceRegister()
        ..add(
          const SecurityPrivacyMaintenancePlan(
            maintenanceId: '',
            fixes: <String>[],
            securityTests: <String>[],
            privacyTests: <String>[],
            threatUpdate: '',
            dataFlowUpdate: '',
            dependencyUpdate: '',
            advisory: '',
          ),
        );
      final result = report.evaluate();

      expect(result.state, SecurityPrivacyMaintenanceState.fail);
      final notes = result.limitations.join(' ');
      for (final field in <String>[
        'maintenance_id',
        'fixes',
        'security_tests',
        'privacy_tests',
        'threat_update',
        'data_flow_update',
        'dependency_update',
        'advisory',
      ]) {
        expect(notes, contains(field));
      }
    });

    test('manifest records the canonical outputs and external limits', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_security_privacy_maintenance.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.32');
      expect(
        manifest['outputs'],
        containsAll(<String>[
          'fixes',
          'security_tests',
          'privacy_tests',
          'threat_update',
          'data_flow_update',
          'dependency_update',
          'advisory',
        ]),
      );
      expect(manifest['limits'], isNotEmpty);
    });
  });
}
