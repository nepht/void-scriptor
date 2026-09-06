enum OcclusionResult { started, unavailable }

class OcclusionMask {
  const OcclusionMask({
    required this.width,
    required this.height,
    required this.visibleSamples,
  });

  final int width;
  final int height;
  final List<bool> visibleSamples;

  bool get isValid =>
      width > 0 && height > 0 && visibleSamples.length == width * height;

  double get visibleRatio {
    if (!isValid || visibleSamples.isEmpty) return 0;
    final visible = visibleSamples.where((sample) => sample).length;
    return visible / visibleSamples.length;
  }

  bool isVisibleAt(int index) =>
      index >= 0 && index < visibleSamples.length && visibleSamples[index];
}

abstract interface class OcclusionAdapter {
  Future<OcclusionResult> start();
}

class UnavailableOcclusionAdapter implements OcclusionAdapter {
  const UnavailableOcclusionAdapter();

  @override
  Future<OcclusionResult> start() async => OcclusionResult.unavailable;
}
