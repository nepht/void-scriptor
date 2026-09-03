// Sprint 110.17 - Genealogy Relationship Rules.
//
// Domain-only genealogy relationship rules: parent_child, adoption,
// partnership, guardian, clan, with validity ranges per relation. No
// persistence, UI, wall clock, locale, or random input; calculations are
// deterministic and unit-based.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart";

void main() {
  group("parent_child", () {
    test("parent_child adalah hubungan terarah dari parent ke child", () {
      const relation = GenealogyRelation.parentChild(
        parentId: "p1",
        childId: "c1",
      );
      expect(relation.type, GenealogyRelationType.parentChild);
      expect(relation.fromId, "p1");
      expect(relation.toId, "c1");
      expect(relation.isBiological, isTrue);
    });

    test(
      "parent_child menolak siklus: child tidak bisa jadi parent dari parent",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
        );
        expect(
          () => registry.add(
            const GenealogyRelation.parentChild(parentId: "c1", childId: "p1"),
          ),
          throwsA(isA<GenealogyCycleDetected>()),
        );
      },
    );

    test("parent_child tidak bisa digabung adoption untuk node yang sama", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      expect(
        () => registry.add(
          const GenealogyRelation(
            type: GenealogyRelationType.adoption,
            fromId: "p1",
            toId: "c1",
          ),
        ),
        throwsA(isA<GenealogyRelationConflict>()),
      );
    });
  });

  group("adoption", () {
    test("adoption membuat hubungan non-biologis antara parent dan child", () {
      const relation = GenealogyRelation.adoption(
        parentId: "a1",
        childId: "c1",
      );
      expect(relation.type, GenealogyRelationType.adoption);
      expect(relation.isBiological, isFalse);
    });

    test(
      "adoption tidak bisa dimiliki child yang sudah punya adoption lain",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.adoption(parentId: "a1", childId: "c1"),
        );
        expect(
          () => registry.add(
            const GenealogyRelation.adoption(parentId: "a2", childId: "c1"),
          ),
          throwsA(isA<GenealogyRelationConflict>()),
        );
      },
    );
  });

  group("partnership", () {
    test("partnership adalah hubungan bidirectional", () {
      final relation = GenealogyRelation.partnership(
        leftId: "x1",
        rightId: "x2",
      );
      expect(relation.type, GenealogyRelationType.partnership);
      expect(relation.partnerIds, ["x1", "x2"]);
      expect(relation.isBiological, isFalse);
    });

    test("partnership tidak bisa self-loop", () {
      expect(
        () => GenealogyRelation.partnership(leftId: "x1", rightId: "x1"),
        throwsA(isA<GenealogyInvalidRelation>()),
      );
    });
  });

  group("guardian", () {
    test("guardian menghubungkan wali dengan anak di luar garis darah", () {
      const relation = GenealogyRelation.guardian(
        guardianId: "g1",
        wardId: "c1",
      );
      expect(relation.type, GenealogyRelationType.guardian);
      expect(relation.isBiological, isFalse);
    });

    test(
      "guardian bisa coexist dengan parent_child biologis (tambahan wali)",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
        );
        registry.add(
          const GenealogyRelation.guardian(guardianId: "g1", wardId: "c1"),
        );
        expect(registry.relationsOf("c1"), hasLength(2));
      },
    );
  });

  group("clan", () {
    test("clan membership menambahkan anggota ke klan yang sama", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation(
          type: GenealogyRelationType.clan,
          fromId: "k1",
          toId: "n1",
        ),
      );
      registry.add(
        const GenealogyRelation(
          type: GenealogyRelationType.clan,
          fromId: "k1",
          toId: "n2",
        ),
      );
      expect(registry.clanMembers("k1"), unorderedEquals(["n1", "n2"]));
    });
  });

  group("validity_ranges", () {
    test("validity range membatasi kapan relation berlaku", () {
      const relation = GenealogyRelation.parentChild(
        parentId: "p1",
        childId: "c1",
        validity: ValidityRange(fromTick: 100, toTick: 500),
      );
      expect(relation.isActiveAt(50), isFalse);
      expect(relation.isActiveAt(150), isTrue);
      expect(relation.isActiveAt(600), isFalse);
    });

    test("validity range tanpa toTick berlaku selamanya sejak fromTick", () {
      const relation = GenealogyRelation.parentChild(
        parentId: "p1",
        childId: "c1",
        validity: ValidityRange(fromTick: 100),
      );
      expect(relation.isActiveAt(50), isFalse);
      expect(relation.isActiveAt(1 << 30, asOfTick: true), isTrue);
    });
  });

  group("registry queries", () {
    test("relationsOf mengembalikan semua relation yang melibatkan node", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      registry.add(
        const GenealogyRelation.guardian(guardianId: "g1", wardId: "c1"),
      );
      registry.add(GenealogyRelation.partnership(leftId: "p1", rightId: "x1"));
      expect(registry.relationsOf("c1"), hasLength(2));
      expect(registry.relationsOf("p1"), hasLength(2));
      expect(registry.relationsOf("g1"), hasLength(1));
    });
  });
}
