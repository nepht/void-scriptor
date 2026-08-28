import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/journey_consistency_validator.dart";
import "package:void_scriptor/features/world_logic/domain/route_network.dart";
import "package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart";
import "package:void_scriptor/features/world_logic/domain/travel_supplies.dart";

void main() {
  group("JourneyConsistencyValidator", () {
    late RouteGraph graph;
    late TravelModeProfile walk;
    late SupplyLoadout balancedLoadout;
    late SupplyLoadout starvingLoadout;

    setUp(() {
      graph = RouteGraph(
        nodes: const {
          "A": RouteNode(id: "A", name: "A"),
          "B": RouteNode(id: "B", name: "B"),
          "C": RouteNode(id: "C", name: "C"),
        },
        edges: [
          RouteEdge(
            id: "e1",
            fromId: "A",
            toId: "B",
            distance: 30.0,
            terrain: Terrain.plain,
            source: defaultRouteSource,
          ),
          RouteEdge(
            id: "e2",
            fromId: "B",
            toId: "C",
            distance: 50.0,
            terrain: Terrain.forest,
            source: defaultRouteSource,
          ),
          RouteEdge(
            id: "e3",
            fromId: "A",
            toId: "C",
            distance: 200.0,
            terrain: Terrain.mountain,
            source: defaultRouteSource,
          ),
        ],
      );
      walk = const TravelModeProfile(
        id: "walk",
        label: "Walk",
        baseSpeedKmPerHour: 5.0,
        capacityPersons: 1,
        passableTerrains: {
          TerrainKind.plain,
          TerrainKind.forest,
          TerrainKind.mountain,
          TerrainKind.desert,
          TerrainKind.swamp,
        },
        restAfterHours: 0,
        restDurationHours: 0,
      );
      balancedLoadout = SupplyLoadout(
        partySize: 2,
        bundles: [
          SupplyBundle(kind: SupplyKind.rations, quantity: 200.0, unit: "meal"),
          SupplyBundle(kind: SupplyKind.water, quantity: 200.0, unit: "litre"),
          SupplyBundle(
            kind: SupplyKind.fodder,
            quantity: 200.0,
            unit: "portion",
          ),
        ],
      );
      starvingLoadout = SupplyLoadout(
        partySize: 2,
        bundles: [
          SupplyBundle(kind: SupplyKind.rations, quantity: 0.5, unit: "meal"),
          SupplyBundle(kind: SupplyKind.water, quantity: 0.5, unit: "litre"),
        ],
      );
    });

    test("detects missing origin node", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "X",
          destinationId: "C",
          segments: const ["e1", "e2"],
          mode: walk,
          season: Season.summer,
          partySize: 2,
          loadout: balancedLoadout,
          claimedDurationHours: 20.0,
          restHours: 0.0,
        ),
      );
      expect(
        result.warnings.any((w) => w.code == "scene_route_check"),
        isTrue,
        reason: "origin not in graph should raise scene_route_check",
      );
    });

    test("detects segment not contiguous with origin->destination", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1", "e2", "e3"],
          mode: walk,
          season: Season.summer,
          partySize: 2,
          loadout: balancedLoadout,
          claimedDurationHours: 50.0,
          restHours: 0.0,
        ),
      );
      expect(result.warnings.any((w) => w.code == "scene_route_check"), isTrue);
    });

    test("reports time feasibility when claimed duration is too small", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1"],
          mode: walk,
          season: Season.summer,
          partySize: 1,
          loadout: balancedLoadout,
          claimedDurationHours: 1.0,
          restHours: 0.0,
        ),
      );
      expect(
        result.warnings.any((w) => w.code == "time_feasibility"),
        isTrue,
        reason: "walking 30km @5km/h should take 6h, claimed 1h is infeasible",
      );
    });

    test("flags supply warnings when loadout is insufficient", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1"],
          mode: walk,
          season: Season.summer,
          partySize: 2,
          loadout: starvingLoadout,
          claimedDurationHours: 6.0,
          restHours: 0.0,
        ),
      );
      expect(result.warnings.any((w) => w.code == "supply_warning"), isTrue);
    });

    test("raises route_closure_awareness when an edge is blocked", () {
      final blocked = RouteEdge(
        id: "e2",
        fromId: "B",
        toId: "C",
        distance: 50.0,
        terrain: Terrain.forest,
        source: defaultRouteSource,
        blocked: const BlockedRoute(reason: "landslide"),
      );
      final blockedGraph = RouteGraph(
        nodes: const {
          "A": RouteNode(id: "A", name: "A"),
          "B": RouteNode(id: "B", name: "B"),
          "C": RouteNode(id: "C", name: "C"),
        },
        edges: [graph.edge("e1"), blocked],
      );
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: blockedGraph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1", "e2"],
          mode: walk,
          season: Season.summer,
          partySize: 2,
          loadout: balancedLoadout,
          claimedDurationHours: 24.0,
          restHours: 0.0,
        ),
      );
      expect(
        result.warnings.any((w) => w.code == "route_closure_awareness"),
        isTrue,
      );
    });

    test("explain_warning: every warning has non-empty message and code", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1"],
          mode: walk,
          season: Season.summer,
          partySize: 1,
          loadout: balancedLoadout,
          claimedDurationHours: 0.5,
          restHours: 0.0,
        ),
      );
      for (final w in result.warnings) {
        expect(w.code, isNotEmpty);
        expect(w.message, isNotEmpty);
      }
    });

    test("clean journey produces no warnings", () {
      final result = const JourneyConsistencyValidator().validate(
        spec: JourneySpec(
          graph: graph,
          originId: "A",
          destinationId: "B",
          segments: const ["e1"],
          mode: walk,
          season: Season.summer,
          partySize: 1,
          loadout: balancedLoadout,
          claimedDurationHours: 7.0,
          restHours: 1.0,
        ),
      );
      expect(
        result.warnings,
        isEmpty,
        reason: "feasible + supplied + open route should yield no warnings",
      );
    });
  });
}
