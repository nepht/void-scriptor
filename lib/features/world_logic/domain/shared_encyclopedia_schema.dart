// Sprint 111.6 - Shared Encyclopedia Data Schema and Migration.
//
// Domain-only contract that unifies the six Wave 3 encyclopedia domains
// (F23 Herbology, F24 Bestiary, F26 Artifacts, F27 Myth/Theology,
// F28 Names, F29 Idioms) and exposes a deterministic migration plan,
// compatibility checks, repair path, backup contract, and rollback drill.
//
// No persistence, UI, locale, network, wall clock, or random input.
// D-SCHEMA-01 remains OPEN; this module is the canonical Wave 3 shared
// schema foundation that future Drift tables may mirror, but no premature
// Drift migrations are introduced here.

library;

/// Six canonical Wave 3 encyclopedia domains. Order is part of the public
/// contract - keep stable for serialized references in backups and exports.
enum EncyclopediaDomain {
  herbology,
  bestiary,
  artifacts,
  mythTheology,
  names,
  idioms,
}

extension EncyclopediaDomainContract on EncyclopediaDomain {
  /// Stable lowercased identifier suitable for JSON keys and slug ids.
  String get id {
    switch (this) {
      case EncyclopediaDomain.herbology:
        return "herbology";
      case EncyclopediaDomain.bestiary:
        return "bestiary";
      case EncyclopediaDomain.artifacts:
        return "artifacts";
      case EncyclopediaDomain.mythTheology:
        return "myth_theology";
      case EncyclopediaDomain.names:
        return "names";
      case EncyclopediaDomain.idioms:
        return "idioms";
    }
  }

  /// Reverse lookup by id; throws ArgumentError when unknown.
}

/// Re-exported canon status hierarchy from 111.4 to keep the shared schema
/// module self-contained. The canonical definition lives in
/// encyclop_canon_provenance.dart and is mirrored here for test ergonomics.
enum CanonStatus { canon, rumor, myth, hypothesis, generated }

/// Aggregated record across the shared encyclopedia schema. Carries the
/// domain, taxonomy category, scope facets, and canon status so that the
/// migration pipeline can validate and migrate records uniformly.
class EncyclopediaRecord {
  const EncyclopediaRecord._({
    required this.recordId,
    required this.domain,
    required this.title,
    required this.taxonomyCategoryId,
    required this.canonStatus,
    required this.scopeLocationIds,
  });

  factory EncyclopediaRecord.validated({
    required String recordId,
    required EncyclopediaDomain domain,
    required String title,
    String? taxonomyCategoryId,
    CanonStatus canonStatus = CanonStatus.canon,
    List<String> scopeLocations = const [],
  }) {
    final id = recordId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        recordId,
        "recordId",
        "recordId cannot be empty",
      );
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, "title", "title cannot be empty");
    }
    final cleanedLocations = scopeLocations
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return EncyclopediaRecord._(
      recordId: id,
      domain: domain,
      title: trimmedTitle,
      taxonomyCategoryId: taxonomyCategoryId?.trim().isEmpty ?? true
          ? null
          : taxonomyCategoryId!.trim(),
      canonStatus: canonStatus,
      scopeLocationIds: List.unmodifiable(cleanedLocations),
    );
  }

  final String recordId;
  final EncyclopediaDomain domain;
  final String title;
  final String? taxonomyCategoryId;
  final CanonStatus canonStatus;
  final List<String> scopeLocationIds;

  bool get hasScopeFacet => scopeLocationIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaRecord &&
          other.recordId == recordId &&
          other.domain == domain &&
          other.title == title &&
          other.taxonomyCategoryId == taxonomyCategoryId &&
          other.canonStatus == canonStatus &&
          _listEq(other.scopeLocationIds, scopeLocationIds));

  @override
  int get hashCode => Object.hash(
    recordId,
    domain,
    title,
    taxonomyCategoryId,
    canonStatus,
    Object.hashAll(scopeLocationIds),
  );
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Mutable registry of encyclopedia records keyed by recordId. Provides
/// duplicate and empty-id guards, per-domain filtering, and counts.
class SharedEncyclopediaSchema {
  final Map<String, EncyclopediaRecord> _records =
      <String, EncyclopediaRecord>{};

