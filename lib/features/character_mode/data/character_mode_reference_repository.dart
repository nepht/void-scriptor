import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart' as db;

class CharacterModeReferenceRepository {
  CharacterModeReferenceRepository(this.database);
  final db.ProjectDatabase database;

  Future<List<db.CharacterModeReference>> getReferences(String modeId) =>
      database.characterModeDao.getReferences(modeId);

  Future<void> add({
    required String modeId,
    required String referenceType,
    required String filePath,
    int priority = 0,
    bool primaryReference = false,
  }) => database
      .into(database.characterModeReferences)
      .insert(
        db.CharacterModeReferencesCompanion.insert(
          id: const Uuid().v4(),
          modeId: modeId,
          referenceType: referenceType,
          filePath: filePath,
          priority: Value(priority),
          primaryReference: Value(primaryReference),
        ),
      );

  Future<void> remove(String id) => (database.delete(
    database.characterModeReferences,
  )..where((row) => row.id.equals(id))).go();
}
