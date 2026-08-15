enum ThumbnailSize {
  tiny(64),
  small(128),
  medium(256),
  large(512);

  const ThumbnailSize(this.pixels);
  final int pixels;
}

enum ThumbnailRequestPriority { low, normal, high }

class ThumbnailRequest {
  const ThumbnailRequest({
    required this.sourcePath,
    required this.cacheKey,
    required this.size,
  });

  final String sourcePath;
  final String cacheKey;
  final ThumbnailSize size;
}

class ThumbnailCacheKey {
  const ThumbnailCacheKey(this.value);

  factory ThumbnailCacheKey.fromContentHash(
    String contentHash,
    ThumbnailSize size, {
    String algorithmVersion = 'v1',
  }) => ThumbnailCacheKey('${contentHash}_${size.pixels}_$algorithmVersion');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ThumbnailCacheKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class ThumbnailMemoryCache {
  ThumbnailMemoryCache({this.maxItems = 100}) : assert(maxItems > 0);

  final int maxItems;
  final Map<String, Object> _items = {};

  int get itemsCount => _items.length;

  T? get<T>(String key) {
    final value = _items.remove(key);
    if (value == null) return null;
    _items[key] = value;
    return value as T;
  }

  void put(String key, Object value) {
    _items.remove(key);
    _items[key] = value;
    while (_items.length > maxItems) {
      _items.remove(_items.keys.first);
    }
  }
}

class ThumbnailViewport {
  const ThumbnailViewport({
    required this.firstVisible,
    required this.lastVisible,
    this.overscan = 10,
  });

  final int firstVisible;
  final int lastVisible;
  final int overscan;

  ThumbnailRequestPriority priorityFor(int index) {
    if (index >= firstVisible && index <= lastVisible) {
      return ThumbnailRequestPriority.high;
    }
    if (index >= firstVisible - overscan && index <= lastVisible + overscan) {
      return ThumbnailRequestPriority.normal;
    }
    return ThumbnailRequestPriority.low;
  }
}
