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

/// Prefix of the `provenance_record` line that names the logs the rebuild
/// records are supposed to cite.
const String _kLogSummaryPrefix = 'provenance_logs ';

/// The grammar a `provenance_record` line uses to restate a rebuild's
/// measurements: label, exit code, duration, and both ends of its window.
///
/// A 40-hex source revision is deliberately NOT part of this pattern — whether
/// such a revision names a real tree is not decidable without resolving a git
/// object, which this layer does not do.
final RegExp _kRebuildSummaryPattern = RegExp(
  r'^(\S+)\s+exit_code\s+(-?\d+)\s+duration_seconds\s+(-?\d+)\s+'
  r'\((.+?)\s+\.\.\s+(.+?)\)$',
);

/// A `provenance_logs` line and the paths it names.
final class _LogSummary {
  const _LogSummary(this.paths);

  final Set<String> paths;
}

/// One `rebuild_<label> ...` restatement, decoded.
final class _RebuildSummary {
  const _RebuildSummary(
    this.label,
    this.exitCode,
    this.duration,
    this.start,
    this.finish,
  );

  final String label;
  final int exitCode;
  final int duration;
  final DateTime start;
  final DateTime finish;
}

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
    if (!_hasWellFormedDigestClaims(evidence.buildInputs)) {
      missing.add('build_inputs');
    }
    if (!_hasContent(evidence.toolchainVersions)) {
      missing.add('toolchain_versions');
    }
    if (!_hasContent(evidence.dependencyLock)) missing.add('dependency_lock');
    if (!_hasWellFormedDigestClaims(evidence.dependencyLock)) {
      missing.add('dependency_lock');
    }
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
    if (!_summaryAgreesWithRebuilds(evidence)) {
      missing.add('provenance_record');
    }
    return missing;
  }

  /// Whether every summary line that restates a measurement agrees with the
  /// rebuild record it restates.
  ///
  /// Sprint 117.43-15 (fail-open, fixed). `provenance_record` was checked by
  /// `_hasContent` alone, which asks whether the group holds non-blank strings
  /// and nothing more — then the verdict printed `provenance_record: 6 item`
  /// as though six lines had been checked against anything. Nothing ever read
  /// them, so the group could contradict the `rebuild_results` it summarises
  /// in every direction at once and the 113.39 evaluation still returned
  /// `pass`.
  ///
  /// The shipped document states four of its six lines in a precise grammar:
  ///
  ///   rebuild_LABEL exit_code N duration_seconds N (START .. END)
  ///
  /// That line restates three facts this file already measures elsewhere — the
  /// exit code (`isWellFormed`), the duration (`hasWellFormedWindow`), and the
  /// window — so those three are compared against the record they name. A
  /// summary that disagrees with the measurement it summarises is not evidence,
  /// and a document that contradicts itself is the one document a
  /// reproducibility gate cannot accept.
  ///
  /// `provenance_logs <paths...>` is the same kind of restatement: 117.43-10
  /// and 117.43-14 made every rebuild's log readable, so a summary naming a
  /// different set of logs is contradicted by the records it summarises. The
  /// named set must equal the set the rebuild records cite.
  ///
  /// Two lines are deliberately NOT compared, and the boundaries are pinned by
  /// the 117.43-15 tests:
  ///
  /// * `build_command` states what the release pipeline runs, not what one
  ///   rebuild cycle ran. The shipped value omits the `flutter clean &&`
  ///   prefix its rebuild records carry, and that difference is CORRECT —
  ///   comparing them would refuse the honest document. 117.43-10 measures the
  ///   clean step where it is actually claimed, on the record that carries it.
  /// * `source_revision` names the tree, and this layer resolves no git
  ///   objects. A fabricated 40-hex revision is shape-identical to a real one,
  ///   so its existence is not decidable here without adding a process seam
  ///   that would make the verdict depend on a live checkout. Only its weaker
  ///   shape claim is enforced: a value that is not 40 hex characters at all
  ///   names no tree.
  ///
  /// Everything else is prose. `rebuild_a rebuilt cleanly after ...` names a
  /// rebuild while stating no exit code, duration, or window, so it makes no
  /// claim to contradict — the same non-claim rule 117.43-07 settled for the
  /// comparison verdict. Absence of a summary line is likewise not a defect:
  /// a document that stops restating its own measurements loses a convenience,
  /// not its evidence.
  static bool _summaryAgreesWithRebuilds(BuildProvenanceEvidence evidence) {
    final lines = evidence.provenanceRecord;
    final rebuilds = evidence.rebuildResults;
    if (lines == null || rebuilds == null) return true;

    for (final line in lines) {
      final summary = _parseRebuildSummary(line.trim());
      if (summary == null) {
        if (_logSummaryNamesUnknownLogs(line, rebuilds)) return false;
        continue;
      }

      final label = summary.label;
      final matches = <RebuildResult>[];
      for (final rebuild in rebuilds) {
        if (rebuild.label == label) matches.add(rebuild);
      }
      // A summary naming a rebuild no record mentions is the inverse of the
      // omission 117.43-14 closed: the gate once reported a rebuild count it
      // had chosen rather than read, and this adds a count it never read.
      if (matches.isEmpty) return false;
      for (final rebuild in matches) {
        if (rebuild.exitCode != summary.exitCode) return false;
        if (!_summaryDurationAgrees(rebuild, summary)) return false;
      }
    }
    // The reverse direction is deliberately NOT required. Nothing in the
    // document promises that every rebuild is restated in prose, and the
    // shipped fixtures restate none of them — requiring it would invent an
    // acceptance criterion the evidence never stated, which is the same
    // overclaim this gate exists to refuse. Only lines that ARE written are
    // held to agree.
    return true;
  }

  /// A `provenance_logs <paths...>` line, or null when [line] is not one.
  static _LogSummary? _parseLogSummary(String line) {
    if (!line.startsWith(_kLogSummaryPrefix)) return null;
    final paths = line
        .substring(_kLogSummaryPrefix.length)
        .split(RegExp(r'\s+'))
        .where((path) => path.isNotEmpty)
        .toList();
    if (paths.isEmpty) return null;
    return _LogSummary(paths.toSet());
  }

  /// A `rebuild_<label> exit_code <n> duration_seconds <n> (<a> .. <b>)` line.
  ///
  /// Null for every other line, including prose that names a rebuild without
  /// restating a measurement.
  static _RebuildSummary? _parseRebuildSummary(String line) {
    final match = _kRebuildSummaryPattern.firstMatch(line);
    if (match == null) return null;
    final label = match.group(1)!;
    // Only the summary lines that name a rebuild are restatements. A line that
    // merely starts with `rebuild_` but states no measurement is prose.
    if (!label.startsWith('rebuild_')) return null;
    final exitCode = int.tryParse(match.group(2)!);
    final duration = int.tryParse(match.group(3)!);
    if (exitCode == null || duration == null) return null;
    final start = DateTime.tryParse(match.group(4)!);
    final finish = DateTime.tryParse(match.group(5)!);
    if (start == null || finish == null) return null;
    return _RebuildSummary(label, exitCode, duration, start, finish);
  }

  /// Whether a `provenance_logs` line contradicts the logs the rebuild records
  /// cite. A line that names no log at all is prose.
  ///
  /// When NO record states a log there is no claim for the summary to
  /// contradict, so the line is left alone — the same non-claim rule
  /// 117.43-07/09/10 settled for windows, commands, and logs. Decoders that
  /// omit the field entirely (the 113.39 contract test builds its
  /// `RebuildResult` without one) therefore stay honest rather than being
  /// refused for stating something the records never denied.
  static bool _logSummaryNamesUnknownLogs(
    String line,
    List<RebuildResult> rebuilds,
  ) {
    final summary = _parseLogSummary(line);
    if (summary == null) return false;
    final cited = <String>{
      for (final rebuild in rebuilds)
        if (rebuild.log != null && rebuild.log!.trim().isNotEmpty)
          rebuild.log!.trim(),
    };
    if (cited.isEmpty) return false;
    // 117.43-10 makes a cited-but-unreadable log fail closed, so the summary
    // may neither add a log no record cites nor drop one the records do:
    // either would restate the evidence differently from the records it
    // summarises.
    return !_samePathSet(summary.paths, cited);
  }

  /// Whether the summary's window is the rebuild's own window, and the stated
  /// duration is the window's own length.
  static bool _summaryDurationAgrees(
    RebuildResult rebuild,
    _RebuildSummary summary,
  ) {
    final start = rebuild.startedAt == null
        ? null
        : DateTime.tryParse(rebuild.startedAt!.trim());
    final finish = rebuild.finishedAt == null
        ? null
        : DateTime.tryParse(rebuild.finishedAt!.trim());
    if (start == null || finish == null) return true;
    if (!start.isAtSameMomentAs(summary.start)) return false;
    if (!finish.isAtSameMomentAs(summary.finish)) return false;
    // The record's own duration is measured against its own window by the
    // gate's `_durationAgrees`; here the summary is measured against that same
    // window, so both numbers are held to the interval itself rather than to
    // each other. A summary that restates a correct duration while the record
    // disagrees with its own window is still caught, because the summary is
    // compared to the window, not copied from the record.
    return summary.duration == finish.difference(start).inSeconds;
  }

  static bool _samePathSet(Set<String> left, Set<String> right) {
    if (left.length != right.length) return false;
    return left.containsAll(right);
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

  /// A line that NAMES a digest must carry a real one.
  ///
  /// `<path> sha256 <64 hex>` is the whole point of `build_inputs` and
  /// `dependency_lock`: it says WHICH file was hashed and WHAT it hashed to.
  /// Sprint 117.43-11 (fail-open, fixed): nothing here ever parsed those
  /// lines — `_hasContent` only asked whether each entry was non-blank — so
  /// the shipped manifest's five real digests were checked for being
  /// non-empty strings and for nothing else. A line naming a file with a
  /// fabricated 64-hex digest, a truncated 8-character one, the literal
  /// `NOT-A-DIGEST`, or 63 hex characters instead of 64 all reported `pass`,
  /// and the gate printed `build_inputs: 5 item` as though the content had
  /// been verified. Proven before the fix: eleven cases, of which ten passed
  /// — only a blank line was refused, and then for being blank rather than
  /// for its digest.
  ///
  /// The rule is deliberately narrow, because over-refusing is the other way
  /// to make a gate useless. What counts as a claim is a `sha256` (any case,
  /// hyphen optional) followed by whitespace and a value: that is the form
  /// `<path> sha256 <digest>` always takes. Merely mentioning the word is not
  /// a claim, which is what keeps the shipped manifest's own prose entry
  /// honest — `hosted dependencies hash-pinned sha256; 0 git/path source`
  /// names the algorithm as a description of a scan and states no value, so it
  /// is left alone, the same non-claim rule 117.43-07 established for the
  /// comparison verdict. What this refuses is the half-written claim: a line
  /// that announces a digest and then supplies something that is not one,
  /// because the difference between those two cases is exactly the difference
  /// between evidence and a promise about it.
  static bool _hasWellFormedDigestClaims(List<String>? items) {
    if (items == null) return true;
    final values = RegExp(r'sha-?256\s+(\S+)', caseSensitive: false);
    for (final item in items) {
      for (final match in values.allMatches(item)) {
        if (!_digestPattern.hasMatch(match.group(1)!)) return false;
      }
    }
    return true;
  }

  /// A SHA-256 digest is exactly 64 hexadecimal characters.
  static final RegExp _digestPattern = RegExp(r'^[0-9a-fA-F]{64}$');

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
