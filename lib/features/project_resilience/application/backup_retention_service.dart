import 'project_resilience_repository.dart';

class BackupInfo {
  const BackupInfo({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String type;
  final DateTime createdAt;
}

/// Backup retention enforcement (Step 24.26).
///
/// Automatic and manual backups have independent retention budgets. When a
/// new backup pushes a category over its limit, the oldest backups in that
/// category are pruned. Manual backups are never evicted by automatic
/// pressure and vice-versa.
class BackupRetentionService {
  const BackupRetentionService({required this.policy});

  final BackupRetentionPolicy policy;

  List<BackupInfo> selectForPrune(Iterable<BackupInfo> backups) {
    final automatic = backups.where((b) => b.type == 'automatic').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final manual = backups.where((b) => b.type == 'manual').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final toPrune = <BackupInfo>[];
    if (automatic.length > policy.maxAutomatic) {
      toPrune.addAll(
        automatic.sublist(0, automatic.length - policy.maxAutomatic),
      );
    }
    if (manual.length > policy.maxManual) {
      toPrune.addAll(manual.sublist(0, manual.length - policy.maxManual));
    }
    return toPrune;
  }
}
