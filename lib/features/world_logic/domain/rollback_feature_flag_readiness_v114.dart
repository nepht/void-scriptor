/// Fail-closed readiness contract for Sprint 114.36.
library;

enum RollbackReadinessStatus { ready, fail, blocked }

enum RollbackReadinessEvidenceStatus { verifiedLocal, deferredExternal, notRun }

abstract final class RollbackFeatureFlagReadiness {
  static const String canonicalStep = '114.36';

  static const List<String> requiredEvidence = <String>[
    'rollback_artifact',
    'kill_switch',
    'flag_matrix',
    'data_compatibility',
    'rollback_drill',
    'user_guidance',
  ];
}

const int kRollbackFeatureFlagReadinessDatabaseSchema = 62;

const List<int> kRollbackFeatureFlagReadinessSupportedSourceSchemas = <int>[
  55,
  58,
  60,
  61,
];

const String kRollbackFeatureFlagReadinessFutureSchemaPolicy = 'reject';

class RollbackFeatureFlagReadinessEvidence {
  const RollbackFeatureFlagReadinessEvidence({
    required this.name,
    required this.status,
    required this.sources,
  });

  final String name;
  final RollbackReadinessEvidenceStatus status;
  final List<String> sources;

  bool get isWellFormed {
    final normalized = name.trim();
    if (!RollbackFeatureFlagReadiness.requiredEvidence.contains(normalized)) {
      return false;
    }
    if (status != RollbackReadinessEvidenceStatus.verifiedLocal) {
      return false;
    }
    if (sources.isEmpty || sources.any((source) => source.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  RollbackFeatureFlagReadinessEvidence copyWith({
    String? name,
    RollbackReadinessEvidenceStatus? status,
    List<String>? sources,
  }) {
    return RollbackFeatureFlagReadinessEvidence(
      name: name ?? this.name,
      status: status ?? this.status,
      sources: sources ?? this.sources,
    );
  }
}

class RollbackFeatureFlagReadinessReport {
  const RollbackFeatureFlagReadinessReport({
    required this.status,
    required this.readyEvidence,
    required this.missingEvidence,
    required this.invalidEvidence,
    required this.unverifiedEvidence,
    required this.duplicateEvidence,
    required this.unexpectedEvidence,
    required this.violations,
  });

  final RollbackReadinessStatus status;
  final List<String> readyEvidence;
  final List<String> missingEvidence;
  final List<String> invalidEvidence;
  final List<String> unverifiedEvidence;
  final List<String> duplicateEvidence;
  final List<String> unexpectedEvidence;
  final List<String> violations;
}

class RollbackFeatureFlagReadinessRegister {
  final List<RollbackFeatureFlagReadinessEvidence> _entries =
      <RollbackFeatureFlagReadinessEvidence>[];

  void add(RollbackFeatureFlagReadinessEvidence entry) => _entries.add(entry);

  void addEntries(Iterable<RollbackFeatureFlagReadinessEvidence> entries) =>
      _entries.addAll(entries);

  RollbackFeatureFlagReadinessReport evaluate() {
    if (_entries.isEmpty) {
      return const RollbackFeatureFlagReadinessReport(
        status: RollbackReadinessStatus.blocked,
        readyEvidence: <String>[],
        missingEvidence: RollbackFeatureFlagReadiness.requiredEvidence,
        invalidEvidence: <String>[],
        unverifiedEvidence: <String>[],
        duplicateEvidence: <String>[],
        unexpectedEvidence: <String>[],
        violations: <String>[
          'No rollback readiness evidence is available; readiness is not claimed.',
        ],
      );
    }

    final counts = <String, int>{};
    final ready = <String>[];
    final invalid = <String>[];
    final unverified = <String>[];
    final duplicate = <String>[];
    final unexpected = <String>[];
    final violations = <String>[];

    for (final entry in _entries) {
      final name = entry.name.trim();
      counts.update(name, (count) => count + 1, ifAbsent: () => 1);

      if (!RollbackFeatureFlagReadiness.requiredEvidence.contains(name)) {
        unexpected.add(name);
        violations.add('$name unexpected evidence');
        continue;
      }
      if (counts[name]! > 1) {
        duplicate.add(name);
        violations.add('$name duplicate evidence');
        continue;
      }
      if (entry.status != RollbackReadinessEvidenceStatus.verifiedLocal) {
        unverified.add(name);
        violations.add('$name unverified evidence');
        continue;
      }
      if (entry.sources.isEmpty ||
          entry.sources.any((source) => source.trim().isEmpty)) {
        invalid.add(name);
        violations.add('$name missing evidence source');
        continue;
      }
      ready.add(name);
    }

    final missing = RollbackFeatureFlagReadiness.requiredEvidence
        .where((name) => !counts.containsKey(name))
        .toList(growable: false);
    for (final name in missing) {
      violations.add('$name missing evidence');
    }

    final status = violations.isEmpty
        ? RollbackReadinessStatus.ready
        : RollbackReadinessStatus.fail;
    ready.sort();
    invalid.sort();
    unverified.sort();
    duplicate.sort();
    unexpected.sort();
    return RollbackFeatureFlagReadinessReport(
      status: status,
      readyEvidence: List<String>.unmodifiable(ready),
      missingEvidence: List<String>.unmodifiable(missing),
      invalidEvidence: List<String>.unmodifiable(invalid),
      unverifiedEvidence: List<String>.unmodifiable(unverified),
      duplicateEvidence: List<String>.unmodifiable(duplicate),
      unexpectedEvidence: List<String>.unmodifiable(unexpected),
      violations: List<String>.unmodifiable(violations),
    );
  }
}
