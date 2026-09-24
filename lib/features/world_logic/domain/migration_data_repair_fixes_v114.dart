/// Dependency-free contract for Sprint 114.31 migration/data repair fixes.
enum MigrationRepairState { pass, fail, blocked }

class MigrationDataRepairFix {
  const MigrationDataRepairFix({
    required this.issueId,
    required this.backupFirst,
    required this.repairPreview,
    required this.recordComparison,
    required this.checksum,
    required this.rollback,
    required this.auditLog,
  });

  final String issueId;
  final String backupFirst;
  final String repairPreview;
  final String recordComparison;
  final String checksum;
  final String rollback;
  final String auditLog;

  static List<String> requiredFields(MigrationDataRepairFix fix) {
    final missing = <String>[];
    if (fix.issueId.trim().isEmpty) missing.add('issue_id');
    if (fix.backupFirst.trim().isEmpty) missing.add('backup_first');
    if (fix.repairPreview.trim().isEmpty) missing.add('repair_preview');
    if (fix.recordComparison.trim().isEmpty) missing.add('record_comparison');
    if (fix.checksum.trim().isEmpty) missing.add('checksum');
    if (fix.rollback.trim().isEmpty) missing.add('rollback');
    if (fix.auditLog.trim().isEmpty) missing.add('audit_log');
    return missing;
  }
}

class MigrationDataRepairReport {
  const MigrationDataRepairReport({
    required this.state,
    required this.fixCount,
    required this.limitations,
  });

  final MigrationRepairState state;
  final int fixCount;
  final List<String> limitations;
}

class MigrationDataRepairFixRegister {
  final List<MigrationDataRepairFix> _fixes = <MigrationDataRepairFix>[];

  void add(MigrationDataRepairFix fix) => _fixes.add(fix);

  MigrationDataRepairReport evaluate() {
    if (_fixes.isEmpty) {
      return const MigrationDataRepairReport(
        state: MigrationRepairState.blocked,
        fixCount: 0,
        limitations: <String>[
          'No migration/data repair fix is available; no repair is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final fix in _fixes) {
      for (final field in MigrationDataRepairFix.requiredFields(fix)) {
        limitations.add(
          '${fix.issueId.trim().isEmpty ? '<unknown>' : fix.issueId} missing $field',
        );
      }
    }
    return MigrationDataRepairReport(
      state: limitations.isEmpty
          ? MigrationRepairState.pass
          : MigrationRepairState.fail,
      fixCount: _fixes.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
