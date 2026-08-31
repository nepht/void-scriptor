// Sprint 111.18 - Encounter and Observation Journal.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_encounter.dart";

void main() {
  group("EncounterWitness", () {
    test("rejects empty witness id", () {
      expect(
        () => EncounterWitness.validated(witnessId: " ", name: "Ranger A"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => EncounterWitness.validated(witnessId: "w1", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps witness fields", () {
      final w = EncounterWitness.validated(
        witnessId: "w1",
        name: "Ranger A",
        note: "Saw it at dusk",
      );
      expect(w.witnessId, "w1");
      expect(w.name, "Ranger A");
      expect(w.note, "Saw it at dusk");
    });
    test("accepts witness without note", () {
      final w = EncounterWitness.validated(witnessId: "w1", name: "Ranger A");
      expect(w.note, isNull);
    });
  });

  group("EncounterLocation", () {
    test("rejects empty location id", () {
      expect(
        () => EncounterLocation.validated(locationId: " ", name: "North Pass"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => EncounterLocation.validated(locationId: "np", name: "  "),
        throwsArgumentError,
      );
    });
    test("keeps location fields", () {
      final l = EncounterLocation.validated(
        locationId: "np",
        name: "North Pass",
        region: "Frostlands",
      );
      expect(l.locationId, "np");
      expect(l.name, "North Pass");
      expect(l.region, "Frostlands");
    });
    test("accepts location without region", () {
      final l = EncounterLocation.validated(
        locationId: "np",
        name: "North Pass",
      );
      expect(l.region, isNull);
    });
  });

  group("EncounterOutcome", () {
    test("has a defined set of outcomes with labels", () {
      expect(EncounterOutcome.values.length, greaterThanOrEqualTo(4));
      for (final o in EncounterOutcome.values) {
        expect(o.label, isNotEmpty);
      }
    });
  });

  group("ReliabilityLevel", () {
    test("has a defined ladder with labels", () {
      expect(ReliabilityLevel.values.length, greaterThanOrEqualTo(4));
      for (final r in ReliabilityLevel.values) {
        expect(r.label, isNotEmpty);
      }
    });
    test("levels are strictly ordered", () {
      for (var i = 1; i < ReliabilityLevel.values.length; i++) {
        expect(
          ReliabilityLevel.values[i].index,
          greaterThan(ReliabilityLevel.values[i - 1].index),
        );
      }
    });
  });

  group("SceneLink", () {
    test("rejects empty scene id", () {
      expect(() => SceneLink.validated(sceneId: " "), throwsArgumentError);
    });
    test("keeps scene id", () {
      final s = SceneLink.validated(sceneId: "scene_1");
      expect(s.sceneId, "scene_1");
    });
  });

  group("EncounterRecord validated", () {
    test("rejects empty encounter id", () {
      expect(
        () => EncounterRecord.validated(encounterId: " ", speciesId: "fw"),
        throwsArgumentError,
      );
    });
    test("rejects empty species id", () {
      expect(
        () => EncounterRecord.validated(encounterId: "e1", speciesId: ""),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final e = EncounterRecord.validated(encounterId: "e1", speciesId: "fw");
      expect(e.encounterId, "e1");
      expect(e.speciesId, "fw");
      expect(e.witnesses, isEmpty);
      expect(e.sceneLinks, isEmpty);
      expect(e.location, isNull);
      expect(e.outcome, isNull);
      expect(e.reliability, isNull);
      expect(e.timeDescription, isNull);
      expect(e.summary, isNull);
    });
    test("stores a complete encounter record", () {
      final e = EncounterRecord.validated(
        encounterId: "e1",
        speciesId: "fw",
        witnesses: [
          EncounterWitness.validated(witnessId: "w1", name: "Ranger A"),
        ],
        location: EncounterLocation.validated(
          locationId: "np",
          name: "North Pass",
        ),
        timeDescription: "Dusk, third moon",
        outcome: EncounterOutcome.observed,
        reliability: ReliabilityLevel.corroborated,
        summary: "Fangwing circled twice",
        sceneLinks: [SceneLink.validated(sceneId: "scene_1")],
      );
      expect(e.witnesses, hasLength(1));
      expect(e.location!.name, "North Pass");
      expect(e.timeDescription, "Dusk, third moon");
      expect(e.outcome, EncounterOutcome.observed);
      expect(e.reliability, ReliabilityLevel.corroborated);
      expect(e.summary, "Fangwing circled twice");
      expect(e.sceneLinks, hasLength(1));
    });
  });

  group("EncounterRecord guards", () {
    test("rejects duplicate witness ids", () {
      expect(
        () => EncounterRecord.validated(
          encounterId: "e1",
          speciesId: "fw",
          witnesses: [
            EncounterWitness.validated(witnessId: "w1", name: "A"),
            EncounterWitness.validated(witnessId: "w1", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate scene links", () {
      expect(
        () => EncounterRecord.validated(
          encounterId: "e1",
          speciesId: "fw",
          sceneLinks: [
            SceneLink.validated(sceneId: "scene_1"),
            SceneLink.validated(sceneId: "scene_1"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty summary when provided", () {
      expect(
        () => EncounterRecord.validated(
          encounterId: "e1",
          speciesId: "fw",
          summary: " ",
        ),
        throwsArgumentError,
      );
    });
  });

  group("EncounterRecord behavior", () {
    test("hasWitness detects membership", () {
      final e = EncounterRecord.validated(
        encounterId: "e1",
        speciesId: "fw",
        witnesses: [
          EncounterWitness.validated(witnessId: "w1", name: "Ranger A"),
        ],
      );
      expect(e.hasWitness("w1"), isTrue);
      expect(e.hasWitness("w2"), isFalse);
    });
    test("linksToScene detects membership", () {
      final e = EncounterRecord.validated(
        encounterId: "e1",
        speciesId: "fw",
        sceneLinks: [SceneLink.validated(sceneId: "scene_1")],
      );
      expect(e.linksToScene("scene_1"), isTrue);
      expect(e.linksToScene("scene_2"), isFalse);
    });
  });

  group("EncounterJournal", () {
    test("empty journal has no records", () {
      final j = EncounterJournal.empty();
      expect(j.length, 0);
      expect(j.recordFor("e1"), isNull);
    });
    test("withRecords guards duplicate encounter ids", () {
      final e = EncounterRecord.validated(encounterId: "e1", speciesId: "fw");
      final j = EncounterJournal.withRecords([e]);
      expect(j.length, 1);
      expect(j.recordFor("e1"), same(e));
      expect(() => EncounterJournal.withRecords([e, e]), throwsArgumentError);
    });
    test("recordsForSpecies returns sorted by encounter id", () {
      final z = EncounterRecord.validated(encounterId: "z", speciesId: "fw");
      final a = EncounterRecord.validated(encounterId: "a", speciesId: "fw");
      final m = EncounterRecord.validated(encounterId: "m", speciesId: "other");
      final j = EncounterJournal.withRecords([z, a, m]);
      expect(j.recordsForSpecies("fw").map((r) => r.encounterId).toList(), [
        "a",
        "z",
      ]);
    });
    test("byReliability returns sorted by encounter id", () {
      final c1 = EncounterRecord.validated(
        encounterId: "b",
        speciesId: "fw",
        reliability: ReliabilityLevel.corroborated,
      );
      final c2 = EncounterRecord.validated(
        encounterId: "a",
        speciesId: "fw",
        reliability: ReliabilityLevel.corroborated,
      );
      final r = EncounterRecord.validated(
        encounterId: "r",
        speciesId: "fw",
        reliability: ReliabilityLevel.unverified,
      );
      final j = EncounterJournal.withRecords([c1, c2, r]);
      expect(
        j
            .byReliability(ReliabilityLevel.corroborated)
            .map((rec) => rec.encounterId)
            .toList(),
        ["a", "b"],
      );
    });
  });
}
