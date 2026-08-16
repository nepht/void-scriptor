import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/thumbnail_pipeline.dart';

void main() {
  test('thumbnail sizes expose bounded pixel presets', () {
    expect(ThumbnailSize.tiny.pixels, 64);
    expect(ThumbnailSize.small.pixels, 128);
    expect(ThumbnailSize.medium.pixels, 256);
    expect(ThumbnailSize.large.pixels, 512);
  });

  test('cache key changes with content, size, and algorithm version', () {
    final first = ThumbnailCacheKey.fromContentHash(
      'abc',
      ThumbnailSize.medium,
    );
    final changedContent = ThumbnailCacheKey.fromContentHash(
      'def',
      ThumbnailSize.medium,
    );
    final changedSize = ThumbnailCacheKey.fromContentHash(
      'abc',
      ThumbnailSize.large,
    );

    expect(first.value, 'abc_256_v1');
    expect(changedContent, isNot(first));
    expect(changedSize, isNot(first));
  });

  test('LRU memory cache evicts least recently used preview', () {
    final cache = ThumbnailMemoryCache(maxItems: 2);
    cache.put('a', 'A');
    cache.put('b', 'B');
    expect(cache.get('a'), 'A');
    cache.put('c', 'C');

    expect(cache.get('a'), 'A');
    expect(cache.get('b'), isNull);
    expect(cache.get('c'), 'C');
  });

  test('viewport priority marks visible items high and distant items low', () {
    const viewport = ThumbnailViewport(firstVisible: 10, lastVisible: 20);
    expect(viewport.priorityFor(15), ThumbnailRequestPriority.high);
    expect(viewport.priorityFor(25), ThumbnailRequestPriority.normal);
    expect(viewport.priorityFor(100), ThumbnailRequestPriority.low);
  });

  test('thumbnail request retains project-relative source path', () {
    const request = ThumbnailRequest(
      sourcePath: 'assets/references/a.png',
      cacheKey: 'abc_128_v1',
      size: ThumbnailSize.small,
    );
    expect(request.sourcePath, 'assets/references/a.png');
    expect(request.sourcePath, isNot(startsWith('/')));
  });
}
