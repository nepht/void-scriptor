// Sprint 111.24 - Myth & Legend Registry.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_myth.dart";

MythVariant _variant(String id, {String? name, String? region}) =>
    MythVariant.validated(
      variantId: id,
      name: name ?? "Variant $id",
      region: region,
    );

MythMotif _motif(String id, {String? name}) =>
    MythMotif.validated(motifId: id, name: name ?? "Motif $id");

MythFigure _figure(
  String id, {
  String? name,
  FigureRole role = FigureRole.hero,
}) =>
    MythFigure.validated(figureId: id, name: name ?? "Figure $id", role: role);

MythLocationReference _location(
  String id, {
  String? placeName,
  bool sacred = false,
}) => MythLocationReference.validated(
  locationId: id,
  placeName: placeName ?? "Place $id",
  sacred: sacred,
);

BelievingGroup _group(
  String id, {
  String? name,
  GroupStance stance = GroupStance.devout,
}) => BelievingGroup.validated(
  groupId: id,
  name: name ?? "Group $id",
  stance: stance,
);

MythRecord _record({
  String mythId = "m1",
  String title = "The Drowned Star",
  List<MythVariant> variants = const [],
  List<MythMotif> motifs = const [],
  List<MythFigure> figures = const [],
  List<MythLocationReference> locations = const [],
  List<BelievingGroup> believingGroups = const [],
  MythCategory? category,
}) => MythRecord.validated(
  mythId: mythId,
  title: title,
  variants: variants,
  motifs: motifs,
  figures: figures,
  locations: locations,
  believingGroups: believingGroups,
  category: category,
);

