import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists creative briefs and ideas (Step 40.15).
class CreativeRepository {
  CreativeRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveBrief({
    required String id,
    required String title,
    required String genre,
    required String tone,
    required List<String> goals,
  }) async {
    await database
        .into(database.creativeBriefs)
        .insertOnConflictUpdate(
          CreativeBriefsCompanion.insert(
            id: id,
            title: title,
            genre: genre,
            tone: tone,
            goalsJson: Value(jsonEncode(goals)),
          ),
        );
  }

  Future<List<CreativeBrief>> listBriefs() async =>
      database.select(database.creativeBriefs).get();

  Future<void> saveIdea({
    required String id,
    required String briefId,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    await database
        .into(database.creativeIdeas)
        .insertOnConflictUpdate(
          CreativeIdeasCompanion.insert(
            id: id,
            briefId: briefId,
            title: title,
            description: description,
            tagsJson: Value(jsonEncode(tags)),
          ),
        );
  }

  Future<List<CreativeIdea>> listIdeas(String briefId) async {
    final query = database.select(database.creativeIdeas)
      ..where((row) => row.briefId.equals(briefId));
    return query.get();
  }
}
