// Sprint 111.16 - Habitat, Ecology and Behavior.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_ecology.dart";

void main() {
  group("EcologyHabitat", () {
    test("rejects empty habitat id", () {
      expect(
        () => EcologyHabitat.validated(habitatId: " ", description: "Cave"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => EcologyHabitat.validated(habitatId: "cave", description: ""),
        throwsArgumentError,
      );
    });
    test("keeps habitat fields", () {
      final h = EcologyHabitat.validated(
        habitatId: "cave",
        description: "Deep limestone caves",
      );
      expect(h.habitatId, "cave");
      expect(h.description, "Deep limestone caves");
    });
  });

  group("DietItem", () {
    test("rejects empty item id", () {
      expect(
        () => DietItem.validated(itemId: " ", name: "Small mammals"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => DietItem.validated(itemId: "mammals", name: "  "),
        throwsArgumentError,
      );
    });
    test("keeps diet item fields", () {
      final d = DietItem.validated(
        itemId: "mammals",
        name: "Small mammals",
        proportion: "Primary",
      );
      expect(d.itemId, "mammals");
      expect(d.name, "Small mammals");
      expect(d.proportion, "Primary");
    });
    test("accepts diet item without proportion", () {
      final d = DietItem.validated(itemId: "mammals", name: "Small mammals");
      expect(d.proportion, isNull);
    });
  });

  group("SpeciesRef", () {
    test("rejects empty species id", () {
      expect(() => SpeciesRef.validated(speciesId: " "), throwsArgumentError);
    });
    test("keeps species id", () {
      final s = SpeciesRef.validated(speciesId: "fangwing");
      expect(s.speciesId, "fangwing");
    });
  });

  group("SocialStructure", () {
    test("rejects empty structure id", () {
      expect(
        () => SocialStructure.validated(structureId: " ", name: "Pack"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => SocialStructure.validated(structureId: "pack", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps structure fields", () {
      final s = SocialStructure.validated(
        structureId: "pack",
        name: "Pack",
        description: "Alpha-led packs of 6-12",
      );
      expect(s.structureId, "pack");
      expect(s.name, "Pack");
      expect(s.description, "Alpha-led packs of 6-12");
    });
    test("accepts structure without description", () {
      final s = SocialStructure.validated(structureId: "pack", name: "Pack");
      expect(s.description, isNull);
    });
  });

  group("MigrationPattern", () {
    test("rejects empty pattern id", () {
      expect(
        () =>
            MigrationPattern.validated(patternId: " ", description: "Seasonal"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () =>
            MigrationPattern.validated(patternId: "seasonal", description: " "),
        throwsArgumentError,
      );
    });
    test("keeps migration fields", () {
      final m = MigrationPattern.validated(
        patternId: "seasonal",
        description: "North in summer",
        route: "Coastal route",
      );
      expect(m.patternId, "seasonal");
      expect(m.description, "North in summer");
      expect(m.route, "Coastal route");
    });
    test("accepts migration without route", () {
      final m = MigrationPattern.validated(
        patternId: "seasonal",
        description: "North",
      );
      expect(m.route, isNull);
    });
  });

  group("HuntingBehavior", () {
    test("rejects empty behavior id", () {
      expect(
        () => HuntingBehavior.validated(behaviorId: " ", name: "Ambush"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => HuntingBehavior.validated(behaviorId: "ambush", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps behavior fields", () {
      final b = HuntingBehavior.validated(
        behaviorId: "ambush",
        name: "Ambush",
        description: "Strikes from cover",
      );
      expect(b.behaviorId, "ambush");
      expect(b.name, "Ambush");
      expect(b.description, "Strikes from cover");
    });
    test("accepts behavior without description", () {
      final b = HuntingBehavior.validated(behaviorId: "ambush", name: "Ambush");
      expect(b.description, isNull);
    });
  });

  group("EcologyProfile validated", () {
    test("rejects empty species id", () {
      expect(
        () => EcologyProfile.validated(speciesId: " "),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final e = EcologyProfile.validated(speciesId: "fw");
      expect(e.speciesId, "fw");
      expect(e.habitats, isEmpty);
      expect(e.diet, isEmpty);
      expect(e.predators, isEmpty);
      expect(e.prey, isEmpty);
      expect(e.socialStructures, isEmpty);
      expect(e.migrations, isEmpty);
      expect(e.huntingBehaviors, isEmpty);
    });
    test("stores a complete ecology profile", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        habitats: [
          EcologyHabitat.validated(habitatId: "cave", description: "Cave"),
        ],
        diet: [DietItem.validated(itemId: "mammals", name: "Small mammals")],
        predators: [SpeciesRef.validated(speciesId: "wyrm")],
        prey: [SpeciesRef.validated(speciesId: "moth")],
        socialStructures: [
          SocialStructure.validated(structureId: "pack", name: "Pack"),
        ],
        migrations: [
          MigrationPattern.validated(
            patternId: "seasonal",
            description: "North",
          ),
        ],
        huntingBehaviors: [
          HuntingBehavior.validated(behaviorId: "ambush", name: "Ambush"),
        ],
      );
      expect(e.habitats, hasLength(1));
      expect(e.diet, hasLength(1));
      expect(e.predators, hasLength(1));
      expect(e.prey, hasLength(1));
      expect(e.socialStructures, hasLength(1));
      expect(e.migrations, hasLength(1));
      expect(e.huntingBehaviors, hasLength(1));
    });
  });

  group("EcologyProfile duplicate guards", () {
    test("rejects duplicate habitat ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          habitats: [
            EcologyHabitat.validated(habitatId: "cave", description: "A"),
            EcologyHabitat.validated(habitatId: "cave", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate diet item ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          diet: [
            DietItem.validated(itemId: "mammals", name: "A"),
            DietItem.validated(itemId: "mammals", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate predator species ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          predators: [
            SpeciesRef.validated(speciesId: "wyrm"),
            SpeciesRef.validated(speciesId: "wyrm"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate prey species ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          prey: [
            SpeciesRef.validated(speciesId: "moth"),
            SpeciesRef.validated(speciesId: "moth"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate social structure ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          socialStructures: [
            SocialStructure.validated(structureId: "pack", name: "A"),
            SocialStructure.validated(structureId: "pack", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate migration pattern ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          migrations: [
            MigrationPattern.validated(patternId: "seasonal", description: "A"),
            MigrationPattern.validated(patternId: "seasonal", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate hunting behavior ids", () {
      expect(
        () => EcologyProfile.validated(
          speciesId: "fw",
          huntingBehaviors: [
            HuntingBehavior.validated(behaviorId: "ambush", name: "A"),
            HuntingBehavior.validated(behaviorId: "ambush", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("EcologyProfile behavior", () {
    test("inHabitat detects membership", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        habitats: [
          EcologyHabitat.validated(habitatId: "cave", description: "Cave"),
        ],
      );
      expect(e.inHabitat("cave"), isTrue);
      expect(e.inHabitat("forest"), isFalse);
    });
    test("eats detects diet membership", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        diet: [DietItem.validated(itemId: "mammals", name: "Small mammals")],
      );
      expect(e.eats("mammals"), isTrue);
      expect(e.eats("fish"), isFalse);
    });
    test("hasPredator detects membership", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        predators: [SpeciesRef.validated(speciesId: "wyrm")],
      );
      expect(e.hasPredator("wyrm"), isTrue);
      expect(e.hasPredator("hawk"), isFalse);
    });
    test("hasPrey detects membership", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        prey: [SpeciesRef.validated(speciesId: "moth")],
      );
      expect(e.hasPrey("moth"), isTrue);
      expect(e.hasPrey("deer"), isFalse);
    });
    test("hasHuntingBehavior detects membership", () {
      final e = EcologyProfile.validated(
        speciesId: "fw",
        huntingBehaviors: [
          HuntingBehavior.validated(behaviorId: "ambush", name: "Ambush"),
        ],
      );
      expect(e.hasHuntingBehavior("ambush"), isTrue);
      expect(e.hasHuntingBehavior("chase"), isFalse);
    });
  });

  group("EcologyCatalog", () {
    test("empty catalog has no profiles", () {
      final c = EcologyCatalog.empty();
      expect(c.length, 0);
      expect(c.profileFor("fw"), isNull);
    });
    test("withProfiles guards duplicate species ids", () {
      final e = EcologyProfile.validated(speciesId: "fw");
      final c = EcologyCatalog.withProfiles([e]);
      expect(c.length, 1);
      expect(c.profileFor("fw"), same(e));
      expect(() => EcologyCatalog.withProfiles([e, e]), throwsArgumentError);
    });
    test("inHabitat returns sorted by species id", () {
      final z = EcologyProfile.validated(
        speciesId: "z",
        habitats: [
          EcologyHabitat.validated(habitatId: "cave", description: "Cave"),
        ],
      );
      final a = EcologyProfile.validated(
        speciesId: "a",
        habitats: [
          EcologyHabitat.validated(habitatId: "cave", description: "Cave"),
        ],
      );
      final m = EcologyProfile.validated(speciesId: "m");
      final cat = EcologyCatalog.withProfiles([z, a, m]);
      expect(cat.inHabitat("cave").map((p) => p.speciesId).toList(), [
        "a",
        "z",
      ]);
    });
  });
}
