import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/support_documentation_maintenance_v114.dart';

void main() {
  group('114.34 Support & Documentation Maintenance', () {
    test('empty register is blocked without claiming maintenance', () {
      final report = SupportDocumentationMaintenanceRegister().evaluate();

      expect(report.state, SupportDocumentationMaintenanceState.blocked);
      expect(report.maintenanceCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete plan preserves all six canonical outputs', () {
      const plan = SupportDocumentationMaintenancePlan(
        maintenanceId: 'DOC-SUP-001',
        recoveryGuide: 'docs/release/v1.2.0-rc.1-recovery-guide.md',
        migrationNotes: 'docs/planning/v1.2/migration_backup_rollback_plan.md',
        knownIssues: 'docs/release/v1.2.0-rc.1-known-limits.md',
        troubleshooting:
            'docs/user/void_scriptor_user_guide.md#backup-and-restore',
        uiGuidance: <String>[
          'Read the recovery report before accepting restore.',
        ],
        supportMacros: <String>[
          'SUPPORT-STARTUP-001: preserve source and attach a redacted log.',
        ],
      );

      expect(SupportDocumentationMaintenancePlan.requiredFields(plan), isEmpty);
      final report = SupportDocumentationMaintenanceRegister()..add(plan);
      final evaluation = report.evaluate();

      expect(evaluation.state, SupportDocumentationMaintenanceState.pass);
      expect(evaluation.maintenanceCount, 1);
    });

    test('incomplete plan names every missing canonical output', () {
      final report = SupportDocumentationMaintenanceRegister()
        ..add(
          const SupportDocumentationMaintenancePlan(
            maintenanceId: '',
            recoveryGuide: '',
            migrationNotes: '',
            knownIssues: '',
            troubleshooting: '',
            uiGuidance: <String>[],
            supportMacros: <String>[],
          ),
        );

      final result = report.evaluate();
      final notes = result.limitations.join(' ');

      expect(result.state, SupportDocumentationMaintenanceState.fail);
      for (final field in <String>[
        'maintenance_id',
        'recovery_guide',
        'migration_notes',
        'known_issues',
        'troubleshooting',
        'ui_guidance',
        'support_macros',
      ]) {
        expect(notes, contains(field));
      }
    });

    test('whitespace-only guidance and support macros are invalid', () {
      const plan = SupportDocumentationMaintenancePlan(
        maintenanceId: 'DOC-SUP-002',
        recoveryGuide: 'recovery guide',
        migrationNotes: 'migration notes',
        knownIssues: 'known issues',
        troubleshooting: 'troubleshooting',
        uiGuidance: <String>['   '],
        supportMacros: <String>['\t'],
      );

      expect(
        SupportDocumentationMaintenancePlan.requiredFields(plan),
        containsAll(<String>['ui_guidance', 'support_macros']),
      );
    });

    test('support macros are reusable by key without duplicating text', () {
      const plan = SupportDocumentationMaintenancePlan(
        maintenanceId: 'DOC-SUP-003',
        recoveryGuide: 'recovery guide',
        migrationNotes: 'migration notes',
        knownIssues: 'known issues',
        troubleshooting: 'troubleshooting',
        uiGuidance: <String>['Read the recovery report.'],
        supportMacros: <String>[
          'SUPPORT-RESTORE-001: verify the restored copy.',
        ],
      );
      final register = SupportDocumentationMaintenanceRegister()..add(plan);

      expect(
        register.macro('SUPPORT-RESTORE-001'),
        'SUPPORT-RESTORE-001: verify the restored copy.',
      );
      expect(register.macro('SUPPORT-MISSING-001'), isNull);
    });

    test('manifest records all six outputs and local evidence boundaries', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_support_documentation_maintenance.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.34');
      expect(
        manifest['outputs'],
        containsAll(<String>[
          'recovery_guide',
          'migration_notes',
          'known_issues',
          'troubleshooting',
          'ui_guidance',
          'support_macros',
        ]),
      );
      final sources = manifest['sources'] as Map<String, dynamic>;
      for (final source in sources.values) {
        final path = (source! as String).split('#').first;
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(manifest['limits'], isNotEmpty);
    });
  });
}
