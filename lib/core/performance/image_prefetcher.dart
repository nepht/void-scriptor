/// Bounded image prefetch (Step 26.42).
///
/// When the user opens asset N, prefetch the thumbnails of the immediate
/// neighbors (N±window) at low priority. This must stay bounded: never
/// prefetch hundreds of items, and never exceed [maxTotal].
class ImagePrefetcher {
  const ImagePrefetcher({this.window = 2, this.maxTotal = 6});

  final int window;
  final int maxTotal;

  List<String> prefetchNeighbors({
    required int currentIndex,
    required List<String> allKeys,
    required void Function(String key) onPrefetch,
  }) {
    if (allKeys.isEmpty) return const [];

    final indices = <int>[];
    for (var offset = 1; offset <= window; offset++) {
      if (currentIndex - offset >= 0) indices.add(currentIndex - offset);
      if (currentIndex + offset < allKeys.length) {
        indices.add(currentIndex + offset);
      }
    }
    indices.sort();

    final requested = <String>[];
    for (final index in indices) {
      if (requested.length >= maxTotal) break;
      final key = allKeys[index];
      onPrefetch(key);
      requested.add(key);
    }
    return requested;
  }
}
