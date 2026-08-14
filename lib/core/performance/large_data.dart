import 'dart:async';

class PageRequest {
  const PageRequest({required this.limit, this.offset = 0, this.cursor});

  final int limit;
  final int offset;
  final String? cursor;
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}

class AssetPageCursor {
  const AssetPageCursor({this.value});
  final String? value;
}

class SearchDocument {
  const SearchDocument({
    required this.entityId,
    required this.entityType,
    required this.title,
    required this.body,
  });

  final String entityId;
  final String entityType;
  final String title;
  final String body;
}

class InMemoryFullTextIndex {
  final Map<String, SearchDocument> _documents = {};

  void upsert(SearchDocument document) =>
      _documents[document.entityId] = document;
  void remove(String entityId) => _documents.remove(entityId);

  List<SearchDocument> search(String query, {int limit = 50}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return _documents.values
        .where(
          (document) => '${document.title} ${document.body}'
              .toLowerCase()
              .contains(normalized),
        )
        .take(limit)
        .toList(growable: false);
  }
}

class DebouncedSearchController<T> {
  DebouncedSearchController({
    required this.search,
    this.debounce = const Duration(milliseconds: 250),
  });

  final Future<List<T>> Function(String query) search;
  final Duration debounce;
  Timer? _timer;
  Completer<List<T>>? _pending;
  int _generation = 0;
  bool _disposed = false;

  Future<List<T>> query(String value) {
    final generation = ++_generation;
    _timer?.cancel();
    final previous = _pending;
    if (previous != null && !previous.isCompleted) {
      previous.complete(const []);
    }
    final completer = Completer<List<T>>();
    _pending = completer;
    _timer = Timer(debounce, () async {
      try {
        final results = await search(value);
        if (!_disposed && generation == _generation) {
          completer.complete(results);
        } else {
          completer.complete(const []);
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    final previous = _pending;
    if (previous != null && !previous.isCompleted) {
      previous.complete(const []);
    }
  }
}