  int get totalRecords => _records.length;

  Iterable<String> get recordIds => _records.keys;

  EncyclopediaRecord? recordFor(String recordId) => _records[recordId];

  List<EncyclopediaRecord> recordsFor(EncyclopediaDomain domain) =>
      _records.values.where((r) => r.domain == domain).toList();

  int countFor(EncyclopediaDomain domain) =>
      _records.values.where((r) => r.domain == domain).length;

  void register(EncyclopediaRecord record) {
    final id = record.recordId;
    if (id.isEmpty) {
      throw ArgumentError.value(id, "recordId", "recordId cannot be empty");
    }
    if (_records.containsKey(id)) {
      throw ArgumentError.value(id, "recordId", "recordId already registered");
    }
    _records[id] = record;
  }
}

/// Phases of the Wave 3 encyclopedia migration pipeline.
enum MigrationStepKind {
  backup,
  schemaCheck,
  transfer,
  compatibility,
  rollbackDrill,
  repairPath,
}

/// Single step in a migration plan; carries order, kind, label, and the
/// domains it covers so the pipeline can scope its execution.
class SchemaMigrationStep {
  const SchemaMigrationStep._({
    required this.order,
    required this.kind,
    required this.label,
    required this.domainsCovered,
  });

  factory SchemaMigrationStep.validated({
    required int order,
    required MigrationStepKind kind,
    required String label,
    required List<EncyclopediaDomain> domainsCovered,
  }) {
    if (order < 1) {
      throw ArgumentError.value(order, "order", "order must be >= 1");
    }
    final l = label.trim();
    if (l.isEmpty) {
      throw ArgumentError.value(label, "label", "label cannot be empty");
    }
    if (domainsCovered.isEmpty) {
      throw ArgumentError.value(
        domainsCovered,
        "domainsCovered",
        "migration step must cover at least one domain",
      );
    }
    return SchemaMigrationStep._(
      order: order,
      kind: kind,
      label: l,
      domainsCovered: List.unmodifiable(domainsCovered),
    );
  }

  final int order;
  final MigrationStepKind kind;
  final String label;
  final List<EncyclopediaDomain> domainsCovered;
}

/// Ordered list of migration steps covering the six Wave 3 domains.
class SchemaMigrationPlan {
  const SchemaMigrationPlan._({required this.steps});

  /// Canonical Wave 3 migration plan: backup, schema check, transfer,
  /// compatibility, rollback drill, repair path. Each step covers every
  /// domain so the pipeline is uniform.
  factory SchemaMigrationPlan.canonicalWave3() {
    const allDomains = EncyclopediaDomain.values;
    return SchemaMigrationPlan._(
      steps: List.unmodifiable(<SchemaMigrationStep>[
        SchemaMigrationStep.validated(
          order: 1,
          kind: MigrationStepKind.backup,
          label: "Pre-migration backup",
          domainsCovered: allDomains,
        ),
        SchemaMigrationStep.validated(
          order: 2,
          kind: MigrationStepKind.schemaCheck,
          label: "Schema validation",
          domainsCovered: allDomains,
        ),
        SchemaMigrationStep.validated(
          order: 3,
          kind: MigrationStepKind.transfer,
          label: "Domain transfer",
          domainsCovered: allDomains,
        ),
        SchemaMigrationStep.validated(
          order: 4,
          kind: MigrationStepKind.compatibility,
          label: "Compatibility verification",
          domainsCovered: allDomains,
        ),
        SchemaMigrationStep.validated(
          order: 5,
          kind: MigrationStepKind.rollbackDrill,
          label: "Rollback drill",
          domainsCovered: allDomains,
        ),
        SchemaMigrationStep.validated(
          order: 6,
          kind: MigrationStepKind.repairPath,
          label: "Repair path application",
          domainsCovered: allDomains,
        ),
      ]),
    );
  }

