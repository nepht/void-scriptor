// Sprint 111.10 - Habitat, Rarity and Harvest Model.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_harvest.dart";

void main() {
  group("RarityLevel", () {
    test("has a defined rarity ladder with labels", () {
      expect(RarityLevel.values.length, greaterThanOrEqualTo(5));
      for (final r in RarityLevel.values) {
        expect(r.label, isNotEmpty);
      }
    });
    test("weights are strictly increasing", () {
      final weights = RarityLevel.values.map((r) => r.weight).toList();
      for (var i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("SeasonWindow", () {
    test("rejects empty note when provided", () {
      expect(
        () => SeasonWindow.validated(season: Season.spring, note: "  "),
        throwsArgumentError,
      );
    });
    test("keeps season and optional note", () {
      final w = SeasonWindow.validated(
        season: Season.autumn,
        note: "After first frost",
      );
      expect(w.season, Season.autumn);
      expect(w.note, "After first frost");
    });
    test("accepts season without note", () {
      final w = SeasonWindow.validated(season: Season.summer);
      expect(w.season, Season.summer);
      expect(w.note, isNull);
    });
  });

  group("HabitatRef", () {
    test("rejects empty habitat id", () {
      expect(() => HabitatRef.validated(habitatId: "  "), throwsArgumentError);
    });
    test("rejects empty region when provided", () {
      expect(
        () => HabitatRef.validated(habitatId: "cave", region: " "),
        throwsArgumentError,
      );
    });
    test("keeps habitat id and optional region", () {
      final h = HabitatRef.validated(habitatId: "cave", region: "N");
      expect(h.habitatId, "cave");
      expect(h.region, "N");
    });
    test("accepts habitat without region", () {
      final h = HabitatRef.validated(habitatId: "cave");
      expect(h.habitatId, "cave");
      expect(h.region, isNull);
    });
  });

  group("HarvestMethod", () {
    test("rejects empty method id", () {
      expect(
        () => HarvestMethod.validated(methodId: " ", description: "Cut"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => HarvestMethod.validated(methodId: "m1", description: ""),
        throwsArgumentError,
      );
    });
    test("rejects empty tools when provided", () {
      expect(
        () => HarvestMethod.validated(
          methodId: "m1",
          description: "Cut",
          tools: "  ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps method fields", () {
      final m = HarvestMethod.validated(
        methodId: "moonlight_cut",
        description: "Cut under moonlight",
        tools: "Silver sickle",
      );
      expect(m.methodId, "moonlight_cut");
      expect(m.description, "Cut under moonlight");
      expect(m.tools, "Silver sickle");
    });
  });

  group("HarvestHazard", () {
    test("rejects empty hazard id", () {
      expect(
        () => HarvestHazard.validated(hazardId: " ", description: "Thorns"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => HarvestHazard.validated(hazardId: "h1", description: ""),
        throwsArgumentError,
      );
    });
    test("rejects severity out of range 1..5", () {
      expect(
        () => HarvestHazard.validated(
          hazardId: "h1",
          description: "T",
          severity: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => HarvestHazard.validated(
          hazardId: "h1",
          description: "T",
          severity: 6,
        ),
        throwsArgumentError,
      );
    });
    test("keeps hazard fields with severity", () {
      final h = HarvestHazard.validated(
        hazardId: "thorns",
        description: "Poisoned",
        severity: 3,
      );
      expect(h.hazardId, "thorns");
      expect(h.description, "Poisoned");
      expect(h.severity, 3);
    });
    test("accepts hazard without severity", () {
      final h = HarvestHazard.validated(
        hazardId: "scent",
        description: "Attracts predators",
      );
      expect(h.severity, isNull);
    });
  });

  group("HarvestRecord validated", () {
    test("rejects empty ingredient id", () {
      expect(
        () => HarvestRecord.validated(
          ingredientId: "  ",
          rarity: RarityLevel.common,
        ),
        throwsArgumentError,
      );
    });
    test("stores basic fields", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.rare,
      );
      expect(r.ingredientId, "vb");
      expect(r.rarity, RarityLevel.rare);
      expect(r.habitats, isEmpty);
      expect(r.seasonality, isEmpty);
      expect(r.methods, isEmpty);
      expect(r.hazards, isEmpty);
      expect(r.notes, isNull);
    });
    test("stores optional notes", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
        notes: "Only near rift",
      );
      expect(r.notes, "Only near rift");
    });
  });

  group("HarvestRecord duplicate guards", () {
    test("rejects duplicate habitat ids", () {
      expect(
        () => HarvestRecord.validated(
          ingredientId: "vb",
          rarity: RarityLevel.common,
          habitats: [
            HabitatRef.validated(habitatId: "cave"),
            HabitatRef.validated(habitatId: "cave"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate seasons in seasonality", () {
      expect(
        () => HarvestRecord.validated(
          ingredientId: "vb",
          rarity: RarityLevel.common,
          seasonality: [
            SeasonWindow.validated(season: Season.spring),
            SeasonWindow.validated(season: Season.spring),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate method ids", () {
      expect(
        () => HarvestRecord.validated(
          ingredientId: "vb",
          rarity: RarityLevel.common,
          methods: [
            HarvestMethod.validated(methodId: "m1", description: "A"),
            HarvestMethod.validated(methodId: "m1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate hazard ids", () {
      expect(
        () => HarvestRecord.validated(
          ingredientId: "vb",
          rarity: RarityLevel.common,
          hazards: [
            HarvestHazard.validated(hazardId: "h1", description: "A"),
            HarvestHazard.validated(hazardId: "h1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("HarvestRecord behavior", () {
    test("isHarvestableInSeason respects seasonality", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
      );
      expect(r.isHarvestableInSeason(Season.autumn), isTrue);
      expect(r.isHarvestableInSeason(Season.spring), isFalse);
    });
    test("isHarvestableInSeason is true when seasonality empty", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
      );
      expect(r.isHarvestableInSeason(Season.winter), isTrue);
    });
    test("matchesHabitat finds matching habitat", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
        habitats: [HabitatRef.validated(habitatId: "cave")],
      );
      expect(r.matchesHabitat("cave"), isTrue);
      expect(r.matchesHabitat("forest"), isFalse);
    });
    test("isAtLeast compares rarity ladder", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.rare,
      );
      expect(r.isAtLeast(RarityLevel.common), isTrue);
      expect(r.isAtLeast(RarityLevel.rare), isTrue);
      expect(r.isAtLeast(RarityLevel.veryRare), isFalse);
    });
  });

  group("HarvestAvailabilityQuery", () {
    test("matches all records with no filters", () {
      const q = HarvestAvailabilityQuery();
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
      );
      expect(q.matches(r), isTrue);
    });
    test("filters by minimum rarity", () {
      const q = HarvestAvailabilityQuery(minRarity: RarityLevel.rare);
      expect(
        q.matches(
          HarvestRecord.validated(
            ingredientId: "a",
            rarity: RarityLevel.common,
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(
          HarvestRecord.validated(ingredientId: "b", rarity: RarityLevel.rare),
        ),
        isTrue,
      );
    });
    test("filters by season", () {
      const q = HarvestAvailabilityQuery(season: Season.autumn);
      expect(
        q.matches(
          HarvestRecord.validated(
            ingredientId: "a",
            rarity: RarityLevel.common,
            seasonality: [SeasonWindow.validated(season: Season.autumn)],
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          HarvestRecord.validated(
            ingredientId: "b",
            rarity: RarityLevel.common,
            seasonality: [SeasonWindow.validated(season: Season.spring)],
          ),
        ),
        isFalse,
      );
    });
    test("filters by habitat id", () {
      const q = HarvestAvailabilityQuery(habitatId: "cave");
      expect(
        q.matches(
          HarvestRecord.validated(
            ingredientId: "a",
            rarity: RarityLevel.common,
            habitats: [HabitatRef.validated(habitatId: "cave")],
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          HarvestRecord.validated(
            ingredientId: "b",
            rarity: RarityLevel.common,
            habitats: [HabitatRef.validated(habitatId: "forest")],
          ),
        ),
        isFalse,
      );
    });
    test("describe returns non-empty explanation", () {
      const q = HarvestAvailabilityQuery(
        minRarity: RarityLevel.rare,
        season: Season.autumn,
        habitatId: "cave",
      );
      expect(q.describe(), isNotEmpty);
    });
  });

  group("HarvestCatalog", () {
    test("empty catalog has no records", () {
      final c = HarvestCatalog.empty();
      expect(c.length, 0);
      expect(c.recordFor("vb"), isNull);
    });
    test("withRecords guards duplicate ingredient ids", () {
      final r = HarvestRecord.validated(
        ingredientId: "vb",
        rarity: RarityLevel.common,
      );
      final c = HarvestCatalog.withRecords([r]);
      expect(c.length, 1);
      expect(c.recordFor("vb"), same(r));
      expect(() => HarvestCatalog.withRecords([r, r]), throwsArgumentError);
    });
    test("query returns sorted by ingredient id", () {
      final a = HarvestRecord.validated(
        ingredientId: "z",
        rarity: RarityLevel.rare,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
      );
      final b = HarvestRecord.validated(
        ingredientId: "a",
        rarity: RarityLevel.common,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
      );
      final c = HarvestRecord.validated(
        ingredientId: "m",
        rarity: RarityLevel.unique,
        seasonality: [SeasonWindow.validated(season: Season.spring)],
      );
      final cat = HarvestCatalog.withRecords([a, b, c]);
      final results = cat.query(const HarvestAvailabilityQuery());
      expect(results.map((r) => r.ingredientId).toList(), ["a", "m", "z"]);
    });
    test("query applies combined filters", () {
      final autumnRareCave = HarvestRecord.validated(
        ingredientId: "x",
        rarity: RarityLevel.rare,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
        habitats: [HabitatRef.validated(habitatId: "cave")],
      );
      final autumnCommonCave = HarvestRecord.validated(
        ingredientId: "y",
        rarity: RarityLevel.common,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
        habitats: [HabitatRef.validated(habitatId: "cave")],
      );
      final autumnRareForest = HarvestRecord.validated(
        ingredientId: "w",
        rarity: RarityLevel.rare,
        seasonality: [SeasonWindow.validated(season: Season.autumn)],
        habitats: [HabitatRef.validated(habitatId: "forest")],
      );
      final cat = HarvestCatalog.withRecords([
        autumnRareCave,
        autumnCommonCave,
        autumnRareForest,
      ]);
      const q = HarvestAvailabilityQuery(
        minRarity: RarityLevel.rare,
        season: Season.autumn,
        habitatId: "cave",
      );
      expect(cat.query(q).map((r) => r.ingredientId).toList(), ["x"]);
    });
  });
}
