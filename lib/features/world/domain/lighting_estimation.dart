enum LightingResult { estimated, unavailable }

class LightingEstimate {
  const LightingEstimate({
    required this.ambientIntensity,
    required this.colorTemperatureKelvin,
    required this.directionX,
    required this.directionY,
    required this.directionZ,
  });

  final double ambientIntensity;
  final double colorTemperatureKelvin;
  final double directionX;
  final double directionY;
  final double directionZ;

  bool get isValid =>
      ambientIntensity >= 0 &&
      ambientIntensity <= 1 &&
      colorTemperatureKelvin >= 1000 &&
      colorTemperatureKelvin <= 20000;

  bool get isDaylightLike => isValid && colorTemperatureKelvin >= 5000;
}

abstract interface class LightingProvider {
  Future<LightingResult> estimate();
}

class UnavailableLightingProvider implements LightingProvider {
  const UnavailableLightingProvider();

  @override
  Future<LightingResult> estimate() async => LightingResult.unavailable;
}
