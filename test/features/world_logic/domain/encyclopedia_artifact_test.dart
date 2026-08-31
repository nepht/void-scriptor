// Sprint 111.20 - Artifact & Relic Registry.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_artifact.dart";

void main() {
  group("ArtifactType", () {
    test("has a defined set of types with labels", () {
      expect(ArtifactType.values.length, greaterThanOrEqualTo(6));
      for (final t in ArtifactType.values) {
        expect(t.label, isNotEmpty);
      }
    });
  });

  group("ArtifactCondition", () {
    test("has a defined condition ladder with labels", () {
      expect(ArtifactCondition.values.length, greaterThanOrEqualTo(5));
      for (final c in ArtifactCondition.values) {
        expect(c.label, isNotEmpty);
      }
    });
    test("weights are strictly increasing", () {
      final weights = ArtifactCondition.values.map((c) => c.weight).toList();
      for (int i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("ArtifactAuthenticity", () {
    test("has a defined authenticity ladder with labels", () {
      expect(ArtifactAuthenticity.values.length, greaterThanOrEqualTo(4));
      for (final a in ArtifactAuthenticity.values) {
        expect(a.label, isNotEmpty);
      }
    });
    test("weights are strictly increasing", () {
      final weights = ArtifactAuthenticity.values.map((a) => a.weight).toList();
      for (int i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("ArtifactCreator", () {
    test("rejects empty creator id", () {
      expect(
        () => ArtifactCreator.validated(creatorId: "  ", name: "Morgoth"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => ArtifactCreator.validated(creatorId: "c1", name: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty note when provided", () {
      expect(
        () => ArtifactCreator.validated(
          creatorId: "c1",
          name: "Morgoth",
          note: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps creator fields with note", () {
      final c = ArtifactCreator.validated(
        creatorId: "morgoth",
        name: "Morgoth the Smith",
        note: "First age dwarf-smith",
      );
      expect(c.creatorId, "morgoth");
      expect(c.name, "Morgoth the Smith");
      expect(c.note, "First age dwarf-smith");
    });
    test("accepts creator without note", () {
      final c = ArtifactCreator.validated(creatorId: "anon", name: "Unknown");
      expect(c.creatorId, "anon");
      expect(c.note, isNull);
    });
  });

  group("ArtifactOrigin", () {
    test("rejects empty origin id", () {
      expect(
        () => ArtifactOrigin.validated(
          originId: "  ",
          description: "Forged in fire",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => ArtifactOrigin.validated(originId: "o1", description: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty region when provided", () {
      expect(
        () => ArtifactOrigin.validated(
          originId: "o1",
          description: "Forged",
          region: " ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty culture when provided", () {
      expect(
        () => ArtifactOrigin.validated(
          originId: "o1",
          description: "Forged",
          culture: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps origin with all fields", () {
      final o = ArtifactOrigin.validated(
        originId: "forge_erebor",
        description: "Forged in the halls of Erebor",
        region: "Erebor",
        culture: "Dwarven",
      );
      expect(o.originId, "forge_erebor");
      expect(o.description, "Forged in the halls of Erebor");
      expect(o.region, "Erebor");
      expect(o.culture, "Dwarven");
    });
    test("accepts origin without optional fields", () {
      final o = ArtifactOrigin.validated(
        originId: "unknown",
        description: "Unknown origin",
      );
      expect(o.originId, "unknown");
      expect(o.region, isNull);
      expect(o.culture, isNull);
    });
  });

  group("MaterialComponent", () {
    test("rejects empty component id", () {
      expect(
        () => MaterialComponent.validated(componentId: "  ", name: "Iron"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => MaterialComponent.validated(componentId: "c1", name: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty quantity when provided", () {
      expect(
        () => MaterialComponent.validated(
          componentId: "c1",
          name: "Iron",
          quantity: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps material component with quantity", () {
      final m = MaterialComponent.validated(
        componentId: "mythril_ingot",
        name: "Mythril Ingot",
        quantity: "3 bars",
      );
      expect(m.componentId, "mythril_ingot");
      expect(m.name, "Mythril Ingot");
      expect(m.quantity, "3 bars");
    });
    test("accepts material component without quantity", () {
      final m = MaterialComponent.validated(componentId: "iron", name: "Iron");
      expect(m.componentId, "iron");
      expect(m.quantity, isNull);
    });
  });

  group("ComponentRef", () {
    test("rejects empty ref id", () {
      expect(
        () => ComponentRef.validated(refId: "  ", role: "Blade"),
        throwsArgumentError,
      );
    });
    test("rejects empty role", () {
      expect(
        () => ComponentRef.validated(refId: "r1", role: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty note when provided", () {
      expect(
        () => ComponentRef.validated(refId: "r1", role: "Blade", note: " "),
        throwsArgumentError,
      );
    });
    test("keeps component ref with note", () {
      final r = ComponentRef.validated(
        refId: "blade_01",
        role: "Main blade",
        note: "Tempered three times",
      );
      expect(r.refId, "blade_01");
      expect(r.role, "Main blade");
      expect(r.note, "Tempered three times");
    });
    test("accepts component ref without note", () {
      final r = ComponentRef.validated(refId: "hilt_01", role: "Hilt");
      expect(r.refId, "hilt_01");
      expect(r.note, isNull);
    });
  });

  group("ArtifactRecord", () {
    test("rejects empty artifact id", () {
      expect(
        () => ArtifactRecord.validated(artifactId: "  ", name: "Narsil"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => ArtifactRecord.validated(artifactId: "narsil", name: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty type name when provided", () {
      expect(
        () => ArtifactRecord.validated(
          artifactId: "narsil",
          name: "Narsil",
          typeName: " ",
        ),
        throwsArgumentError,
      );
    });
    test("guards duplicate creator ids", () {
      expect(
        () => ArtifactRecord.validated(
          artifactId: "narsil",
          name: "Narsil",
          creators: [
            ArtifactCreator.validated(creatorId: "c1", name: "A"),
            ArtifactCreator.validated(creatorId: "c1", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("guards duplicate origin ids", () {
      expect(
        () => ArtifactRecord.validated(
          artifactId: "narsil",
          name: "Narsil",
          origins: [
            ArtifactOrigin.validated(originId: "o1", description: "A"),
            ArtifactOrigin.validated(originId: "o1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("guards duplicate material component ids", () {
      expect(
        () => ArtifactRecord.validated(
          artifactId: "narsil",
          name: "Narsil",
          materials: [
            MaterialComponent.validated(componentId: "m1", name: "A"),
            MaterialComponent.validated(componentId: "m1", name: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("guards duplicate component ref ids", () {
      expect(
        () => ArtifactRecord.validated(
          artifactId: "narsil",
          name: "Narsil",
          components: [
            ComponentRef.validated(refId: "r1", role: "A"),
            ComponentRef.validated(refId: "r1", role: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("keeps artifact record with all fields", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        type: ArtifactType.weapon,
        typeName: "Sword",
        condition: ArtifactCondition.pristine,
        authenticity: ArtifactAuthenticity.authentic,
        creators: [
          ArtifactCreator.validated(creatorId: "telchar", name: "Telchar"),
        ],
        origins: [
          ArtifactOrigin.validated(
            originId: "nogrod",
            description: "Forged in Nogrod",
          ),
        ],
        materials: [
          MaterialComponent.validated(componentId: "steel", name: "Steel"),
        ],
        components: [ComponentRef.validated(refId: "blade", role: "Blade")],
        notes: "Sword of Elendil",
      );
      expect(a.artifactId, "narsil");
      expect(a.name, "Narsil");
      expect(a.type, ArtifactType.weapon);
      expect(a.typeName, "Sword");
      expect(a.condition, ArtifactCondition.pristine);
      expect(a.authenticity, ArtifactAuthenticity.authentic);
      expect(a.creators.length, 1);
      expect(a.origins.length, 1);
      expect(a.materials.length, 1);
      expect(a.components.length, 1);
      expect(a.notes, "Sword of Elendil");
    });
    test("accepts artifact record with minimal fields", () {
      final a = ArtifactRecord.validated(
        artifactId: "unknown_relic",
        name: "Unknown Relic",
      );
      expect(a.artifactId, "unknown_relic");
      expect(a.name, "Unknown Relic");
      expect(a.type, isNull);
      expect(a.condition, isNull);
      expect(a.authenticity, isNull);
      expect(a.creators, isEmpty);
      expect(a.origins, isEmpty);
      expect(a.materials, isEmpty);
      expect(a.components, isEmpty);
      expect(a.notes, isNull);
    });
    test("hasCreator finds declared creator", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        creators: [
          ArtifactCreator.validated(creatorId: "telchar", name: "Telchar"),
        ],
      );
      expect(a.hasCreator("telchar"), isTrue);
      expect(a.hasCreator("anon"), isFalse);
    });
    test("hasOrigin finds declared origin", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        origins: [
          ArtifactOrigin.validated(originId: "nogrod", description: "Nogrod"),
        ],
      );
      expect(a.hasOrigin("nogrod"), isTrue);
      expect(a.hasOrigin("erebor"), isFalse);
    });
    test("hasMaterial finds declared material", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        materials: [
          MaterialComponent.validated(componentId: "steel", name: "Steel"),
        ],
      );
      expect(a.hasMaterial("steel"), isTrue);
      expect(a.hasMaterial("mythril"), isFalse);
    });
    test("hasComponent finds declared component ref", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        components: [ComponentRef.validated(refId: "blade", role: "Blade")],
      );
      expect(a.hasComponent("blade"), isTrue);
      expect(a.hasComponent("hilt"), isFalse);
    });
    test("isAtLeastCondition uses condition weight", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        condition: ArtifactCondition.good,
      );
      expect(a.isAtLeastCondition(ArtifactCondition.pristine), isFalse);
      expect(a.isAtLeastCondition(ArtifactCondition.good), isTrue);
      expect(a.isAtLeastCondition(ArtifactCondition.worn), isTrue);
    });
    test("isAtLeastCondition returns false when condition is null", () {
      final a = ArtifactRecord.validated(artifactId: "narsil", name: "Narsil");
      expect(a.isAtLeastCondition(ArtifactCondition.pristine), isFalse);
    });
    test("hasAuthenticityStatus matches authenticity", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        authenticity: ArtifactAuthenticity.authentic,
      );
      expect(a.hasAuthenticityStatus(ArtifactAuthenticity.authentic), isTrue);
      expect(a.hasAuthenticityStatus(ArtifactAuthenticity.forged), isFalse);
    });
    test("hasAuthenticityStatus returns false when authenticity is null", () {
      final a = ArtifactRecord.validated(artifactId: "narsil", name: "Narsil");
      expect(a.hasAuthenticityStatus(ArtifactAuthenticity.authentic), isFalse);
    });
    test("isOfType matches declared type", () {
      final a = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        type: ArtifactType.weapon,
      );
      expect(a.isOfType(ArtifactType.weapon), isTrue);
      expect(a.isOfType(ArtifactType.armor), isFalse);
    });
    test("isOfType returns false when type is null", () {
      final a = ArtifactRecord.validated(artifactId: "narsil", name: "Narsil");
      expect(a.isOfType(ArtifactType.weapon), isFalse);
    });
  });

  group("ArtifactQuery", () {
    test("matches all records with no filters", () {
      const q = ArtifactQuery();
      final a = ArtifactRecord.validated(artifactId: "narsil", name: "Narsil");
      expect(q.matches(a), isTrue);
    });
    test("filters by type", () {
      const q = ArtifactQuery(type: ArtifactType.weapon);
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            type: ArtifactType.weapon,
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            type: ArtifactType.armor,
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(ArtifactRecord.validated(artifactId: "c", name: "C")),
        isFalse,
      );
    });
    test("filters by minimum condition", () {
      const q = ArtifactQuery(minCondition: ArtifactCondition.good);
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            condition: ArtifactCondition.pristine,
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            condition: ArtifactCondition.damaged,
          ),
        ),
        isFalse,
      );
    });
    test("filters by authenticity", () {
      const q = ArtifactQuery(authenticity: ArtifactAuthenticity.authentic);
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            authenticity: ArtifactAuthenticity.authentic,
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            authenticity: ArtifactAuthenticity.forged,
          ),
        ),
        isFalse,
      );
      expect(
        q.matches(ArtifactRecord.validated(artifactId: "c", name: "C")),
        isFalse,
      );
    });
    test("filters by creator id", () {
      const q = ArtifactQuery(creatorId: "telchar");
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            creators: [
              ArtifactCreator.validated(creatorId: "telchar", name: "Telchar"),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            creators: [
              ArtifactCreator.validated(creatorId: "anon", name: "Anon"),
            ],
          ),
        ),
        isFalse,
      );
    });
    test("filters by origin id", () {
      const q = ArtifactQuery(originId: "nogrod");
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            origins: [
              ArtifactOrigin.validated(
                originId: "nogrod",
                description: "Nogrod",
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            origins: [
              ArtifactOrigin.validated(
                originId: "erebor",
                description: "Erebor",
              ),
            ],
          ),
        ),
        isFalse,
      );
    });
    test("filters by material id", () {
      const q = ArtifactQuery(materialId: "steel");
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "a",
            name: "A",
            materials: [
              MaterialComponent.validated(componentId: "steel", name: "Steel"),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        q.matches(
          ArtifactRecord.validated(
            artifactId: "b",
            name: "B",
            materials: [
              MaterialComponent.validated(componentId: "iron", name: "Iron"),
            ],
          ),
        ),
        isFalse,
      );
    });
    test("describe returns non-empty explanation", () {
      const q = ArtifactQuery(
        type: ArtifactType.weapon,
        minCondition: ArtifactCondition.good,
        authenticity: ArtifactAuthenticity.authentic,
        creatorId: "telchar",
      );
      expect(q.describe(), isNotEmpty);
    });
  });

  group("ArtifactCatalog", () {
    test("empty catalog has no records", () {
      final c = ArtifactCatalog.empty();
      expect(c.length, 0);
      expect(c.recordFor("narsil"), isNull);
    });
    test("withRecords guards duplicate artifact ids", () {
      final a = ArtifactRecord.validated(artifactId: "narsil", name: "Narsil");
      final c = ArtifactCatalog.withRecords([a]);
      expect(c.length, 1);
      expect(c.recordFor("narsil"), same(a));
      expect(() => ArtifactCatalog.withRecords([a, a]), throwsArgumentError);
    });
    test("query returns sorted by artifact id", () {
      final z = ArtifactRecord.validated(artifactId: "zephyr", name: "Zephyr");
      final a = ArtifactRecord.validated(
        artifactId: "angrist",
        name: "Angrist",
      );
      final m = ArtifactRecord.validated(
        artifactId: "mithril_mail",
        name: "Mithril Mail",
      );
      final cat = ArtifactCatalog.withRecords([z, a, m]);
      final results = cat.query(const ArtifactQuery());
      expect(results.map((r) => r.artifactId).toList(), [
        "angrist",
        "mithril_mail",
        "zephyr",
      ]);
    });
    test("query applies combined filters", () {
      final weaponGood = ArtifactRecord.validated(
        artifactId: "narsil",
        name: "Narsil",
        type: ArtifactType.weapon,
        condition: ArtifactCondition.good,
        authenticity: ArtifactAuthenticity.authentic,
      );
      final armorDamaged = ArtifactRecord.validated(
        artifactId: "helm",
        name: "Helm",
        type: ArtifactType.armor,
        condition: ArtifactCondition.damaged,
        authenticity: ArtifactAuthenticity.authentic,
      );
      final weaponForged = ArtifactRecord.validated(
        artifactId: "fake_sword",
        name: "Fake Sword",
        type: ArtifactType.weapon,
        condition: ArtifactCondition.pristine,
        authenticity: ArtifactAuthenticity.forged,
      );
      final cat = ArtifactCatalog.withRecords([
        weaponGood,
        armorDamaged,
        weaponForged,
      ]);
      const q = ArtifactQuery(
        type: ArtifactType.weapon,
        authenticity: ArtifactAuthenticity.authentic,
      );
      expect(cat.query(q).map((r) => r.artifactId).toList(), ["narsil"]);
    });
  });
}
