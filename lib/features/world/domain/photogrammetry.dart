enum PhotogrammetryResult { reconstructed, unavailable }

class ImageObservation {
  const ImageObservation({
    required this.id,
    required this.featureCount,
    required this.yawDegrees,
  });

  final String id;
  final int featureCount;
  final int yawDegrees;
}

class PhotogrammetrySession {
  const PhotogrammetrySession({
    required this.id,
    required this.observations,
    required this.maxFeaturePoints,
  });

  final String id;
  final List<ImageObservation> observations;
  final int maxFeaturePoints;

  bool get isValid =>
      id.trim().isNotEmpty &&
      observations.isNotEmpty &&
      maxFeaturePoints > 0 &&
      observations.every(
        (observation) =>
            observation.id.trim().isNotEmpty && observation.featureCount >= 0,
      );

  int get totalFeatureCount => observations.fold(
    0,
    (total, observation) => total + observation.featureCount,
  );

  int get coverageDegrees {
    if (observations.length < 2) return 0;
    final yaws =
        observations.map((observation) => observation.yawDegrees).toList()
          ..sort();
    return yaws.last - yaws.first;
  }

  bool get canReconstruct =>
      isValid && totalFeatureCount <= maxFeaturePoints && coverageDegrees >= 90;
}

abstract interface class PhotogrammetryAdapter {
  Future<PhotogrammetryResult> reconstruct([PhotogrammetrySession? session]);
}

class UnavailablePhotogrammetryAdapter implements PhotogrammetryAdapter {
  const UnavailablePhotogrammetryAdapter();

  @override
  Future<PhotogrammetryResult> reconstruct([
    PhotogrammetrySession? session,
  ]) async => PhotogrammetryResult.unavailable;
}
