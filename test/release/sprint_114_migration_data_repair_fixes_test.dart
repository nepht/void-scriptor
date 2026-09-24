import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/migration_data_repair_fixes_v114.dart';

void main() {
  group('114.31 Migration & Data Repair Fixes', () {
    test('empty register is blocked without claiming a repair', () {
      final report = MigrationDataRepairFixRegister().evaluate();

      expect(report.state, MigrationRepairState.blocked);
      expect(report.fixCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete repair records all six safety requirements', () {
      const fix = MigrationDataRepairFix(
        issueId: 'MIG-001',
        backupFirst: 'Snapshot v1.2.0 before repair.',
        repairPreview:
            'Preview 3 orphan links; write set is empty until approved.',
        recordComparison: 'Compare row counts and stable IDs before and after.',
        checksum: 'sha256:abc123',
        rollback: 'Restore the verified snapshot if comparison fails.',
        auditLog: 'Local audit entry records operator, scope, and result.',
      );

      expect(MigrationDataRepairFix.requiredFields(fix), isEmpty);
      final report = MigrationDataRepairFixRegister()..add(fix);
      expect(report.evaluate().state, MigrationRepairState.pass);
      expect(report.evaluate().fixCount, 1);
    });

    test('incomplete repair names every missing requirement', () {
      final report = MigrationDataRepairFixRegister()
        ..add(
          const MigrationDataRepairFix(
            issueId: '',
            backupFirst: '',
            repairPreview: '',
            recordComparison: '',
            checksum: '',
            rollback: '',
            auditLog: '',
          ),
        );
      final result = report.evaluate();

      expect(result.state, MigrationRepairState.fail);
      expect(
        result.limitations.join(' '),
        allOf(
          contains('issue_id'),
          contains('backup_first'),
          contains('repair_preview'),
          contains('record_comparison'),
          contains('checksum'),
          contains('rollback'),
          contains('audit_log'),
        ),
      );
    });

    test('manifest records the canonical requirements and external limits', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_migration_data_repair_fixes.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.31');
      expect(
        manifest['requirements'],
        containsAll(<String>[
          'backup_first',
          'repair_preview',
          'record_comparison',
          'checksum',
          'rollback',
          'audit_log',
        ]),
      );
      expect(manifest['limits'], isNotEmpty);
    });
  });
}
