import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/thumbnail_pipeline.dart';
import 'package:void_scriptor/core/performance/performance_runtime.dart';
import 'package:void_scriptor/core/search/search_index_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:drift/native.dart';

void main() {
  test('search benchmark: FTS5 over 20k docs stays interactive', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    await db.initialize();
    final index = SqliteSearchIndex(db);
    await index.ensureIndexed();

    final docs = List.generate(
      20000,
      (i) => SearchDocument(
        entityId: 'entity-$i',
        entityType: 'reference',
        title: 'Reference $i',
        body: 'qowner face reference $i',
      ),
    );
    for (var i = 0; i < docs.length; i += 500) {
      final batch = docs.sublist(i, (i + 500).clamp(0, docs.length));
      for (final doc in batch) {
        await index.upsert(doc);
      }
    }

    final stopwatch = Stopwatch()..start();
    final results = await index.search('qowner', limit: 50);
    stopwatch.stop();

    expect(results, isNotEmpty);
    expect(results.length, lessThanOrEqualTo(50));
    // Interactive: well under 2 seconds even with cold start in CI.
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));

    await db.close();
  });

  test('memory benchmark: thumbnail cache stays bounded under churn', () {
    final cache = ThumbnailMemoryCache(maxItems: 100);
    for (var i = 0; i < 2000; i++) {
      cache.put('key-$i', i);
    }
    // LRU eviction keeps memory bounded, not unbounded growth.
    expect(cache.itemsCount, 100);
    expect(cache.itemsCount, lessThan(2000));
  });

  test('memory cache policy flags eviction past budget', () {
    const policy = MemoryCachePolicy(maxPreviewItems: 100);
    expect(policy.shouldEvict(50), isFalse);
    expect(policy.shouldEvict(101), isTrue);
  });
}
