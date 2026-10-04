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

import 'dart:io';

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

/// Prefix of the `provenance_record` line that cites a shipped document the
/// document claims was verified.
const String _kCitationPrefix = 'signed_candidate ';

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

/// Whether a recorded comparison method names a digest algorithm whose output
/// is not the 64-character SHA-256 value every recorded digest is validated as.
///
/// Sprint 117.43-22. `ArtifactComparison.method` is the document's own account
/// of how the digests were produced, and until this slice the only question
/// asked of it was whether it was blank. The rebuild records it sits beside are
/// held to a strict rule — every value in `artifactHashes` must be exactly 64
/// hex characters — so a method naming MD5, SHA-1, or CRC-32 states that the
/// comparison ran on an algorithm that cannot emit those values at all.
///
/// Matching is on whole algorithm TOKENS rather than on substrings, so prose
/// that merely mentions a digest (`hash-pinned sha256; 0 git/path source`)
/// cannot trip it, and a method that names no algorithm at all is a non-claim
/// in the same sense 117.43-07/11/21 settled for windows, commands, logs, and
/// lines that only mention the word.
///
/// BLAKE2b, BLAKE3, Keccak, and SHA3 are deliberately absent: they also emit 64
/// hex characters, so a method naming one is not contradicting the recorded
/// values' width and this layer cannot tell whether the document used it.
bool _namesOtherDigestAlgorithm(String method) {
  // `SHA-1`, `sha1`, and `Sha 1` are the same algorithm written three ways, but
  // the hyphen and the space are separators for the tokenizer below, which
  // would read `SHA-1` as the tokens `sha` and `1` and miss it. Fold the
  // numbered digests back together first, then tokenize on what remains. The
  // trailing digits matter: `SHA-512` must stay distinguishable from the
  // SHA-256 family, so only the fold happens here and the exact number is what
  // the set lookup then judges.
  final normalised = method.replaceAllMapped(
    RegExp(r'sha[\s_-]*(\d+)', caseSensitive: false),
    (match) => 'sha${match.group(1)}',
  );
  final tokens = normalised
      .split(RegExp(r'[^0-9a-zA-Z]+'))
      .where((token) => token.isNotEmpty)
      .map((token) => token.toLowerCase())
      .toSet();
  return tokens.any(_kNonSha256Algorithms.contains);
}

/// The artifacts a [method] sentence claims to have covered, as a count and a
/// name set, or `null` when the sentence makes no scope claim at all.
///
/// Both shapes are returned together because they are one claim read two ways:
/// a count with no names still states how much was covered, and names with no
/// count still state which artifacts. Either alone would under-read the
/// sentence.
({int? count, Set<String>? names})? _statedArtifactScope(String method) {
  // The count. `the 6 exe/dll artifacts`, `6 exe/dll artifacts`, and `over 12
  // artifacts` all state how many were covered. Anchoring on `artifacts` keeps
  // unrelated numbers out: `SHA-256` has a number but names no artifact scope,
  // and `dartjni.dll` is named without ever stating a total.
  final countMatch = RegExp(
    r'\b(\d+)\s+(?:[a-zA-Z/]*\s+)?artifacts?\b',
    caseSensitive: false,
  ).firstMatch(method);
  final count = countMatch == null ? null : int.tryParse(countMatch.group(1)!);

  // The enumeration, when the sentence offers one: a parenthetical, or a
  // trailing `+`/`and` list. `SHA-256 over the 6 exe/dll artifacts` has neither
  // and claims no individual artifact, so there is nothing to cross-check.
  final names = <String>{};
  final parenthesised = RegExp(r'\(([^()]*)\)').allMatches(method);
  for (final match in parenthesised) {
    names.addAll(_artifactNamesIn(match.group(1)!));
  }
  // `void_scriptor.exe + dartjni.dll` and `a, b and c` both sit outside
  // parentheses in a method sentence, so collect the names that appear after a
  // `+` or `and` anywhere in the line.
  final joined = RegExp(
    r'(?:\+|,|\band\b)([^,]+?)(?=\s*(?:,|\+|\band\b|\)|$))',
    caseSensitive: false,
  ).allMatches(method);
  for (final match in joined) {
    names.addAll(_artifactNamesIn(match.group(1)!));
  }
  if (names.isEmpty) return count == null ? null : (count: count, names: null);
  return (count: count, names: names);
}

