// Sprint 111.14 - Creature and Species Registry.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_creature.dart";

void main() {
  group("CreatureClassification", () {
    test("has a defined set of classifications with labels", () {
      expect(CreatureClassification.values.length, greaterThanOrEqualTo(6));
      for (final c in CreatureClassification.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });

  group("SpeciesVariant", () {
    test("rejects empty variant id", () {
      expect(
        () => SpeciesVariant.validated(variantId: " ", name: "Northern"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => SpeciesVariant.validated(variantId: "v1", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps variant fields with optional notes", () {
      final v = SpeciesVariant.validated(
        variantId: "northern",
        name: "Northern Fangwing",
        notes: "Pale fur, larger ears",
      );
      expect(v.variantId, "northern");
      expect(v.name, "Northern Fangwing");
      expect(v.notes, "Pale fur, larger ears");
    });
    test("accepts variant without notes", () {
      final v = SpeciesVariant.validated(
        variantId: "northern",
        name: "Northern",
      );
      expect(v.notes, isNull);
    });
  });

  group("LifeStage", () {
    test("rejects empty stage id", () {
      expect(
        () => LifeStage.validated(stageId: " ", name: "Hatchling"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => LifeStage.validated(stageId: "s1", name: "  "),
        throwsArgumentError,
      );
    });
    test("keeps stage fields", () {
      final s = LifeStage.validated(
        stageId: "hatchling",
        name: "Hatchling",
        description: "First three months",
      );
      expect(s.stageId, "hatchling");
      expect(s.name, "Hatchling");
      expect(s.description, "First three months");
    });
    test("accepts stage without description", () {
      final s = LifeStage.validated(stageId: "adult", name: "Adult");
      expect(s.description, isNull);
    });
  });

  group("LocalName", () {
    test("rejects empty name", () {
      expect(
        () => LocalName.validated(name: " ", culture: "Voidfolk"),
        throwsArgumentError,
      );
    });
    test("rejects empty culture", () {
      expect(
        () => LocalName.validated(name: "Zar", culture: ""),
        throwsArgumentError,
      );
    });
    test("keeps local name fields", () {
      final n = LocalName.validated(
        name: "Zar",
        culture: "Voidfolk",
        meaning: "Shadow eater",
      );
      expect(n.name, "Zar");
      expect(n.culture, "Voidfolk");
      expect(n.meaning, "Shadow eater");
    });
    test("accepts local name without meaning", () {
      final n = LocalName.validated(name: "Zar", culture: "Voidfolk");
      expect(n.meaning, isNull);
    });
  });

  group("CanonStatus", () {
    test("has a defined ladder with labels", () {
      expect(CanonStatus.values.length, greaterThanOrEqualTo(5));
      for (final s in CanonStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });
  group("CreatureSpecies validated", () {
    test("rejects empty species id", () {
      expect(
        () => CreatureSpecies.validated(speciesId: " ", name: "Fangwing"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => CreatureSpecies.validated(speciesId: "fw", name: ""),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final c = CreatureSpecies.validated(speciesId: "fw", name: "Fangwing");
      expect(c.speciesId, "fw");
      expect(c.name, "Fangwing");
      expect(c.variants, isEmpty);
      expect(c.lifeStages, isEmpty);
      expect(c.localNames, isEmpty);
      expect(c.classification, isNull);
      expect(c.canonStatus, isNull);
    });
    test("stores a complete species", () {
      final c = CreatureSpecies.validated(
        speciesId: "fw",
        name: "Fangwing",
        classification: CreatureClassification.animal,
        canonStatus: CanonStatus.canon,
        variants: [SpeciesVariant.validated(variantId: "n", name: "Northern")],
        lifeStages: [LifeStage.validated(stageId: "adult", name: "Adult")],
        localNames: [LocalName.validated(name: "Zar", culture: "Voidfolk")],
      );
      expect(c.classification, CreatureClassification.animal);
      expect(c.canonStatus, CanonStatus.canon);
      expect(c.variants, hasLength(1));
      expect(c.lifeStages, hasLength(1));
      expect(c.localNames, hasLength(1));
    });
  });

  group("CreatureSpecies duplicate guards", () {
    test("rejects duplicate variant ids", () {
      expect(
        () => CreatureSpecies.validated(
          speciesId: "fw",
          name: "Fangwing",
          variants: [
            SpeciesVariant.validated(variantId: "n", name: "A"),
            SpeciesVariant.validated(variantId: "n", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate life stage ids", () {
      expect(
        () => CreatureSpecies.validated(
          speciesId: "fw",
          name: "Fangwing",
          lifeStages: [
            LifeStage.validated(stageId: "adult", name: "A"),
            LifeStage.validated(stageId: "adult", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate local names", () {
      expect(
        () => CreatureSpecies.validated(
          speciesId: "fw",
          name: "Fangwing",
          localNames: [
            LocalName.validated(name: "Zar", culture: "Voidfolk"),
            LocalName.validated(name: "Zar", culture: "Voidfolk"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("CreatureSpecies behavior", () {
    test("hasVariant detects membership", () {
      final c = CreatureSpecies.validated(
        speciesId: "fw",
        name: "Fangwing",
        variants: [SpeciesVariant.validated(variantId: "n", name: "Northern")],
      );
      expect(c.hasVariant("n"), isTrue);
      expect(c.hasVariant("s"), isFalse);
    });
    test("hasLifeStage detects membership", () {
      final c = CreatureSpecies.validated(
        speciesId: "fw",
        name: "Fangwing",
        lifeStages: [LifeStage.validated(stageId: "adult", name: "Adult")],
      );
      expect(c.hasLifeStage("adult"), isTrue);
      expect(c.hasLifeStage("egg"), isFalse);
    });
    test("localNameForCulture finds a local name", () {
      final c = CreatureSpecies.validated(
        speciesId: "fw",
        name: "Fangwing",
        localNames: [LocalName.validated(name: "Zar", culture: "Voidfolk")],
      );
      expect(c.localNameForCulture("Voidfolk"), "Zar");
      expect(c.localNameForCulture("Other"), isNull);
    });
  });

  group("CreatureCatalog", () {
    test("empty catalog has no species", () {
      final c = CreatureCatalog.empty();
      expect(c.length, 0);
      expect(c.speciesFor("fw"), isNull);
    });
    test("withSpecies guards duplicate species ids", () {
      final c = CreatureSpecies.validated(speciesId: "fw", name: "Fangwing");
      final cat = CreatureCatalog.withSpecies([c]);
      expect(cat.length, 1);
      expect(cat.speciesFor("fw"), same(c));
      expect(() => CreatureCatalog.withSpecies([c, c]), throwsArgumentError);
    });
    test("byClassification returns sorted by species id", () {
      final z = CreatureSpecies.validated(
        speciesId: "z",
        name: "Z",
        classification: CreatureClassification.animal,
      );
      final a = CreatureSpecies.validated(
        speciesId: "a",
        name: "A",
        classification: CreatureClassification.animal,
      );
      final m = CreatureSpecies.validated(
        speciesId: "m",
        name: "M",
        classification: CreatureClassification.plant,
      );
      final cat = CreatureCatalog.withSpecies([z, a, m]);
      expect(
        cat
            .byClassification(CreatureClassification.animal)
            .map((s) => s.speciesId)
            .toList(),
        ["a", "z"],
      );
    });
    test("byCanonStatus returns sorted by species id", () {
      final c1 = CreatureSpecies.validated(
        speciesId: "b",
        name: "B",
        canonStatus: CanonStatus.canon,
      );
      final c2 = CreatureSpecies.validated(
        speciesId: "a",
        name: "A",
        canonStatus: CanonStatus.canon,
      );
      final r = CreatureSpecies.validated(
        speciesId: "r",
        name: "R",
        canonStatus: CanonStatus.rumor,
      );
      final cat = CreatureCatalog.withSpecies([c1, c2, r]);
      expect(
        cat.byCanonStatus(CanonStatus.canon).map((s) => s.speciesId).toList(),
        ["a", "b"],
      );
    });
  });
}
