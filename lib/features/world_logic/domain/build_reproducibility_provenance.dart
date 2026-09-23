/// Build Reproducibility & Provenance (Step 113.39).
///
/// Domain contract for the six canonical provenance evidence groups —
/// `build_inputs`, `toolchain_versions`, `dependency_lock`,
/// `rebuild_results`, `artifact_comparison`, and `provenance_record` —
/// plus the evaluation state machine that decides whether the candidate
/// build carries complete, incomplete, or absent provenance.
///
/// An artifact comparison records an honest verdict: [RebuildVerdict]
/// `bitIdentical` when two clean rebuilds hash the same, or
/// `notBitIdentical` with documented limits when the toolchain embeds
/// varying data. A comparison without its rebuild results or without
/// limits on a non-identical verdict is incomplete, never a pass.
library;

/// Canonical evidence names, in roadmap order.
const List<String> kBuildProvenanceRequiredEvidence = <String>[
  'build_inputs',
  'toolchain_versions',
  'dependency_lock',
  'rebuild_results',
  'artifact_comparison',
  'provenance_record',
];

/// Verdict of comparing two clean rebuilds.
enum RebuildVerdict {
  /// Both rebuilds produced byte-identical artifact hashes.
  bitIdentical,

  /// Hashes differ; limits must document why the difference is bounded.
  notBitIdentical,
}

/// Immutable record of one clean rebuild.
class RebuildResult {
  const RebuildResult({
    required this.label,
    required this.artifactHashes,
    this.exitCode,
    this.startedAt,
    this.finishedAt,
  });

  /// Which rebuild this is (for example `rebuild_a`).
  final String label;

  /// Artifact path -> SHA-256 hex recorded after the rebuild.
  final Map<String, String> artifactHashes;

  /// Build process exit code (0 required for a recorded rebuild).
  final int? exitCode;

  /// ISO-8601 timestamps of the rebuild window.
  final String? startedAt;
  final String? finishedAt;

  bool get isWellFormed {
    if (label.trim().isEmpty || artifactHashes.isEmpty) return false;
    if (exitCode == null || exitCode != 0) return false;
    final hashPattern = RegExp(r'^[0-9a-f]{64}$');
    return artifactHashes.entries.every(
      (entry) =>
          entry.key.trim().isNotEmpty && hashPattern.hasMatch(entry.value),
    );
  }
}

/// Immutable record comparing two clean rebuilds.
class ArtifactComparison {
  const ArtifactComparison({
    this.method,
    this.rebuildA,
    this.rebuildB,
    this.verdict,
    this.limits,
  });

  /// How the comparison was performed (hash algorithm and scope).
  final String? method;

  /// The two rebuild results being compared.
  final RebuildResult? rebuildA;
  final RebuildResult? rebuildB;

  /// Honest verdict of the comparison.
  final RebuildVerdict? verdict;

  /// Documented limits; required whenever the verdict is not identical.
  final List<String>? limits;

  bool get isWellFormed {
    if (method == null || method!.trim().isEmpty) return false;
    if (rebuildA == null || rebuildB == null) return false;
    if (!rebuildA!.isWellFormed || !rebuildB!.isWellFormed) return false;
    if (verdict == null) return false;
    final keysA = rebuildA!.artifactHashes.keys.toSet();
    final keysB = rebuildB!.artifactHashes.keys.toSet();
    final sameKeys = keysA.length == keysB.length && keysA.containsAll(keysB);
    if (!sameKeys) return false;
    if (verdict == RebuildVerdict.notBitIdentical) {
      if (limits == null || limits!.isEmpty) return false;
      if (limits!.any((limit) => limit.trim().isEmpty)) return false;
    }
    return true;
  }
}

/// Immutable snapshot of the six provenance evidence groups.
class BuildProvenanceEvidence {
  const BuildProvenanceEvidence({
    this.buildInputs,
    this.toolchainVersions,
    this.dependencyLock,
    this.rebuildResults,
    this.artifactComparison,
    this.provenanceRecord,
  });

  /// Inputs hashed for the build (path -> SHA-256 or description).
  final List<String>? buildInputs;

  /// Recorded toolchain versions (Flutter, Dart, CMake, MSVC, Windows SDK).
  final List<String>? toolchainVersions;

