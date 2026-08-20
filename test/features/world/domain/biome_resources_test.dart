import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/biome_resources.dart';
import 'package:void_scriptor/features/world/domain/climate_weather.dart';

void main() {
  test('defines default biomes and places vegetation by climate', () {
    final catalog = BiomeCatalog.defaults();
    expect(catalog.biomes, contains('tropical-forest'));
    expect(catalog.vegetationLod(distanceMeters: 10), 0);
    expect(catalog.vegetationLod(distanceMeters: 5000), 3);
    expect(catalog.biomeFor(ClimateZone.tropical), 'tropical-forest');
  });

  test('distributes visible and hidden resources with suitability score', () {
    final resources = ResourceDistribution();
    resources.add(
      const PlanetResource(id: 'water', hidden: false, abundance: .8),
    );
    resources.add(
      const PlanetResource(id: 'void-crystal', hidden: true, abundance: .2),
    );
    expect(resources.visible, hasLength(1));
    expect(resources.hidden, hasLength(1));
    expect(SettlementSuitability.score(resources), closeTo(.5, .001));
  });
}
