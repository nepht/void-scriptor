import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/search/search_document.dart';
import 'package:void_scriptor/core/search/search_index_queue.dart';

void main() {
  test(
    'coalesces repeated updates for the same entity within a window',
    () async {
      final queue = SearchIndexQueue(window: const Duration(milliseconds: 60));
      final processed = <String>[];

      await queue.start((docs) async {
        processed.addAll(docs.map((d) => d.entityId));
      });

      queue.enqueue(
        const SearchDocument(
          entityId: 'a',
          entityType: 'asset',
          title: 'A',
          body: '1',
        ),
      );
      queue.enqueue(
        const SearchDocument(
          entityId: 'a',
          entityType: 'asset',
          title: 'A',
          body: '2',
        ),
      );
      queue.enqueue(
        const SearchDocument(
          entityId: 'a',
          entityType: 'asset',
          title: 'A',
          body: '3',
        ),
      );
      queue.enqueue(
        const SearchDocument(
          entityId: 'b',
          entityType: 'asset',
          title: 'B',
          body: '1',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      await queue.stop();

      // a should be processed once (latest wins), b once.
      expect(processed.where((id) => id == 'a').length, 1);
      expect(processed.where((id) => id == 'b').length, 1);
    },
  );

  test('flush drains pending updates immediately', () async {
    final queue = SearchIndexQueue(window: const Duration(seconds: 10));
    final processed = <String>[];

    await queue.start((docs) async {
      processed.addAll(docs.map((d) => d.entityId));
    });

    queue.enqueue(
      const SearchDocument(
        entityId: 'a',
        entityType: 'asset',
        title: 'A',
        body: '1',
      ),
    );
    await queue.flush();
    expect(processed, contains('a'));
    await queue.stop();
  });
}
