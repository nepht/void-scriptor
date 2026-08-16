import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists audio automation curve points (Step 34.14).
class AutomationRepository {
  AutomationRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveCurvePoint({
    required String id,
    required String clipId,
    required String parameter,
    required String interpolation,
    required double timeSeconds,
    required double value,
  }) async {
    await database
        .into(database.audioAutomationCurves)
        .insertOnConflictUpdate(
          AudioAutomationCurvesCompanion.insert(
            id: id,
            clipId: clipId,
            parameter: parameter,
            interpolation: interpolation,
            timeSeconds: timeSeconds,
            value: value,
          ),
        );
  }

  Future<List<AudioAutomationCurve>> listCurvePoints(String clipId) async {
    final query = database.select(database.audioAutomationCurves)
      ..where((row) => row.clipId.equals(clipId))
      ..orderBy([(row) => OrderingTerm.asc(row.timeSeconds)]);
    return query.get();
  }
}
