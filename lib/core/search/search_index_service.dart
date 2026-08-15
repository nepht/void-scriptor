import 'package:drift/drift.dart';

import '../../database/project/project_database.dart';
import 'search_document.dart';

export 'search_document.dart';

class SearchIndexResult {
  const SearchIndexResult({required this.entityId, required this.body});

  final String entityId;
  final String body;
}

/// SQLite FTS5-backed search index.
///
/// This is a real full-text search index (Step 26.30), not an in-memory
/// fallback. It operates on the project database via a virtual FTS5 table and
/// supports incremental upsert/remove (Step 26.32).
class SqliteSearchIndex {
  SqliteSearchIndex(this._db);

  final ProjectDatabase _db;

  Future<void> ensureIndexed() async {
    await _db.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
        entity_id UNINDEXED,
        entity_type UNINDEXED,
        title,
        body,
        tokenize = 'porter unicode61'
      )
    ''');
  }

  Future<void> upsert(SearchDocument document) async {
    await ensureIndexed();
    await _db.customStatement('DELETE FROM search_index WHERE entity_id = ?', [
      document.entityId,
    ]);
    await _db.customStatement(
      'INSERT INTO search_index '
      '(entity_id, entity_type, title, body) VALUES (?, ?, ?, ?)',
      [document.entityId, document.entityType, document.title, document.body],
    );
  }

  Future<void> remove(String entityId) async {
    await ensureIndexed();
    await _db.customStatement('DELETE FROM search_index WHERE entity_id = ?', [
      entityId,
    ]);
  }

  Future<List<SearchIndexResult>> search(String query, {int limit = 50}) async {
    await ensureIndexed();
    final rows = await _db
        .customSelect(
          'SELECT entity_id, body '
          'FROM search_index WHERE search_index MATCH ? LIMIT ?',
          variables: [Variable<String>(query), Variable<int>(limit)],
        )
        .get();
    return rows
        .map(
          (row) => SearchIndexResult(
            entityId: row.data['entity_id'] as String,
            body: (row.data['body'] as String?) ?? '',
          ),
        )
        .toList(growable: false);
  }
}
