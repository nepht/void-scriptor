import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/lighting_estimation.dart';

void main() {
  test('lighting estimate validates bounded light parameters', () {
    const estimate = LightingEstimate(
      ambientIntensity: .8,
      colorTemperatureKelvin: 6500,
      directionX: 0,
      directionY: 1,
      directionZ: 0,
    );

    expect(estimate.isValid, isTrue);
    expect(estimate.isDaylightLike, isTrue);
  });

  test('unavailable lighting provider reports platform boundary', () async {
    const provider = UnavailableLightingProvider();
    expect(await provider.estimate(), LightingResult.unavailable);
  });
}
