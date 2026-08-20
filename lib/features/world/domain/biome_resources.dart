import 'climate_weather.dart';

class BiomeCatalog {
  BiomeCatalog(this.biomes);
  final List<String> biomes;
  factory BiomeCatalog.defaults() => BiomeCatalog(const [
    'tropical-forest',
    'temperate-forest',
    'polar-tundra',
  ]);

  String biomeFor(ClimateZone zone) {
    switch (zone) {
      case ClimateZone.tropical:
        return 'tropical-forest';
      case ClimateZone.temperate:
        return 'temperate-forest';
      case ClimateZone.polar:
        return 'polar-tundra';
    }
  }

  int vegetationLod({required double distanceMeters}) {
    if (distanceMeters < 100) return 0;
    if (distanceMeters < 1000) return 1;
    if (distanceMeters < 5000) return 2;
    return 3;
  }
}

class PlanetResource {
  const PlanetResource({
    required this.id,
    required this.hidden,
    required this.abundance,
  });
  final String id;
  final bool hidden;
  final double abundance;
}

class ResourceDistribution {
  final List<PlanetResource> _resources = [];
  void add(PlanetResource resource) => _resources.add(resource);
  List<PlanetResource> get visible =>
      _resources.where((resource) => !resource.hidden).toList(growable: false);
  List<PlanetResource> get hidden =>
      _resources.where((resource) => resource.hidden).toList(growable: false);
}

class SettlementSuitability {
  static double score(ResourceDistribution distribution) {
    final resources = [...distribution.visible, ...distribution.hidden];
    if (resources.isEmpty) return 0;
    final total = resources.fold<double>(
      0,
      (sum, resource) => sum + resource.abundance,
    );
    return total / resources.length;
  }
}
