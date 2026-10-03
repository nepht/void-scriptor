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
    this.command,
    this.log,
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

  /// The command line the record states produced this rebuild.
  ///
  /// Sprint 117.43-10: this is the only field that can show WHAT was built, so
  /// it is what turns the comparison's "clean rebuild cycles" phrase into
  /// something checkable rather than a promise.
  final String? command;

  /// Path to the build log the record states supports this rebuild.
  final String? log;

  bool get isWellFormed {
    if (label.trim().isEmpty || artifactHashes.isEmpty) return false;
    if (exitCode == null || exitCode != 0) return false;
    final hashPattern = RegExp(r'^[0-9a-f]{64}$');
    if (!artifactHashes.entries.every(
      (entry) =>
          entry.key.trim().isNotEmpty && hashPattern.hasMatch(entry.value),
    )) {
      return false;
    }
    // Sprint 117.43-09 (fail-open, fixed): a rebuild window that ends before
    // it starts, or that cannot be read as a time at all, is not a record of a
    // rebuild — but nothing here ever looked at the two timestamps, so such a
    // record was accepted and the 117.43 gate reported `provenance` as `pass`.
    // The provenance claim of a reproducibility check is that TWO CLEAN
    // REBUILDS were compared, and these two strings are the only evidence in
    // the document that a rebuild happened during a real interval. Read them
    // when they are recorded; absence is not a defect, because a record that
    // states no window makes no window claim (same rule as 117.43-07).
    return hasWellFormedWindow;
  }

  /// Whether the recorded rebuild window is absent or internally consistent.
  ///
  /// Absent — BOTH ends missing or blank — is accepted as a non-claim. Half
  /// recorded is NOT absence: a record that states when a rebuild started and
  /// then stops is a claim with a hole in it, so it fails closed. Treating one
  /// end as if the other had never been written would let a truncated window
  /// through the same way an entirely absent one does. Present means both ends
  /// must parse as ISO-8601 and the finish must be strictly after the start, so
  /// a zero-length or reversed window fails closed too.
  bool get hasWellFormedWindow {
    final start = startedAt?.trim();
    final finish = finishedAt?.trim();
    final hasStart = start != null && start.isNotEmpty;
    final hasFinish = finish != null && finish.isNotEmpty;
    if (!hasStart && !hasFinish) return true;
    if (!hasStart || !hasFinish) return false;
    final parsedStart = DateTime.tryParse(start);
    final parsedFinish = DateTime.tryParse(finish);
    if (parsedStart == null || parsedFinish == null) return false;
    return parsedFinish.isAfter(parsedStart);
  }

  /// Whether the recorded command supports the CLEAN rebuild the comparison
  /// claims, or states no command at all.
  ///
  /// Sprint 117.43-10 (fail-open, fixed): every prior rule in this file asks
  /// about the artifacts a rebuild produced or when it ran. None asks WHAT was
  /// built, because nothing read `command` — so the comparison method's "two
  /// INDEPENDENT CLEAN rebuild cycles" phrase had nothing behind it, and a
  /// record admitting it ran no clean step at all was accepted as well formed.
  /// A command that names no clean step cannot have produced a clean rebuild,
  /// so when one is recorded it must contain one. Absence stays a non-claim,
  /// the same rule as the window: a record that states no command gives the
  /// gate nothing to contradict.
  bool get hasWellFormedMethod {
    final stated = command?.trim();
    if (stated == null || stated.isEmpty) return true;
    return RegExp(r'(^|[\s;&|])flutter\s+clean([\s;&|]|$)').hasMatch(stated);
  }

  /// Whether this rebuild ran the same experiment as [other].
  ///
  /// Two records that differ only in whitespace, separator, or the absolute
  /// path of the toolchain binary ran the same build; records that name a
  /// different build mode did not. Comparing the normalized form keeps a
  /// cosmetic difference in the recorded line from being read as a difference
  /// in the experiment, which is the mistake that would make this check
  /// refuse honest manifests.
  bool ranSameExperimentAs(RebuildResult other) {
    final mine = _normalizeCommand(command);
    final theirs = _normalizeCommand(other.command);
    if (mine == null || theirs == null) return true;
    return mine == theirs;
  }

  /// The comparable form of a recorded command, or null when none is recorded.
  ///
  /// Quoted segments are compared verbatim because a quoted argument carries a
  /// literal path that must not be silently rewritten; everything outside them
  /// is lowercased and squeezed so separators and spacing do not decide the
  /// outcome.
  static String? _normalizeCommand(String? command) {
    final stated = command?.trim();
    if (stated == null || stated.isEmpty) return null;
    final buffer = StringBuffer();
    var quoted = false;
    for (final rune in stated.runes) {
      final char = String.fromCharCode(rune);
      if (char == '"') {
        quoted = !quoted;
        buffer.write(char);
        continue;
      }
      if (quoted) {
        buffer.write(char);
        continue;
      }
      if (RegExp(r'\s').hasMatch(char)) {
        buffer.write(' ');
        continue;
      }
      buffer.write(char.toLowerCase());
    }
    return buffer
        .toString()
        .split(' ')
        .where((token) => token.isNotEmpty)
        .join(' ');
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
    // Sprint 117.43-01 (fail-open, fixed): the verdict is an assertion about
    // hash EQUALITY, so comparing only the artifact name sets accepted a
    // `bitIdentical` claim whose two rebuilds recorded different digests, and
    // the reproducibility gate passed on a false identity claim. Compare the
    // recorded values, so a false claim fails closed.
    if (verdict == RebuildVerdict.bitIdentical) {
      for (final entry in rebuildA!.artifactHashes.entries) {
        if (rebuildB!.artifactHashes[entry.key] != entry.value) return false;
      }
      return true;
    }
    // Sprint 117.43-06 (fail-open, fixed): the mirror image of 117.43-01.
    // 117.43-01 made the `bitIdentical` branch verify the recorded digests, so a
    // false identity claim failed closed. This branch verified NOTHING: it fell
    // straight through to the `limits` documentation test below, so a
    // `notBitIdentical` claim whose two rebuilds record byte-identical digests
    // was reported as well formed, the 113.39 evaluation returned `pass`, and
    // the 117.43 gate reported the `provenance` output as `pass` while printing
    // a verdict that says the artifacts are not reproducible. A difference
    // claim needs at least one recorded difference to be evidence of one.
    final differing = rebuildA!.artifactHashes.entries.any(
      (entry) => rebuildB!.artifactHashes[entry.key] != entry.value,
    );
    if (!differing) return false;
    if (limits == null || limits!.isEmpty) return false;
    if (limits!.any((limit) => limit.trim().isEmpty)) return false;
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
