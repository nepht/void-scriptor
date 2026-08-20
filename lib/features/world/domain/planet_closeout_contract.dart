class PlanetCloseoutContract {
  const PlanetCloseoutContract();
  static const _suites = [
    'schema',
    'coordinates',
    'terrain',
    'climate',
    'streaming',
    'persistence',
    'scale',
  ];
  List<String> get requiredSuites => _suites;
  bool isCovered(Set<String> completed) =>
      requiredSuites.every(completed.contains);
}

class PlanetScenarioCatalog {
  const PlanetScenarioCatalog({required this.names, required this.previewOnly});
  final List<String> names;
  final bool previewOnly;
  factory PlanetScenarioCatalog.defaultCatalog() => const PlanetScenarioCatalog(
    names: ['Kokuen', 'Crash Site'],
    previewOnly: true,
  );
}
