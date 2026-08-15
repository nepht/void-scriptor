import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/thumbnail_pipeline.dart';

void main() {
  test('put and get roundtrip by key', () {
    final cache = ThumbnailMemoryCache(maxItems: 10);
    cache.put('a', 1);
    expect(cache.get<int>('a'), 1);
    expect(cache.itemsCount, 1);
  });

  test('get refreshes recency order (LRU)', () {
    final cache = ThumbnailMemoryCache(maxItems: 2);
    cache.put('a', 1);
    cache.put('b', 2);
    cache.get<Object>('a'); // touch a
    cache.put('c', 3); // evicts least recently used (b)

    expect(cache.get<int>('a'), 1);
    expect(cache.get<int>('c'), 3);
    expect(cache.get<int>('b'), isNull);
    expect(cache.itemsCount, 2);
  });

  test('evicts oldest when exceeding maxItems', () {
    final cache = ThumbnailMemoryCache(maxItems: 3);
    cache.put('a', 1);
    cache.put('b', 2);
    cache.put('c', 3);
    cache.put('d', 4);

    expect(cache.get<int>('a'), isNull);
    expect(cache.itemsCount, 3);
  });

  test('put replaces existing key without growing count', () {
    final cache = ThumbnailMemoryCache(maxItems: 3);
    cache.put('a', 1);
    cache.put('a', 2);

    expect(cache.get<int>('a'), 2);
    expect(cache.itemsCount, 1);
  });

  test('rejects non-positive maxItems', () {
    expect(() => ThumbnailMemoryCache(maxItems: 0), throwsAssertionError);
  });

  test('cache key from content hash embeds size and version', () {
    final key = ThumbnailCacheKey.fromContentHash(
      'abc123',
      ThumbnailSize.medium,
    );
    expect(key.value, contains('256'));
    expect(key.value, contains('v1'));
  });

  test('cache keys compare by value equality', () {
    final a = ThumbnailCacheKey.fromContentHash('x', ThumbnailSize.small);
    const b = ThumbnailCacheKey('x_128_v1');
    expect(a, b);
  });
}
