/// A spatial anchor in a scene (Step 41.7).
class SpatialAnchor {
  const SpatialAnchor({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.contentId,
  });

  final String id;
  final double x;
  final double y;
  final double z;
  final String contentId;
}

/// Spatial scene with anchors (Step 41.8).
class SpatialScene {
  final Map<String, SpatialAnchor> _anchors = {};

  void add(SpatialAnchor anchor) => _anchors[anchor.id] = anchor;

  int get anchorCount => _anchors.length;

  List<SpatialAnchor> anchorsForContent(String contentId) => [
    for (final anchor in _anchors.values)
      if (anchor.contentId == contentId) anchor,
  ];
}
