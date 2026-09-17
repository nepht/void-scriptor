import 'character_location_history.dart';
import 'route_network.dart';
import 'shared_world_clock_integration.dart';
import 'temporal_location_route_validator.dart';
import 'temporal_map_state.dart';
import 'travel_mode_profiles.dart';

/// Deterministic application boundary joining the temporal map, route graph,
/// travel model, and character location history at an explicit world tick.
class TemporalMapRouteTravelIntegration {
  const TemporalMapRouteTravelIntegration({
    required this.clock,
    required this.map,
    required this.routes,
    required this.travelMode,
    this.characterTimelines = const <String, CharacterLocationTimeline>{},
  });

  final SharedWorldClockIntegration clock;
  final TemporalMapState map;
  final RouteGraph routes;
  final TravelModeProfile travelMode;
  final Map<String, CharacterLocationTimeline> characterTimelines;

  TemporalMapSnapshot mapAt({required int tick, String? branchId}) =>
      map.snapshotAt(branchId: branchId ?? map.branchId, tick: tick);

  TemporalRouteResult routeAt({required String edgeId, required int tick}) =>
      TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: routes,
      ).validateRoute(branchId: map.branchId, edgeId: edgeId, tick: tick);

  TravelEstimate estimateTravel({
    required String edgeId,
    WeatherCondition weather = WeatherCondition.clear,
  }) {
    final edge = routes.edge(edgeId);
    final weatherMode = travelMode.applyWeather(weather);
    weatherMode.requireTerrain(_terrainFor(edge.terrain));
    return TravelEstimate(
      edgeId: edgeId,
      distance: edge.distance,
      hours:
          edge.distance *
          edge.terrain.baseMultiplier /
          weatherMode.baseSpeedKmPerHour,
      weather: weather,
      sourceRevision: edge.source.revision,
    );
  }

  LocationResolution locationOf({required String personId, required int tick}) {
    final timeline = characterTimelines[personId];
    if (timeline == null) {
      return LocationResolution.unknown('no location timeline for $personId');
    }
    return timeline.resolveAt(tick);
  }

  SceneFeasibility sceneFeasibility({
    required int tick,
    required String locationId,
    String? routeId,
    String? characterId,
  }) {
    final reasons = <String>[];
    final location =
        TemporalLocationRouteValidator(
          mapState: map,
          routeGraph: routes,
        ).validateLocation(
          branchId: map.branchId,
          locationId: locationId,
          tick: tick,
        );
    if (!location.isValid) reasons.add('location_not_active');
    if (routeId != null && !routeAt(edgeId: routeId, tick: tick).isValid) {
      reasons.add('route_not_available');
    }
    if (characterId != null) {
      final resolved = locationOf(personId: characterId, tick: tick);
      if (resolved.isInTransit || resolved.locationId != locationId) {
        reasons.add('character_location_mismatch');
      }
    }
    return SceneFeasibility(
      tick: tick,
      locationId: locationId,
      isFeasible: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  TerrainKind _terrainFor(Terrain terrain) {
    switch (terrain) {
      case Terrain.plain:
        return TerrainKind.plain;
      case Terrain.forest:
        return TerrainKind.forest;
      case Terrain.swamp:
        return TerrainKind.swamp;
      case Terrain.desert:
        return TerrainKind.desert;
      case Terrain.mountain:
        return TerrainKind.mountain;
    }
  }
}

class TravelEstimate {
  const TravelEstimate({
    required this.edgeId,
    required this.distance,
    required this.hours,
    required this.weather,
    required this.sourceRevision,
  });

  final String edgeId;
  final double distance;
  final double hours;
  final WeatherCondition weather;
  final String sourceRevision;
}

class SceneFeasibility {
  const SceneFeasibility({
    required this.tick,
    required this.locationId,
    required this.isFeasible,
    required this.reasons,
  });

  final int tick;
  final String locationId;
  final bool isFeasible;
  final List<String> reasons;
}
