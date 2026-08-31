// Sprint 111.6 - Shared Encyclopedia Data Schema and Migration.
//
// Tests the domain-only contract that unifies the six Wave 3 encyclopedia
// domains (F23 Herbology, F24 Bestiary, F26 Artifacts, F27 Myth/Theology,
// F28 Names, F29 Idioms) and exposes a migration plan covering backup,
// rollback, compatibility checks, and a deterministic repair path.
//
// Library is pure Dart, deterministic, and free of persistence, UI, locale,
// network, wall clock, and random input.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart";

void main() {
  group("encyclopedia domain", () {
    test("six canonical domains with stable ids", () {
      expect(
        EncyclopediaDomain.values.map((d) => d.id).toList(),
        <String>["herbology", "bestiary", "artifacts", "myth_theology", "names", "idioms"],
      );
    });

    test("domain lookup by id rejects unknown ids", () {
      expect(EncyclopediaDomainLookup.fromId("herbology"), EncyclopediaDomain.herbology);
      expect(
        () => EncyclopediaDomainLookup.fromId("unknown"),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("domain ids are lowercased and non-empty", () {
      for (final d in EncyclopediaDomain.values) {
        expect(d.id, isNotEmpty);
        expect(d.id, d.id.toLowerCase());
      }
    });
  });

  group("encyclopedia record", () {
    test("rejects empty record id and empty title", () {
      expect(
        () => EncyclopediaRecord.validated(
          recordId: "",
          domain: EncyclopediaDomain.herbology,
          title: "Moonbell",
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EncyclopediaRecord.validated(
          recordId: "rec-1",
          domain: EncyclopediaDomain.herbology,
          title: "   ",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("aggregates taxonomy category id, scope and canon status", () {
      final record = EncyclopediaRecord.validated(
        recordId: "rec-moonbell",
        domain: EncyclopediaDomain.herbology,
        title: "Moonbell",
        taxonomyCategoryId: "flora",
        canonStatus: CanonStatus.canon,
        scopeLocations: const ["loc-grove"],
      );
      expect(record.taxonomyCategoryId, "flora");
      expect(record.canonStatus, CanonStatus.canon);
      expect(record.scopeLocationIds.single, "loc-grove");
      expect(record.hasScopeFacet, isTrue);
    });

    test("record without scope facets reports no scope facet", () {
      final record = EncyclopediaRecord.validated(
        recordId: "rec-2",
        domain: EncyclopediaDomain.bestiary,
        title: "Glade Stag",
      );
      expect(record.hasScopeFacet, isFalse);
    });
  });

  group("schema registry", () {
    test("rejects duplicate record ids and empty ids", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-a",
          domain: EncyclopediaDomain.herbology,
          title: "A",
        ),
      );
      expect(
        () => registry.register(
          EncyclopediaRecord.validated(
            recordId: "rec-a",
            domain: EncyclopediaDomain.bestiary,
            title: "A duplicate",
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.register(
          EncyclopediaRecord.validated(
            recordId: "",
            domain: EncyclopediaDomain.bestiary,
            title: "No id",
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("registry filters by domain and counts per domain", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-a",
          domain: EncyclopediaDomain.herbology,
          title: "A",
        ),
      );
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-b",
          domain: EncyclopediaDomain.herbology,
          title: "B",
        ),
      );
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-c",
          domain: EncyclopediaDomain.bestiary,
          title: "C",
        ),
      );
      expect(registry.recordsFor(EncyclopediaDomain.herbology).length, 2);
      expect(registry.recordsFor(EncyclopediaDomain.bestiary).length, 1);
      expect(registry.countFor(EncyclopediaDomain.names), 0);
      expect(registry.totalRecords, 3);
    });
  });

  group("migration plan", () {
    test("migration step ordering is preserved and stable", () {
      final plan = SchemaMigrationPlan.canonicalWave3();
      expect(plan.steps.first.kind, MigrationStepKind.backup);
      expect(plan.steps.last.kind, MigrationStepKind.repairPath);
      expect(plan.steps.map((s) => s.kind).toList(), <MigrationStepKind>[
        MigrationStepKind.backup,
        MigrationStepKind.schemaCheck,
        MigrationStepKind.transfer,
        MigrationStepKind.compatibility,
        MigrationStepKind.rollbackDrill,
        MigrationStepKind.repairPath,
      ]);
    });

    test("migration plan rejects empty label and empty domain coverage", () {
      expect(
        () => SchemaMigrationStep.validated(
          order: 1,
          kind: MigrationStepKind.backup,
          label: "",
          domainsCovered: const [EncyclopediaDomain.herbology],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SchemaMigrationStep.validated(
          order: 1,
          kind: MigrationStepKind.backup,
          label: "backup",
          domainsCovered: const [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("migration plan covers all six domains at least once", () {
      final plan = SchemaMigrationPlan.canonicalWave3();
      final covered = <EncyclopediaDomain>{};
      for (final step in plan.steps) {
        covered.addAll(step.domainsCovered);
      }
      expect(covered, EncyclopediaDomain.values.toSet());
    });
  });

  group("compatibility check", () {
    test("passes for registry with no issues", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-a",
          domain: EncyclopediaDomain.herbology,
          title: "A",
          taxonomyCategoryId: "flora",
        ),
      );
      final check = SchemaCompatibilityCheck.evaluate(registry);
      expect(check.issues, isEmpty);
      expect(check.isHealthy, isTrue);
    });

    test("flags duplicate taxonomy category ids within same domain", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-a",
          domain: EncyclopediaDomain.herbology,
          title: "A",
          taxonomyCategoryId: "flora",
        ),
      );
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-b",
          domain: EncyclopediaDomain.herbology,
          title: "B",
          taxonomyCategoryId: "flora",
        ),
      );
      final check = SchemaCompatibilityCheck.evaluate(registry);
      expect(check.isHealthy, isFalse);
      expect(
        check.issues.where((i) => i.kind == CompatibilityIssueKind.duplicateCategory).length,
        greaterThanOrEqualTo(1),
      );
    });

    test("flags records without taxonomy category as warnings", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-orphan",
          domain: EncyclopediaDomain.bestiary,
          title: "Orphan",
        ),
      );
      final check = SchemaCompatibilityCheck.evaluate(registry);
      expect(check.issues, isNotEmpty);
      expect(
        check.issues.where((i) => i.kind == CompatibilityIssueKind.missingCategory).length,
        1,
      );
    });
  });

  group("repair path", () {
    test("produces deterministic action sequence for known issues", () {
      final registry = SharedEncyclopediaSchema();
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-a",
          domain: EncyclopediaDomain.herbology,
          title: "A",
          taxonomyCategoryId: "flora",
        ),
      );
      registry.register(
        EncyclopediaRecord.validated(
          recordId: "rec-b",
          domain: EncyclopediaDomain.herbology,
          title: "B",
        ),
      );
      final check = SchemaCompatibilityCheck.evaluate(registry);
      final path = SchemaRepairPath.build(check);
      expect(path.actions, isNotEmpty);
      expect(path.actions.first.kind, RepairActionKind.flagMissingCategory);
    });

    test("repair action rejects empty note", () {
      expect(
        () => SchemaRepairAction.validated(
          kind: RepairActionKind.flagMissingCategory,
          targetRecordId: "rec-x",
          note: "   ",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group("backup + rollback contract", () {
    test("backup contract records size and checksum", () {
      final contract = EncyclopediaBackupContract.validated(
        backupId: "bak-1",
        recordCount: 12,
        byteSize: 4096,
        checksum: "abc123",
        domainsCovered: const [EncyclopediaDomain.herbology],
      );
      expect(contract.recordCount, 12);
      expect(contract.byteSize, 4096);
      expect(
        () => EncyclopediaBackupContract.validated(
          backupId: "",
          recordCount: 0,
          byteSize: 0,
          checksum: "",
          domainsCovered: const [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("rollback drill outcome tracks success and notes", () {
      final drill = RollbackDrillOutcome.validated(
        success: true,
        notes: "Restore snapshot 2026-08-31 ok",
      );
      expect(drill.success, isTrue);
      expect(
        () => RollbackDrillOutcome.validated(success: false, notes: "   "),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
