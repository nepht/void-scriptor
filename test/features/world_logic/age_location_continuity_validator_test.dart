// Sprint 110.28 - Age & Location Continuity Alerts (RED).

library;

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/age_location_continuity_validator.dart";
import "package:void_scriptor/features/world_logic/domain/character_location_history.dart";

void main() {
  final source = LocationHistorySource.validated(
    id: "scene-source",
    revision: "r1",
    reason: "continuity fixture",
    kind: LocationSourceKind.novel,
  );

  ScenePresence scene(String id, int tick, String locationId) =>
      ScenePresence.validated(
        sceneId: id,
        personId: "p1",
        tick: tick,
        locationId: locationId,
        sourceId: "chapter-1",
      );

  group("Sprint 110.28 AgeLocationContinuityValidator", () {
    test("not_born_warning explains a scene before birth", () {
      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 10,
        scenes: [scene("before-birth", 9, "north")],
      );

      expect(result.codes, contains(ContinuityAlertCode.notBorn));
      expect(result.alerts.single.explanation, contains("birth tick 10"));
    });

    test("after_death_warning explains a scene at or after death", () {
      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 0,
        deathTick: 20,
        scenes: [scene("after-death", 20, "crypt")],
      );

      expect(result.codes, contains(ContinuityAlertCode.afterDeath));
      expect(result.alerts.single.explanation, contains("death tick 20"));
    });

    test("impossible_travel warns when location changes without a segment", () {
      final timeline = CharacterLocationTimeline(personId: "p1")
        ..record(
          LocationEvent.validated(
            id: "arrival-north",
            personId: "p1",
            locationId: "north",
            tick: 1,
            kind: LocationEventKind.arrival,
            source: source,
          ),
        );

      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 0,
        timeline: timeline,
        scenes: [
          scene("north-scene", 5, "north"),
          scene("south-scene", 6, "south"),
        ],
      );

      expect(result.codes, contains(ContinuityAlertCode.impossibleTravel));
      expect(result.alerts.single.relatedSceneIds, [
        "north-scene",
        "south-scene",
      ]);
    });

    test("recorded travel segment makes the same transition valid", () {
      final timeline = CharacterLocationTimeline(personId: "p1")
        ..record(
          TravelSegment.validated(
            id: "north-south",
            personId: "p1",
            fromLocationId: "north",
            toLocationId: "south",
            startTick: 5,
            endTick: 6,
            source: source,
          ),
        );

      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 0,
        timeline: timeline,
        scenes: [
          scene("north-scene", 5, "north"),
          scene("south-scene", 6, "south"),
        ],
      );

      expect(
        result.codes,
        isNot(contains(ContinuityAlertCode.impossibleTravel)),
      );
    });

    test("overlap_warning reports simultaneous incompatible locations", () {
      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 0,
        scenes: [
          scene("north-scene", 8, "north"),
          scene("south-scene", 8, "south"),
        ],
      );

      expect(result.codes, contains(ContinuityAlertCode.overlap));
      expect(result.alerts.single.explanation, contains("tick 8"));
    });

    test("explain_result is clean and traceable when continuity is valid", () {
      final result = AgeLocationContinuityValidator.validate(
        personId: "p1",
        birthTick: 0,
        scenes: [scene("only-scene", 8, "north")],
      );

      expect(result.isConsistent, isTrue);
      expect(result.alerts, isEmpty);
      expect(result.explanation, contains("p1"));
      expect(result.explanation, contains("1 scene"));
    });
  });
}
