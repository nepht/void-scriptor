/// Sprint 50 — Step 50.88–50.91 Automatic Backup, Health Check, Repair.
class BackupPolicy {
  const BackupPolicy({
    required this.automaticBackups,
    required this.intervalHours,
    this.keepCount = 7,
  });

  final bool automaticBackups;
  final int intervalHours;
  final int keepCount;
}

class BackupHealth {
  const BackupHealth({
    required this.id,
    required this.lastBackupAt,
    required this.healthy,
  });

  final String id;
  final DateTime lastBackupAt;
  final bool healthy;
}

class HealthCheck {
  const HealthCheck({required this.id, required this.checks});

  final String id;
  final Map<String, bool> checks;

  // Fail-closed (PLAT-hunt-20260914 PLAT-BUG-01): `every` bernilai true secara
  // vacuous pada koleksi kosong — health check yang belum dijalankan bukan
  // "sehat". Butuh minimal satu pemeriksaan sebelum boleh meluluskan.
  bool get allPassed => checks.isNotEmpty && checks.values.every((v) => v);
}

class RepairAction {
  const RepairAction({
    required this.id,
    required this.target,
    required this.description,
    required this.performed,
  });

  final String id;
  final String target;
  final String description;
  final bool performed;
}