void main() {
  group("MythCategory", () {
    test("has a defined set of categories with labels", () {
      expect(MythCategory.values.length, greaterThanOrEqualTo(6));
      for (final c in MythCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });

  group("FigureRole", () {
    test("has a defined set of roles with labels", () {
      expect(FigureRole.values.length, greaterThanOrEqualTo(6));
      for (final r in FigureRole.values) {
        expect(r.label, isNotEmpty);
      }
    });
  });

  group("GroupStance", () {
    test("has a defined set of stances with labels", () {
      expect(GroupStance.values.length, greaterThanOrEqualTo(4));
      for (final s in GroupStance.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  group("MythVariant", () {
    test("trims required fields", () {
      final v = MythVariant.validated(
        variantId: " v1 ",
        name: " Coastal Version ",
      );
      expect(v.variantId, "v1");
      expect(v.name, "Coastal Version");
      expect(v.region, isNull);
    });

    test("rejects blank variantId", () {
      expect(
        () => MythVariant.validated(variantId: "  ", name: "X"),
        throwsArgumentError,
      );
    });

    test("rejects blank name", () {
      expect(
        () => MythVariant.validated(variantId: "v1", name: "   "),
        throwsArgumentError,
      );
    });

    test("optional fields reject blank and accept trimmed values", () {
      expect(
        () => MythVariant.validated(variantId: "v1", name: "V", region: " "),
        throwsArgumentError,
      );
      final v = MythVariant.validated(
        variantId: "v1",
        name: "V",
        region: " North ",
        culture: " Reed Folk ",
        note: " sung at tide ",
      );
      expect(v.region, "North");
      expect(v.culture, "Reed Folk");
      expect(v.note, "sung at tide");
    });
  });

  group("MythMotif", () {
    test("trims fields and keeps description optional", () {
      final m = MythMotif.validated(motifId: " mt1 ", name: " dying god ");
      expect(m.motifId, "mt1");
      expect(m.name, "dying god");
      expect(m.description, isNull);
    });

    test("rejects blank motifId or name", () {
      expect(
        () => MythMotif.validated(motifId: "", name: "X"),
        throwsArgumentError,
      );
      expect(
        () => MythMotif.validated(motifId: "m", name: " "),
        throwsArgumentError,
      );
    });

    test("rejects blank description when provided", () {
      expect(
        () => MythMotif.validated(motifId: "m", name: "X", description: "   "),
        throwsArgumentError,
      );
    });
  });

  group("MythFigure", () {
    test("defaults role to other", () {
      final f = MythFigure.validated(figureId: "f1", name: "Ash Widow");
      expect(f.role, FigureRole.other);
      expect(f.roleLabel, isNotEmpty);
    });

    test("keeps explicit role and trims fields", () {
      final f = MythFigure.validated(
        figureId: " f1 ",
        name: " Ash Widow ",
        role: FigureRole.trickster,
        description: " steals the tide ",
      );
      expect(f.figureId, "f1");
      expect(f.name, "Ash Widow");
      expect(f.role, FigureRole.trickster);
      expect(f.description, "steals the tide");
    });

    test("rejects blank figureId or name", () {
      expect(
        () => MythFigure.validated(figureId: " ", name: "X"),
        throwsArgumentError,
      );
      expect(
        () => MythFigure.validated(figureId: "f", name: ""),
        throwsArgumentError,
      );
    });
  });

  group("MythLocationReference", () {
    test("trims fields and defaults sacred to false", () {
      final l = MythLocationReference.validated(
        locationId: " l1 ",
        placeName: " Salt Hollow ",
      );
      expect(l.locationId, "l1");
      expect(l.placeName, "Salt Hollow");
      expect(l.sacred, isFalse);
    });

    test("accepts sacred flag and optional description", () {
      final l = MythLocationReference.validated(
        locationId: "l1",
        placeName: "Salt Hollow",
        sacred: true,
        description: " where the star fell ",
      );
      expect(l.sacred, isTrue);
      expect(l.description, "where the star fell");
    });

    test("rejects blank locationId or placeName", () {
      expect(
        () => MythLocationReference.validated(locationId: "", placeName: "X"),
        throwsArgumentError,
      );
      expect(
        () => MythLocationReference.validated(locationId: "l", placeName: " "),
        throwsArgumentError,
      );
    });
  });

  group("BelievingGroup", () {
    test("trims fields and keeps explicit stance", () {
      final g = BelievingGroup.validated(
        groupId: " g1 ",
        name: " Tidekeepers ",
        stance: GroupStance.hostile,
      );
      expect(g.groupId, "g1");
      expect(g.name, "Tidekeepers");
      expect(g.stance, GroupStance.hostile);
      expect(g.region, isNull);
    });

    test("defaults stance to devout", () {
      final g = BelievingGroup.validated(groupId: "g1", name: "Keepers");
      expect(g.stance, GroupStance.devout);
    });

    test("rejects blank groupId or name", () {
      expect(
        () => BelievingGroup.validated(groupId: " ", name: "X"),
        throwsArgumentError,
      );
      expect(
        () => BelievingGroup.validated(groupId: "g", name: ""),
        throwsArgumentError,
      );
    });
  });

  group("MythRecord", () {
    test("rejects blank mythId and title", () {
      expect(
        () => MythRecord.validated(mythId: " ", title: "X"),
        throwsArgumentError,
      );
      expect(
        () => MythRecord.validated(mythId: "m1", title: "  "),
        throwsArgumentError,
      );
    });

    test("trims required fields and keeps optionals null", () {
      final r = MythRecord.validated(mythId: " m1 ", title: " Drowned Star ");
      expect(r.mythId, "m1");
      expect(r.title, "Drowned Star");
      expect(r.summary, isNull);
      expect(r.category, isNull);
      expect(r.eraLabel, isNull);
      expect(r.variantCount, 0);
      expect(r.motifCount, 0);
      expect(r.figureCount, 0);
      expect(r.locationCount, 0);
      expect(r.groupCount, 0);
    });

    test("rejects blank optional summary and eraLabel", () {
      expect(
        () => MythRecord.validated(mythId: "m1", title: "T", summary: "   "),
        throwsArgumentError,
      );
      expect(
        () => MythRecord.validated(mythId: "m1", title: "T", eraLabel: " "),
        throwsArgumentError,
      );
    });

    test("guards duplicate variant ids", () {
      expect(
        () => _record(
          variants: [
            _variant("v1"),
            _variant("v1", name: "Other"),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("guards duplicate motif ids", () {
      expect(
        () => _record(
          motifs: [
            _motif("k1"),
            _motif("k1", name: "Other"),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("guards duplicate figure ids", () {
      expect(
        () => _record(
          figures: [
            _figure("f1"),
            _figure("f1", name: "Other"),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("guards duplicate location ids", () {
      expect(
        () => _record(
          locations: [
            _location("l1"),
            _location("l1", placeName: "Other"),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("guards duplicate group ids", () {
      expect(
        () => _record(
          believingGroups: [
            _group("g1"),
            _group("g1", name: "Other"),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("collections are immutable", () {
      final r = _record(
        variants: [_variant("v1")],
        motifs: [_motif("k1")],
        figures: [_figure("f1")],
        locations: [_location("l1")],
        believingGroups: [_group("g1")],
      );
      expect(() => r.variants.add(_variant("v2")), throwsUnsupportedError);
      expect(() => r.motifs.clear(), throwsUnsupportedError);
      expect(() => r.figures.removeLast(), throwsUnsupportedError);
      expect(() => r.locations.add(_location("l2")), throwsUnsupportedError);
      expect(() => r.believingGroups.add(_group("g2")), throwsUnsupportedError);
    });

    test("membership helpers by id", () {
      final r = _record(
        variants: [_variant("v1")],
        motifs: [_motif("k1")],
        figures: [_figure("f1")],
        locations: [_location("l1")],
        believingGroups: [_group("g1")],
      );
      expect(r.hasVariant("v1"), isTrue);
      expect(r.hasMotif("k1"), isTrue);
      expect(r.hasFigure("f1"), isTrue);
      expect(r.hasLocation("l1"), isTrue);
      expect(r.hasGroup("g1"), isTrue);
      expect(r.hasMotif("nope"), isFalse);
    });

    test("id lists are sorted copies", () {
      final r = _record(
        motifs: [_motif("k9"), _motif("k2"), _motif("k5")],
        figures: [_figure("f7"), _figure("f3")],
      );
      expect(r.motifIds, ["k2", "k5", "k9"]);
      expect(r.figureIds, ["f3", "f7"]);
      expect(() => r.motifIds.add("k1"), throwsUnsupportedError);
    });

    test("figuresWithRole filters deterministically", () {
      final r = _record(
        figures: [
          _figure("f2", role: FigureRole.trickster),
          _figure("f1", role: FigureRole.trickster),
          _figure("f3", role: FigureRole.hero),
        ],
      );
      expect(r.figuresWithRole(FigureRole.trickster).map((f) => f.figureId), [
        "f1",
        "f2",
      ]);
      expect(r.figuresWithRole(FigureRole.deity), isEmpty);
    });

    test("groupsHolding filters deterministically", () {
      final r = _record(
        believingGroups: [
          _group("g2", stance: GroupStance.skeptical),
          _group("g1", stance: GroupStance.skeptical),
          _group("g3", stance: GroupStance.devout),
        ],
      );
      expect(r.groupsHolding(GroupStance.skeptical).map((g) => g.groupId), [
        "g1",
        "g2",
      ]);
    });

    test("isOfCategory and hasSacredLocation", () {
      final r = _record(
        category: MythCategory.flood,
        locations: [_location("l1"), _location("l2", sacred: true)],
      );
      expect(r.isOfCategory(MythCategory.flood), isTrue);
      expect(r.isOfCategory(MythCategory.creation), isFalse);
      expect(r.hasSacredLocation, isTrue);
      expect(_record(locations: [_location("l1")]).hasSacredLocation, isFalse);
    });
  });

  group("MythQuery", () {
    test("empty query matches everything", () {
      expect(const MythQuery().matches(_record(mythId: "a")), isTrue);
    });

    test("category filter", () {
      const q = MythQuery(category: MythCategory.flood);
      expect(q.matches(_record(category: MythCategory.flood)), isTrue);
      expect(q.matches(_record(category: MythCategory.creation)), isFalse);
      expect(q.matches(_record()), isFalse);
    });

    test("motif figure location group stance filters", () {
      final r = _record(
        motifs: [_motif("k1")],
        figures: [_figure("f1")],
        locations: [_location("l1")],
        believingGroups: [_group("g1", stance: GroupStance.hostile)],
      );
      expect(const MythQuery(motifId: "k1").matches(r), isTrue);
      expect(const MythQuery(motifId: "zz").matches(r), isFalse);
      expect(const MythQuery(figureId: "f1").matches(r), isTrue);
      expect(const MythQuery(locationId: "l1").matches(r), isTrue);
      expect(const MythQuery(groupId: "g1").matches(r), isTrue);
      expect(const MythQuery(stance: GroupStance.hostile).matches(r), isTrue);
      expect(const MythQuery(stance: GroupStance.devout).matches(r), isFalse);
    });

    test("describe names active filters only", () {
      expect(const MythQuery().describe(), contains("no filters"));
      final d = const MythQuery(
        category: MythCategory.trickster,
        motifId: "k1",
      ).describe();
      expect(d, contains("category=trickster"));
      expect(d, contains("motif=k1"));
      expect(d, isNot(contains("figure=")));
    });
  });

  group("MythCatalog", () {
    test("empty catalog", () {
      final c = MythCatalog.empty();
      expect(c.isEmpty, isTrue);
      expect(c.length, 0);
      expect(c.records, isEmpty);
      expect(c.mostCommonMotifId(), isNull);
    });

    test("withRecords guards duplicate mythId", () {
      expect(
        () => MythCatalog.withRecords([
          _record(mythId: "dup"),
          _record(mythId: "dup", title: "Other"),
        ]),
        throwsArgumentError,
      );
    });

    test("records are sorted by mythId and immutable", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m9"),
        _record(mythId: "m1"),
      ]);
      expect(c.mythIds, ["m1", "m9"]);
      expect(
        () => c.records.add(_record(mythId: "m0")),
        throwsUnsupportedError,
      );
    });

    test("titleFor lookup", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m1", title: "Drowned Star"),
      ]);
      expect(c.titleFor("m1"), "Drowned Star");
      expect(c.titleFor("nope"), isNull);
    });

    test("reverse indexes are deterministic", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m2", motifs: [_motif("k1")]),
        _record(mythId: "m1", motifs: [_motif("k2"), _motif("k1")]),
      ]);
      expect(c.mythsFeaturingMotif("k1"), ["m1", "m2"]);
      expect(c.mythsFeaturingMotif("k2"), ["m1"]);
      expect(c.mythsFeaturingMotif("zz"), isEmpty);
    });

    test("figure location and group reverse lookups", () {
      final c = MythCatalog.withRecords([
        _record(
          mythId: "b",
          figures: [_figure("f1")],
          locations: [_location("l1")],
          believingGroups: [_group("g1")],
        ),
        _record(
          mythId: "a",
          figures: [_figure("f1", name: "Same")],
        ),
      ]);
      expect(c.mythsFeaturingFigure("f1"), ["a", "b"]);
      expect(c.mythsTiedToLocation("l1"), ["b"]);
      expect(c.mythsHeldByGroup("g1"), ["b"]);
      expect(c.mythsHeldByGroup("zz"), isEmpty);
    });

    test("motifFrequency counts across records", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m1", motifs: [_motif("k1"), _motif("k2")]),
        _record(mythId: "m2", motifs: [_motif("k1")]),
      ]);
      final f = c.motifFrequency();
      expect(f["k1"], 2);
      expect(f["k2"], 1);
      expect(() => f["k3"] = 9, throwsUnsupportedError);
    });

    test("mostCommonMotifId ties break on motifId ascending", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m1", motifs: [_motif("k9"), _motif("k2")]),
        _record(mythId: "m2", motifs: [_motif("k9"), _motif("k2")]),
      ]);
      expect(c.mostCommonMotifId(), "k2");
    });

    test("query returns sorted subset", () {
      final c = MythCatalog.withRecords([
        _record(mythId: "m3", motifs: [_motif("k1")]),
        _record(mythId: "m1", motifs: [_motif("k1")]),
        _record(mythId: "m2"),
      ]);
      const q = MythQuery(motifId: "k1");
      expect(c.query(q).map((r) => r.mythId), ["m1", "m3"]);
      expect(c.query(const MythQuery()).length, 3);
    });

    test("sacredLocationIndex lists sacred refs deterministically", () {
      final c = MythCatalog.withRecords([
        _record(
          mythId: "m2",
          locations: [_location("l5", sacred: true), _location("l6")],
        ),
        _record(mythId: "m1", locations: [_location("l1", sacred: true)]),
      ]);
      final idx = c.sacredLocations();
      expect(idx.map((e) => "${e.mythId}:${e.locationId}"), ["m1:l1", "m2:l5"]);
    });
  });
}