/// Artifact file names mentioned in one clause of a method sentence.
///
/// Only names shaped like build output are collected, so a qualifier such as
/// `two independent cycles` or `the same tree and machine` is not mistaken
/// for an artifact: a name has to end in an extension, and the extensions
/// accepted are the ones a Windows build actually emits.
Iterable<String> _artifactNamesIn(String clause) sync* {
  final pattern = RegExp(r'[\w.-]+\.(?:exe|dll|so|dylib|a|lib|dylib)');
  for (final match in pattern.allMatches(clause)) {
    yield match.group(0)!.toLowerCase();
  }
}

/// Digest algorithms that cannot produce a 64-character hex value, spelled as
/// the token forms a method line can carry (`SHA-1`, `sha1`, `MD5`, `crc32`).
///
/// SHA-224, SHA-384, and SHA-512 are here for a second reason than MD5: they
/// are digests at all, but they emit 56, 96, and 128 hex characters
/// respectively, so naming one contradicts the width every recorded value was
/// just validated to have.
const Set<String> _kNonSha256Algorithms = <String>{
  'md5',
  'sha1',
  'sha224',
  'sha384',
  'sha512',
  'crc32',
  'crc32c',
  'adler32',
  'xxhash',
  'murmur',
  'fnv',
  'djb2',
};

/// A `toolchain_versions` line, split into the tool it names and the version it
/// states for it.
final class _ToolchainLine {
  const _ToolchainLine(this.name, this.version);

  final String name;
  final String version;
}

_ToolchainLine? _readToolchainLine(String line) {
  final tokens = line
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  final name = <String>[];
  for (final raw in tokens) {
    final token = raw.replaceAll(RegExp(r'^[^0-9A-Za-z]+|[^0-9A-Za-z]+$'), '');
    if (token.isEmpty) continue;
    // The first token carrying a digit ends the name. A bare integer (`2026`,
    // `10`) or a date-shaped token (`2026-07-08`) is the product year or the
    // build date, so it ends the name without ever being a version.
    if (RegExp(r'[0-9]').hasMatch(token)) break;
    name.add(token.toLowerCase());
  }
  if (name.isEmpty) return null;
  // The first DOTTED number after the name is the tool's own version; the ones
  // after it are its qualifiers (`18.9.0 version 18.9.12105.275` states the
  // tool at one precision and the installed build at another). A line with no
  // dotted number at all states no version.
  final version = tokens
      .map(
        (raw) => raw.replaceAll(RegExp(r'^[^0-9A-Za-z]+|[^0-9A-Za-z]+$'), ''),
      )
      .firstWhere(
        (token) => RegExp(r'^\d+(\.\d+)+$').hasMatch(token),
        orElse: () => '',
      );
  if (version.isEmpty) return null;
  return _ToolchainLine(name.join(' '), version);
}

