// Scene Knowledge Preview test - 110.38 (RED/GREEN).

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/character_location_history.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';
import 'package:void_scriptor/features/world_logic/domain/scene_knowledge_preview.dart';

void main() {
  group("Scene Knowledge Preview (110.38)", () {
    RumorSeed seed({
      String id = "rumor-1",
      String summary = "The Void opens at the pole.",
      String personId = "aria",
      int tick = 10,
    }) {
      return RumorSeed(
        id: id,
        summary: summary,
        origin: RumorOrigin(personId: personId),
        tick: tick,
        source: const RumorSource(
          revision: "rev-1",
          reason: "initial sighting",
        ),
      );
    }

    RumorNetwork networkFor(List<List<String>> edges, Set<String> persons) {
      return RumorNetwork(
        persons: persons,
        edges: [for (final e in edges) RumorEdge(from: e[0], to: e[1])],
      );
    }

    CharacterLocationTimeline blankTimeline(String personId) {
      return CharacterLocationTimeline(personId: personId);
    }

    CharacterLocationTimeline timelineWithEvents(
      String personId,
      List<LocationEvent> events,
    ) {
      final t = CharacterLocationTimeline(personId: personId);
      for (final e in events) {
        t.record(e);
      }
      return t;
    }

    LocationEvent ev({
      required String id,
      required String personId,
      required String locationId,
      required int tick,
      LocationEventKind kind = LocationEventKind.confirmed,
    }) {
      return LocationEvent.validated(
        id: id,
        personId: personId,
        locationId: locationId,
        tick: tick,
        kind: kind,
        source: LocationHistorySource.validated(
          id: 'src-$id',
          revision: 'rev-$id',
          reason: 'event $id',
          kind: LocationSourceKind.outline,
        ),
      );
    }

    test("knowledge_query origin + downstream with arrival", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: [
          blankTimeline("aria"),
          blankTimeline("boreas"),
          blankTimeline("cyra"),
          blankTimeline("dax"),
        ],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
            ["boreas", "cyra"],
            ["aria", "dax"],
          ],
          const {"aria", "boreas", "cyra", "dax"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 2,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final report = resolver.whoKnows(factId: "rumor-1", sceneTick: 20);
      final byPerson = {for (final k in report.knowledge) k.personId: k};
      expect(byPerson["aria"]!.knowsFact, isTrue);
      expect(byPerson["aria"]!.arrivalTick, 10);
      expect(byPerson["aria"]!.confidence, 1.0);
      expect(byPerson["boreas"]!.knowsFact, isTrue);
      expect(byPerson["boreas"]!.arrivalTick, 12);
      expect(byPerson["cyra"]!.knowsFact, isTrue);
      expect(byPerson["cyra"]!.arrivalTick, 14);
      expect(byPerson["dax"]!.knowsFact, isTrue);
      expect(byPerson["dax"]!.arrivalTick, 12);
    });

    test("source_chain retained to seed revision", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: [blankTimeline("aria"), blankTimeline("boreas")],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
          ],
          const {"aria", "boreas"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 1,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final report = resolver.whoKnows(factId: "rumor-1", sceneTick: 20);
      final boreas = report.knowledge.firstWhere((k) => k.personId == "boreas");
      expect(boreas.sourceChain, isNotEmpty);
      expect(boreas.sourceChain, contains("rev-1"));
    });

    test("confidence clamped [0,1] and decays with reliability", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: [
          blankTimeline("aria"),
          blankTimeline("boreas"),
          blankTimeline("cyra"),
        ],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
            ["boreas", "cyra"],
          ],
          const {"aria", "boreas", "cyra"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 1,
          reliability: 4,
          distortionFactor: 0.0,
        ),
      );
      final report = resolver.whoKnows(factId: "rumor-1", sceneTick: 30);
      final byPerson = {for (final k in report.knowledge) k.personId: k};
      for (final k in byPerson.values) {
        expect(k.confidence, inInclusiveRange(0.0, 1.0));
      }
      expect(byPerson["aria"]!.confidence, 1.0);
      expect(byPerson["boreas"]!.confidence, closeTo(0.4, 1e-9));
      expect(byPerson["cyra"]!.confidence, closeTo(0.16, 1e-9));
    });

    test("arrival beyond scene tick -> not knowing with reason", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed(tick: 100)],
        simulator: const RumorPropagationSimulator(),
        timelines: [
          blankTimeline("aria"),
          blankTimeline("boreas"),
          blankTimeline("cyra"),
        ],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
            ["boreas", "cyra"],
          ],
          const {"aria", "boreas", "cyra"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 50,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final report = resolver.whoKnows(factId: "rumor-1", sceneTick: 120);
      // aria at origin (tick 100) knows fact at sceneTick 120.
      final aria = report.knowledge.firstWhere((k) => k.personId == "aria");
      expect(aria.knowsFact, isTrue);
      expect(aria.arrivalTick, 100);
      // boreas arrivalTick 150 > sceneTick 120 -> absent from report.
      expect(report.knowledge.any((k) => k.personId == "boreas"), isFalse);
    });

    test("writer_preview ordered arrival then id; reasons non-empty", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: [
          blankTimeline("aria"),
          blankTimeline("boreas"),
          blankTimeline("cyra"),
          blankTimeline("dax"),
        ],
        networkOverride: networkFor(
          const [
            ["aria", "dax"],
            ["aria", "boreas"],
            ["boreas", "cyra"],
          ],
          const {"aria", "boreas", "cyra", "dax"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 3,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final preview = resolver.writerPreview(factId: "rumor-1", sceneTick: 30);
      final ids = preview.entries.map((e) => e.personId).toList();
      expect(ids, ["aria", "boreas", "dax", "cyra"]);
      for (final entry in preview.entries) {
        expect(entry.reason, isNotEmpty);
      }
    });

    test("location_awareness marks recipients at scene as in scene", () {
      final ariaTimeline = timelineWithEvents("aria", [
        ev(
          id: "ev1",
          personId: "aria",
          locationId: "scene-loc",
          tick: 5,
          kind: LocationEventKind.confirmed,
        ),
      ]);
      final boreasTimeline = timelineWithEvents("boreas", [
        ev(id: "ev2", personId: "boreas", locationId: "other-loc", tick: 5),
      ]);
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: [ariaTimeline, boreasTimeline],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
          ],
          const {"aria", "boreas"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 1,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final preview = resolver.writerPreview(
        factId: "rumor-1",
        sceneTick: 20,
        sceneLocationId: "scene-loc",
      );
      final byPerson = {for (final e in preview.entries) e.personId: e};
      expect(byPerson["aria"]!.isInScene, isTrue);
      expect(byPerson["boreas"]!.isInScene, isFalse);
    });

    test("unknown fact id raises ArgumentError", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [seed()],
        simulator: const RumorPropagationSimulator(),
        timelines: const <CharacterLocationTimeline>[],
        networkOverride: networkFor(const [], const {"aria"}),
        traitsOverride: const RumorTraits(),
      );
      expect(
        () => resolver.whoKnows(factId: "nope", sceneTick: 50),
        throwsArgumentError,
      );
    });

    test("multi-seed scenarios are independent per fact", () {
      final resolver = SceneKnowledgeResolver(
        seeds: [
          seed(),
          const RumorSeed(
            id: 'rumor-2',
            summary: 'Ships are gathering.',
            origin: RumorOrigin(personId: 'boreas'),
            tick: 12,
            source: RumorSource(revision: 'rev-2', reason: 'port report'),
          ),
        ],
        simulator: const RumorPropagationSimulator(),
        timelines: [blankTimeline("aria"), blankTimeline("boreas")],
        networkOverride: networkFor(
          const [
            ["aria", "boreas"],
          ],
          const {"aria", "boreas"},
        ),
        traitsOverride: const RumorTraits(
          propagationDelayTicks: 1,
          reliability: 10,
          distortionFactor: 0.0,
        ),
      );
      final report1 = resolver.whoKnows(factId: "rumor-1", sceneTick: 30);
      final report2 = resolver.whoKnows(factId: "rumor-2", sceneTick: 30);
      // rumor-1: aria origin -> chain is [rev-1].
      expect(
        report1.knowledge.firstWhere((k) => k.personId == "aria").sourceChain,
        ["rev-1"],
      );
      // rumor-2 origin boreas; no outgoing edges -> only boreas in report.
      final boreasR2 = report2.knowledge.firstWhere(
        (k) => k.personId == "boreas",
      );
      expect(boreasR2.sourceChain, ["rev-2"]);
      expect(report2.knowledge.any((k) => k.personId == "aria"), isFalse);
    });
  });
}
