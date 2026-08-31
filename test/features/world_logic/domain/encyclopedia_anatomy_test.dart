// Sprint 111.15 - Anatomy and Physiology Profile.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_anatomy.dart";

void main() {
  group("BodyPlan", () {
    test("rejects empty body plan id", () {
      expect(
        () => BodyPlan.validated(bodyPlanId: " ", description: "Quadruped"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => BodyPlan.validated(bodyPlanId: "bp1", description: ""),
        throwsArgumentError,
      );
    });
    test("keeps body plan fields", () {
      final b = BodyPlan.validated(
        bodyPlanId: "quadruped",
        description: "Four-legged frame",
      );
      expect(b.bodyPlanId, "quadruped");
      expect(b.description, "Four-legged frame");
    });
  });

  group("OrganRef", () {
    test("rejects empty organ id", () {
      expect(
        () => OrganRef.validated(organId: " ", name: "Heart"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => OrganRef.validated(organId: "heart", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps organ fields", () {
      final o = OrganRef.validated(
        organId: "heart",
        name: "Heart",
        note: "Three chambers",
      );
      expect(o.organId, "heart");
      expect(o.name, "Heart");
      expect(o.note, "Three chambers");
    });
    test("accepts organ without note", () {
      final o = OrganRef.validated(organId: "heart", name: "Heart");
      expect(o.note, isNull);
    });
  });

  group("SenseRef", () {
    test("rejects empty sense id", () {
      expect(
        () => SenseRef.validated(senseId: " ", name: "Echolocation"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => SenseRef.validated(senseId: "echo", name: "  "),
        throwsArgumentError,
      );
    });
    test("keeps sense fields", () {
      final s = SenseRef.validated(
        senseId: "echo",
        name: "Echolocation",
        range: "100m",
      );
      expect(s.senseId, "echo");
      expect(s.name, "Echolocation");
      expect(s.range, "100m");
    });
    test("accepts sense without range", () {
      final s = SenseRef.validated(senseId: "echo", name: "Echolocation");
      expect(s.range, isNull);
    });
  });

  group("LocomotionMode", () {
    test("rejects empty mode id", () {
      expect(
        () => LocomotionMode.validated(modeId: " ", name: "Flight"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => LocomotionMode.validated(modeId: "fly", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps mode fields", () {
      final m = LocomotionMode.validated(
        modeId: "fly",
        name: "Flight",
        speed: "Up to 60 km/h",
      );
      expect(m.modeId, "fly");
      expect(m.name, "Flight");
      expect(m.speed, "Up to 60 km/h");
    });
    test("accepts mode without speed", () {
      final m = LocomotionMode.validated(modeId: "fly", name: "Flight");
      expect(m.speed, isNull);
    });
  });

  group("DefenseMechanism", () {
    test("rejects empty defense id", () {
      expect(
        () => DefenseMechanism.validated(defenseId: " ", name: "Camouflage"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => DefenseMechanism.validated(defenseId: "cam", name: " "),
        throwsArgumentError,
      );
    });
    test("keeps defense fields", () {
      final d = DefenseMechanism.validated(
        defenseId: "cam",
        name: "Camouflage",
        description: "Blends with rock",
      );
      expect(d.defenseId, "cam");
      expect(d.name, "Camouflage");
      expect(d.description, "Blends with rock");
    });
    test("accepts defense without description", () {
      final d = DefenseMechanism.validated(
        defenseId: "cam",
        name: "Camouflage",
      );
      expect(d.description, isNull);
    });
  });

  group("ReproductionProfile", () {
    test("rejects empty method", () {
      expect(
        () => ReproductionProfile.validated(method: " ", details: "Eggs"),
        throwsArgumentError,
      );
    });
    test("keeps reproduction fields", () {
      final r = ReproductionProfile.validated(
        method: "Oviparous",
        details: "Clutch of 3-5 eggs",
      );
      expect(r.method, "Oviparous");
      expect(r.details, "Clutch of 3-5 eggs");
    });
    test("accepts reproduction without details", () {
      final r = ReproductionProfile.validated(method: "Oviparous");
      expect(r.details, isNull);
    });
  });

  group("BiologicalNeed", () {
    test("rejects empty need id", () {
      expect(
        () => BiologicalNeed.validated(needId: " ", name: "Water"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => BiologicalNeed.validated(needId: "water", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps need fields", () {
      final n = BiologicalNeed.validated(
        needId: "water",
        name: "Water",
        description: "Daily soak required",
      );
      expect(n.needId, "water");
      expect(n.name, "Water");
      expect(n.description, "Daily soak required");
    });
    test("accepts need without description", () {
      final n = BiologicalNeed.validated(needId: "water", name: "Water");
      expect(n.description, isNull);
    });
  });
  group("AnatomyProfile validated", () {
    test("rejects empty species id", () {
      expect(
        () => AnatomyProfile.validated(speciesId: " "),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final a = AnatomyProfile.validated(speciesId: "fw");
      expect(a.speciesId, "fw");
      expect(a.organs, isEmpty);
      expect(a.senses, isEmpty);
      expect(a.locomotion, isEmpty);
      expect(a.defenses, isEmpty);
      expect(a.biologicalNeeds, isEmpty);
      expect(a.bodyPlan, isNull);
      expect(a.reproduction, isNull);
    });
    test("stores a complete anatomy profile", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        bodyPlan: BodyPlan.validated(
          bodyPlanId: "quadruped",
          description: "Four-legged",
        ),
        organs: [OrganRef.validated(organId: "heart", name: "Heart")],
        senses: [SenseRef.validated(senseId: "echo", name: "Echolocation")],
        locomotion: [LocomotionMode.validated(modeId: "fly", name: "Flight")],
        defenses: [
          DefenseMechanism.validated(defenseId: "cam", name: "Camouflage"),
        ],
        reproduction: ReproductionProfile.validated(method: "Oviparous"),
        biologicalNeeds: [
          BiologicalNeed.validated(needId: "water", name: "Water"),
        ],
      );
      expect(a.bodyPlan!.bodyPlanId, "quadruped");
      expect(a.organs, hasLength(1));
      expect(a.senses, hasLength(1));
      expect(a.locomotion, hasLength(1));
      expect(a.defenses, hasLength(1));
      expect(a.reproduction!.method, "Oviparous");
      expect(a.biologicalNeeds, hasLength(1));
    });
  });

  group("AnatomyProfile duplicate guards", () {
    test("rejects duplicate organ ids", () {
      expect(
        () => AnatomyProfile.validated(
          speciesId: "fw",
          organs: [
            OrganRef.validated(organId: "heart", name: "A"),
            OrganRef.validated(organId: "heart", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate sense ids", () {
      expect(
        () => AnatomyProfile.validated(
          speciesId: "fw",
          senses: [
            SenseRef.validated(senseId: "echo", name: "A"),
            SenseRef.validated(senseId: "echo", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate locomotion ids", () {
      expect(
        () => AnatomyProfile.validated(
          speciesId: "fw",
          locomotion: [
            LocomotionMode.validated(modeId: "fly", name: "A"),
            LocomotionMode.validated(modeId: "fly", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate defense ids", () {
      expect(
        () => AnatomyProfile.validated(
          speciesId: "fw",
          defenses: [
            DefenseMechanism.validated(defenseId: "cam", name: "A"),
            DefenseMechanism.validated(defenseId: "cam", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate biological need ids", () {
      expect(
        () => AnatomyProfile.validated(
          speciesId: "fw",
          biologicalNeeds: [
            BiologicalNeed.validated(needId: "water", name: "A"),
            BiologicalNeed.validated(needId: "water", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("AnatomyProfile behavior", () {
    test("hasOrgan detects membership", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        organs: [OrganRef.validated(organId: "heart", name: "Heart")],
      );
      expect(a.hasOrgan("heart"), isTrue);
      expect(a.hasOrgan("lung"), isFalse);
    });
    test("hasSense detects membership", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        senses: [SenseRef.validated(senseId: "echo", name: "Echolocation")],
      );
      expect(a.hasSense("echo"), isTrue);
      expect(a.hasSense("sight"), isFalse);
    });
    test("hasLocomotion detects membership", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        locomotion: [LocomotionMode.validated(modeId: "fly", name: "Flight")],
      );
      expect(a.hasLocomotion("fly"), isTrue);
      expect(a.hasLocomotion("swim"), isFalse);
    });
    test("hasDefense detects membership", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        defenses: [
          DefenseMechanism.validated(defenseId: "cam", name: "Camouflage"),
        ],
      );
      expect(a.hasDefense("cam"), isTrue);
      expect(a.hasDefense("venom"), isFalse);
    });
    test("hasBiologicalNeed detects membership", () {
      final a = AnatomyProfile.validated(
        speciesId: "fw",
        biologicalNeeds: [
          BiologicalNeed.validated(needId: "water", name: "Water"),
        ],
      );
      expect(a.hasBiologicalNeed("water"), isTrue);
      expect(a.hasBiologicalNeed("heat"), isFalse);
    });
  });

  group("AnatomyCatalog", () {
    test("empty catalog has no profiles", () {
      final c = AnatomyCatalog.empty();
      expect(c.length, 0);
      expect(c.profileFor("fw"), isNull);
    });
    test("withProfiles guards duplicate species ids", () {
      final a = AnatomyProfile.validated(speciesId: "fw");
      final c = AnatomyCatalog.withProfiles([a]);
      expect(c.length, 1);
      expect(c.profileFor("fw"), same(a));
      expect(() => AnatomyCatalog.withProfiles([a, a]), throwsArgumentError);
    });
    test("profilesWithOrgan returns sorted by species id", () {
      final z = AnatomyProfile.validated(
        speciesId: "z",
        organs: [OrganRef.validated(organId: "heart", name: "Heart")],
      );
      final a = AnatomyProfile.validated(
        speciesId: "a",
        organs: [OrganRef.validated(organId: "heart", name: "Heart")],
      );
      final m = AnatomyProfile.validated(speciesId: "m");
      final cat = AnatomyCatalog.withProfiles([z, a, m]);
      expect(cat.profilesWithOrgan("heart").map((p) => p.speciesId).toList(), [
        "a",
        "z",
      ]);
    });
  });
}
