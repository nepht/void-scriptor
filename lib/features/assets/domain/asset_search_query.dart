import '../domain/asset_type.dart';

enum AssetSortField { name, createdAt, updatedAt, lastOpenedAt, type }

enum AssetViewMode { grid, list, compact }

class AssetSearchQuery {
  const AssetSearchQuery({
    this.text = '',
    this.types = const {},
    this.tags = const {},
    this.favoriteOnly = false,
  });
  final String text;
  final Set<AssetType> types;
  final Set<String> tags;
  final bool favoriteOnly;
}

class SearchQueryParser {
  const SearchQueryParser();
  AssetSearchQuery parse(String input) {
    final textParts = <String>[];
    final types = <AssetType>{};
    final tags = <String>{};
    var favoriteOnly = false;
    String? pendingField;
    for (final token
        in input.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty)) {
      if (pendingField != null) {
        final value = token.trim().toLowerCase();
        if (pendingField == 'tag' && value.isNotEmpty) tags.add(value);
        if (pendingField == 'type') {
          final type = AssetType.values
              .where((candidate) => candidate.name == value)
              .firstOrNull;
          if (type != null) types.add(type);
        }
        pendingField = null;
        continue;
      }
      final separator = token.indexOf(':');
      if (separator <= 0) {
        textParts.add(token);
        continue;
      }
      final field = token.substring(0, separator).toLowerCase();
      final value = token.substring(separator + 1).trim().toLowerCase();
      if (value.isEmpty && (field == 'tag' || field == 'type')) {
        pendingField = field;
        continue;
      }
      switch (field) {
        case 'type':
          final type = AssetType.values
              .where((candidate) => candidate.name == value)
              .firstOrNull;
          if (type != null) {
            types.add(type);
          } else {
            textParts.add(token);
          }
        case 'tag':
          if (value.isNotEmpty) tags.add(value);
        case 'favorite':
          if (value == 'true') favoriteOnly = true;
          if (value != 'true' && value != 'false') textParts.add(token);
        default:
          textParts.add(token);
      }
    }
    return AssetSearchQuery(
      text: textParts.join(' '),
      types: types,
      tags: tags,
      favoriteOnly: favoriteOnly,
    );
  }
}

class AssetSearchResult {
  const AssetSearchResult({required this.asset, required this.score});
  final SearchableAsset asset;
  final double score;
}

class SearchableAsset {
  const SearchableAsset({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    this.description = '',
    this.tags = const {},
    this.favorite = false,
    this.lastOpenedAt,
    this.thumbnailPath,
  });
  final String id;
  final String projectId;
  final String name;
  final AssetType type;
  final String description;
  final Set<String> tags;
  final bool favorite;
  final DateTime? lastOpenedAt;
  final String? thumbnailPath;

  SearchableAsset copyWith({
    bool? favorite,
    DateTime? lastOpenedAt,
    String? thumbnailPath,
  }) => SearchableAsset(
    id: id,
    projectId: projectId,
    name: name,
    type: type,
    description: description,
    tags: tags,
    favorite: favorite ?? this.favorite,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
