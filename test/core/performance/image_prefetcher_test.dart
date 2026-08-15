import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/image_prefetcher.dart';

void main() {
  test('prefetch neighbors of the opened asset within a bounded window', () {
    const prefetcher = ImagePrefetcher(window: 2, maxTotal: 6);
    final requested = <String>[];

    prefetcher.prefetchNeighbors(
      currentIndex: 10,
      allKeys: List.generate(20, (i) => 'asset-$i'),
      onPrefetch: requested.add,
    );

    // neighbors 8,9,11,12 — bounded, not hundreds.
    expect(requested, ['asset-8', 'asset-9', 'asset-11', 'asset-12']);
  });

  test('does not prefetch beyond list bounds', () {
    const prefetcher = ImagePrefetcher(window: 2, maxTotal: 6);
    final requested = <String>[];

    prefetcher.prefetchNeighbors(
      currentIndex: 0,
      allKeys: List.generate(5, (i) => 'asset-$i'),
      onPrefetch: requested.add,
    );

    // only after current index; nothing before index 0.
    expect(requested, ['asset-1', 'asset-2']);
  });

  test('respects maxTotal cap even with a large window', () {
    const prefetcher = ImagePrefetcher(window: 10, maxTotal: 4);
    final requested = <String>[];

    prefetcher.prefetchNeighbors(
      currentIndex: 20,
      allKeys: List.generate(50, (i) => 'asset-$i'),
      onPrefetch: requested.add,
    );

    expect(requested.length, lessThanOrEqualTo(4));
  });
}
