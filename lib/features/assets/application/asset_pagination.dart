import 'package:flutter/foundation.dart';

import '../domain/asset_search_query.dart';

/// Incremental pagination for the Asset Browser (Step 26.24).
///
/// The browser renders only the first [pageSize] items and grows as the user
/// scrolls (infinite scroll, Step 26.25). This keeps render cost bounded by
/// what the user has actually revealed, not the total asset count.
class AssetPaginationController extends ChangeNotifier {
  AssetPaginationController({required this._source}) {
    loadMore();
  }
  static const int pageSize = 80;

  List<SearchableAsset> _source;
  int _visibleCount = 0;

  List<SearchableAsset> get items {
    final count = _visibleCount < _source.length
        ? _visibleCount
        : _source.length;
    return _source.sublist(0, count);
  }

  int get visibleCount => items.length;

  int get totalCount => _source.length;

  bool get hasMore => visibleCount < totalCount;

  void loadMore() {
    if (!hasMore) return;
    _visibleCount = (visibleCount + pageSize).clamp(0, totalCount);
    notifyListeners();
  }

  void replaceSource(List<SearchableAsset> source) {
    _source = source;
    _visibleCount = 0;
    loadMore();
    notifyListeners();
  }
}
