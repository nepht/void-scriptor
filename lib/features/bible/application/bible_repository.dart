import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/bible_entries.dart';
import '../domain/bible_entry.dart' as domain;
import '../../story/domain/canon_status.dart';

part 'bible_repository.g.dart';

@DriftAccessor(tables: [BibleEntries])
class BibleRepository extends DatabaseAccessor<ProjectDatabase>
    with _$BibleRepositoryMixin {
  BibleRepository(super.database);

  Future<void> saveEntry(domain.BibleEntry entry) =>
      into(bibleEntries).insertOnConflictUpdate(
        BibleEntriesCompanion.insert(
          id: entry.id,
          projectId: entry.projectId,
          type: entry.type.name,
          title: entry.title,
          content: Value(entry.content),
          canonStatus: Value(entry.status.name),
          tagsJson: Value(jsonEncode(entry.tags)),
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        ),
      );

  Future<List<domain.BibleEntry>> listEntries(String projectId) async {
    final rows =
        await (select(bibleEntries)
              ..where((row) => row.projectId.equals(projectId))
              ..orderBy([(row) => OrderingTerm(expression: row.title)]))
            .get();
    return rows.map<domain.BibleEntry>(_toDomain).toList(growable: false);
  }

  domain.BibleEntry _toDomain(BibleEntry row) => domain.BibleEntry(
    id: row.id,
    projectId: row.projectId,
    type: domain.BibleEntryType.values.byName(row.type),
    title: row.title,
    content: row.content,
    status: CanonStatus.values.byName(row.canonStatus),
    tags: (jsonDecode(row.tagsJson) as List<dynamic>).cast<String>(),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
