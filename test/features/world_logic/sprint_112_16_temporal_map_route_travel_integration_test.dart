import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/character_location_history.dart';
import 'package:void_scriptor/features/world_logic/domain/custom_calendar.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_location_route_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_world_clock_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_route_travel_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_state.dart';
import 'package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart';

void main() {
  final clock = SharedWorldClockIntegration(
    calendar: CustomCalendar(
      months: const <CustomMonth>[
        CustomMonth(name: 'Frost', daysInMonth: 30, indexInYear: 0),
      ],
    ),
    seasons: const <int, Season>{0: Season.winter},
    eras: const <WorldEra>[WorldEra(id: 'age', startTick: 0)],
  );

  TemporalMapRouteTravelIntegration create() {
    final map = TemporalMapState(
      branchId: 'main',
      locations: const <TemporalLocation>[
        TemporalLocation(id: 'harbor', name: 'Harbor', validFrom: 0),
        TemporalLocation(id: 'pass', name: 'Mountain Pass', validFrom: 5),
      ],
    );
    final graph = RouteGraph(
      nodes: const <String, RouteNode>{
        'harbor': RouteNode(id: 'harbor', name: 'Harbor'),
        'pass': RouteNode(id: 'pass', name: 'Mountain Pass'),
      },
      edges: <RouteEdge>[
        RouteEdge(
          id: 'road',
          fromId: 'harbor',
          toId: 'pass',
          distance: 18,
          terrain: Terrain.mountain,
        ),
      ],
    );
    final timeline = CharacterLocationTimeline(personId: 'ada')
      ..record(
        LocationEvent.validated(
          id: 'arrive',
          personId: 'ada',
          locationId: 'harbor',
          tick: 0,
          kind: LocationEventKind.arrival,
          source: _source,
        ),
      )
      ..record(
        TravelSegment.validated(
          id: 'trip',
          personId: 'ada',
          fromLocationId: 'harbor',
          toLocationId: 'pass',
          startTick: 5,
          endTick: 9,
          source: _source,
        ),
      );
    return TemporalMapRouteTravelIntegration(
      clock: clock,
      map: map,
      routes: graph,
      travelMode: TravelModes.mount,
      characterTimelines: <String, CharacterLocationTimeline>{'ada': timeline},
    );
  }

  test(
    'map_at_time resolves only locations active on the selected branch and tick',
    () {
      final result = create().mapAt(tick: 3);
      expect(result.locations.map((location) => location.id), <String>[
        'harbor',
      ]);
    },
  );

  test('route_at_time validates endpoints against the same map tick', () {
    final result = create().routeAt(edgeId: 'road', tick: 3);
    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains(TemporalIssueCode.routeEndpointExpired),
    );
  });

  test('travel_estimate applies terrain and weather to route distance', () {
    final result = create().estimateTravel(
      edgeId: 'road',
      weather: WeatherCondition.rain,
    );
    expect(result.hours, closeTo(18 * 2.5 / (12 * .85), 0.0001));
  });

  test(
    'location_events resolve a character location or transit state at a tick',
    () {
      final result = create().locationOf(personId: 'ada', tick: 6);
      expect(result.isInTransit, isTrue);
      expect(result.sourceChain, contains('trip'));
    },
  );

  test(
    'scene_feasibility combines map, route, and character location checks',
    () {
      final result = create().sceneFeasibility(
        tick: 3,
        locationId: 'pass',
        routeId: 'road',
        characterId: 'ada',
      );
      expect(result.isFeasible, isFalse);
      expect(result.reasons, contains('location_not_active'));
    },
  );
}

final _source = LocationHistorySource.validated(
  id: 'test-source',
  revision: 'test-r1',
  reason: 'integration test',
  kind: LocationSourceKind.novel,
);
