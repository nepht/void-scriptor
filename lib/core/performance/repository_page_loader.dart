/// Repository page loader (Steps 26.48/50/51).
///
/// Reference Library, Story tree, and Bible lists can hold thousands of rows.
/// This connects the lazy-loading pattern to an async repository/DAO: it
/// fetches pages on demand instead of materializing every row up front. The
/// UI calls [loadFirstPage] on open and [loadMore] on scroll.
class RepositoryPageLoader<T> {
  RepositoryPageLoader({
    required this.fetch,
    required this.total,
    this.pageSize = 20,
  });

  final Future<List<T>> Function(int offset, int limit) fetch;
  final Future<int> Function() total;
  final int pageSize;

  List<T> _items = const [];
  int _total = 0;
  bool _loading = false;

  List<T> get items => List.unmodifiable(_items);
  int get totalCount => _total;
  bool get hasMore => _items.length < _total;
  bool get isLoading => _loading;

  Future<void> loadFirstPage() async {
    _loading = true;
    _items = await fetch(0, pageSize);
    _total = await total();
    _loading = false;
  }

  Future<void> loadMore() async {
    if (!hasMore || _loading) return;
    _loading = true;
    final next = await fetch(_items.length, pageSize);
    _items = [..._items, ...next];
    if (_items.length > _total) {
      _items = _items.sublist(0, _total);
    }
    _loading = false;
  }
}
