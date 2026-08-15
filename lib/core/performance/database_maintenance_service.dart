import '../../database/project/project_database.dart';

class DatabaseIntegrityResult {
  const DatabaseIntegrityResult({required this.healthy, this.details = ''});

  final bool healthy;
  final String details;
}

/// Database maintenance operations (Step 26.61).
///
/// `VACUUM` must not be run automatically too often because it can be heavy;
/// it is exposed here so the UI can run it as a background job after the DB is
/// in a safe state (Step 26.62).
class DatabaseMaintenanceService {
  DatabaseMaintenanceService(this._db);

  final ProjectDatabase _db;

  static const List<String> operations = [
    'Analyze',
    'Optimize',
    'Integrity Check',
    'Vacuum',
  ];

  Future<void> analyze() => _db.customStatement('ANALYZE');

  Future<void> optimize() => _db.customStatement('PRAGMA optimize');

  Future<DatabaseIntegrityResult> integrityCheck() async {
    final rows = await _db.customSelect('PRAGMA integrity_check').get();
    final details = rows.map((r) => r.data.values.join(' ')).join('\n');
    return DatabaseIntegrityResult(
      healthy: details.trim() == 'ok',
      details: details,
    );
  }

  Future<void> vacuum() => _db.customStatement('VACUUM');
}
