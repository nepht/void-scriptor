import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/faction_diplomacy_core.dart";
import "package:void_scriptor/features/world_logic/domain/derived_result_provenance.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart";

void main() {
  group("FactionDiplomacyCore", () {
    test("FactionId is value-equal and distinct from raw strings", () {
      expect(const FactionId("alpha"), const FactionId("alpha"));
      expect(const FactionId("alpha") == const FactionId("beta"), isFalse);
    });

    test("FactionRelation rejects self-loop from == to", () {
      expect(
        () => FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("a"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 0),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("FactionRelation validated rejects tone outside [-1, 1]", () {
      expect(
        () => FactionRelation.validated(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 0),
          tone: 1.5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("FactionRelation validated accepts in-range tone", () {
      final r = FactionRelation.validated(
        id: "r1",
        from: const FactionId("a"),
        to: const FactionId("b"),
        kind: DiplomacyRelationKind.publicRival,
        validity: const ValidityRange(fromTick: 0),
        tone: -0.5,
      );
      expect(r.tone, -0.5);
    });

    test("Registry upsert replaces same id", () {
      final reg = FactionDiplomacyRegistry();
      reg.upsertRelation(
        FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 0),
        ),
      );
      reg.upsertRelation(
        FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicRival,
          validity: const ValidityRange(fromTick: 0),
        ),
      );
      expect(reg.relations.length, 1);
      expect(reg.relationById("r1")!.kind, DiplomacyRelationKind.publicRival);
    });

    test("Registry rejects overlapping same-kind relations same pair", () {
      final reg = FactionDiplomacyRegistry();
      reg.upsertRelation(
        FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 0, toTick: 100),
        ),
      );
      expect(
        () => reg.upsertRelation(
          FactionRelation(
            id: "r2",
            from: const FactionId("a"),
            to: const FactionId("b"),
            kind: DiplomacyRelationKind.publicAlly,
            validity: const ValidityRange(fromTick: 50, toTick: 200),
          ),
        ),
        throwsA(isA<FactionRelationOverlap>()),
      );
    });

    test("Registry allows non-overlapping same-kind pair", () {
      final reg = FactionDiplomacyRegistry();
      reg.upsertRelation(
        FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 0, toTick: 50),
        ),
      );
      reg.upsertRelation(
        FactionRelation(
          id: "r2",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.publicAlly,
          validity: const ValidityRange(fromTick: 100, toTick: 200),
        ),
      );
      expect(reg.relations.length, 2);
    });

    test("Registry rejects treaty where a == b", () {
      final reg = FactionDiplomacyRegistry();
      expect(
        () => reg.upsertTreaty(
          const FactionTreaty(
            id: "t1",
            a: FactionId("a"),
            b: FactionId("a"),
            terms: ["non-aggression"],
            validity: ValidityRange(fromTick: 0),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("Treaty conflict trade recorded and retrievable", () {
      final reg = FactionDiplomacyRegistry();
      reg.upsertTreaty(
        const FactionTreaty(
          id: "t1",
          a: FactionId("a"),
          b: FactionId("b"),
          terms: ["non-aggression"],
          validity: ValidityRange(fromTick: 0),
        ),
      );
      reg.upsertConflict(
        const FactionConflict(
          id: "c1",
          a: FactionId("a"),
          b: FactionId("c"),
          severity: 3,
          validity: ValidityRange(fromTick: 0),
        ),
      );
      reg.upsertTrade(
        const FactionTrade(
          id: "tr1",
          a: FactionId("a"),
          b: FactionId("b"),
          goods: {"grain": 100},
          validity: ValidityRange(fromTick: 0),
        ),
      );
      expect(reg.treatyById("t1")!.terms, ["non-aggression"]);
      expect(reg.conflictById("c1")!.severity, 3);
      expect(reg.tradeById("tr1")!.goods["grain"], 100);
      expect(reg.eventsForFaction(const FactionId("a")), 3);
    });

    test("attachProvenance writes ResultOrigin to the relation", () {
      final reg = FactionDiplomacyRegistry();
      reg.upsertRelation(
        FactionRelation(
          id: "r1",
          from: const FactionId("a"),
          to: const FactionId("b"),
          kind: DiplomacyRelationKind.secretAlliance,
          validity: const ValidityRange(fromTick: 0),
        ),
      );
      reg.attachProvenance(
        "r1",
        const ResultOrigin.manual(
          sourceRevision: "court.letter",
          generatedAtTick: 42,
        ),
      );
      final r = reg.relationById("r1")!;
      expect(r.provenance, isNotNull);
      expect(r.provenance!.sourceRevision, "court.letter");
    });

    test(
      "historyOf returns relations for a faction sorted by fromTick asc",
      () {
        final reg = FactionDiplomacyRegistry();
        reg.upsertRelation(
          FactionRelation(
            id: "r1",
            from: const FactionId("a"),
            to: const FactionId("b"),
            kind: DiplomacyRelationKind.publicAlly,
            validity: const ValidityRange(fromTick: 0, toTick: 50),
          ),
        );
        reg.upsertRelation(
          FactionRelation(
            id: "r2",
            from: const FactionId("c"),
            to: const FactionId("a"),
            kind: DiplomacyRelationKind.publicRival,
            validity: const ValidityRange(fromTick: 100, toTick: 200),
          ),
        );
        final h = reg.historyOf(const FactionId("a"));
        expect(h.length, 2);
        expect(h.first.validity.fromTick, 0);
        expect(h.last.validity.fromTick, 100);
      },
    );
  });
}
