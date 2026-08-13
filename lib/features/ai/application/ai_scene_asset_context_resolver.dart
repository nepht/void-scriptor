import '../../assets/domain/asset_type.dart';
import '../../scene_assets/domain/scene_asset_instance.dart';

class AiSceneAssetCandidate {
  const AiSceneAssetCandidate({
    required this.assetId,
    required this.name,
    required this.type,
    required this.priority,
    this.state,
    this.storyCritical = false,
    this.references = const [],
  });
  final String assetId;
  final String name;
  final AssetType type;
  final SceneContextPriority priority;
  final String? state;
  final bool storyCritical;
  final List<String> references;
}

class AiSceneAssetContext {
  const AiSceneAssetContext({
    required this.assetId,
    required this.name,
    required this.type,
    required this.priority,
    this.state,
    this.references = const [],
  });
  final String assetId;
  final String name;
  final AssetType type;
  final SceneContextPriority priority;
  final String? state;
  final List<String> references;
}

class AiSceneAssetContextResolver {
  List<AiSceneAssetContext> resolve(
    Iterable<AiSceneAssetCandidate> candidates, {
    int maxAssets = 8,
    int maxReferences = 12,
  }) {
    final sorted = candidates.toList()
      ..sort((a, b) {
        final priority = _rank(b).compareTo(_rank(a));
        return priority != 0 ? priority : a.name.compareTo(b.name);
      });
    var referencesRemaining = maxReferences;
    return sorted
        .take(maxAssets)
        .map((candidate) {
          final selected = candidate.references
              .take(referencesRemaining)
              .toList(growable: false);
          referencesRemaining -= selected.length;
          return AiSceneAssetContext(
            assetId: candidate.assetId,
            name: candidate.name,
            type: candidate.type,
            priority:
                candidate.storyCritical &&
                    candidate.priority.index > SceneContextPriority.high.index
                ? SceneContextPriority.high
                : candidate.priority,
            state: candidate.state,
            references: selected,
          );
        })
        .toList(growable: false);
  }

  int _rank(AiSceneAssetCandidate candidate) {
    final priority =
        candidate.storyCritical &&
            candidate.priority.index > SceneContextPriority.high.index
        ? SceneContextPriority.high
        : candidate.priority;
    return switch (priority) {
      SceneContextPriority.critical => 4,
      SceneContextPriority.high => 3,
      SceneContextPriority.normal => 2,
      SceneContextPriority.optional => 1,
    };
  }
}
