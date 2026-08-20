class InputCalibration {
  InputCalibration({required this.requiredSamples})
    : assert(requiredSamples > 0);

  final int requiredSamples;
  final List<double> _samples = [];

  bool get complete => _samples.length >= requiredSamples;

  double get normalized =>
      _samples.isEmpty ? 0 : _samples.reduce((a, b) => a + b) / _samples.length;

  void addSample(double value) {
    if (!complete) _samples.add(value.clamp(0, 1).toDouble());
  }
}
