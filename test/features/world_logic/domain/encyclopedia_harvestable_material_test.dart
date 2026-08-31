// Sprint 111.19 - Harvestable Materials and Consequences.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_harvestable_material.dart";

void main() {
  group("MaterialQualityGrade", () {
    test("has a defined quality ladder with labels", () {
      expect(MaterialQualityGrade.values.length, greaterThanOrEqualTo(4));
      for (final q in MaterialQualityGrade.values) {
        expect(q.label, isNotEmpty);
      }
    });
    test("weights are strictly increasing", () {
      final weights = MaterialQualityGrade.values.map((q) => q.weight).toList();
      for (int i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("LegalityStatus", () {
    test("has a defined legality ladder with labels", () {
      expect(LegalityStatus.values.length, greaterThanOrEqualTo(3));
      for (final s in LegalityStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
    test("weights are strictly increasing", () {
      final weights = LegalityStatus.values.map((s) => s.weight).toList();
      for (int i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("MaterialHarvestMethod", () {
    test("rejects empty method id", () {
      expect(
        () => MaterialHarvestMethod.validated(
          methodId: "  ",
          description: "Mine",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => MaterialHarvestMethod.validated(methodId: "m1", description: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty tools when provided", () {
      expect(
        () => MaterialHarvestMethod.validated(
          methodId: "m1",
          description: "Mine",
          tools: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps method fields with tools", () {
      final m = MaterialHarvestMethod.validated(
        methodId: "deep_mine",
        description: "Mine deep veins",
        tools: "Iron pickaxe",
      );
      expect(m.methodId, "deep_mine");
      expect(m.description, "Mine deep veins");
      expect(m.tools, "Iron pickaxe");
    });
    test("accepts method without tools", () {
      final m = MaterialHarvestMethod.validated(
        methodId: "gather",
        description: "Gather by hand",
      );
      expect(m.methodId, "gather");
      expect(m.tools, isNull);
    });
  });

  group("MaterialQualityProfile", () {
    test("rejects empty notes when provided", () {
      expect(
        () => MaterialQualityProfile.validated(
          grade: MaterialQualityGrade.fine,
          notes: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps grade and optional notes", () {
      final q = MaterialQualityProfile.validated(
        grade: MaterialQualityGrade.pristine,
        notes: "Only from deep veins",
      );
      expect(q.grade, MaterialQualityGrade.pristine);
      expect(q.notes, "Only from deep veins");
    });
    test("accepts grade without notes", () {
      final q = MaterialQualityProfile.validated(
        grade: MaterialQualityGrade.standard,
      );
      expect(q.grade, MaterialQualityGrade.standard);
      expect(q.notes, isNull);
    });
  });

  group("MaterialUse", () {
    test("rejects empty use id", () {
      expect(
        () => MaterialUse.validated(useId: " ", purpose: "Forge"),
        throwsArgumentError,
      );
    });
    test("rejects empty purpose", () {
      expect(
        () => MaterialUse.validated(useId: "u1", purpose: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty note when provided", () {
      expect(
        () => MaterialUse.validated(useId: "u1", purpose: "Forge", note: " "),
        throwsArgumentError,
      );
    });
    test("keeps use fields", () {
      final u = MaterialUse.validated(
        useId: "blade",
        purpose: "Blade forging",
        note: "Needs high heat",
      );
      expect(u.useId, "blade");
      expect(u.purpose, "Blade forging");
      expect(u.note, "Needs high heat");
    });
  });

  group("MaterialHazard", () {
    test("rejects empty hazard id", () {
      expect(
        () => MaterialHazard.validated(hazardId: " ", description: "Toxic"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => MaterialHazard.validated(hazardId: "h1", description: " "),
        throwsArgumentError,
      );
    });
    test("rejects severity out of range 1..5", () {
      expect(
        () => MaterialHazard.validated(
          hazardId: "h1",
          description: "T",
          severity: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => MaterialHazard.validated(
          hazardId: "h1",
          description: "T",
          severity: 6,
        ),
        throwsArgumentError,
      );
    });
    test("keeps hazard fields", () {
      final h = MaterialHazard.validated(
        hazardId: "toxic_dust",
        description: "Inhaling dust",
        severity: 4,
      );
      expect(h.hazardId, "toxic_dust");
      expect(h.description, "Inhaling dust");
      expect(h.severity, 4);
    });
    test("accepts hazard without severity", () {
      final h = MaterialHazard.validated(
        hazardId: "sharp",
        description: "Sharp edges",
      );
      expect(h.severity, isNull);
    });
  });

  group("LegalityProfile", () {
    test("rejects empty jurisdiction when provided", () {
      expect(
        () => LegalityProfile.validated(
          status: LegalityStatus.restricted,
          jurisdiction: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps status and optional jurisdiction", () {
      final l = LegalityProfile.validated(
        status: LegalityStatus.contraband,
        jurisdiction: "Northern Reach",
      );
      expect(l.status, LegalityStatus.contraband);
      expect(l.jurisdiction, "Northern Reach");
    });
    test("accepts status without jurisdiction", () {
      final l = LegalityProfile.validated(status: LegalityStatus.legal);
      expect(l.status, LegalityStatus.legal);
      expect(l.jurisdiction, isNull);
    });
  });

  group("EcologicalImpact", () {
    test("has a severity enum with labels", () {
      expect(EcologicalImpactSeverity.values.length, greaterThanOrEqualTo(3));
      for (final s in EcologicalImpactSeverity.values) {
        expect(s.label, isNotEmpty);
      }
    });
    test("rejects empty impact id", () {
      expect(
        () => EcologicalImpact.validated(
          impactId: " ",
          description: "Deforestation",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => EcologicalImpact.validated(impactId: "e1", description: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty mitigation when provided", () {
      expect(
        () => EcologicalImpact.validated(
          impactId: "e1",
          description: "D",
          mitigation: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps impact fields", () {
      final i = EcologicalImpact.validated(
        impactId: "deforest",
        description: "Clears canopy",
        severity: EcologicalImpactSeverity.severe,
        mitigation: "Replant one per tree",
      );
      expect(i.impactId, "deforest");
      expect(i.description, "Clears canopy");
      expect(i.severity, EcologicalImpactSeverity.severe);
      expect(i.mitigation, "Replant one per tree");
    });
    test("accepts impact without severity or mitigation", () {
      final i = EcologicalImpact.validated(
        impactId: "noise",
        description: "Disturbs nesting",
      );
      expect(i.impactId, "noise");
      expect(i.severity, isNull);
      expect(i.mitigation, isNull);
    });
  });

  group("HarvestableMaterial validated", () {
    test("rejects empty material id", () {
      expect(
        () => HarvestableMaterial.validated(materialId: " ", name: "Iron"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => HarvestableMaterial.validated(materialId: "iron", name: " "),
        throwsArgumentError,
      );
    });
    test("stores basic fields", () {
      final m = HarvestableMaterial.validated(materialId: "iron", name: "Iron");
      expect(m.materialId, "iron");
      expect(m.name, "Iron");
      expect(m.sourceId, isNull);
      expect(m.methods, isEmpty);
      expect(m.qualities, isEmpty);
      expect(m.uses, isEmpty);
      expect(m.hazards, isEmpty);
      expect(m.legality, isNull);
      expect(m.impacts, isEmpty);
      expect(m.notes, isNull);
    });
    test("stores optional source and notes", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        sourceId: "ore_vein",
        notes: "Found near rift",
      );
      expect(m.sourceId, "ore_vein");
      expect(m.notes, "Found near rift");
    });
    test("rejects empty sourceId when provided", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          sourceId: " ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty notes when provided", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          notes: " ",
        ),
        throwsArgumentError,
      );
    });
  });

  group("HarvestableMaterial duplicate guards", () {
    test("rejects duplicate method ids", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          methods: [
            MaterialHarvestMethod.validated(methodId: "m1", description: "A"),
            MaterialHarvestMethod.validated(methodId: "m1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate quality grades", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          qualities: [
            MaterialQualityProfile.validated(grade: MaterialQualityGrade.fine),
            MaterialQualityProfile.validated(grade: MaterialQualityGrade.fine),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate use ids", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          uses: [
            MaterialUse.validated(useId: "u1", purpose: "A"),
            MaterialUse.validated(useId: "u1", purpose: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate hazard ids", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          hazards: [
            MaterialHazard.validated(hazardId: "h1", description: "A"),
            MaterialHazard.validated(hazardId: "h1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate impact ids", () {
      expect(
        () => HarvestableMaterial.validated(
          materialId: "iron",
          name: "Iron",
          impacts: [
            EcologicalImpact.validated(impactId: "e1", description: "A"),
            EcologicalImpact.validated(impactId: "e1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("HarvestableMaterial behavior", () {
    test("hasMethod finds declared method", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        methods: [
          MaterialHarvestMethod.validated(
            methodId: "deep_mine",
            description: "M",
          ),
        ],
      );
      expect(m.hasMethod("deep_mine"), isTrue);
      expect(m.hasMethod("gather"), isFalse);
    });
    test("hasUse finds declared use", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        uses: [MaterialUse.validated(useId: "blade", purpose: "Forge")],
      );
      expect(m.hasUse("blade"), isTrue);
      expect(m.hasUse("armor"), isFalse);
    });
    test("hasHazard finds declared hazard", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        hazards: [
          MaterialHazard.validated(hazardId: "sharp", description: "S"),
        ],
      );
      expect(m.hasHazard("sharp"), isTrue);
      expect(m.hasHazard("toxic"), isFalse);
    });
    test("bestQuality returns highest declared grade or null", () {
      final none = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
      );
      expect(none.bestQuality, isNull);
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        qualities: [
          MaterialQualityProfile.validated(
            grade: MaterialQualityGrade.standard,
          ),
          MaterialQualityProfile.validated(
            grade: MaterialQualityGrade.pristine,
          ),
        ],
      );
      expect(m.bestQuality, MaterialQualityGrade.pristine);
    });
    test("isAtLeastQuality uses best declared quality", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        qualities: [
          MaterialQualityProfile.validated(grade: MaterialQualityGrade.fine),
        ],
      );
      expect(m.isAtLeastQuality(MaterialQualityGrade.crude), isTrue);
      expect(m.isAtLeastQuality(MaterialQualityGrade.fine), isTrue);
      expect(m.isAtLeastQuality(MaterialQualityGrade.pristine), isFalse);
    });
    test("maxHazardSeverity returns highest severity or null", () {
      final none = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
      );
      expect(none.maxHazardSeverity, isNull);
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        hazards: [
          MaterialHazard.validated(
            hazardId: "h1",
            description: "A",
            severity: 2,
          ),
          MaterialHazard.validated(
            hazardId: "h2",
            description: "B",
            severity: 4,
          ),
        ],
      );
      expect(m.maxHazardSeverity, 4);
    });
    test("hasLegalityStatus matches status", () {
      final m = HarvestableMaterial.validated(
        materialId: "iron",
        name: "Iron",
        legality: LegalityProfile.validated(status: LegalityStatus.restricted),
      );
      expect(m.hasLegalityStatus(LegalityStatus.restricted), isTrue);
      expect(m.hasLegalityStatus(LegalityStatus.legal), isFalse);
    });
  });

  group("HarvestableMaterialQuery", () {
    test("matches all records with no filters", () {
      const q = HarvestableMaterialQuery();
      final m = HarvestableMaterial.validated(materialId: "iron", name: "Iron");
      expect(q.matches(m), isTrue);
    });
    test("filters by minimum quality", () {
      const q = HarvestableMaterialQuery(minQuality: MaterialQualityGrade.fine);
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "a",
            name: "A",
            qualities: [
              MaterialQualityProfile.validated(
                grade: MaterialQualityGrade.crude,
              ),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "b",
            name: "B",
            qualities: [
              MaterialQualityProfile.validated(
                grade: MaterialQualityGrade.fine,
              ),
            ],
          ),
        ),
        isTrue,
      );
    });
    test("filters by legality", () {
      const q = HarvestableMaterialQuery(legality: LegalityStatus.legal);
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "a",
            name: "A",
            legality: LegalityProfile.validated(
              status: LegalityStatus.contraband,
            ),
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "b",
            name: "B",
            legality: LegalityProfile.validated(status: LegalityStatus.legal),
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(HarvestableMaterial.validated(materialId: "c", name: "C")),
        isFalse,
      );
    });
    test("filters by minimum hazard severity", () {
      const q = HarvestableMaterialQuery(minHazardSeverity: 3);
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "a",
            name: "A",
            hazards: [
              MaterialHazard.validated(
                hazardId: "h1",
                description: "X",
                severity: 2,
              ),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "b",
            name: "B",
            hazards: [
              MaterialHazard.validated(
                hazardId: "h1",
                description: "X",
                severity: 3,
              ),
            ],
          ),
        ),
        isTrue,
      );
    });
    test("filters by use id", () {
      const q = HarvestableMaterialQuery(useId: "blade");
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "a",
            name: "A",
            uses: [MaterialUse.validated(useId: "armor", purpose: "Armor")],
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(
          HarvestableMaterial.validated(
            materialId: "b",
            name: "B",
            uses: [MaterialUse.validated(useId: "blade", purpose: "Blade")],
          ),
        ),
        isTrue,
      );
    });
    test("describe returns non-empty explanation", () {
      const q = HarvestableMaterialQuery(
        minQuality: MaterialQualityGrade.fine,
        legality: LegalityStatus.restricted,
        minHazardSeverity: 2,
        useId: "blade",
      );
      expect(q.describe(), isNotEmpty);
    });
  });

  group("HarvestableMaterialCatalog", () {
    test("empty catalog has no records", () {
      final c = HarvestableMaterialCatalog.empty();
      expect(c.length, 0);
      expect(c.recordFor("iron"), isNull);
    });
    test("withRecords guards duplicate material ids", () {
      final m = HarvestableMaterial.validated(materialId: "iron", name: "Iron");
      final c = HarvestableMaterialCatalog.withRecords([m]);
      expect(c.length, 1);
      expect(c.recordFor("iron"), same(m));
      expect(
        () => HarvestableMaterialCatalog.withRecords([m, m]),
        throwsArgumentError,
      );
    });
    test("query returns sorted by material id", () {
      final z = HarvestableMaterial.validated(materialId: "zinc", name: "Zinc");
      final a = HarvestableMaterial.validated(
        materialId: "adamant",
        name: "Adamant",
      );
      final m = HarvestableMaterial.validated(
        materialId: "mythril",
        name: "Mythril",
      );
      final cat = HarvestableMaterialCatalog.withRecords([z, a, m]);
      final results = cat.query(const HarvestableMaterialQuery());
      expect(results.map((r) => r.materialId).toList(), [
        "adamant",
        "mythril",
        "zinc",
      ]);
    });
    test("query applies combined filters", () {
      final fineLegal = HarvestableMaterial.validated(
        materialId: "x",
        name: "X",
        qualities: [
          MaterialQualityProfile.validated(grade: MaterialQualityGrade.fine),
        ],
        legality: LegalityProfile.validated(status: LegalityStatus.legal),
        uses: [MaterialUse.validated(useId: "blade", purpose: "Blade")],
      );
      final crudeLegal = HarvestableMaterial.validated(
        materialId: "y",
        name: "Y",
        qualities: [
          MaterialQualityProfile.validated(grade: MaterialQualityGrade.crude),
        ],
        legality: LegalityProfile.validated(status: LegalityStatus.legal),
        uses: [MaterialUse.validated(useId: "blade", purpose: "Blade")],
      );
      final fineContraband = HarvestableMaterial.validated(
        materialId: "w",
        name: "W",
        qualities: [
          MaterialQualityProfile.validated(grade: MaterialQualityGrade.fine),
        ],
        legality: LegalityProfile.validated(status: LegalityStatus.contraband),
        uses: [MaterialUse.validated(useId: "blade", purpose: "Blade")],
      );
      final cat = HarvestableMaterialCatalog.withRecords([
        fineLegal,
        crudeLegal,
        fineContraband,
      ]);
      const q = HarvestableMaterialQuery(
        minQuality: MaterialQualityGrade.fine,
        legality: LegalityStatus.legal,
        useId: "blade",
      );
      expect(cat.query(q).map((r) => r.materialId).toList(), ["x"]);
    });
  });
}
