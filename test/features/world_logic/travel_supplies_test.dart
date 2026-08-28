// ignore_for_file: prefer_const_constructors
// Sprint 110.11 - Travel Supplies.
//
// Domain-only supply system: per-kind consumption policy per travel mode,
// loadout (bundle + party size), and a deterministic planner that consumes
// supplies along a sequence of route segments while a travel mode is in use.
// No persistence, UI, hidden wall clock, locale, or random input.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/route_network.dart";
import "package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart";
import "package:void_scriptor/features/world_logic/domain/travel_supplies.dart";

void main() {
  group("SupplyKind", () {
    test("mendeklarasikan jenis bawaan yang umum untuk perjalanan", () {
      expect(SupplyKind.rations, isNotNull);
      expect(SupplyKind.water, isNotNull);
      expect(SupplyKind.fodder, isNotNull);
    });
  });

  group("SupplyBundle", () {
    test("menolak quantity negatif, kosong, atau unit kosong", () {
      expect(
        () => SupplyBundle(kind: SupplyKind.rations, quantity: -1, unit: "kg"),
        throwsArgumentError,
      );
      expect(
        () => SupplyBundle(kind: SupplyKind.rations, quantity: 0, unit: "kg"),
        throwsArgumentError,
      );
      expect(
        () => SupplyBundle(kind: SupplyKind.rations, quantity: 1, unit: ""),
        throwsArgumentError,
      );
    });
    test("validated() menerima nilai valid dan mengembalikan bundle", () {
      final bundle = SupplyBundle(
        kind: SupplyKind.rations,
        quantity: 5,
        unit: "kg",
      );
      expect(bundle.validated(), same(bundle));
    });
  });

  group("SupplyPolicy", () {
    test("menolak modeId kosong, kind null, atau rate negatif", () {
      expect(
        () => SupplyPolicy(
          modeId: "",
          kind: SupplyKind.rations,
          perPersonPerHour: 0.1,
        ),
        throwsArgumentError,
      );
      expect(
        () => SupplyPolicy(modeId: "walk", kind: null, perPersonPerHour: 0.1),
        throwsArgumentError,
      );
      expect(
        () => SupplyPolicy(
          modeId: "walk",
          kind: SupplyKind.rations,
          perPersonPerHour: -0.1,
        ),
        throwsArgumentError,
      );
    });
    test("policy walk mensyaratkan rations dan water", () {
      final policy = SupplyPolicies.standard;
      final walk = policy.forMode(TravelModes.walk.id);
      expect(walk.requiredKinds, contains(SupplyKind.rations));
      expect(walk.requiredKinds, contains(SupplyKind.water));
    });
    test("policy mount mensyaratkan fodder untuk kuda", () {
      final policy = SupplyPolicies.standard;
      final mount = policy.forMode(TravelModes.mount.id);
      expect(mount.requiredKinds, contains(SupplyKind.fodder));
    });
  });

  group("SupplyLoadout", () {
    test("menolak party size nol atau negatif", () {
      expect(
        () => SupplyLoadout(
          partySize: 0,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 5, unit: "kg"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("loadout menolak bundle duplikat untuk kind yang sama", () {
      expect(
        () => SupplyLoadout(
          partySize: 2,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 3, unit: "kg"),
            SupplyBundle(kind: SupplyKind.rations, quantity: 2, unit: "kg"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("total untuk satu kind mengembalikan quantity bundle itu", () {
      final loadout = SupplyLoadout(
        partySize: 1,
        bundles: [
          SupplyBundle(kind: SupplyKind.water, quantity: 4, unit: "liter"),
        ],
      );
      expect(loadout.totalOf(SupplyKind.water), 4.0);
    });
  });

  group("SupplyPlanner", () {
    RouteGraph twoLegJourney() => RouteGraph(
      nodes: {
        "a": const RouteNode(id: "a", name: "A"),
        "b": const RouteNode(id: "b", name: "B"),
        "c": const RouteNode(id: "c", name: "C"),
      },
      edges: [
        RouteEdge(id: "e1", fromId: "a", toId: "b", distance: 18),
        RouteEdge(id: "e2", fromId: "b", toId: "c", distance: 12),
      ],
    );

    test("perjalanan singkat dengan loadout cukup menghasilkan status ok", () {
      final result = SupplyPlanner().plan(
        graph: twoLegJourney(),
        segments: const ["e1", "e2"],
        mode: TravelModes.walk,
        season: Season.spring,
        partySize: 2,
        loadout: SupplyLoadout(
          partySize: 2,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 5, unit: "kg"),
            SupplyBundle(kind: SupplyKind.water, quantity: 10, unit: "liter"),
          ],
        ),
      );

      expect(result.status, SupplyStatus.sufficient);
      expect(result.shortages, isEmpty);
      expect(result.consumption, isNotEmpty);
    });

    test("perjalanan jauh dengan loadout kurang memicu shortage rations", () {
      final result = SupplyPlanner().plan(
        graph: twoLegJourney(),
        segments: const ["e1", "e2"],
        mode: TravelModes.walk,
        season: Season.winter,
        partySize: 4,
        loadout: SupplyLoadout(
          partySize: 4,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 0.5, unit: "kg"),
            SupplyBundle(kind: SupplyKind.water, quantity: 20, unit: "liter"),
          ],
        ),
      );

      expect(result.status, SupplyStatus.insufficient);
      final rationShortage = result.shortages.firstWhere(
        (s) => s.kind == SupplyKind.rations,
      );
      expect(rationShortage.shortBy, greaterThan(0));
      expect(rationShortage.reasonCode, "rations_exhausted");
    });

    test(
      "mount mensyaratkan fodder; loadout tanpa fodder menghasilkan shortage",
      () {
        final result = SupplyPlanner().plan(
          graph: twoLegJourney(),
          segments: const ["e1"],
          mode: TravelModes.mount,
          season: Season.autumn,
          partySize: 1,
          loadout: SupplyLoadout(
            partySize: 1,
            bundles: [
              SupplyBundle(kind: SupplyKind.rations, quantity: 10, unit: "kg"),
              SupplyBundle(kind: SupplyKind.water, quantity: 10, unit: "liter"),
            ],
          ),
        );

        expect(result.status, SupplyStatus.insufficient);
        expect(
          result.shortages.map((s) => s.kind),
          contains(SupplyKind.fodder),
        );
      },
    );

    test("blocked segment memicu RouteBlockedException bukan shortage", () {
      final graph = RouteGraph(
        nodes: {
          "a": const RouteNode(id: "a", name: "A"),
          "b": const RouteNode(id: "b", name: "B"),
        },
        edges: [
          RouteEdge(
            id: "e1",
            fromId: "a",
            toId: "b",
            distance: 10,
            blocked: const BlockedRoute(reason: "flooded"),
          ),
        ],
      );

      expect(
        () => SupplyPlanner().plan(
          graph: graph,
          segments: const ["e1"],
          mode: TravelModes.walk,
          season: Season.spring,
          partySize: 1,
          loadout: SupplyLoadout(
            partySize: 1,
            bundles: [
              SupplyBundle(kind: SupplyKind.rations, quantity: 5, unit: "kg"),
              SupplyBundle(kind: SupplyKind.water, quantity: 5, unit: "liter"),
            ],
          ),
        ),
        throwsA(isA<RouteBlockedException>()),
      );
    });

    test("hasil plan deterministik untuk input identik", () {
      final first = SupplyPlanner().plan(
        graph: twoLegJourney(),
        segments: const ["e1", "e2"],
        mode: TravelModes.walk,
        season: Season.summer,
        partySize: 2,
        loadout: SupplyLoadout(
          partySize: 2,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 4, unit: "kg"),
            SupplyBundle(kind: SupplyKind.water, quantity: 8, unit: "liter"),
          ],
        ),
      );
      final second = SupplyPlanner().plan(
        graph: twoLegJourney(),
        segments: const ["e1", "e2"],
        mode: TravelModes.walk,
        season: Season.summer,
        partySize: 2,
        loadout: SupplyLoadout(
          partySize: 2,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 4, unit: "kg"),
            SupplyBundle(kind: SupplyKind.water, quantity: 8, unit: "liter"),
          ],
        ),
      );

      expect(second.consumed, first.consumed);
      expect(second.shortages, first.shortages);
    });
  });
}
