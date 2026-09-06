enum DepthCaptureResult { started, unavailable, stopped }

class DepthFrame {
  const DepthFrame({
    required this.width,
    required this.height,
    required this.samplesMeters,
    required this.minReliableMeters,
    required this.maxReliableMeters,
  });

  final int width;
  final int height;
  final List<double> samplesMeters;
  final double minReliableMeters;
  final double maxReliableMeters;

  bool get isValid =>
      width > 0 &&
      height > 0 &&
      samplesMeters.length == width * height &&
      minReliableMeters >= 0 &&
      maxReliableMeters > minReliableMeters;

  int get sampleCount => samplesMeters.length;

  List<double> get reliableSamples => List.unmodifiable(
    samplesMeters.where(
      (sample) => sample >= minReliableMeters && sample <= maxReliableMeters,
    ),
  );

  double get averageMeters {
    if (samplesMeters.isEmpty) return 0;
    return samplesMeters.reduce((a, b) => a + b) / samplesMeters.length;
  }
}

abstract interface class DepthCaptureAdapter {
  Future<DepthCaptureResult> start();
  Future<DepthCaptureResult> stop();
}

class UnavailableDepthAdapter implements DepthCaptureAdapter {
  const UnavailableDepthAdapter();

  @override
  Future<DepthCaptureResult> start() async => DepthCaptureResult.unavailable;

  @override
  Future<DepthCaptureResult> stop() async => DepthCaptureResult.stopped;
}
