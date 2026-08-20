class WindVector {
  const WindVector({required this.x, required this.y});
  final int x;
  final int y;
}

class WorldIntegrationContract {
  WorldIntegrationContract() : _damage = {};
  static const _moduleNames = ['planet', 'terrain', 'climate', 'streaming'];
  final Map<String, int> _damage;
  WindVector _wind = const WindVector(x: 0, y: 0);
  List<String> get editorModules => WorldIntegrationContract._moduleNames;
  void setWind(WindVector wind) => _wind = wind;
  int travelCost({required int distanceKm, required bool againstWind}) =>
      againstWind ? distanceKm + distanceKm ~/ 5 * _wind.x.abs() : distanceKm;

  String geographyEffect(String event) =>
      event == 'volcano' ? 'terrain and climate' : 'terrain';

  void destroy(String objectId, {required int severity}) =>
      _damage[objectId] = severity.clamp(0, 10);
  void repair(String objectId, {required int amount}) {
    final current = _damage[objectId] ?? 0;
    _damage[objectId] = (current - amount).clamp(0, 10);
  }

  bool isDestroyed(String objectId) => (_damage[objectId] ?? 0) > 0;
  int damageOf(String objectId) => _damage[objectId] ?? 0;
}

class PlanetPreview {
  const PlanetPreview({required this.seed, required this.isPreview});
  final int seed;
  final bool isPreview;
}

class PlanetDesignerAi {
  const PlanetDesignerAi();
  PlanetPreview preview(String prompt) {
    var hash = 17;
    for (final code in prompt.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return PlanetPreview(seed: hash, isPreview: true);
  }
}
