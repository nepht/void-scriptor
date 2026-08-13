import '../domain/asset_search_query.dart';

abstract interface class AssetSearchService {
  Future<List<AssetSearchResult>> search(
    AssetSearchQuery query, {
    int limit = 50,
  });
}

class InMemoryAssetSearchService implements AssetSearchService {
  InMemoryAssetSearchService(Iterable<SearchableAsset> assets)
    : _assets = List.unmodifiable(assets);
  final List<SearchableAsset> _assets;

  @override
  Future<List<AssetSearchResult>> search(
    AssetSearchQuery query, {
    int limit = 50,
  }) async {
    final needle = query.text.trim().toLowerCase();
    final results = <AssetSearchResult>[];
    for (final asset in _assets) {
      if (query.types.isNotEmpty && !query.types.contains(asset.type)) {
        continue;
      }
      if (query.favoriteOnly && !asset.favorite) {
        continue;
      }
      if (query.tags.isNotEmpty && !query.tags.every(asset.tags.contains)) {
        continue;
      }
      final name = asset.name.toLowerCase();
      final description = asset.description.toLowerCase();
      final terms = needle
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty);
      final matchesText =
          needle.isEmpty ||
          name.contains(needle) ||
          description.contains(needle) ||
          terms.any((term) => asset.tags.any((tag) => tag.contains(term)));
      if (!matchesText) continue;
      var score = 0.0;
      if (needle.isNotEmpty) {
        if (name == needle) {
          score = 100;
        } else if (name.startsWith(needle)) {
          score = 80;
        } else if (name.contains(needle)) {
          score = 60;
        } else if (terms.any(
          (term) => asset.tags.any((tag) => tag.contains(term)),
        )) {
          score = 40;
        } else {
          score = 20;
        }
      }
      results.add(AssetSearchResult(asset: asset, score: score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList(growable: false);
  }
}