  final List<SchemaMigrationStep> steps;
}

/// Categories of compatibility issues detected by the schema check.
enum CompatibilityIssueKind { missingCategory, duplicateCategory }

/// Single issue surfaced by the compatibility check.
class CompatibilityIssue {
  const CompatibilityIssue._({
    required this.kind,
    required this.recordId,
    required this.domain,
    required this.note,
  });

  factory CompatibilityIssue.missingCategory({
    required String recordId,
    required EncyclopediaDomain domain,
  }) => CompatibilityIssue._(
    kind: CompatibilityIssueKind.missingCategory,
    recordId: recordId,
    domain: domain,
    note: "record has no taxonomy category",
  );

  factory CompatibilityIssue.duplicateCategory({
    required String recordId,
    required EncyclopediaDomain domain,
    required String taxonomyCategoryId,
  }) => CompatibilityIssue._(
    kind: CompatibilityIssueKind.duplicateCategory,
    recordId: recordId,
    domain: domain,
    note: "taxonomy category $taxonomyCategoryId reused",
  );

  final CompatibilityIssueKind kind;
  final String recordId;
  final EncyclopediaDomain domain;
  final String note;
}

/// Result of evaluating the registry for compatibility issues.
class SchemaCompatibilityCheck {
  const SchemaCompatibilityCheck._({required this.issues});

  factory SchemaCompatibilityCheck.evaluate(SharedEncyclopediaSchema registry) {
    final issues = <CompatibilityIssue>[];
    final byCategory = <EncyclopediaDomain, Map<String, List<String>>>{};
    for (final id in registry.recordIds) {
      final record = registry.recordFor(id);
      if (record == null) continue;
      if (record.taxonomyCategoryId == null) {
        issues.add(
          CompatibilityIssue.missingCategory(
            recordId: record.recordId,
            domain: record.domain,
          ),
        );
      } else {
        final bucket = byCategory.putIfAbsent(
          record.domain,
          () => <String, List<String>>{},
        );
        final list = bucket.putIfAbsent(
          record.taxonomyCategoryId!,
          () => <String>[],
        );
        list.add(record.recordId);
      }
    }
    for (final entry in byCategory.entries) {
      for (final cat in entry.value.entries) {
        if (cat.value.length > 1) {
          for (final id in cat.value) {
            issues.add(
              CompatibilityIssue.duplicateCategory(
                recordId: id,
                domain: entry.key,
                taxonomyCategoryId: cat.key,
              ),
            );
          }
        }
      }
    }
    return SchemaCompatibilityCheck._(issues: List.unmodifiable(issues));
  }

  final List<CompatibilityIssue> issues;

  bool get isHealthy => issues.isEmpty;

  Iterable<CompatibilityIssue> issuesOfKind(CompatibilityIssueKind kind) =>
      issues.where((i) => i.kind == kind);
}

/// Categories of repair actions derived from compatibility issues.
enum RepairActionKind { flagMissingCategory, deDuplicateCategory }

/// Single repair action. Target record id and human-readable note are
/// required so the action is auditable in the repair log.
class SchemaRepairAction {
  const SchemaRepairAction._({
    required this.kind,
    required this.targetRecordId,
    required this.note,
  });

  factory SchemaRepairAction.validated({
    required RepairActionKind kind,
    required String targetRecordId,
    required String note,
  }) {
    if (targetRecordId.trim().isEmpty) {
      throw ArgumentError.value(
        targetRecordId,
        "targetRecordId",
        "targetRecordId cannot be empty",
      );
    }
    final n = note.trim();
    if (n.isEmpty) {
      throw ArgumentError.value(note, "note", "note cannot be empty");
    }
    return SchemaRepairAction._(
      kind: kind,
      targetRecordId: targetRecordId,
      note: n,
    );
  }

