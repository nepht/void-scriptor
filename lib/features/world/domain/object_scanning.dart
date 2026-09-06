enum ObjectScanResult { scanned, unavailable }

class ScanBounds {
  const ScanBounds({
    required this.width,
    required this.height,
    required this.depth,
  });

  final double width;
  final double height;
  final double depth;

  bool get isValid => width > 0 && height > 0 && depth > 0;
}

class ObjectScan {
  const ObjectScan({
    required this.objectId,
    required this.label,
    required this.observationCount,
    required this.bounds,
  });

  final String objectId;
  final String label;
  final int observationCount;
  final ScanBounds bounds;

  bool get isValid =>
      objectId.trim().isNotEmpty &&
      label.trim().isNotEmpty &&
      observationCount >= 0 &&
      bounds.isValid;

  double get volumeCubicMeters => bounds.width * bounds.height * bounds.depth;

  bool isSufficientlyObserved({required int minimumObservations}) =>
      isValid &&
      minimumObservations >= 0 &&
      observationCount >= minimumObservations;
}

abstract interface class ObjectScanner {
  Future<ObjectScanResult> scan();
}

class UnavailableObjectScanner implements ObjectScanner {
  const UnavailableObjectScanner();

  @override
  Future<ObjectScanResult> scan() async => ObjectScanResult.unavailable;
}