  /// Dependency lock evidence (for example `pubspec.lock sha256 <hex>`).
  final List<String>? dependencyLock;

  /// The two clean rebuild records.
  final List<RebuildResult>? rebuildResults;

  /// Comparison verdict across the rebuilds.
  final ArtifactComparison? artifactComparison;

  /// Provenance record (source revision, build command, exit codes).
  final List<String>? provenanceRecord;

  /// Returns the canonical names of evidence groups that are missing,
  /// empty, or malformed.
  static List<String> missingEvidence(BuildProvenanceEvidence evidence) {
    final missing = <String>[];
    if (!_hasContent(evidence.buildInputs)) missing.add('build_inputs');
    if (!_hasContent(evidence.toolchainVersions)) {
      missing.add('toolchain_versions');
    }
    if (!_hasContent(evidence.dependencyLock)) missing.add('dependency_lock');
    final rebuilds = evidence.rebuildResults;
    if (rebuilds == null ||
        rebuilds.length < 2 ||
        rebuilds.any((rebuild) => !rebuild.isWellFormed)) {
      missing.add('rebuild_results');
    }
    if (evidence.artifactComparison == null ||
        !evidence.artifactComparison!.isWellFormed) {
      missing.add('artifact_comparison');
    }
    if (!_hasContent(evidence.provenanceRecord)) {
      missing.add('provenance_record');
    }
    return missing;
  }

  /// Evaluates evidence: null or unrecorded evidence is
  /// [BuildProvenanceState.blocked]; any missing group fails with the
  /// canonical names in its notes; complete evidence passes and retains
  /// the comparison verdict, artifact counts, and documented limits.
  static BuildProvenanceEvaluation evaluate(BuildProvenanceEvidence? evidence) {
    if (evidence == null || _isUnrecorded(evidence)) {
      return const BuildProvenanceEvaluation(
        state: BuildProvenanceState.blocked,
        notes: <String>['no build provenance recorded'],
      );
    }

    final missing = missingEvidence(evidence);
    if (missing.isNotEmpty) {
      return BuildProvenanceEvaluation(
        state: BuildProvenanceState.fail,
        notes: <String>[
          'build provenance incomplete: missing ${missing.join(', ')}',
        ],
      );
    }

    final comparison = evidence.artifactComparison!;
    final notes = <String>[
      'build_inputs: ${evidence.buildInputs!.length} item',
      'toolchain_versions: ${evidence.toolchainVersions!.length} item',
      'rebuild_results: ${evidence.rebuildResults!.length} item',
      'artifact_comparison: ${_verdictLabel(comparison.verdict!)} '
          '(${comparison.rebuildA!.artifactHashes.length} artifact)',
      'provenance_record: ${evidence.provenanceRecord!.length} item',
      for (final limit in comparison.limits ?? const <String>[])
        'limit: $limit',
    ];
    return BuildProvenanceEvaluation(
      state: BuildProvenanceState.pass,
      notes: notes,
    );
  }

  static String _verdictLabel(RebuildVerdict verdict) => switch (verdict) {
    RebuildVerdict.bitIdentical => 'BIT_IDENTICAL',
    RebuildVerdict.notBitIdentical => 'NOT_BIT_IDENTICAL',
  };

  static bool _hasContent(List<String>? items) {
    if (items == null || items.isEmpty) return false;
    return items.every((item) => item.trim().isNotEmpty);
  }

  static bool _isUnrecorded(BuildProvenanceEvidence evidence) {
    return evidence.buildInputs == null &&
        evidence.toolchainVersions == null &&
        evidence.dependencyLock == null &&
        evidence.rebuildResults == null &&
        evidence.artifactComparison == null &&
        evidence.provenanceRecord == null;
  }
}

/// Evaluation outcome of build provenance evidence.
enum BuildProvenanceState {
  /// Every required evidence group is present, well-formed, and the
  /// comparison verdict is honestly documented.
  pass,

  /// Some evidence group is missing, empty, or malformed.
  fail,

  /// No evidence recorded at all — nothing to evaluate.
  blocked,
}

/// Result of evaluating [BuildProvenanceEvidence].
class BuildProvenanceEvaluation {
  const BuildProvenanceEvaluation({required this.state, required this.notes});

  final BuildProvenanceState state;
  final List<String> notes;
}
