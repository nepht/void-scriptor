import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/large_data.dart';

void main() {
  test('page request and result preserve pagination contract', () {
    const request = PageRequest(limit: 80, cursor: 'asset-80');
    const result = PageResult<String>(
      items: ['a'],
      hasMore: true,
      nextCursor: 'asset-81',
    );
    expect(request.limit, 80);
    expect(request.cursor, 'asset-80');
    expect(result.hasMore, isTrue);
    expect(result.nextCursor, 'asset-81');
  });

  test('full text index updates documents incrementally', () {
    final index = InMemoryFullTextIndex();
    index.upsert(
      const SearchDocument(
        entityId: 'character-1',
        entityType: 'character',
        title: 'Qowner',
        body: 'Pole of Creation',
      ),
    );
    expect(index.search('pole').single.entityId, 'character-1');
    index.remove('character-1');
    expect(index.search('pole'), isEmpty);
  });

  test('debounced search returns only the newest generation result', () async {
    final controller = DebouncedSearchController<String>(
      debounce: const Duration(milliseconds: 1),
      search: (query) async {
        await Future<void>.delayed(
          Duration(milliseconds: query == 'old' ? 10 : 1),
        );
        return [query];
      },
    );
    addTearDown(controller.dispose);

    final old = controller.query('old');
    final newest = controller.query('new');
    expect(await newest, ['new']);
    expect(await old, isEmpty);
  });
}
