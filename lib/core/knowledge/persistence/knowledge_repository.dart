import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists knowledge entities and relations (Step 38.15).
class KnowledgeRepository {
  KnowledgeRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveEntity({
    required String id,
    required String type,
    required String title,
    required List<String> facts,
  }) async {
    await database
        .into(database.knowledgeEntities)
        .insertOnConflictUpdate(
          KnowledgeEntitiesCompanion.insert(
            id: id,
            type: type,
            title: title,
            factsJson: Value(jsonEncode(facts)),
          ),
        );
  }

  Future<List<KnowledgeEntity>> listEntities() async =>
      database.select(database.knowledgeEntities).get();

  Future<void> saveRelation({
    required String id,
    required String sourceId,
    required String targetId,
    required String kind,
  }) async {
    await database
        .into(database.knowledgeRelations)
        .insertOnConflictUpdate(
          KnowledgeRelationsCompanion.insert(
            id: id,
            sourceId: sourceId,
            targetId: targetId,
            kind: kind,
          ),
        );
  }

  Future<List<KnowledgeRelation>> listRelations() async =>
      database.select(database.knowledgeRelations).get();
}
