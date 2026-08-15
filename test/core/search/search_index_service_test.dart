import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/search/search_index_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  late ProjectDatabase db;
  late SqliteSearchIndex index;

  setUp(() async {
    db = ProjectDatabase(NativeDatabase.memory());
    await db.initialize();
    index = SqliteSearchIndex(db);
    await index.ensureIndexed();
  });

  tearDown(() => db.close());

  test('fts index stores and matches documents by keyword', () async {
    await index.upsert(
      const SearchDocument(
        entityId: 'asset-qowner',
        entityType: 'asset',
        title: 'Qowner',
        body: 'Protagonist of the Void Cube Saga',
      ),
    );

    final results = await index.search('qowner');
    expect(results.map((r) => r.entityId), contains('asset-qowner'));
  });

  test(
    'fts index updates a document incrementally without duplicates',
    () async {
      await index.upsert(
        const SearchDocument(
          entityId: 'asset-qowner',
          entityType: 'asset',
          title: 'Qowner',
          body: 'old description',
        ),
      );
      await index.upsert(
        const SearchDocument(
          entityId: 'asset-qowner',
          entityType: 'asset',
          title: 'Qowner',
          body: 'new description',
        ),
      );

      final results = await index.search('qowner');
      expect(results, hasLength(1));
      expect(results.single.body, contains('new description'));
    },
  );

  test('fts index removes documents', () async {
    await index.upsert(
      const SearchDocument(
        entityId: 'asset-qowner',
        entityType: 'asset',
        title: 'Qowner',
        body: 'protagonist',
      ),
    );
    await index.remove('asset-qowner');

    final results = await index.search('qowner');
    expect(results, isEmpty);
  });
}
