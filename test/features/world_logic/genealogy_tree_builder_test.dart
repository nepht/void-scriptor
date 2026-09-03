// Sprint 110.18 - Genealogy Tree Builder (Family/Dynasty View).
//
// Domain-only tree builder atop GenealogyRegistry (110.17): membangun
// struktur pohon/klaster dynasty yang siap-query untuk UI interaktif.
// Mendukung roots (node tanpa parent_child aktif), generations (BFS depth),
// ancestors/descendants traversal, dan dynasty clustering. Semua kalkulasi
// time-aware (asOfTick) dan deterministic; tidak ada persistence/UI/wall
// clock/locale/random.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_tree_builder.dart";

void main() {
  group("roots", () {
    test("roots mengembalikan node tanpa parent_child aktif pada asOfTick", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c2"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "c1", childId: "g1"),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1", "c2", "g1"],
        asOfTick: 100,
      );
      expect(tree.roots.toSet(), equals({"p1"}));
    });

    test("roots kosong ketika semua node memiliki parent aktif", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1"],
        asOfTick: 0,
      );
      expect(tree.roots.toSet(), equals({"p1"}));
    });

    test("roots mengabaikan parent_child yang toTick < asOfTick", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(
          parentId: "p1",
          childId: "c1",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1"],
        asOfTick: 100,
      );
      expect(tree.roots.toSet(), equals({"p1", "c1"}));
    });
  });

  group("generations", () {
    test("generations mengelompokkan node berdasarkan BFS dari root", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "c1", childId: "g1"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "c1", childId: "g2"),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1", "g1", "g2"],
        asOfTick: 0,
      );
      expect(tree.generationOf("p1"), 0);
      expect(tree.generationOf("c1"), 1);
      expect(tree.generationOf("g1"), 2);
      expect(tree.generationOf("g2"), 2);
    });
  });

  group("ancestors and descendants", () {
    test("ancestors diurutkan dari immediate parent ke atas", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c2"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "c2", childId: "g1"),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1", "c2", "g1"],
        asOfTick: 0,
      );
      expect(tree.ancestorsOf("g1"), equals(<String>["c2", "p1"]));
      expect(tree.descendantsOf("p1").toSet(), equals({"c1", "c2", "g1"}));
    });

    test("ancestors menyertakan adoption parent sebagai non-biological", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.adoption(parentId: "a1", childId: "c1"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "c1", childId: "g1"),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["a1", "c1", "g1"],
        asOfTick: 0,
      );
      final ancestors = tree.ancestorsWithKind("g1");
      expect(ancestors["a1"], equals(GenealogyRelationType.adoption));
      expect(ancestors["c1"], equals(GenealogyRelationType.parentChild));
    });
  });

  group("dynasty clustering", () {
    test(
      "dynastyClusters memisahkan parent_child dan adoption jadi klaster",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
        );
        registry.add(
          const GenealogyRelation.adoption(parentId: "a1", childId: "x1"),
        );
        final tree = GenealogyTreeBuilder.build(
          registry,
          nodeIds: const ["p1", "c1", "a1", "x1"],
          asOfTick: 0,
        );
        final clusters = tree.dynastyClusters();
        expect(clusters.length, 2);
        final byMembers = {for (final c in clusters) c.members.toSet(): c};
        expect(
          byMembers.keys,
          containsAll([
            {"p1", "c1"},
            {"a1", "x1"},
          ]),
        );
      },
    );

    test("dynastyClusters menggabungkan parent_child dan partnership", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
      );
      registry.add(GenealogyRelation.partnership(leftId: "p1", rightId: "s1"));
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: const ["p1", "c1", "s1"],
        asOfTick: 0,
      );
      final clusters = tree.dynastyClusters();
      expect(clusters.length, 1);
      expect(clusters.first.members.toSet(), equals({"p1", "c1", "s1"}));
    });
  });

  group("inheritance validation", () {
    test("validateInheritance menolak parent_child cycle implisit", () {
      final rawRelations = <GenealogyRelation>[
        const GenealogyRelation.parentChild(parentId: "p1", childId: "c1"),
        const GenealogyRelation.parentChild(parentId: "c1", childId: "p1"),
      ];
      final tree = GenealogyTreeBuilder.fromRelations(
        rawRelations,
        nodeIds: const ["p1", "c1"],
        asOfTick: 0,
      );
      final issues = tree.validateInheritance();
      expect(
        issues,
        contains(
          predicate<GenealogyInheritanceIssue>(
            (i) => i.kind == GenealogyInheritanceIssueKind.cycle,
          ),
        ),
      );
    });

    test(
      "validateInheritance menolak kepala klan yang juga parent anggota",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation(
            type: GenealogyRelationType.clan,
            fromId: "house",
            toId: "p1",
          ),
        );
        registry.add(
          const GenealogyRelation(
            type: GenealogyRelationType.clan,
            fromId: "house",
            toId: "h1",
          ),
        );
        registry.add(
          const GenealogyRelation.parentChild(parentId: "p1", childId: "h1"),
        );
        final tree = GenealogyTreeBuilder.build(
          registry,
          nodeIds: const ["p1", "h1"],
          asOfTick: 0,
          clanNodes: const ["house"],
        );
        final issues = tree.validateInheritance();
        expect(
          issues,
          contains(
            predicate<GenealogyInheritanceIssue>(
              (i) => i.kind == GenealogyInheritanceIssueKind.clanParentConflict,
            ),
          ),
        );
      },
    );
  });
}
