// Sprint 110.17 - Genealogy Relationship Rules.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart";

void main() {
  group("parent_child", () {
    test("graph menerima edge parent_child dan expose parent/child", () {
      final graph = GenealogyGraph(
        nodes: const {
          "p1": GenealogyNode(id: "p1", name: "Parent"),
          "c1": GenealogyNode(id: "c1", name: "Child"),
        },
        edges: [
          const GenealogyRelation(
            id: "r1",
            kind: GenealogyRelationKind.parentChild,
            fromId: "p1",
            toId: "c1",
            validFrom: 0,
          ),
        ],
      );
      expect(graph.parentsOf("c1"), ["p1"]);
      expect(graph.childrenOf("p1"), ["c1"]);
    });

    test("graph menolak self-loop pada parent_child", () {
      expect(
        () => GenealogyGraph(
          nodes: const {"p1": GenealogyNode(id: "p1", name: "Parent")},
          edges: [
            const GenealogyRelation(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "p1",
              toId: "p1",
              validFrom: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
  group("adoption", () {
    test("adopsi menghasilkan parentChild virtual edge dengan note adoption", () {
      final graph = GenealogyGraph(
        nodes: const {
          "a1": GenealogyNode(id: "a1", name: "Adopter"),
          "a2": GenealogyNode(id: "a2", name: "Adoptee"),
        },
        edges: [
          const GenealogyRelation(
            id: "ad1",
            kind: GenealogyRelationKind.adoption,
            fromId: "a1",
            toId: "a2",
            validFrom: 5,
            note: "resmi",
          ),
        ],
      );
      expect(graph.parentsOf("a2"), ["a1"]);
      expect(graph.adoptiveParentsOf("a2"), ["a1"]);
    });
  });

  group("partnership", () {
    test("partnership bersifat dua arah dan terekspos di both members", () {
      final graph = GenealogyGraph(
        nodes: const {
          "p1": GenealogyNode(id: "p1", name: "Partner A"),
          "p2": GenealogyNode(id: "p2", name: "Partner B"),
        },
        edges: [
          const GenealogyRelation(
            id: "pt1",
            kind: GenealogyRelationKind.partnership,
            fromId: "p1",
            toId: "p2",
            validFrom: 0,
          ),
        ],
      );
      expect(graph.partnersOf("p1"), ["p2"]);
      expect(graph.partnersOf("p2"), ["p1"]);
    });

    test("partnership menolak self-partnership", () {
      expect(
        () => GenealogyGraph(
          nodes: const {"p1": GenealogyNode(id: "p1", name: "Solo")},
          edges: [
            const GenealogyRelation(
              id: "pt1",
              kind: GenealogyRelationKind.partnership,
              fromId: "p1",
              toId: "p1",
              validFrom: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("guardian", () {
    test("guardian hanya menunjuk satu arah (guardian ke ward)", () {
      final graph = GenealogyGraph(
        nodes: const {
          "g1": GenealogyNode(id: "g1", name: "Guardian"),
          "w1": GenealogyNode(id: "w1", name: "Ward"),
        },
        edges: [
          const GenealogyRelation(
            id: "gd1",
            kind: GenealogyRelationKind.guardian,
            fromId: "g1",
            toId: "w1",
            validFrom: 0,
          ),
        ],
      );
      expect(graph.guardianOf("w1"), "g1");
      expect(graph.wardsOf("g1"), ["w1"]);
      expect(graph.parentsOf("w1"), isEmpty);
    });
  });

  group("clan", () {
    test("clan mengelompokkan banyak node, queryable via membersOfClan", () {
      final graph = GenealogyGraph(
        nodes: const {
          "m1": GenealogyNode(id: "m1", name: "Member 1"),
          "m2": GenealogyNode(id: "m2", name: "Member 2"),
          "m3": GenealogyNode(id: "m3", name: "Member 3"),
        },
        edges: [
          const GenealogyRelation(
            id: "cl1",
            kind: GenealogyRelationKind.clan,
            fromId: "m1",
            toId: "clan:north",
            validFrom: 0,
          ),
          const GenealogyRelation(
            id: "cl2",
            kind: GenealogyRelationKind.clan,
            fromId: "m2",
            toId: "clan:north",
            validFrom: 0,
          ),
          const GenealogyRelation(
            id: "cl3",
            kind: GenealogyRelationKind.clan,
            fromId: "m3",
            toId: "clan:north",
            validFrom: 0,
          ),
        ],
      );
      final members = graph.membersOfClan("clan:north");
      expect(members, containsAll(<String>["m1", "m2", "m3"]));
      expect(members.length, 3);
      expect(graph.clansOf("m2"), ["clan:north"]);
    });
  });

  group("validity_ranges", () {
    test("validUntil lebih kecil dari validFrom / rujukan hilang / id kosong / validFrom negatif ditolak", () {
      expect(
        () => GenealogyGraph(
          nodes: const {
            "a": GenealogyNode(id: "a", name: "A"),
            "b": GenealogyNode(id: "b", name: "B"),
          },
          edges: [
            const GenealogyRelation(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "a",
              toId: "b",
              validFrom: 10,
              validUntil: 5,
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => GenealogyGraph(
          nodes: const {"a": GenealogyNode(id: "a", name: "A")},
          edges: [
            const GenealogyRelation(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "a",
              toId: "ghost",
              validFrom: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => GenealogyRelation.validated(
          id: "",
          kind: GenealogyRelationKind.parentChild,
          fromId: "a",
          toId: "b",
          validFrom: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => GenealogyRelation.validated(
          id: "r1",
          kind: GenealogyRelationKind.parentChild,
          fromId: "a",
          toId: "b",
          validFrom: -1,
        ),
        throwsArgumentError,
      );
    });

    test("activeAt(tick) memfilter edge di dalam validity range", () {
      final graph = GenealogyGraph(
        nodes: const {
          "p": GenealogyNode(id: "p", name: "Parent"),
          "c": GenealogyNode(id: "c", name: "Child"),
        },
        edges: [
          const GenealogyRelation(
            id: "r1",
            kind: GenealogyRelationKind.parentChild,
            fromId: "p",
            toId: "c",
            validFrom: 10,
            validUntil: 20,
          ),
        ],
      );
      expect(graph.parentsOf("c", atTick: 5), isEmpty);
      expect(graph.parentsOf("c", atTick: 15), ["p"]);
      expect(graph.parentsOf("c", atTick: 25), isEmpty);

      final openEnded = GenealogyGraph(
        nodes: const {
          "p": GenealogyNode(id: "p", name: "Parent"),
          "c": GenealogyNode(id: "c", name: "Child"),
        },
        edges: [
          const GenealogyRelation(
            id: "r2",
            kind: GenealogyRelationKind.parentChild,
            fromId: "p",
            toId: "c",
            validFrom: 10,
          ),
        ],
      );
      expect(openEnded.parentsOf("c", atTick: 9999), ["p"]);
    });
  });
}
