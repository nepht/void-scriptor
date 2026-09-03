// Sprint 110.19 - Genealogy & Inheritance Validation.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_inheritance_validator.dart";

void main() {
  group("GenealogyInheritanceValidator - date consistency", () {
    test("mendeteksi parent_child berakhir sebelum adoption dimulai", () {
      final registry = GenealogyRegistry();
      // parent_child X->Z 0..80
      registry.add(
        const GenealogyRelation.parentChild(
          parentId: "X",
          childId: "Z",
          validity: ValidityRange(fromTick: 0, toTick: 80),
        ),
      );
      // adoption Y->Z 90..200, asOfTick=50 -> keduanya aktif
      registry.add(
        const GenealogyRelation.adoption(
          parentId: "Y",
          childId: "Z",
          validity: ValidityRange(fromTick: 90, toTick: 200),
        ),
      );

      final result = GenealogyInheritanceValidator.fromRegistry(
        registry,
      ).validate(asOfTick: 50);

      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) => i.kind == InheritanceIssueKind.dateConsistency,
        ),
        isTrue,
      );
    });

    test("tidak ada date_consistency bila validity overlap", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(
          parentId: "P",
          childId: "C",
          validity: ValidityRange(fromTick: 0, toTick: 200),
        ),
      );
      registry.add(
        const GenealogyRelation.adoption(
          parentId: "A",
          childId: "C",
          validity: ValidityRange(fromTick: 50, toTick: 200),
        ),
      );

      final result = GenealogyInheritanceValidator.fromRegistry(
        registry,
      ).validate(asOfTick: 100);

      expect(
        result.issues.where(
          (i) => i.kind == InheritanceIssueKind.dateConsistency,
        ),
        isEmpty,
      );
    });
  });

  group("GenealogyInheritanceValidator - cycle detection", () {
    test("mendeteksi siklus parent_child implisit (A->B->C->A)", () {
      // Hubungan yang melepaskan diri dari validasi internal 110.17
      // dengan membuat siklus akan ditolak oleh registry, jadi
      // konstruktor manual lewat factory ini.
      final relations = <GenealogyRelation>[
        const GenealogyRelation.parentChild(parentId: "A", childId: "B"),
        const GenealogyRelation.parentChild(parentId: "B", childId: "C"),
        const GenealogyRelation.parentChild(parentId: "C", childId: "A"),
      ];
      final validator = GenealogyInheritanceValidator(relations: relations);

      final result = validator.validate(asOfTick: 0);

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.kind == InheritanceIssueKind.cycle),
        isTrue,
      );
    });

    test("tidak ada cycle pada pohon normal", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "A", childId: "B"),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: "A", childId: "C"),
      );

      final result = GenealogyInheritanceValidator.fromRegistry(
        registry,
      ).validate(asOfTick: 0);

      expect(
        result.issues.where((i) => i.kind == InheritanceIssueKind.cycle),
        isEmpty,
      );
    });
  });

  group("GenealogyInheritanceValidator - manual exception", () {
    test(
      "semua node di cycle ditandai sebagai manual exception -> no cycle",
      () {
        final relations = <GenealogyRelation>[
          const GenealogyRelation.parentChild(parentId: "A", childId: "B"),
          const GenealogyRelation.parentChild(parentId: "B", childId: "C"),
          const GenealogyRelation.parentChild(parentId: "C", childId: "A"),
        ];
        final validator = GenealogyInheritanceValidator(
          relations: relations,
          manualExceptions: const {"A", "B", "C"},
        );

        final result = validator.validate(asOfTick: 0);

        expect(
          result.issues.where((i) => i.kind == InheritanceIssueKind.cycle),
          isEmpty,
          reason: "semua node di cycle termasuk manual exception",
        );
      },
    );
  });

  group("GenealogyInheritanceValidator - candidate order", () {
    test(
      "default rule: parent_child > adoption > guardian, partnership excluded",
      () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(parentId: "P1", childId: "X"),
        );
        registry.add(
          const GenealogyRelation.adoption(parentId: "P2", childId: "X"),
        );
        registry.add(
          const GenealogyRelation(
            type: GenealogyRelationType.guardian,
            fromId: "G",
            toId: "X",
          ),
        );
        registry.add(GenealogyRelation.partnership(leftId: "W", rightId: "X"));

        final candidates = GenealogyInheritanceValidator.fromRegistry(
          registry,
        ).candidatesFor("X");

        expect(candidates, ["P1", "P2", "G"]);
        expect(
          candidates.contains("W"),
          isFalse,
          reason: "partnership tidak boleh menjadi pewaris",
        );
      },
    );

    test("custom rule mengubah urutan prioritas", () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: "P1", childId: "X"),
      );
      registry.add(
        const GenealogyRelation.adoption(parentId: "P2", childId: "X"),
      );

      const custom = InheritanceRuleSet(
        order: [
          GenealogyRelationType.adoption,
          GenealogyRelationType.parentChild,
        ],
        excludes: {},
      );

      final candidates = GenealogyInheritanceValidator.fromRegistry(
        registry,
        ruleSet: custom,
      ).candidatesFor("X");

      expect(candidates, ["P2", "P1"]);
    });
  });

  group("GenealogyInheritanceValidator - integrasi", () {
    test(
      "validate registry kosong mengembalikan isValid=true tanpa issues",
      () {
        final registry = GenealogyRegistry();
        final result = GenealogyInheritanceValidator.fromRegistry(
          registry,
        ).validate(asOfTick: 0);
        expect(result.isValid, isTrue);
        expect(result.issues, isEmpty);
      },
    );

    test("memfilter relasi yang tidak aktif sesuai asOfTick", () {
      final relations = <GenealogyRelation>[
        const GenealogyRelation.parentChild(
          parentId: "P",
          childId: "C",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
      ];
      final validator = GenealogyInheritanceValidator(relations: relations);

      final result = validator.validate(asOfTick: 100);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });
  });
}
