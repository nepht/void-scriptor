import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/repository_page_loader.dart';

void main() {
  test('loads first page eagerly and reports total', () async {
    final loader = RepositoryPageLoader<int>(
      fetch: (offset, limit) async => List.generate(limit, (i) => offset + i),
      total: () async => 100,
      pageSize: 10,
    );

    await loader.loadFirstPage();

    expect(loader.items, List.generate(10, (i) => i));
    expect(loader.totalCount, 100);
    expect(loader.hasMore, isTrue);
  });

  test('loadMore appends the next page', () async {
    final loader = RepositoryPageLoader<int>(
      fetch: (offset, limit) async => List.generate(limit, (i) => offset + i),
      total: () async => 25,
      pageSize: 10,
    );

    await loader.loadFirstPage();
    await loader.loadMore();

    expect(loader.items, List.generate(20, (i) => i));
    expect(loader.hasMore, isTrue);
  });

  test('loadMore stops at the total', () async {
    final loader = RepositoryPageLoader<int>(
      fetch: (offset, limit) async => List.generate(limit, (i) => offset + i),
      total: () async => 15,
      pageSize: 10,
    );

    await loader.loadFirstPage();
    await loader.loadMore();

    expect(loader.items, List.generate(15, (i) => i));
    expect(loader.hasMore, isFalse);
  });

  test('empty total yields empty page with no more', () async {
    final loader = RepositoryPageLoader<int>(
      fetch: (offset, limit) async => const [],
      total: () async => 0,
      pageSize: 10,
    );

    await loader.loadFirstPage();

    expect(loader.items, isEmpty);
    expect(loader.hasMore, isFalse);
  });
}