/// Whether two spellings of a version say the same number.
///
/// `18.9` and `18.9.0` are one version written twice. Compared component by
/// component rather than as text, so `18.9` is a prefix of `18.9.0` without
/// `18` and `180` matching.
bool _sameVersion(String left, String right) {
  if (left == right) return true;
  return left.startsWith('$right.') || right.startsWith('$left.');
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
    final statedMethod = method;
    if (statedMethod == null || statedMethod.trim().isEmpty) return false;
    // Sprint 117.43-22 (fail-open, fixed): the only test on `method` was "is it
    // blank?". Everything else this getter checks about the two rebuilds is
    // about the digests themselves — that each one is exactly 64 hex characters,
    // that the verdict matches what they show — while `method` is the sentence
    // that says HOW those digests were produced, and nothing ever read it. A
    // comparison performed with MD5, SHA-1, or CRC-32 cannot produce 64-hex
    // values, so such a method contradicts every digest the same document
    // records, yet `missingEvidence` returned no missing group, `evaluate`
    // returned `pass`, and the gate printed `artifact_comparison:
    // NOT_BIT_IDENTICAL (6 artifact)` as though the hashing had been checked.
    //
    // The rule is narrow on purpose, for the reason 117.43-11 is narrow: a
    // method that names NO algorithm (`cold rebuilds, cache dropped`) makes no
    // algorithm claim and is left alone, exactly as a line that only mentions
    // an algorithm without naming it as the one used makes no claim. What is
    // refused is the affirmative claim of an algorithm whose output width is not
    // the 64 characters every recorded digest was just validated to be.
    if (_namesOtherDigestAlgorithm(statedMethod)) return false;
    if (rebuildA == null || rebuildB == null) return false;
    if (!rebuildA!.isWellFormed || !rebuildB!.isWellFormed) return false;
    if (verdict == null) return false;
    final keysA = rebuildA!.artifactHashes.keys.toSet();
    final keysB = rebuildB!.artifactHashes.keys.toSet();
    final sameKeys = keysA.length == keysB.length && keysA.containsAll(keysB);
    if (!sameKeys) return false;
    // Sprint 117.43-24 (fail-open, fixed): 117.43-22 read this same `method`
    // sentence for the ALGORITHM that produced the digests and left the rest of
    // it unread. But `method` also states the SCOPE of the comparison — the
    // shipped document says "SHA-256 over the 6 exe/dll artifacts" and then
    // enumerates six names — and a count or a name the recorded digests do not
    // support means the comparison was never performed over what it claims.
    // Nothing below compares the scope, so a document recording six digests
    // under a method claiming four (or naming a seventh artifact no rebuild
    // hashed) reported no missing group, `evaluate` returned `pass`, and the
    // gate printed `artifact_comparison: ... (6 artifact)` as though the
    // coverage had been checked.
    //
    // Narrow for the same reason 117.43-22 and 117.43-23 are narrow. A sentence
    // that states no count and enumerates nothing makes no scope claim and is
    // left alone. An enumeration that illustrates rather than exhausts claims no
    // completeness, so an artifact the records hold but the sentence does not
    // name is not a defect — requiring the list to be complete would invent an
    // acceptance criterion the evidence never stated, the very overclaim this
    // gate exists to refuse. What is refused is the affirmative claim: a total
    // the recorded inventory does not match, and a named artifact that no
    // rebuild in this same comparison ever hashed.
    final scope = _statedArtifactScope(statedMethod);
    if (scope != null) {
      final recorded = keysA;
      if (scope.count != null && scope.count != recorded.length) return false;
      if (scope.names != null && !recorded.containsAll(scope.names!)) {
        return false;
      }
    }
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
    if (!_digestsAgreeWithinGroup(evidence.buildInputs)) {
      missing.add('build_inputs');
    }
    if (!_hasContent(evidence.toolchainVersions)) {
      missing.add('toolchain_versions');
    }
    if (!_toolVersionsAgree(evidence.toolchainVersions)) {
      missing.add('toolchain_versions');
    }
    if (!_hasContent(evidence.dependencyLock)) missing.add('dependency_lock');
    if (!_hasWellFormedDigestClaims(evidence.dependencyLock)) {
      missing.add('dependency_lock');
    }
    if (!_digestsAgreeWithinGroup(evidence.dependencyLock)) {
      missing.add('dependency_lock');
    }
    if (!_restatedDigestsAgree(evidence)) {
      missing.add('dependency_lock');
      missing.add('build_inputs');
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
    // Sprint 117.43-25 (unmeasured-claim, fixed): a `signed_candidate <path>`
    // line is the second restatement this group could not reach. Unlike
    // `rebuild_*` and `provenance_logs`, it restates no number — it names a
    // shipped document and asserts it was verified — and nothing in `lib/` ever
    // opened the path it cites. 117.43-10 made a rebuild's own `log` readable
    // and 117.43-15 made the `provenance_logs` summary match it, so a document
    // whose log citations name nothing was already refused; the one remaining
    // citation shape had no reader at all, and the gate published
    // `provenance_evaluation: pass` for a document asserting a checksum file
    // was verified intact while that citation named a tree nothing could open.
    //
    // The scope is deliberately narrow, mirroring what is already measured:
    // reachability only, never the digest. Re-hashing the cited file against
    // the record would invent an acceptance the evidence never stated — the
    // same overclaim 117.43-11 refused when it declined to re-hash a stated
    // digest against the working tree. The shipped citation names a file this
    // tree can open, so the check agrees with what ships; a citation naming
    // anything else is evidence about nothing and fails closed.
    for (final line in lines) {
      if (!_citationIsReadable(line)) return false;
    }
    // The reverse direction is deliberately NOT required. Nothing in the
    // document promises that every rebuild is restated in prose, and the
    // shipped fixtures restate none of them — requiring it would invent an
    // acceptance criterion the evidence never stated, which is the same
    // overclaim this gate exists to refuse. Only lines that ARE written are
    // held to agree.
    return true;
  }

  /// Whether a `signed_candidate <path>` line cites a document this tree can
  /// open, or states no citation at all.
  ///
  /// Sprint 117.43-25: only the shipped citation grammar is read. A line that
  /// names no document — including a `signed_candidate` line whose path is
  /// blank — makes no claim, the same non-claim rule 117.43-07 settled for an
  /// absent verdict. Nothing is required about how many such lines there are,
  /// or about the rest of the line: the reachability of the cited path is the
  /// whole claim, and measuring anything else would demand an acceptance
  /// criterion the document never stated.
  static bool _citationIsReadable(String line) {
    final citation = _parseCitation(line.trim());
    if (citation == null) return true;
    return File(citation).existsSync();
  }

  /// The path one `signed_candidate` line cites, or null when [line] is not
  /// that shape or states no path.
  static String? _parseCitation(String line) {
    if (!line.startsWith(_kCitationPrefix)) return null;
    final path = line.substring(_kCitationPrefix.length).trim();
    if (path.isEmpty) return null;
    // A citation names one document. Stop at the first whitespace so a line
    // that goes on to state an algorithm and an outcome is read for the path
    // alone, exactly as `provenance_logs` reads its own trailing prose.
    final token = path.split(RegExp(r'\s+')).first;
    return token.isEmpty ? null : token;
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

  /// Whether the versions one tool is given in two lines agree.
  ///
  /// Sprint 117.43-23 (fail-open, fixed). `toolchain_versions` was read by
  /// `_hasContent` alone — the group was checked for holding non-blank strings
  /// and nothing else — then the verdict printed `toolchain_versions: N item`
  /// as though N versions had been compared against anything. It is the one
  /// group that says WHICH SDK produced the build, and the comparison's own
  /// method rests on "the same tree and machine" while its limits explicitly
  /// disclaim cross-SDK reproducibility, so a document naming the same tool
  /// under two different versions contradicts the claim the whole step makes.
  ///
  /// This is the cross-line counterpart to 117.43-21, which held one path's
  /// digest to the same value in two groups: the same kind of restatement, at
  /// the same layer, one axis further out.
  ///
  /// Bounds, all pinned by the 117.43-23 test:
  ///
  ///  * a line stating NO dotted version makes no version claim — a pinned
  ///    engine revision and a prose host line are left alone (117.43-07);
  ///  * a tool named by only ONE line has nothing to contradict;
  ///  * a bare integer (`2026`) and a date-shaped token (`2026-07-08`) are the
  ///    product year and the build date, never the version, so they are read
  ///    as the end of the name rather than as a second version;
  ///  * less precise and more precise spellings of ONE version
  ///    (`18.9` beside `18.9.0`) are the same version, so a document that
  ///    states a tool once in detail and once tersely stays honest;
  ///  * nothing is required about WHICH tools a document chooses to record, or
  ///    how many.
  static bool _toolVersionsAgree(List<String>? lines) {
    if (lines == null) return true;
    final claims = <_ToolchainLine>[];
    for (final line in lines) {
      final parsed = _readToolchainLine(line);
      if (parsed != null) claims.add(parsed);
    }
    // Group by tool NAME, then refuse a tool whose lines cannot all be told
    // the same version. The rule is pairwise because one line can carry
    // several numbers — `18.9.0 version 18.9.12105.275` states the tool at one
    // precision and the installed build at another — and only the FIRST dotted
    // number of a line is read as the version, so a document that records a
    // tool in detail on one line and tersely on the next stays honest. What is
    // refused is a document that names the same tool under two versions that
    // differ in a component both spell out.
    for (var i = 0; i < claims.length; i++) {
      for (var j = i + 1; j < claims.length; j++) {
        final left = claims[i];
        final right = claims[j];
        if (left.name != right.name) continue;
        if (!_sameVersion(left.version, right.version)) return false;
      }
    }
    return true;
  }

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

  /// The digest every group claims for one path, when the claim parses.
  ///
  /// The shipped document states `pubspec.lock sha256 <hex>` in BOTH
  /// `build_inputs` and `dependency_lock`, so the same file is hashed twice
  /// and stated twice. A line that carries a `sha256` value names a path and
  /// the digest recorded for it; a line that only mentions the algorithm
  /// (`hosted dependencies hash-pinned sha256; 0 git/path source`) states
  /// nothing and is skipped here exactly as 117.43-11 skips it.
  static Map<String, String>? _digestsByPath(List<String>? items) {
    if (items == null) return null;
    final declared = <String, String>{};
    final claim = RegExp(
      r'^(\S+)\s+sha-?256\s+(\S+)\s*$',
      caseSensitive: false,
    );
    for (final item in items) {
      final match = claim.firstMatch(item.trim());
      // Not a path-plus-digest claim: prose, or a line already refused by
      // `_hasWellFormedDigestClaims`. Neither is a restatement to compare.
      if (match == null) continue;
      // A half-written claim was already reported missing; do not invent a
      // second, different reason for the same defect here.
      if (!_digestPattern.hasMatch(match.group(2)!)) continue;
      declared[match.group(1)!] = match.group(2)!;
    }
    return declared;
  }

  /// Whether one group ever gives the same path two different digests.
  ///
  /// Sprint 117.43-26 (fail-open, fixed). 117.43-21 held a path hashed in two
  /// DIFFERENT groups to one value, but it compared the groups by parsing each
  /// into a `Map<String, String>` — and that map cannot hold a contradiction:
  /// `_digestsByPath` assigns `declared[path] = digest`, so a second line
  /// naming the same path silently overwrites the first (last wins). A document
  /// that stated one path twice inside `build_inputs` with two different
  /// digests therefore had one of them discarded before anything compared them,
  /// and the gate reported no missing evidence and evaluated to `pass` while
  /// printing `build_inputs: 5 item` as though five mutually consistent files
  /// had been hashed. Proven before the fix: `windows/CMakeLists.txt` — a path
  /// the shipped document names in `build_inputs` and NOWHERE ELSE, so
  /// 117.43-21's cross-group reader had nothing to compare it against — stated
  /// twice with different digests, `pass`.
  ///
  /// This is the intra-group counterpart to 117.43-21, and it is what makes
  /// that rule sound: a restatement whose copies are already allowed to
  /// disagree with each other cannot be evidence of agreement. A build's
  /// recorded inputs cannot change under a single evaluation, whichever
  /// direction the restatement is read in.
  ///
  /// Bounds, so the rule does not over-refuse:
  ///
  ///  * the SAME path restated with the SAME digest is an idempotent
  ///    restatement — a document may repeat itself, and no value is claimed
  ///    about how many times a path may appear;
  ///  * a line that merely mentions the algorithm states no digest and is not a
  ///    claim (117.43-07, 117.43-11), so prose cannot contradict a digest;
  ///  * a half-written digest is already reported missing by
  ///    `_hasWellFormedDigestClaims`; inventing a second reason for the same
  ///    defect here would misattribute it;
  ///  * a reachable path cannot rescue failing evidence.
  static bool _digestsAgreeWithinGroup(List<String>? items) {
    if (items == null) return true;
    final declared = <String, String>{};
    for (final item in items) {
      for (final claim in _digestClaimsIn(item)) {
        final path = claim.key;
        final digest = claim.value;
        final first = declared.putIfAbsent(path, () => digest);
        if (first != digest) return false;
      }
    }
    return true;
  }

  /// Every `<path> sha256 <digest>` claim a line states, in order.
  ///
  /// Sprint 117.43-27 (fail-open, fixed). The reader this replaces matched
  /// `^(\S+)\s+sha-?256\s+(\S+)\s*$` with `firstMatch`, which is anchored at
  /// BOTH ends and therefore describes exactly ONE claim per line. The rule
  /// built on it could compare one path to one digest per line, so a line
  /// stating the claim twice — `windows/CMakeLists.txt sha256 <a> sha256 <b>` —
  /// did not merely go uncompared: the anchored pattern found no match at all,
  /// so the line was skipped exactly as prose is skipped and reached the
  /// verdict as though it had stated nothing. Proven before the fix: that one
  /// line reported `provenance_evaluation: pass`, while the two-LINE form of
  /// the same contradiction was already refused by 117.43-26 — the rule could
  /// only ever fire on the shape the shipped document happens to use.
  ///
  /// So a line is read as a sequence of claims rather than one claim. A marker
  /// token introduces the digest that follows it, and the path is the token
  /// before the marker — UNLESS that token is itself a well-formed digest, in
  /// which case it was the PREVIOUS claim's digest and the marker restates
  /// that same path, which is precisely the shape 117.43-26 refused across two
  /// lines and this one refuses across two positions in one.
  ///
  /// Bounds, so nothing beyond the defect is refused:
  ///
  ///  * `a.cpp sha256 <a> b.cpp sha256 <b>` states two DIFFERENT paths and is
  ///    two claims, not a contradiction — the plain token between the digests
  ///    is read as the next path, exactly as one claim per line read it before;
  ///  * a marker naming the algorithm without a value supplies no digest and
  ///    stays a non-claim (117.43-07, 117.43-11), which is what keeps the
  ///    shipped `dependency_lock` prose and the 117.43-26 prose control
  ///    honest — `sha256;` and `sha256` without a following digest are markers
  ///    with nothing to claim;
  ///  * a half-written digest is already reported by
  ///    `_hasWellFormedDigestClaims`; this reader skips it rather than
  ///    inventing a second reason for the same defect (117.43-26);
  ///  * the SAME digest restated stays an idempotent restatement.
  static List<MapEntry<String, String>> _digestClaimsIn(String line) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    final claims = <MapEntry<String, String>>[];
    String? pendingPath;
    for (var i = 0; i < tokens.length; i++) {
      if (!_digestMarkerPattern.hasMatch(tokens[i])) {
        pendingPath = tokens[i];
        continue;
      }
      if (i + 1 >= tokens.length || !_digestPattern.hasMatch(tokens[i + 1])) {
        // Names the algorithm, states no digest (117.43-07, 117.43-11).
        continue;
      }
      // The token before this marker is the path it introduces, unless that
      // token is itself a digest — then it was the previous claim's digest and
      // this marker restates that claim's path.
      final preceding = i >= 1 ? tokens[i - 1] : null;
      final path = preceding != null && !_digestPattern.hasMatch(preceding)
          ? preceding
          : pendingPath;
      if (path == null) continue;
      final digest = tokens[i + 1];
      claims.add(MapEntry<String, String>(path, digest));
      pendingPath = path;
      i++;
    }
    return claims;
  }

  /// The token that introduces a digest: `sha256`, `SHA-256`, `sha 256` is not
  /// a marker — the shipped grammar always writes the algorithm as one token.
  static final RegExp _digestMarkerPattern = RegExp(
    r'^sha-?256$',
    caseSensitive: false,
  );

  /// Whether the digests one path is given in two different groups agree.
  ///
  /// Sprint 117.43-21 (fail-open, fixed). 117.43-11 taught this layer to
  /// insist that a line naming a digest carries a real one, but it checked each
  /// group in isolation: `_hasWellFormedDigestClaims` asks "is this 64 hex?",
  /// and nothing ever asked whether the two groups agree with EACH OTHER. The
  /// shipped 113.39 document states `pubspec.lock sha256 <hex>` twice — once
  /// in `build_inputs`, once in `dependency_lock` — and a document that gave
  /// that one file two different digests passed both checks and returned
  /// `pass`, while the gate printed `dependency_lock: 2 item` as though the
  /// lock had been verified twice. Proven before the fix: two well-formed
  /// 64-hex digests for the same path, one in each group, disagreeing with
  /// each other, reported no missing evidence and evaluated to `pass`.
  ///
  /// This is the cross-group counterpart to 117.43-15, which held the summary
  /// lines in `provenance_record` to agree with the rebuild records they
  /// restate. A path hashed in two groups is the same kind of restatement, at
  /// the same layer, and a build's recorded inputs cannot change under a
  /// single evaluation.
  ///
  /// Bounds, all pinned by test:
  ///
  ///  * a path named by only ONE group has nothing to contradict;
  ///  * a line that merely mentions the algorithm states no digest and is not
  ///    a restatement (117.43-07, 117.43-11);
  ///  * a group that is absent states nothing and cannot contradict the other;
  ///  * nothing is required about WHICH paths a document chooses to restate.
  static bool _restatedDigestsAgree(BuildProvenanceEvidence evidence) {
    final fromInputs = _digestsByPath(evidence.buildInputs);
    final fromLock = _digestsByPath(evidence.dependencyLock);
    if (fromInputs == null || fromLock == null) return true;
    for (final entry in fromInputs.entries) {
      final restated = fromLock[entry.key];
      if (restated != null && restated != entry.value) return false;
    }
    return true;
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
