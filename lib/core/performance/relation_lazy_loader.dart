/// Relation graph lazy loading (Step 26.49).
///
/// An asset can have thousands of relations; the inspector loads only the
/// first N immediate relations and exposes a "View All" affordance. Relation
/// neighborhoods are fetched on-demand rather than materializing the whole
/// graph up front.
class RelationPage<T> {
  const RelationPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int total;
  final bool hasMore;
}

class RelationLazyLoader<T> {
  RelationLazyLoader({this.pageSize = 20});

  final int pageSize;
  List<T> _source = const [];
  int _visible = 0;

  RelationPage<T> firstPage(List<T> relations) {
    _source = relations;
    _visible = 0;
    return loadMore();
  }

  RelationPage<T> loadMore() {
    final next = (_visible + pageSize).clamp(0, _source.length);
    _visible = next;
    return RelationPage(
      items: _source.sublist(0, _visible),
      total: _source.length,
      hasMore: _visible < _source.length,
    );
  }
}
