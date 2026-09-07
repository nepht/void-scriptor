// Sprint 110.19 - Genealogy & Inheritance Validation.
//
// Domain-only contract for detecting impossible biological/adoptive
// relations (cycle detection, lifespan consistency), running configurable
// inheritance rules against a focal person, and letting writers annotate
// manual exceptions that suppress or document known findings.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_inheritance_validator.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart";

void main() {
  group("date_consistency", () {
    test(
      "validator rejects lifespan with negative birthTick or death before birth",
      () {
        const v = GenealogyInheritanceValidator();
        final bad = <String, LifeSpan>{
          "p1": const LifeSpan(id: "p1", birthTick: -1, deathTick: 10),
        };
        expect(
          () => v.validate(graph: _emptyGraph(), lifespans: bad),
          throwsA(isA<ArgumentError>()),
        );
        final swapped = <String, LifeSpan>{
          "p1": const LifeSpan(id: "p1", birthTick: 20, deathTick: 10),
        };
        expect(
          () => v.validate(graph: _emptyGraph(), lifespans: swapped),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      "report flags parentYoungerThanChild when parent birth later than child birth",
      () {
        final graph = GenealogyGraph(
          nodes: const {
            "p1": GenealogyNode(id: "p1", name: "Parent"),
            "c1": GenealogyNode(id: "c1", name: "Child"),
          },
          edges: [
            GenealogyRelation.validated(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "p1",
              toId: "c1",
              validFrom: 5,
            ),
          ],
        );
        final lifespans = <String, LifeSpan>{
          "p1": const LifeSpan(id: "p1", birthTick: 20),
          "c1": const LifeSpan(id: "c1", birthTick: 10),
        };
        final report = const GenealogyInheritanceValidator().validate(
          graph: graph,
          lifespans: lifespans,
        );
        expect(
          report.anomalies
              .where(
                (a) => a.code == GenealogyAnomalyCode.parentYoungerThanChild,
              )
              .length,
          1,
        );
      },
    );

    test(
      "strict missing lifespan marks unknownLifespan for nodes without lifespan",
      () {
        final graph = GenealogyGraph(
          nodes: const {
            "p1": GenealogyNode(id: "p1", name: "Parent"),
            "c1": GenealogyNode(id: "c1", name: "Child"),
          },
          edges: [
            GenealogyRelation.validated(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "p1",
              toId: "c1",
              validFrom: 5,
            ),
          ],
        );
        final report = const GenealogyInheritanceValidator().validate(
          graph: graph,
          lifespans: <String, LifeSpan>{
            "p1": const LifeSpan(id: "p1", birthTick: 0),
          },
          options: const GenealogyValidationOptions(
            strictMissingLifespan: true,
          ),
        );
        expect(
          report.anomalies
              .where((a) => a.code == GenealogyAnomalyCode.unknownLifespan)
              .any((a) => a.nodeIds.contains("c1")),
          isTrue,
        );
      },
    );
  });

  group("cycle_detection", () {
    test("transitive cycle across parentChild + adoption is flagged", () {
      final graph = GenealogyGraph(
        nodes: const {
          "a": GenealogyNode(id: "a", name: "A"),
          "b": GenealogyNode(id: "b", name: "B"),
          "c": GenealogyNode(id: "c", name: "C"),
        },
        edges: [
          GenealogyRelation.validated(
            id: "r1",
            kind: GenealogyRelationKind.parentChild,
            fromId: "a",
            toId: "b",
            validFrom: 0,
          ),
          GenealogyRelation.validated(
            id: "r2",
            kind: GenealogyRelationKind.adoption,
            fromId: "b",
            toId: "c",
            validFrom: 0,
          ),
          GenealogyRelation.validated(
            id: "r3",
            kind: GenealogyRelationKind.parentChild,
            fromId: "c",
            toId: "a",
            validFrom: 0,
          ),
        ],
      );
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
      );
      final cycles = report.anomalies
          .where((a) => a.code == GenealogyAnomalyCode.cycle)
          .toList();
      expect(cycles, isNotEmpty);
      expect(cycles.first.nodeIds, containsAll(<String>{"a", "b", "c"}));
    });

    test("graph without cycles does not emit cycle anomaly", () {
      final graph = GenealogyGraph(
        nodes: const {
          "p1": GenealogyNode(id: "p1", name: "Parent"),
          "c1": GenealogyNode(id: "c1", name: "Child"),
        },
        edges: [
          GenealogyRelation.validated(
            id: "r1",
            kind: GenealogyRelationKind.parentChild,
            fromId: "p1",
            toId: "c1",
            validFrom: 0,
          ),
        ],
      );
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
      );
      expect(
        report.anomalies.any((a) => a.code == GenealogyAnomalyCode.cycle),
        isFalse,
      );
    });
  });

  group("inheritance_rules + candidate_order", () {
    final graph = GenealogyGraph(
      nodes: const {
        "patriarch": GenealogyNode(id: "patriarch", name: "Patriarch"),
        "son": GenealogyNode(id: "son", name: "Son"),
        "daughter": GenealogyNode(id: "daughter", name: "Daughter"),
        "adopted": GenealogyNode(id: "adopted", name: "Adopted"),
      },
      edges: [
        GenealogyRelation.validated(
          id: "r1",
          kind: GenealogyRelationKind.parentChild,
          fromId: "patriarch",
          toId: "son",
          validFrom: 0,
        ),
        GenealogyRelation.validated(
          id: "r2",
          kind: GenealogyRelationKind.parentChild,
          fromId: "patriarch",
          toId: "daughter",
          validFrom: 0,
        ),
        GenealogyRelation.validated(
          id: "r3",
          kind: GenealogyRelationKind.adoption,
          fromId: "patriarch",
          toId: "adopted",
          validFrom: 0,
        ),
      ],
    );
    final lifespans = <String, LifeSpan>{
      "patriarch": const LifeSpan(
        id: "patriarch",
        birthTick: 0,
        deathTick: 100,
      ),
      "son": const LifeSpan(id: "son", birthTick: 10),
      "daughter": const LifeSpan(id: "daughter", birthTick: 12),
      "adopted": const LifeSpan(id: "adopted", birthTick: 14),
    };

    test("default eldestChild excludes adopted and orders by birthTick", () {
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
        lifespans: lifespans,
        focalId: "patriarch",
      );
      final ids = report.candidates
          .map((c) => c.nodeId)
          .toList(growable: false);
      expect(ids, equals(<String>["son", "daughter"]));
      expect(ids.contains("adopted"), isFalse);
      expect(report.candidates.first.justification, contains("eldest"));
    });

    test("policy eldestMaleChild only returns male children", () {
      final genders = <String, GenderAssignment>{
        "son": const GenderAssignment(gender: Gender.male),
        "daughter": const GenderAssignment(gender: Gender.female),
        "adopted": const GenderAssignment(gender: Gender.male),
      };
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
        lifespans: lifespans,
        focalId: "patriarch",
        genders: genders,
        policies: const [
          InheritancePolicy(rule: InheritanceRuleKind.eldestMaleChild),
        ],
      );
      final ids = report.candidates
          .map((c) => c.nodeId)
          .toList(growable: false);
      expect(ids, equals(<String>["son"]));
    });

    test(
      "default policy includes adopted when there is no biological child",
      () {
        final onlyAdopted = GenealogyGraph(
          nodes: const {
            "patriarch": GenealogyNode(id: "patriarch", name: "Patriarch"),
            "adopted": GenealogyNode(id: "adopted", name: "Adopted"),
          },
          edges: [
            GenealogyRelation.validated(
              id: "r1",
              kind: GenealogyRelationKind.adoption,
              fromId: "patriarch",
              toId: "adopted",
              validFrom: 0,
            ),
          ],
        );
        final report = const GenealogyInheritanceValidator().validate(
          graph: onlyAdopted,
          focalId: "patriarch",
        );
        final ids = report.candidates
            .map((c) => c.nodeId)
            .toList(growable: false);
        expect(ids, equals(<String>["adopted"]));
      },
    );

    test("policy order determines priority and rank", () {
      final genders = <String, GenderAssignment>{
        "son": const GenderAssignment(gender: Gender.male),
        "daughter": const GenderAssignment(gender: Gender.female),
      };
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
        lifespans: lifespans,
        focalId: "patriarch",
        genders: genders,
        policies: const [
          InheritancePolicy(
            rule: InheritanceRuleKind.eldestMaleChild,
            priority: 0,
          ),
          InheritancePolicy(
            rule: InheritanceRuleKind.eldestChild,
            priority: 10,
          ),
        ],
      );
      expect(report.candidates.first.rank, 1);
      expect(report.candidates.first.justification, contains("eldest_male"));
    });
  });

  group("manual_exception", () {
    test(
      "suppressCycle removes the cycle anomaly and records the exception",
      () {
        final graph = GenealogyGraph(
          nodes: const {
            "a": GenealogyNode(id: "a", name: "A"),
            "b": GenealogyNode(id: "b", name: "B"),
          },
          edges: [
            GenealogyRelation.validated(
              id: "r1",
              kind: GenealogyRelationKind.parentChild,
              fromId: "a",
              toId: "b",
              validFrom: 0,
            ),
            GenealogyRelation.validated(
              id: "r2",
              kind: GenealogyRelationKind.parentChild,
              fromId: "b",
              toId: "a",
              validFrom: 0,
            ),
          ],
        );
        final report = const GenealogyInheritanceValidator().validate(
          graph: graph,
          manualExceptions: [
            ManualException.validated(
              kind: ManualExceptionKind.suppressCycle,
              reason: "ritual time-loop adoption",
              edgeIds: ["r1", "r2"],
            ),
          ],
        );
        expect(
          report.anomalies.any((a) => a.code == GenealogyAnomalyCode.cycle),
          isFalse,
        );
        expect(
          report.exceptionsApplied
              .where((e) => e.kind == ManualExceptionKind.suppressCycle)
              .length,
          1,
        );
      },
    );

    test("annotate exception keeps anomaly and records the annotation", () {
      final graph = GenealogyGraph(
        nodes: const {
          "a": GenealogyNode(id: "a", name: "A"),
          "b": GenealogyNode(id: "b", name: "B"),
        },
        edges: [
          GenealogyRelation.validated(
            id: "r1",
            kind: GenealogyRelationKind.parentChild,
            fromId: "a",
            toId: "b",
            validFrom: 0,
          ),
          GenealogyRelation.validated(
            id: "r2",
            kind: GenealogyRelationKind.parentChild,
            fromId: "b",
            toId: "a",
            validFrom: 0,
          ),
        ],
      );
      final report = const GenealogyInheritanceValidator().validate(
        graph: graph,
        manualExceptions: [
          ManualException.validated(
            kind: ManualExceptionKind.annotate,
            reason: "experimental timeline ch12",
            edgeIds: ["r1", "r2"],
          ),
        ],
      );
      expect(
        report.anomalies.where((a) => a.code == GenealogyAnomalyCode.cycle),
        isNotEmpty,
      );
      expect(
        report.exceptionsApplied
            .where((e) => e.kind == ManualExceptionKind.annotate)
            .length,
        1,
      );
    });

    test("exception with empty reason is rejected", () {
      expect(
        () => ManualException.validated(
          kind: ManualExceptionKind.suppressCycle,
          reason: "",
          edgeIds: const ["r1"],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

GenealogyGraph _emptyGraph() => GenealogyGraph(
  nodes: const {"x": GenealogyNode(id: "x", name: "x")},
  edges: const [],
);
