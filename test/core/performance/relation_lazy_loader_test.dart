import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/relation_lazy_loader.dart';

void main() {
  test('loads only the first N immediate relations by default', () {
    final loader = RelationLazyLoader(pageSize: 20);
    final relations = List.generate(500, (i) => 'rel-$i');

    final page = loader.firstPage(relations);
    expect(page.items, hasLength(20));
    expect(page.hasMore, isTrue);
    expect(page.total, 500);
  });

  test('reports no more when relations fit in one page', () {
    final loader = RelationLazyLoader(pageSize: 20);
    final page = loader.firstPage(List.generate(5, (i) => 'rel-$i'));

    expect(page.items, hasLength(5));
    expect(page.hasMore, isFalse);
  });

  test('loadMore paginates neighborhoods on-demand', () {
    final loader = RelationLazyLoader(pageSize: 20);
    final relations = List.generate(50, (i) => 'rel-$i');

    var page = loader.firstPage(relations);
    expect(page.items, hasLength(20));

    page = loader.loadMore();
    expect(page.items, hasLength(40));
    expect(page.hasMore, isTrue);

    page = loader.loadMore();
    expect(page.items, hasLength(50));
    expect(page.hasMore, isFalse);
  });
}