  final RepairActionKind kind;
  final String targetRecordId;
  final String note;
}

/// Ordered list of repair actions derived deterministically from a
/// compatibility check. Order is stable: missing-category flags precede
/// duplicate-category de-dup actions.
class SchemaRepairPath {
  const SchemaRepairPath._({required this.actions});

  factory SchemaRepairPath.build(SchemaCompatibilityCheck check) {
    final actions = <SchemaRepairAction>[];
    for (final issue in check.issuesOfKind(
      CompatibilityIssueKind.missingCategory,
    )) {
      actions.add(
        SchemaRepairAction.validated(
          kind: RepairActionKind.flagMissingCategory,
          targetRecordId: issue.recordId,
          note: "assign taxonomy category: ${issue.domain.id}",
        ),
      );
    }
    for (final issue in check.issuesOfKind(
      CompatibilityIssueKind.duplicateCategory,
    )) {
      actions.add(
        SchemaRepairAction.validated(
          kind: RepairActionKind.deDuplicateCategory,
          targetRecordId: issue.recordId,
          note: issue.note,
        ),
      );
    }
    return SchemaRepairPath._(actions: List.unmodifiable(actions));
  }

  final List<SchemaRepairAction> actions;
}

/// Backup contract describing a snapshot taken before migration. The
/// checksum and byte size are mandatory so consumers can verify the
/// artifact without re-running the migration.
class EncyclopediaBackupContract {
  const EncyclopediaBackupContract._({
    required this.backupId,
    required this.recordCount,
    required this.byteSize,
    required this.checksum,
    required this.domainsCovered,
  });

  factory EncyclopediaBackupContract.validated({
    required String backupId,
    required int recordCount,
    required int byteSize,
    required String checksum,
    required List<EncyclopediaDomain> domainsCovered,
  }) {
    if (backupId.trim().isEmpty) {
      throw ArgumentError.value(
        backupId,
        "backupId",
        "backupId cannot be empty",
      );
    }
    if (recordCount < 0) {
      throw ArgumentError.value(
        recordCount,
        "recordCount",
        "recordCount must be >= 0",
      );
    }
    if (byteSize < 0) {
      throw ArgumentError.value(byteSize, "byteSize", "byteSize must be >= 0");
    }
    if (checksum.trim().isEmpty) {
      throw ArgumentError.value(
        checksum,
        "checksum",
        "checksum cannot be empty",
      );
    }
    if (domainsCovered.isEmpty) {
      throw ArgumentError.value(
        domainsCovered,
        "domainsCovered",
        "backup must cover at least one domain",
      );
    }
    return EncyclopediaBackupContract._(
      backupId: backupId.trim(),
      recordCount: recordCount,
      byteSize: byteSize,
      checksum: checksum.trim(),
      domainsCovered: List.unmodifiable(domainsCovered),
    );
  }

  final String backupId;
  final int recordCount;
  final int byteSize;
  final String checksum;
  final List<EncyclopediaDomain> domainsCovered;
}

/// Result of a rollback drill that exercises the backup contract.
class RollbackDrillOutcome {
  const RollbackDrillOutcome._({required this.success, required this.notes});

  factory RollbackDrillOutcome.validated({
    required bool success,
    required String notes,
  }) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        notes,
        "notes",
        "rollback drill notes cannot be empty",
      );
    }
    return RollbackDrillOutcome._(success: success, notes: trimmed);
  }

  final bool success;
  final String notes;
}

/// Helper for reverse lookup of EncyclopediaDomain by stable id.
class EncyclopediaDomainLookup {
  const EncyclopediaDomainLookup._();

  static EncyclopediaDomain fromId(String value) {
    final normalized = value.trim().toLowerCase();
    for (final d in EncyclopediaDomain.values) {
      if (d.id == normalized) return d;
    }
    throw ArgumentError.value(value, "value", "unknown encyclopedia domain id");
  }
}
