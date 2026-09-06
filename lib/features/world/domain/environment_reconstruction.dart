enum EnvironmentReconstructionResult { reconstructed, unavailable }

class EnvironmentReconstruction {
  const EnvironmentReconstruction({
    required this.id,
    required this.mappedCellCount,
    required this.scannedObjectCount,
    required this.coverageRatio,
  });

  final String id;
  final int mappedCellCount;
  final int scannedObjectCount;
  final double coverageRatio;

  bool get isValid =>
      id.trim().isNotEmpty &&
      mappedCellCount >= 0 &&
      scannedObjectCount >= 0 &&
      coverageRatio >= 0 &&
      coverageRatio <= 1;

  int get totalElementCount => mappedCellCount + scannedObjectCount;

  bool get isSufficientlyCovered => isValid && coverageRatio >= .5;
}

abstract interface class EnvironmentReconstructor {
  Future<EnvironmentReconstructionResult> reconstruct();
}

class UnavailableEnvironmentReconstructor implements EnvironmentReconstructor {
  const UnavailableEnvironmentReconstructor();

  @override
  Future<EnvironmentReconstructionResult> reconstruct() async =>
      EnvironmentReconstructionResult.unavailable;
}
