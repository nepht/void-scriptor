import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/review_governance.dart';

/// Probe that counts how often an item's `priority` is read.
///
/// STU-BUG-07: `AttentionQueue.next()` re-sorted the whole backing list on
/// every retrieval, so each pop paid O(N log N) priority comparisons. A
/// queue that keeps its order at insertion performs zero comparisons while
/// draining.
class _CountingItem extends AttentionItem {
  _CountingItem({required super.id, required this._value}) : super(priority: 0);

  final int _value;
  int reads = 0;

  @override
  int get priority {
    reads++;
    return _value;
  }
}

void main() {
  test(
    'next drains without re-comparing priorities (vs-hunt-20260913 STU-BUG-07)',
    () {
      final queue = AttentionQueue();
      final items = [
        for (var i = 0; i < 24; i++) _CountingItem(id: 'item-$i', value: i % 7),
      ];
      for (final item in items) {
        queue.add(item);
      }

      for (final item in items) {
        item.reads = 0;
      }

      for (var i = 0; i < items.length; i++) {
        expect(queue.next(), isNotNull);
      }

      final totalReads = items.fold<int>(0, (sum, item) => sum + item.reads);
      expect(
        totalReads,
        0,
        reason: 'next() must not re-sort; ordering belongs in add()',
      );
    },
  );

  test('add keeps the queue ordered by descending priority', () {
    final queue = AttentionQueue();
    queue.add(const AttentionItem(id: 'low', priority: 1));
    queue.add(const AttentionItem(id: 'critical', priority: 9));
    queue.add(const AttentionItem(id: 'mid', priority: 5));
    queue.add(const AttentionItem(id: 'high', priority: 7));

    expect(
      [queue.next()?.id, queue.next()?.id, queue.next()?.id, queue.next()?.id],
      ['critical', 'high', 'mid', 'low'],
    );
  });

  test('equal priorities drain in insertion order', () {
    final queue = AttentionQueue();
    queue.add(const AttentionItem(id: 'first', priority: 4));
    queue.add(const AttentionItem(id: 'second', priority: 4));
    queue.add(const AttentionItem(id: 'third', priority: 4));

    expect(
      [queue.next()?.id, queue.next()?.id, queue.next()?.id],
      ['first', 'second', 'third'],
    );
  });

  test('next returns null only when the queue is empty', () {
    final queue = AttentionQueue();
    expect(queue.next(), isNull);
    queue.add(const AttentionItem(id: 'solo', priority: 2));
    expect(queue.next()?.id, 'solo');
    expect(queue.next(), isNull);
  });
}
