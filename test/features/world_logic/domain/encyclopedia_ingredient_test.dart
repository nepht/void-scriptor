// Sprint 111.9 - Ingredient and Substance Catalog.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_ingredient.dart";

void main() {
  group("IngredientType", () {
    test("has a defined set of ingredient type categories", () {
      expect(IngredientType.values.length, greaterThanOrEqualTo(6));
      expect(IngredientType.flora, isA<IngredientType>());
      expect(IngredientType.fauna, isA<IngredientType>());
      expect(IngredientType.mineral, isA<IngredientType>());
      expect(IngredientType.zat, isA<IngredientType>());
      expect(IngredientType.synthetic, isA<IngredientType>());
      expect(IngredientType.other, isA<IngredientType>());
    });
    test("each type has a descriptive label", () {
      for (final t in IngredientType.values) {
        expect(t.label, isNotEmpty);
      }
    });
  });

  group("IngredientPart", () {
    test("rejects empty part id", () {
      expect(
        () => IngredientPart.validated(partId: "  ", name: "Root"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => IngredientPart.validated(partId: "root", name: ""),
        throwsArgumentError,
      );
    });
    test("keeps part id and name", () {
      final part = IngredientPart.validated(partId: "root", name: "Root");
      expect(part.partId, "root");
      expect(part.name, "Root");
    });
  });

  group("LocalVariant", () {
    test("rejects empty variant id", () {
      expect(
        () => LocalVariant.validated(
          variantId: " ",
          region: "N",
          description: "A",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty region", () {
      expect(
        () => LocalVariant.validated(
          variantId: "n",
          region: "",
          description: "A",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => LocalVariant.validated(
          variantId: "n",
          region: "N",
          description: "",
        ),
        throwsArgumentError,
      );
    });
    test("keeps variant fields", () {
      final v = LocalVariant.validated(
        variantId: "northern",
        region: "N",
        description: "D",
      );
      expect(v.variantId, "northern");
      expect(v.region, "N");
      expect(v.description, "D");
    });
  });

  group("IngredientAlias", () {
    test("rejects empty alias", () {
      expect(() => IngredientAlias.validated(alias: "  "), throwsArgumentError);
    });
    test("keeps alias without language", () {
      final a = IngredientAlias.validated(alias: "nightshade");
      expect(a.alias, "nightshade");
      expect(a.language, isNull);
    });
    test("keeps alias with language", () {
      final a = IngredientAlias.validated(
        alias: "umbrafolia",
        language: "Old Tongue",
      );
      expect(a.alias, "umbrafolia");
      expect(a.language, "Old Tongue");
    });
  });

  group("IngredientMediaLink", () {
    test("rejects empty media id", () {
      expect(
        () => IngredientMediaLink.validated(mediaId: "  ", caption: "Leaf"),
        throwsArgumentError,
      );
    });
    test("keeps media id and optional caption", () {
      final m = IngredientMediaLink.validated(mediaId: "m1", caption: "Leaf");
      expect(m.mediaId, "m1");
      expect(m.caption, "Leaf");
    });
    test("accepts media id without caption", () {
      final m = IngredientMediaLink.validated(mediaId: "m1");
      expect(m.mediaId, "m1");
      expect(m.caption, isNull);
    });
  });

  group("IngredientSourceLink", () {
    test("rejects empty source id", () {
      expect(
        () => IngredientSourceLink.validated(sourceId: "  "),
        throwsArgumentError,
      );
    });
    test("keeps source id and optional note", () {
      final s = IngredientSourceLink.validated(
        sourceId: "src:tome",
        note: "Ch12",
      );
      expect(s.sourceId, "src:tome");
      expect(s.note, "Ch12");
    });
    test("accepts source id without note", () {
      final s = IngredientSourceLink.validated(sourceId: "src:tome");
      expect(s.sourceId, "src:tome");
      expect(s.note, isNull);
    });
  });

  group("IngredientRecord validated", () {
    test("rejects empty ingredient id", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "  ",
          name: "X",
          type: IngredientType.flora,
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "x",
          name: "",
          type: IngredientType.flora,
        ),
        throwsArgumentError,
      );
    });
    test("stores basic fields", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "Void Bloom",
        type: IngredientType.flora,
      );
      expect(r.ingredientId, "vb");
      expect(r.name, "Void Bloom");
      expect(r.type, IngredientType.flora);
      expect(r.parts, isEmpty);
      expect(r.variants, isEmpty);
      expect(r.aliases, isEmpty);
      expect(r.mediaLinks, isEmpty);
      expect(r.sourceLinks, isEmpty);
    });
    test("stores optional parts", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "X",
        type: IngredientType.flora,
        parts: [IngredientPart.validated(partId: "petal", name: "Petal")],
      );
      expect(r.parts.length, 1);
    });
    test("stores optional variants", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "X",
        type: IngredientType.flora,
        variants: [
          LocalVariant.validated(
            variantId: "dv",
            region: "Deep Void",
            description: "Glows",
          ),
        ],
      );
      expect(r.variants.length, 1);
    });
    test("stores optional aliases", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "X",
        type: IngredientType.flora,
        aliases: [IngredientAlias.validated(alias: "umbrafolia")],
      );
      expect(r.aliases.length, 1);
    });
    test("stores optional media links", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "X",
        type: IngredientType.flora,
        mediaLinks: [
          IngredientMediaLink.validated(mediaId: "m1", caption: "Bloom"),
        ],
      );
      expect(r.mediaLinks.length, 1);
    });
    test("stores optional source links", () {
      final r = IngredientRecord.validated(
        ingredientId: "vb",
        name: "X",
        type: IngredientType.flora,
        sourceLinks: [IngredientSourceLink.validated(sourceId: "src:tome")],
      );
      expect(r.sourceLinks.length, 1);
    });

    test("rejects duplicate part ids", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "vb",
          name: "X",
          type: IngredientType.flora,
          parts: [
            IngredientPart.validated(partId: "root", name: "Root"),
            IngredientPart.validated(partId: "root", name: "Root"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate variant ids", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "vb",
          name: "X",
          type: IngredientType.flora,
          variants: [
            LocalVariant.validated(
              variantId: "n",
              region: "N",
              description: "A",
            ),
            LocalVariant.validated(
              variantId: "n",
              region: "N",
              description: "B",
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate alias values", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "vb",
          name: "X",
          type: IngredientType.flora,
          aliases: [
            IngredientAlias.validated(alias: "umbrafolia"),
            IngredientAlias.validated(alias: "umbrafolia"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate media ids", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "vb",
          name: "X",
          type: IngredientType.flora,
          mediaLinks: [
            IngredientMediaLink.validated(mediaId: "m1"),
            IngredientMediaLink.validated(mediaId: "m1"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate source ids", () {
      expect(
        () => IngredientRecord.validated(
          ingredientId: "vb",
          name: "X",
          type: IngredientType.flora,
          sourceLinks: [
            IngredientSourceLink.validated(sourceId: "src:tome"),
            IngredientSourceLink.validated(sourceId: "src:tome"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
