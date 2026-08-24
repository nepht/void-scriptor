/// Sprint 104 / 104.12 — asset pipeline trigger vocabulary. Five canonical
/// events; facts expose identifiers plus (when present) a relative path.
library;

enum AssetPipelineEvent {
  assetImported,
  assetUpdated,
  thumbnailReady,
  assetMissing,
  assetRelinked,
}

Map<String, Object> assetFacts(
  AssetPipelineEvent event, {
  required String assetId,
  required String projectId,
  String? thumbnailPath,
}) {
  final facts = <String, Object>{
    'asset.event': event.name,
    'asset.id': assetId,
    'project.id': projectId,
  };
  final thumb = thumbnailPath;
  if (thumb != null && thumb.isNotEmpty) facts['thumbnail.path'] = thumb;
  return facts;
}
