/// Sprint 43 — Step 43.16 Portfolio Entry, 43.17 Portfolio Content.
enum PortfolioVisibility { private, unlisted, public }

class PortfolioEntry {
  const PortfolioEntry({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.assetIds = const [],
    this.tags = const [],
    this.visibility = PortfolioVisibility.private,
  });

  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final List<String> assetIds;
  final List<String> tags;
  final PortfolioVisibility visibility;

  PortfolioEntry copyWith({
    String? title,
    String? description,
    List<String>? assetIds,
    List<String>? tags,
    PortfolioVisibility? visibility,
  }) {
    return PortfolioEntry(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      assetIds: assetIds ?? this.assetIds,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'title': title,
    'description': description,
    'assetIds': assetIds,
    'tags': tags,
    'visibility': visibility.name,
  };

  factory PortfolioEntry.fromJson(Map<String, dynamic> json) {
    return PortfolioEntry(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assetIds: (json['assetIds'] as List<dynamic>? ?? []).cast<String>(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      visibility: PortfolioVisibility.values.firstWhere(
        (v) => v.name == json['visibility'],
        orElse: () => PortfolioVisibility.private,
      ),
    );
  }
}
