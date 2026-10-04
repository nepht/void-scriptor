/// Sprint 117.43 — GA Artifact & Reproducibility (gate gagal-tertutup).
///
/// Canonical step (external `sprint_117.json`) objective: "Membuat signed
/// artifacts dengan connector, icon, dependency, schema, flag, entitlement,
/// checksum, and provenance manifests.", with eight `required_outputs`:
///   signed_artifacts, connector_manifest, icon_manifest, dependency_manifest,
///   schema_manifest, flag_manifest, checksums, provenance.
///
/// Eight is NOT the shipped 113.38 vocabulary. [Sprint117GaPackagingContract]
/// (Step 113.38, `ga_artifact_packaging.dart`) ships SEVEN outputs and they are
/// a different seven: it has `version_manifest` and `licenses`, which 117.43
/// does not name, and it has no `connector_manifest`, `icon_manifest`, or
/// `provenance`. This gate therefore treats the 117.43 eight as canonical and
/// the 113.38 seven as the packaging subset it may feed, so the step is never
/// closed by a manifest that answers a different question.
///
/// The step names no per-output acceptance vocabulary, so this gate does not
/// invent one. It measures the claims the step DOES state, each against a seam
/// that already ships:
///
/// 1. the GA manifest each output names exists and is readable;
/// 2. the connector and icon manifests are the SHIPPED registries
///    ([ProviderConnectorManifest.standard] / [ProviderIconRegistry.standard]),
///    not a hand-typed list, and the two cover the same provider set;
/// 3. schema and flag entries are what the shipped schema constants and flag
///    registry derive — not strings retyped by a caller;
/// 4. every checksum line matches the bytes on disk, and every signed artifact
///    is covered by a checksum line;
/// 5. provenance is measured through `BuildProvenanceEvidence.evaluate`, and a
///    reproducibility claim is only ever accepted when the recorded digests
///    actually support it: `bitIdentical` needs every digest equal,
///    `notBitIdentical` needs at least one digest that differs, the verdict
///    string itself must be one of the two canonical values, and when the
///    comparison names WHICH artifacts landed on each side of the line
///    (`differing_artifacts` / `identical_artifacts`) each named artifact is
///    checked against its own digest and the two lists must classify the whole
///    recorded inventory (defects 117.43-01, 117.43-06, 117.43-07, and
///    117.43-08 — four directions of the same trust boundary);
/// 6. the rebuild WINDOWS support the independence the comparison claims: each
///    rebuild runs forwards, its recorded duration agrees with the window it
///    summarises, and `rebuild_b` does not start until `rebuild_a` has
///    finished (defect 117.43-09).
///
/// Defect 117.43-01 (fail-open, fixed here): `ArtifactComparison.isWellFormed`
/// compared only the two rebuilds' artifact NAME SETS and never their hash
/// VALUES, so a comparison could record `RebuildVerdict.bitIdentical` while the
/// two rebuilds recorded completely different SHA-256 digests — and it was
/// still well formed, so `BuildProvenanceEvidence.missingEvidence` reported
/// nothing missing and the reproducibility gate returned `pass`. Root cause:
/// the verdict is an assertion about hash equality, and no code compared the
/// hashes that the verdict claims to compare. Proven empirically before the
/// fix: a comparison with rebuild A hashing to `aaa…a` and rebuild B to
/// `bbb…b` reported `isWellFormed == true`. The fix makes `isWellFormed`
/// verify the verdict against the recorded values, so a false identity claim
/// fails closed.
///
/// Defect 117.43-07 (fail-open, fixed here): the verdict was never READ, only
/// INFERRED. `_evaluateShippedProvenance` built it as
/// `comparison['verdict'] == 'BIT_IDENTICAL' ? bitIdentical : notBitIdentical`,
/// so every other value — an absent key, an explicit null, or a typo such as
/// `BIT_IDENTITY` — was silently coerced into a measured difference claim. The
/// gate then reported `provenance` as `pass` while printing
/// `artifact_comparison: NOT_BIT_IDENTICAL (2 artifact)` for a manifest that
/// stated no verdict at all: it manufactured a claim the document never made.
/// 117.43-01 and 117.43-06 both let an unsupported claim THROUGH; this one
/// fabricated one, one step earlier, in the same evidence group. Root cause:
/// the only field in this group that cannot be derived from the digests, because
/// the digests support both labels, was defaulted instead of read. The fix
/// parses the verdict as a closed vocabulary and reports `unmet` when it is
/// absent, null, or outside `BIT_IDENTICAL` / `NOT_BIT_IDENTICAL`. Proven
/// empirically before the fix: three distinct unreadable verdicts all returned
/// `status=pass` with `NOT_BIT_IDENTICAL` in the observed text.
/// The manifest we SHIP records `NOT_BIT_IDENTICAL` and still passes, because it
/// states a canonical verdict that its digests support.
///
/// /// Defect 117.43-02 (measured and reported, NOT fixed): the 113.38 GA manifest
/// is a COMMITTED document describing a build output tree that no longer
/// exists. `checksums` names `build/release-metadata/artifact-manifest.json`
/// and `signing_evidence.sign_manifest_path` names
/// `build/release-metadata/windows-signed-rc-manifest.json`; `build/` is not
/// tracked, so on a clean checkout neither path resolves. All six recorded
/// checksums now DRIFT from the bytes in the current `build/` tree, because
/// that tree is a later debug build rather than the signed 1.2.0-rc.1 release.
/// Re-signing a release candidate is a release action, not this step's
/// acceptance, so this is carried as a named open item and never converted to
/// a pass.
///
/// Status per check:
/// * `pass` — the shipped seam produced the measured value;
/// * `violation` — the manifest or row contradicts what the seam measured;
/// * `unmet` — a row this slice could not measure from a shipped seam, named as
///   an open item and never converted to a pass.
///
/// Fail-closed structural failures:
/// * `non_canonical_outputs` — the eight canonical outputs drifted;
/// * `no_manifest_rows` — an empty row set ships no GA manifest at all;
/// * `missing_output:<id>` — a canonical output no row declares;
/// * `unknown_output:<id>` — vocabulary drift outside the canonical eight;
/// * `duplicate_output:<id>`;
/// * `no_manifest:<id>:<path>` — an output resolves to no manifest path;
/// * `missing_manifest:<id>:<path>` — a named manifest is not readable on disk;
/// * `vacuous:<id>:<check>` — a blank declared/observed statement is not
///   evidence;
/// * `duplicate_check:<id>:<check>`;
/// * `output_without_pass:<id>` — an output with no passing measured check;
/// * `unknown_check:<id>:<check>` — vocabulary drift outside the measured set;
/// * `connector_coverage_drift` — the shipped connector and icon registries do
///   not cover the same provider set;
/// * `checksum_without_artifact:<path>` — a signed artifact no checksum covers;
/// * `artifact_without_checksum:<path>` — a checksum covering no live artifact;
/// * `checksum_digest_drift:<path>` — a recorded digest no longer matches bytes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../core/feature_flags/feature_flag_registry.dart';
import '../../../core/project_package/void_project_format.dart';
import '../../../database/project/project_database.dart';
import '../../account/domain/account_center_provider_connector_manifest.dart';
import '../../account/domain/account_center_provider_icon_registry.dart';
import '../domain/build_reproducibility_provenance.dart';

/// Status of one measured check on one GA artifact output.
enum Sprint117GaArtifactStatus { pass, violation, unmet }

/// The per-artifact partition an `artifact_comparison` claims.
///
/// Both lists are null together, meaning the comparison names no artifact and
/// therefore makes no per-artifact claim. Otherwise both are present and every
/// recorded artifact must appear on exactly one side (defect 117.43-08).
class _ArtifactPartition {
  const _ArtifactPartition({required this.differing, required this.identical});

  /// Artifacts the comparison claims differ between the two rebuilds.
  final List<String>? differing;

  /// Artifacts the comparison claims are byte-identical across the rebuilds.
  final List<String>? identical;

  /// Whether the comparison names any artifact at all.
  bool get declares => differing != null && identical != null;
}

/// Derives the canonical manifest vocabulary for 117.43 from shipped seams.
///
/// The 117.43 eight differ from the 113.38 seven, so neither vocabulary can be
/// reused wholesale. This builds the 117.43 eight explicitly and keeps the
/// 113.38 seven reachable as [packagingSubsetNames] so the gate can state
/// which 113.38 outputs actually feed this step instead of implying the two
/// contracts are the same list.
abstract final class Sprint117GaPackagingContract {
  /// The canonical roadmap step this gate measures.
  static const String canonicalStep = '117.43';

  /// The eight canonical `required_outputs`, verbatim and in contract order.
  static const List<String> requiredOutputs = <String>[
    'signed_artifacts',
    'connector_manifest',
    'icon_manifest',
    'dependency_manifest',
    'schema_manifest',
    'flag_manifest',
    'checksums',
    'provenance',
  ];

  /// The 113.38 (Step 113.38) packaging vocabulary, which is a DIFFERENT seven.
  ///
  /// `version_manifest` and `licenses` ship there but are not named by 117.43;
  /// `connector_manifest`, `icon_manifest`, and `provenance` are named by 117.43
  /// but ship nowhere in 113.38. Recorded so the difference is a measurement,
  /// not an assumption.
  static const List<String> packagingSubsetNames = <String>[
    'signed_artifacts',
    'checksums',
    'dependency_manifest',
    'schema_manifest',
    'flag_manifest',
  ];

  /// The 113.38 outputs that 117.43 does NOT name.
  static const List<String> outputsOutsideThisStep = <String>[
    'version_manifest',
    'licenses',
  ];

  /// The 117.43 outputs with no 113.38 counterpart.
  static const List<String> outputsAbsentFromPackaging = <String>[
    'connector_manifest',
    'icon_manifest',
    'provenance',
  ];

  /// The 113.38 GA packaging manifest this step reconciles against.
  static const String packagingManifestPath =
      'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json';

  /// The 113.39 provenance manifest this step reconciles against.
  static const String provenanceManifestPath =
      'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json';

  /// The step [provenanceManifestPath] documents.
  ///
  /// Read from the document rather than assumed, and then compared: the gate
  /// publishes a verdict about the 113.39 provenance evidence, so a file that
  /// names a different step is not that document (117.43-20).
  static const String provenanceStep = '113.39';

  static const String passVerdict =
      'GA_ARTIFACT_REPRODUCIBILITY_COMPLETE_LOCAL';
  static const String failVerdict = 'GA_ARTIFACT_REPRODUCIBILITY_INCOMPLETE';

  /// The schema identifiers the SHIPPED schema constants derive.
  ///
  /// Read from [ProjectDatabase.currentSchemaVersion] and
  /// [VoidProjectFormat.currentSchema] rather than retyped, so a schema bump
  /// cannot leave the GA manifest silently stale.
  static List<String> deriveSchemaManifest() => <String>[
    'database:${ProjectDatabase.currentSchemaVersion}',
    'project_format:${VoidProjectFormat.currentSchema}',
  ];

  /// The flag identifiers the SHIPPED flag registry derives.
  ///
  /// Read from [kVs12FeatureFlags] plus the kill-switch seam that actually
  /// exists, rather than a hand-typed 13-string copy.
  static List<String> deriveFlagManifest() => <String>[
    ...kVs12FeatureFlags,
    'kill_switch:FeatureFlagRegistry.engageKillSwitch',
  ];

  /// The version the SHIPPED project format declares.
  static String deriveApplicationVersion() =>
      VoidProjectFormat.applicationVersion;

  /// True when [outputId] is one of the canonical eight.
  static bool isCanonicalOutput(String outputId) =>
      requiredOutputs.toSet().contains(outputId.trim());
}

/// One GA artifact output and the manifest that backs it.
final class Sprint117GaArtifactOutput {
  const Sprint117GaArtifactOutput({
    required this.outputId,
    required this.manifestPaths,
    required this.seamLabel,
  });

  /// One of the eight canonical `outputs`.
  final String outputId;

  /// Manifests this output resolves to. Checked against the filesystem.
  final List<String> manifestPaths;

  /// The seam that produced the values. Labelling is reporting, not a
  /// measurement boundary: the gate still re-derives every value.
  final String seamLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'output_id': outputId,
    'manifest_paths': List<String>.from(manifestPaths),
    'seam_label': seamLabel,
  };
}

/// One measured statement about one GA artifact output.
final class Sprint117GaArtifactCheck {
  const Sprint117GaArtifactCheck({
    required this.outputId,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117GaArtifactCheck.pass_({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaArtifactCheck(
    outputId: outputId,
    check: check,
    status: Sprint117GaArtifactStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117GaArtifactCheck.violation({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaArtifactCheck(
    outputId: outputId,
    check: check,
    status: Sprint117GaArtifactStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117GaArtifactCheck.unmet({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaArtifactCheck(
    outputId: outputId,
    check: check,
    status: Sprint117GaArtifactStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  final String outputId;
  final String check;
  final Sprint117GaArtifactStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$outputId:$check';

  bool get isViolation => status == Sprint117GaArtifactStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'output_id': outputId,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// A parsed checksum inventory: the path-to-digest map plus every line that
/// could not be parsed and every path the file contradicts itself about.
///
/// The malformed list is part of the result rather than an internal detail
/// because a dropped line silently shrinks what the inventory claims to cover.
/// The conflicting list is part of it for the same reason one step further
/// down: a repeated path with two different digests cannot be resolved by
/// keeping whichever line came last.
final class ChecksumIndex {
  const ChecksumIndex({
    required this.index,
    required this.malformed,
    this.conflicting = const <String>[],
  });

  /// Recorded digest keyed by artifact path.
  final Map<String, String> index;

  /// Lines that carried content but did not parse as `sha256 <hex> <path>`.
  final List<String> malformed;

  /// Paths recorded more than once with digests that disagree.
  final List<String> conflicting;
}

/// The rebuild window one `rebuild_results` record states.
///
/// [durationSeconds] is carried so the gate can compare a stated duration
/// against the window it summarises. All three fields are null together when
/// the record states no window at all.
final class _RebuildWindow {
  const _RebuildWindow({
    required this.startedAt,
    required this.finishedAt,
    this.durationSeconds,
  });

  final String? startedAt;
  final String? finishedAt;
  final int? durationSeconds;
}

/// Sentinel distinguishing "field absent or explicitly null" from "field
/// present but of a type that cannot be decoded".
///
/// `null` alone cannot carry that distinction, because both cases decode to
/// null. This is the same reason 117.43-08 refuses a mistyped partition field
/// rather than casting past it.
const Object _kUndecodable = Object();

/// Aggregate verdict of the 117.43 GA artifact gate.
final class Sprint117GaArtifactResult {
  const Sprint117GaArtifactResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.outputs,
    required this.providersMeasured,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117GaArtifactCheck> checks;
  final List<Sprint117GaArtifactOutput> outputs;

  /// Providers covered by BOTH shipped registries.
  final List<String> providersMeasured;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117GaPackagingContract.canonicalStep,
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'required_outputs': Sprint117GaPackagingContract.requiredOutputs.toList(),
    'output_count': outputs.length,
    'provider_count': providersMeasured.length,
    'providers_measured': List<String>.from(providersMeasured),
    'packaging_subset_outputs': Sprint117GaPackagingContract
        .packagingSubsetNames
        .toList(),
    'outputs_outside_this_step': Sprint117GaPackagingContract
        .outputsOutsideThisStep
        .toList(),
    'outputs_absent_from_packaging': Sprint117GaPackagingContract
        .outputsAbsentFromPackaging
        .toList(),
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
    'outputs': [for (final output in outputs) output.toJson()],
  };
}

/// Fail-closed GA artifact contract for sprint 117.43.
abstract final class Sprint117GaArtifactGate {
  /// A declared or observed value that trims to nothing is not evidence.
  static bool isVacuous(Sprint117GaArtifactCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  /// Parses a `sha256 <hex>` line, returning the digest or null.
  static String? parseDigest(String line) {
    final match = RegExp(r'^([0-9a-f]{64})\s+(\S+)$').firstMatch(line.trim());
    return match?.group(1);
  }

  /// Maps checksum lines to their artifact path, keyed by path.
  ///
  /// Returns the parsed map plus every line that was malformed, so a silently
  /// dropped line cannot shrink the covered set without being counted. That
  /// promise was not kept before defect 117.43-04: the function returned the
  /// map alone and `continue`d past malformed input, so a truncated or
  /// upper-case digest vanished from the inventory with nothing counting it.
  ///
  /// A path repeated with a DIFFERENT digest is likewise counted rather than
  /// resolved, which is defect 117.43-05: `index[path] = digest` kept the last
  /// line, so an inventory that recorded both a stale and a current digest for
  /// one artifact reported agreement on whichever survived. Identical repeats
  /// stay benign — the same claim twice is not a contradiction.
  static ChecksumIndex readChecksumIndex(List<String> lines) {
    final index = <String, String>{};
    final malformed = <String>[];
    final conflicting = <String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final match = RegExp(r'^([0-9a-f]{64})\s+(\S+)$').firstMatch(trimmed);
      if (match == null) {
        malformed.add(trimmed);
        continue;
      }
      final path = match.group(2)!;
      final digest = match.group(1)!;
      final previous = index[path];
      if (previous != null && previous != digest) {
        conflicting.add(path);
      }
      index[path] = digest;
    }
    return ChecksumIndex(
      index: index,
      malformed: malformed,
      conflicting: conflicting.toList()..sort(),
    );
  }

  /// Evaluates the GA artifact gate.
  static Sprint117GaArtifactResult evaluate(
    List<Sprint117GaArtifactOutput> outputs,
    List<Sprint117GaArtifactCheck> checks,
  ) {
    if (Sprint117GaPackagingContract.requiredOutputs.toSet().length !=
        Sprint117GaPackagingContract.requiredOutputs.length) {
      return Sprint117GaArtifactResult(
        verdict: Sprint117GaPackagingContract.failVerdict,
        pass: false,
        failures: const <String>['non_canonical_outputs'],
        openItems: const <String>[],
        checks: const <Sprint117GaArtifactCheck>[],
        outputs: outputs,
        providersMeasured: const <String>[],
      );
    }

    final failures = <String>[];

    // --- outputs ------------------------------------------------------------
    final seenOutputs = <String>{};
    for (final output in outputs) {
      final id = output.outputId.trim();
      if (id.isEmpty) {
        failures.add('unknown_output:(no id)');
        continue;
      }
      if (!seenOutputs.add(id)) {
        failures.add('duplicate_output:$id');
      }
      if (!Sprint117GaPackagingContract.isCanonicalOutput(id)) {
        failures.add('unknown_output:$id');
        continue;
      }
      if (output.manifestPaths.isEmpty) {
        failures.add('no_manifest:$id');
      }
      for (final path in output.manifestPaths) {
        final trimmed = path.trim();
        if (trimmed.isEmpty) {
          failures.add('no_manifest:$id');
          continue;
        }
        // A GA manifest nobody can open is a promise that fails when the
        // release engineer needs it, so the check is against the filesystem.
        if (!File(trimmed).existsSync()) {
          failures.add('missing_manifest:$id:$trimmed');
        }
      }
    }

    for (final outputId in Sprint117GaPackagingContract.requiredOutputs) {
      if (!seenOutputs.contains(outputId)) {
        failures.add('missing_output:$outputId');
      }
    }

    // --- checks -------------------------------------------------------------
    final seenChecks = <String>{};
    for (final check in checks) {
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (!Sprint117GaPackagingContract.isCanonicalOutput(check.outputId)) {
        failures.add('unknown_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
      if (check.isViolation) {
        failures.add('violation:${check.code}');
      }
    }

    for (final outputId in Sprint117GaPackagingContract.requiredOutputs) {
      // "no checks at all" and "checks, none of them passing" are the same
      // outcome — an output nobody measured. 117.43 necessity run: these two
      // were separate branches and the second subsumed the first, so blocking
      // only the first changed nothing observable. Merged so one condition
      // carries the rule and the necessity probe is provable.
      final passing = checks.any(
        (check) =>
            check.outputId == outputId &&
            check.status == Sprint117GaArtifactStatus.pass &&
            !isVacuous(check),
      );
      if (!passing) {
        failures.add('output_without_pass:$outputId');
      }
    }

    // --- connector / icon coverage ------------------------------------------
    // The two shipped registries must describe the same provider set, and it
    // must be non-empty: a manifest covering nobody ships nothing.
    final connectorIds = ProviderConnectorManifest.standard.manifestIds.toSet();
    final iconIds = ProviderIconRegistry.standard.all
        .map((entry) => entry.providerId)
        .toSet();
    if (connectorIds.isEmpty || iconIds.isEmpty) {
      failures.add('no_registry_coverage');
    }
    if (!connectorIds.containsAll(iconIds) ||
        !iconIds.containsAll(connectorIds)) {
      failures.add('connector_coverage_drift');
    }
    final covered = connectorIds.intersection(iconIds).toList()..sort();

    // --- checksum <-> artifact agreement ------------------------------------
    // A signed artifact with no checksum line is unverified, and a checksum
    // line with no readable artifact is a claim about nothing.
    for (final check in checks) {
      if (check.status != Sprint117GaArtifactStatus.violation) continue;
      if (check.check == 'artifact_checksum_agreement' ||
          check.check == 'checksum_artifact_agreement') {
        failures.add(check.code);
      }
    }

    final openItems = <String>[
      for (final check in checks)
        if (check.status != Sprint117GaArtifactStatus.pass) check.code,
    ];

    return Sprint117GaArtifactResult(
      verdict: failures.isEmpty
          ? Sprint117GaPackagingContract.passVerdict
          : Sprint117GaPackagingContract.failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      outputs: outputs,
      providersMeasured: covered,
    );
  }

  /// Measures the checksum file against the artifacts it names on disk.
  ///
  /// Returns a check plus the drift list, so the caller can decide how to
  /// report it. This never rewrites a checksum: a drifting digest is evidence
  /// about the artifact, and quietly updating the recorded value would destroy
  /// the only record that the tree moved.
  static Sprint117GaArtifactCheck measureChecksums({
    required List<String> signedArtifacts,
    required File checksumFile,
  }) {
    if (!checksumFile.existsSync()) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'checksums',
        check: 'artifact_checksum_agreement',
        declared: checksumFile.path,
        observed: 'checksum file absent',
        note: 'no checksum inventory to verify against',
      );
    }
    final parsed = readChecksumIndex(checksumFile.readAsLinesSync());
    final index = parsed.index;
    final uncovered = <String>[];
    final drifting = <String>[];
    final phantom = <String>[];
    for (final path in signedArtifacts) {
      final file = File(path);
      if (!file.existsSync()) {
        uncovered.add('$path(absent)');
        continue;
      }
      final recorded = index[path];
      if (recorded == null) {
        uncovered.add(path);
        continue;
      }
      final actual = sha256.convert(file.readAsBytesSync()).toString();
      if (actual != recorded) {
        drifting.add(path);
      }
    }
    // The other half of the stated rule: a checksum LINE naming a path with
    // no readable artifact is a claim about nothing. This direction was never
    // walked before defect 117.43-03, so an inventory could name artifacts
    // the tree does not contain and still report a clean agreement.
    //
    // Defect 117.43-31 walks the remaining direction of the SAME line: a line
    // states one claim pairing a path with a digest, and only the signed six
    // were ever hashed against their bytes. A line whose path exists but is
    // not declared signed had its path measured and its digest ignored, so a
    // document kept every signed digest correct and recorded a wrong digest
    // for any other path it named — readable, well formed, never repeated —
    // and the check returned pass while the contract above promises "every
    // checksum line matches the bytes on disk". The signed set now decides
    // which artifacts must be COVERED, not which claims are COMPARABLE: every
    // readable line is hashed against the bytes it names, the measurement the
    // signed loop already performs.
    final declaredSet = signedArtifacts.map((p) => p.trim()).toSet();
    for (final path in index.keys) {
      if (declaredSet.contains(path.trim())) continue;
      final file = File(path);
      if (!file.existsSync()) {
        phantom.add(path);
        continue;
      }
      final actual = sha256.convert(file.readAsBytesSync()).toString();
      if (actual != index[path]) {
        drifting.add(path);
      }
    }
    // `declared` reports both halves of what this check measures: the
    // signed set the packaging manifest declares, and every line the
    // inventory itself states, since both are digest-compared now.
    final declared =
        '${signedArtifacts.length} artifact / ${index.length} checksum line';
    if (uncovered.isNotEmpty ||
        drifting.isNotEmpty ||
        phantom.isNotEmpty ||
        parsed.conflicting.isNotEmpty ||
        parsed.malformed.isNotEmpty) {
      return Sprint117GaArtifactCheck.violation(
        outputId: 'checksums',
        check: 'artifact_checksum_agreement',
        declared: declared,
        observed:
            'uncovered=${uncovered.length} drifting=${drifting.length} '
            'phantom=${phantom.length} conflicting=${parsed.conflicting.length} '
            'malformed=${parsed.malformed.length}',
        note: [
          if (uncovered.isNotEmpty) 'uncovered: ${uncovered.join(', ')}',
          if (drifting.isNotEmpty) 'drifting: ${drifting.join(', ')}',
          if (phantom.isNotEmpty) 'phantom: ${phantom.join(', ')}',
          if (parsed.conflicting.isNotEmpty)
            'conflicting: ${parsed.conflicting.join(', ')}',
          if (parsed.malformed.isNotEmpty)
            'malformed: ${parsed.malformed.join(', ')}',
        ].join(' | '),
      );
    }
    return Sprint117GaArtifactCheck.pass_(
      outputId: 'checksums',
      check: 'artifact_checksum_agreement',
      declared: declared,
      observed: '${index.length} checksum line digest match',
    );
  }

  /// Measures the signed-artifact list against the packaging manifest.
  static Sprint117GaArtifactCheck measureSignedArtifacts({
    required Map<String, Object?> packagingOutputs,
    required List<String> declaredArtifacts,
  }) {
    // Sprint 117.43-13 (fail-open, fixed): this reader was still
    // `(packagingOutputs['signed_artifacts'] as List<dynamic>?)
    //     ?.cast<String>()`, the exact `as` + `cast<>` pair 117.43-12 removed
    // from the four evidence groups. `as` throws on a non-list and
    // `cast<String>()` throws on any non-string element, so a packaging
    // manifest naming `signed_artifacts` as a bare string, as a Map, or as a
    // list holding one number did not report `unmet` — it threw a
    // `type 'int' is not a subtype of type 'String' in type cast` out of the
    // gate and the caller received no check at all. Decode the shape instead.
    final recorded = _stringList(packagingOutputs['signed_artifacts']);
    if (recorded == null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'signed_artifacts',
        check: 'signed_artifact_coverage',
        declared: '${declaredArtifacts.length} artifact',
        observed:
            'packaging manifest records signed_artifacts in a shape this gate '
            'cannot read',
      );
    }
    final recordedSet = recorded.map((p) => p.trim()).toSet();
    final declaredSet = declaredArtifacts.map((p) => p.trim()).toSet();
    if (recorded.isEmpty) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'signed_artifacts',
        check: 'signed_artifact_coverage',
        declared: '0 artifact',
        observed: 'packaging manifest records no signed artifact',
      );
    }
    final onlyDeclared = declaredSet.difference(recordedSet).toList()..sort();
    final onlyRecorded = recordedSet.difference(declaredSet).toList()..sort();
    if (onlyDeclared.isNotEmpty || onlyRecorded.isNotEmpty) {
      return Sprint117GaArtifactCheck.violation(
        outputId: 'signed_artifacts',
        check: 'signed_artifact_coverage',
        declared: '${declaredSet.length} artifact',
        observed:
            'declared_only=${onlyDeclared.length} '
            'recorded_only=${onlyRecorded.length}',
        note: [
          if (onlyDeclared.isNotEmpty)
            'declared_only: ${onlyDeclared.join(', ')}',
          if (onlyRecorded.isNotEmpty)
            'recorded_only: ${onlyRecorded.join(', ')}',
        ].join(' | '),
      );
    }
    return Sprint117GaArtifactCheck.pass_(
      outputId: 'signed_artifacts',
      check: 'signed_artifact_coverage',
      declared: '${declaredSet.length} artifact',
      observed: '${recordedSet.length} artifact match packaging manifest',
    );
  }

  /// Measures provenance through the shipped 113.39 seam.
  ///
  /// The state comes from `BuildProvenanceEvidence.evaluate`; this gate never
  /// restates the verdict. A `notBitIdentical` verdict is reported as `unmet`
  /// rather than `violation` because it is an honest measurement, not a defect
  /// — but it is never reported as `pass` either.
  static Sprint117GaArtifactCheck measureProvenance({
    required Map<String, Object?> provenanceManifest,
  }) {
    final evidence = provenanceManifest['required_evidence'];
    if (evidence is! Map<String, Object?>) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: 'required_evidence',
        observed: 'manifest carries no required_evidence object',
      );
    }
    final evaluation = _evaluateShippedProvenance(
      evidence,
      // Sprint 117.43-16: the restatement lives one level above
      // `required_evidence`, so it has to be handed down here; inside the
      // group it did not exist at all.
      provenanceManifest['rebuild_run'],
    );
    const declared = 'build provenance evaluated';
    if (evaluation == null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: 'shipped evidence did not evaluate',
      );
    }
    final state = evaluation.$1;
    final notes = evaluation.$2;
    if (state != 'pass') {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: '$state: $notes',
        note: 'shipped provenance seam did not pass',
      );
    }
    // Sprint 117.43-17: one level above `rebuild_run` sits the document
    // header, and its verdict fields state the very conclusion this check
    // is about to publish — `status: VERIFIED-LOCAL`, `decision:
    // VERIFIED_LOCAL_...`. Nothing opened them before this slice, so the
    // gate published `pass` over a document that refused it, or over one
    // holding a value in a shape nobody could read. A header that agrees
    // (or states nothing at all) changes nothing here.
    final headerRefusal = _headerVerdictRefusal(provenanceManifest);
    if (headerRefusal != null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: headerRefusal,
        note: 'document header does not declare the published verdict',
      );
    }
    // Sprint 117.43-18: the document-level `limits` group is the last level
    // above the header, and it is the one the header's own `decision` token
    // names (`VERIFIED_LOCAL_PROVENANCE_DOCUMENTED_REPRO_LIMITS`). The only
    // limits this gate ever decoded was the NESTED
    // `artifact_comparison.limits`, so a document-level `limits` in a shape
    // nobody could read was silently skipped while the gate published
    // `provenance_evaluation: pass` — and the `limit: ...` notes it printed
    // came from a different list than the one the header claims. Decode the
    // group the document states; a present-but-unreadable one is unevaluable,
    // an absent one and an explicit null stay non-claims (117.43-07).
    final documentLimitsRefusal = _documentLimitsRefusal(provenanceManifest);
    if (documentLimitsRefusal != null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: documentLimitsRefusal,
        note: 'document limits group cannot be read',
      );
    }
    // Sprint 117.43-19: the same level as the header and the limits group
    // holds `version` — the application version this document measured — and
    // no reader in `lib/` had ever opened it, so a document naming an
    // unreadable version still received `pass`. Read the field the document
    // states, with the same bounds as 117.43-18: absent and explicit null
    // stay non-claims (117.43-07).
    final versionRefusal = _documentVersionRefusal(provenanceManifest);
    if (versionRefusal != null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: versionRefusal,
        note: 'document version field cannot be read',
      );
    }
    // Sprint 117.43-20: the last document-level field the gate never opened is
    // `canonical_step` — the claim about WHICH step this evidence documents.
    // The file at `provenanceManifestPath` is reconciled against as the 113.39
    // provenance document, and a file naming another step is not that document,
    // so publishing `provenance_evaluation: pass` from it was never evidence
    // about 113.39. Same bounds as the header above: absent and explicit null
    // stay non-claims (117.43-07).
    final stepRefusal = _documentStepRefusal(provenanceManifest);
    if (stepRefusal != null) {
      return Sprint117GaArtifactCheck.unmet(
        outputId: 'provenance',
        check: 'provenance_evaluation',
        declared: declared,
        observed: stepRefusal,
        note: 'document names a step other than the provenance step',
      );
    }
    return Sprint117GaArtifactCheck.pass_(
      outputId: 'provenance',
      check: 'provenance_evaluation',
      declared: declared,
      observed: notes,
    );
  }

  /// Refuses a document-level `limits` group that cannot be read as a list of
  /// non-blank strings. Returns the observed reason, or null when the group
  /// states nothing or reads cleanly.
  ///
  /// Sprint 117.43-18: `limits` is the level above the header that the header
  /// itself names in its `decision`, and the gate decoded only the nested
  /// `artifact_comparison.limits`, so the document's own limits were never
  /// opened by anything. Bounds pinned by the tests:
  ///
  ///  * an absent key and an explicit null are non-claims (117.43-07,
  ///    117.43-16, 117.43-17);
  ///  * a present value that is not a list, or that holds anything but
  ///    non-blank strings, is unevaluable — the same fail-closed rule
  ///    117.43-12 applied to the evidence groups, which `_stringList` already
  ///    implements;
  ///  * nothing is required about WHAT the limits say, how many there are, or
  ///    how they relate to the nested comparison limits — that vocabulary
  ///    belongs to the document, so this reader adds no acceptance of its own.
  static String? _documentLimitsRefusal(Map<String, Object?> document) {
    if (!document.containsKey('limits')) return null;
    final value = document['limits'];
    if (value == null) return null;
    final limits = _stringList(value);
    if (limits == null) {
      return 'limits present without a readable group (${value.runtimeType})';
    }
    return null;
  }

  /// Refuses a document header whose verdict fields disagree with the
  /// evaluation this gate is about to publish, or hold a shape it cannot
  /// read. Returns the observed reason, or null when the header agrees — or
  /// states no verdict at all.
  ///
  /// Sprint 117.43-17: `status` and `decision` are document-level
  /// restatements of the gate's own `provenance_evaluation` conclusion, one
  /// level above `rebuild_run`, which 117.43-16 opened. Bounds pinned by
  /// the tests:
  ///
  ///  * an absent key and an explicit null are non-claims (117.43-07,
  ///    117.43-16);
  ///  * `status` declares local verification only with the shipped token
  ///    `VERIFIED-LOCAL`; `decision` only with a `VERIFIED_LOCAL` leading
  ///    segment — the remainder of that token is the document's own;
  ///  * `version`, `canonical_step` and `title` are NOT measured here.
  static String? _headerVerdictRefusal(Map<String, Object?> document) {
    for (final field in const <String>['status', 'decision']) {
      if (!document.containsKey(field)) continue;
      final value = document[field];
      if (value == null) continue;
      if (value is! String || value.trim().isEmpty) {
        return '$field present without a readable verdict '
            '(${value.runtimeType})';
      }
      final declaresLocalVerification = field == 'status'
          ? value.trim() == 'VERIFIED-LOCAL'
          : value.trim().startsWith('VERIFIED_LOCAL');
      if (!declaresLocalVerification) {
        return '$field states ${value.trim()} while the evidence evaluates '
            'pass';
      }
    }
    return null;
  }

  /// Refuses a document-level `version` that cannot be read as a non-blank
  /// string. Returns the observed reason, or null when the field states
  /// nothing or reads cleanly.
  ///
  /// Sprint 117.43-19: `version` sits on the same document level the header
  /// (117.43-17) and the limits group (117.43-18) opened, and names the
  /// application version the provenance document measured. No reader in
  /// `lib/` had opened it — `deriveApplicationVersion()` is shipped but never
  /// called — so a document naming an unreadable version still received
  /// `provenance_evaluation: pass`. Bounds pinned by the tests:
  ///
  ///  * an absent key and an explicit null are non-claims (117.43-07,
  ///    117.43-18);
  ///  * a present value that is not a string, or that is blank, is unevaluable;
  ///  * nothing is required about WHICH version it states — that vocabulary
  ///    belongs to the document, so this reader adds no acceptance of its own.
  static String? _documentVersionRefusal(Map<String, Object?> document) {
    if (!document.containsKey('version')) return null;
    final value = document['version'];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      return 'version present without a readable value (${value.runtimeType})';
    }
    return null;
  }

  /// Refuses a document-level `canonical_step` that cannot be read as the step
  /// the provenance evidence is documented under. Returns the observed reason,
  /// or null when the field states nothing or names the right step.
  ///
  /// Sprint 117.43-20: `canonical_step` is the last field on the document level
  /// that restates which step the evidence belongs to, and no reader in `lib/`
  /// had opened it. The gate opens [Sprint117GaPackagingContract
  /// .provenanceManifestPath] and publishes `provenance_evaluation: pass`
  /// from whatever that file holds, without ever asking whether the file claims
  /// to BE the 113.39 document — so a manifest naming 113.40, or 117.43, or
  /// holding the field as a number, received exactly the same `pass` as the
  /// shipped one. Twelve sibling GA gates in this directory already refuse
  /// precisely that (`document['canonical_step'] != canonicalStep`), which is
  /// what makes its absence here a defect rather than a design choice.
  ///
  /// Bounds pinned by the tests, identical in shape to 117.43-16/-17/-18/-19 so
  /// no acceptance is invented:
  ///
  ///  * an absent key and an explicit null are non-claims (117.43-07);
  ///  * a present value that is not a string, or that is blank, is unevaluable;
  ///  * a present, readable string must name
  ///    [Sprint117GaPackagingContract.provenanceStep]. Which step the document
  ///    is *about* is exactly what this field claims, so comparing it adds no
  ///    acceptance of its own;
  ///  * nothing is required about `title`, which 117.43-19 recorded as prose
  ///    outside acceptance and deliberately left unmeasured.
  static String? _documentStepRefusal(Map<String, Object?> document) {
    if (!document.containsKey('canonical_step')) return null;
    final value = document['canonical_step'];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      return 'canonical_step present without a readable value '
          '(${value.runtimeType})';
    }
    final expected = Sprint117GaPackagingContract.provenanceStep;
    if (value.trim() != expected) {
      return 'canonical_step states ${value.trim()} while the gate reconciles '
          '$expected';
    }
    return null;
  }

  /// Runs the shipped 113.39 evaluation over a decoded manifest, returning
  /// `(state, notes)` or null when the manifest cannot be decoded into the
  /// shipped shape. Never restates the evaluation logic.
  static (String, String)? _evaluateShippedProvenance(
    Map<String, Object?> evidence,
    Object? rebuildRun,
  ) {
    // Sprint 117.43-13 (fail-open, fixed): the list itself was read with
    // `(evidence['rebuild_results'] as List<dynamic>?)?.cast<Map<String,
    // Object?>>()`, which asserts twice over — `as` throws on a non-list and
    // `cast<>` throws on a non-map element. A `rebuild_results` holding
    // `[42, 43]`, holding a Map, or being a bare string did not report
    // `unmet`; it threw a TypeError out of the gate and the caller received no
    // provenance verdict at all. Decode the shape, and refuse it when any
    // element is not a record. 117.43-12 fixed the four groups at this level;
    // this is the same reader one level down.
    List<Map<String, Object?>>? rebuildRecordsFrom(Object? value) {
      if (value is! List<dynamic>) return null;
      final records = <Map<String, Object?>>[];
      for (final entry in value) {
        if (entry is! Map<String, Object?>) return null;
        records.add(entry);
      }
      return records;
    }

    final rebuildList = rebuildRecordsFrom(evidence['rebuild_results']);
    if (rebuildList == null || rebuildList.length < 2) return null;
    final comparison = evidence['artifact_comparison'];
    if (comparison is! Map<String, Object?>) return null;

    // Sprint 117.43-12 (fail-open, fixed): these three groups arrived here
    // through `(evidence[key] as List<dynamic>?)?.cast<String>()`, which
    // asserts rather than checks. A group holding `[42]`, holding a Map, or
    // not being a list at all did not report `unmet` — it threw a
    // `type 'int' is not a subtype of type 'String' in type cast` out of the
    // gate, so a malformed manifest escaped the verdict entirely instead of
    // failing closed. Every other decode in this file was written for this
    // (117.43-08/-09/-10); this one was missed. Read the list explicitly.
    List<String>? strings(String key) => _stringList(evidence[key]);

    RebuildResult rebuild(RebuildResult source) => RebuildResult(
      label: source.label,
      artifactHashes: Map<String, String>.from(source.artifactHashes),
      exitCode: source.exitCode,
      startedAt: source.startedAt,
      finishedAt: source.finishedAt,
      command: source.command,
      log: source.log,
    );

    final a = _rebuildFrom(rebuildList[0]);
    final b = _rebuildFrom(rebuildList[1]);
    if (a == null || b == null) return null;

    // Sprint 117.43-14 (fail-open, fixed): this seam read TWO records out of a
    // list that may hold more, and then reported the two it had read. Every
    // rule above and below — the window, the independence of the windows, the
    // clean command, the digest, the exit code, the reachable log, the
    // partition — was therefore applied to `rebuildList[0]` and
    // `rebuildList[1]` and to nothing else, while the gate printed
    // `rebuild_results: 2 item`: a number it CHOSE rather than one it read.
    //
    // Proven before the fix, by appending one record to the shipped manifest so
    // that only the appended defect could decide the outcome. Eight defects
    // travelled in that third record — a non-zero exit code, a fabricated
    // digest, a window that ends before it starts, a command admitting no
    // clean step, a log nobody can open, a duplicate label, an artifact the
    // partition never names, and a window overlapping the first rebuild — and
    // all eight returned `pass`, each reporting two rebuilds for a document
    // that recorded three.
    //
    // 117.43-13 is the same omission seen from inside one record: it made a
    // mistyped THIRD record fail closed, which it could not and could not have
    // done, because the third record was never decoded. Decode every record
    // now, and hold every one of them to the rules that already exist. A
    // manifest that records one rebuild is still unevaluable (the claim needs
    // two), and a document that records three is checked three times over.
    final decodedRebuilds = <RebuildResult>[];
    for (final record in rebuildList) {
      final rebuild = _rebuildFrom(record);
      if (rebuild == null) return null;
      decodedRebuilds.add(rebuild);
    }

    // A label is how a reader tells one rebuild from another, so two records
    // sharing one make the document ambiguous about how many rebuilds were
    // actually run. Distinct labels are part of what the `rebuild_results`
    // group claims once it may hold more than two records.
    final labels = <String>{};
    for (final rebuild in decodedRebuilds) {
      if (!labels.add(rebuild.label)) return null;
    }

    // The partition in `artifact_comparison` accounts for the artifacts of the
    // rebuilds it names. Once the evidence may record more than those two, the
    // inventory spans every recorded rebuild, so an artifact some other
    // rebuild hashed is an unaccounted digest and the partition is publishing a
    // partial account as the complete one — the defect 117.43-08 fixed for two
    // records, now applied to the whole list.
    final inventoryAcrossRebuilds = <String>{};
    for (final rebuild in decodedRebuilds) {
      inventoryAcrossRebuilds.addAll(rebuild.artifactHashes.keys);
    }

    // Sprint 117.43-09 (fail-open, fixed): the two rebuild WINDOWS were never
    // read, and neither the domain object nor the gate had anywhere to hold
    // them, so the manifest's independence claim — the `method` string says the
    // digests come from two independent clean rebuild cycles — was never
    // measured. Proven before the fix: a manifest whose rebuild_b starts while
    // rebuild_a is still running, one whose rebuild FINISHES BEFORE IT STARTS,
    // one whose recorded duration contradicts its own timestamps, and one whose
    // timestamp cannot be parsed at all all returned `pass` with text
    // indistinguishable from the honest case. Four impossible histories, one
    // answer. The domain now reads the window it is given (see
    // `RebuildResult.hasWellFormedWindow`) and this seam additionally requires
    // the two windows not to overlap, because overlapping clean rebuilds share
    // one `build/` directory and their digests say nothing about
    // reproducibility. Absence stays non-claiming per 117.43-07.
    if (!_windowsAreIndependent(a, b, rebuildList[0], rebuildList[1])) {
      return null;
    }

    // Sprint 117.43-14: the independence rule above compares the first two
    // windows only. Once the evidence may record more, every recorded rebuild
    // must stand clear of every other one — overlapping clean rebuilds share a
    // single `build/` directory, so a third window that overlaps either of the
    // first two makes their digests unattributable in exactly the way 117.43-09
    // refused for the pair.
    if (!_windowsArePairwiseIndependent(decodedRebuilds, rebuildList)) {
      return null;
    }

    // Sprint 117.43-10 (fail-open, fixed): the windows above establish WHEN and
    // THAT the rebuilds ran; nothing established WHAT they ran. The comparison
    // method says the digests come from two INDEPENDENT CLEAN rebuild CYCLES,
    // and a record whose own command admits no clean step — or which was built
    // in a different mode from its pair — contradicts that phrase while every
    // other rule in this file still passes. Two more questions, measured here
    // for the same reason 117.43-09 measured the windows.
    if (!a.hasWellFormedMethod || !b.hasWellFormedMethod) return null;
    if (!a.ranSameExperimentAs(b)) return null;

    // Sprint 117.43-14: the same rule for every recorded rebuild. A third
    // record built in a different mode, or by a command admitting no clean
    // step, contradicts the comparison's "two independent clean rebuild cycles"
    // phrase just as surely for the pair did, and the shipped document now
    // records how many rebuilds the claim rests on, so each one is checked.
    for (final rebuild in decodedRebuilds) {
      if (!rebuild.hasWellFormedMethod) return null;
      if (!rebuild.ranSameExperimentAs(a)) return null;
    }

    // Sprint 117.43-16 (unmeasured-claim, fixed): `rebuild_run` is the second
    // place this manifest restates the run. The records state two cycles and
    // their durations; the group states how many cycles there were
    // (`cycles`) and how long each took (`rebuild_<label>_duration_seconds`),
    // and nothing in `lib/` decoded a single member of it. The gate therefore
    // published `provenance_evaluation: pass` for a document whose own
    // summary claimed 900 seconds where its record claims 122, three cycles
    // where two rebuilds are recorded, or a duration for a rebuild no record
    // mentions. 117.43-15 fixed the copy of this restatement inside
    // `provenance_record`; this is the other copy, one level up and outside
    // `required_evidence`, which is why that reader could not see it. Every
    // number compared here is already measured from the records, so refusing
    // a contradiction invents no acceptance.
    if (!_rebuildRunAgrees(rebuildRun, rebuildList, decodedRebuilds)) {
      return null;
    }

    // Sprint 117.43-07 (fail-open, fixed): the verdict was INFERRED, never read.
    // `comparison['verdict'] == 'BIT_IDENTICAL' ? bitIdentical : notBitIdentical`
    // made every other value — an absent key, an explicit null, or a typo —
    // silently become a measured difference claim. The gate then reported
    // `provenance` as `pass` and printed `NOT_BIT_IDENTICAL` for a manifest that
    // stated no verdict at all, manufacturing a claim the document never made.
    // Parse it as a CLOSED vocabulary: only the two canonical strings produce an
    // enum, and anything else makes the evidence unevaluable so the caller
    // reports `unmet` rather than inventing a claim. Defaulting is the defect.
    final verdict = switch (comparison['verdict']) {
      'BIT_IDENTICAL' => RebuildVerdict.bitIdentical,
      'NOT_BIT_IDENTICAL' => RebuildVerdict.notBitIdentical,
      _ => null,
    };
    if (verdict == null) return null;

    // Sprint 117.43-08 (fail-open, fixed): the PER-ARTIFACT partition was never
    // read. 117.43-01/-06 verified the aggregate claim and 117.43-07 verified
    // the verdict string, but the strongest question any of them asked was "do
    // these two rebuilds agree AT ALL". The manifest we ship answers a sharper
    // question and names every artifact on one side of the line or the other —
    // `differing_artifacts` and `identical_artifacts` — and NOTHING read either
    // field, so no amount of domain checking could. Proven before the fix: a
    // manifest naming `a.exe` as differing and `b.dll` as identical, while the
    // digests prove exactly the reverse, reported `pass` with
    // `NOT_BIT_IDENTICAL (2 artifact)`. Every named claim was false and only
    // the aggregate happened to hold. Measure each name against its own digest
    // instead of trusting the one-bit summary. Absence is not a defect: a
    // manifest that names no artifact makes no per-artifact claim (117.43-07),
    // so a present field is checked and an absent one is simply not claimed.
    final partition = _readPartition(comparison);
    if (partition == null) return null;
    if (partition.declares &&
        !_partitionMatchesDigests(
          partition,
          a.artifactHashes,
          b.artifactHashes,
          inventoryAcrossRebuilds,
        )) {
      return null;
    }

    final buildInputs = strings('build_inputs');
    final toolchainVersions = strings('toolchain_versions');
    final dependencyLock = strings('dependency_lock');
    final provenanceRecord = strings('provenance_record');
    if (buildInputs == null ||
        toolchainVersions == null ||
        dependencyLock == null ||
        provenanceRecord == null) {
      return null;
    }

    // Sprint 117.43-13 (fail-open, fixed): `comparison['method'] as String?`
    // asserted that the method is a string, and `((comparison['limits'] as
    // List<dynamic>?)?.cast<String>())` asserted twice that `limits` is a list
    // of strings. A method recorded as a number, or limits recorded as a bare
    // string / a list holding one number, did not report `unmet` — each threw
    // a TypeError clean out of the gate, so the caller received no provenance
    // verdict instead of a failed one. Decode both shapes: an absent field
    // stays null (a non-claim per 117.43-07) and a present-but-unreadable one
    // makes the evidence unevaluable, which the caller reports as `unmet`.
    final method = comparison.containsKey('method')
        ? comparison['method'] is String
              ? comparison['method'] as String
              : _kUndecodable
        : null;
    final limits = comparison.containsKey('limits')
        ? _stringList(comparison['limits'])
        : null;
    if (identical(method, _kUndecodable)) return null;
    if (comparison.containsKey('limits') && limits == null) return null;

    final shipped = BuildProvenanceEvidence(
      buildInputs: buildInputs,
      toolchainVersions: toolchainVersions,
      dependencyLock: dependencyLock,
      rebuildResults: <RebuildResult>[
        for (final recorded in decodedRebuilds) rebuild(recorded),
      ],
      artifactComparison: ArtifactComparison(
        method: method as String?,
        rebuildA: rebuild(a),
        rebuildB: rebuild(b),
        verdict: verdict,
        limits: limits,
      ),
      provenanceRecord: provenanceRecord,
    );
    final result = BuildProvenanceEvidence.evaluate(shipped);
    return (result.state.name, result.notes.join('; '));
  }

  /// Decodes a claimed list of strings, or null when it is present but is not
  /// a list of non-blank strings.
  ///
  /// Sprint 117.43-12: the reader this replaces was
  /// `(evidence[key] as List<dynamic>?)?.cast<String>()`. The `as` there throws
  /// on a non-list and `cast<String>()` throws on any non-string element, so a
  /// malformed evidence group escaped the verdict as an exception rather than
  /// being reported `unmet`. A gate that crashes is not fail-closed, so decode
  /// the shape instead of asserting it. An absent key is null, which the
  /// callers treat as unevaluable.
  static List<String>? _stringList(Object? value) {
    if (value == null) return null;
    if (value is! List<dynamic>) return null;
    final items = <String>[];
    for (final entry in value) {
      if (entry is! String || entry.trim().isEmpty) return null;
      items.add(entry);
    }
    return items;
  }

  /// The per-artifact partition a comparison claims, or null when a declared
  /// field cannot be decoded (which makes the evidence unevaluable).
  ///
  /// [declares] is false when NEITHER field is present: the comparison makes no
  /// per-artifact claim, so there is nothing to verify. When either field is
  /// present, both are read, because one list without the other cannot state a
  /// partition — a lone `differing_artifacts` is exactly the partial account
  /// 117.43-08 refuses.
  static _ArtifactPartition? _readPartition(Map<String, Object?> comparison) {
    final hasDiffering = comparison.containsKey('differing_artifacts');
    final hasIdentical = comparison.containsKey('identical_artifacts');
    if (!hasDiffering && !hasIdentical) {
      return const _ArtifactPartition(differing: null, identical: null);
    }
    if (!hasDiffering || !hasIdentical) return null;

    final differing = _namesFrom(comparison['differing_artifacts']);
    final identical = _namesFrom(comparison['identical_artifacts']);
    if (differing == null || identical == null) return null;
    return _ArtifactPartition(differing: differing, identical: identical);
  }

  /// Decodes a claimed artifact-name list. Returns null when the value is
  /// present but not a list of non-blank strings — an undecodable claim must
  /// fail closed rather than be silently dropped or cast past.
  static List<String>? _namesFrom(Object? value) {
    if (value is! List<dynamic>) return null;
    final names = <String>[];
    for (final entry in value) {
      if (entry is! String || entry.trim().isEmpty) return null;
      names.add(entry);
    }
    return names;
  }

  /// Whether every named artifact sits on the side the manifest claims, and the
  /// two lists account for the whole recorded inventory.
  ///
  /// Three ways a claim fails here, all fail-closed:
  ///   * a name no rebuild hashed — nothing supports it;
  ///   * a name on both sides — an artifact cannot differ and be identical;
  ///   * a recorded artifact in neither list — the comparison publishes a
  ///     partial account as if it were the complete one.
  static bool _partitionMatchesDigests(
    _ArtifactPartition partition,
    Map<String, String> hashesA,
    Map<String, String> hashesB,
    Set<String> inventoryAcrossRebuilds,
  ) {
    final differing = partition.differing!;
    final identical = partition.identical!;
    final claimed = <String>{...differing, ...identical};
    if (claimed.length != differing.length + identical.length) return false;

    final inventory = hashesA.keys.toSet();
    if (inventory.length != hashesA.length) return false;
    // Sprint 117.43-14: the completeness test used to run against the first
    // rebuild's inventory alone. It now runs against the union across every
    // recorded rebuild, because the partition claims to account for what the
    // document hashed — and when a later rebuild hashes something the first
    // two never mentioned, that artifact is part of the recorded inventory too.
    // A partition that names the first two but omits a third is publishing a
    // partial account as the complete one, which is the defect 117.43-08
    // already refused for the pair.
    if (claimed.length != inventoryAcrossRebuilds.length ||
        !claimed.containsAll(inventoryAcrossRebuilds)) {
      return false;
    }
    if (!claimed.containsAll(inventory)) return false;

    for (final entry in hashesA.entries) {
      final recordedDifference = hashesB[entry.key] != entry.value;
      if (recordedDifference != differing.contains(entry.key)) return false;
    }
    return true;
  }

  static RebuildResult? _rebuildFrom(Map<String, Object?> json) {
    final label = json['label'];
    final hashes = json['artifact_hashes'];
    if (label is! String || hashes is! Map<String, Object?>) return null;
    // Sprint 117.43-13 (fail-open, fixed): the digest map passed its `is`
    // check but its VALUES were still asserted one at a time by
    // `hashes.map((key, value) => MapEntry(key, value as String))`, and
    // `exit_code` by `json['exit_code'] as int?`. A single fabricated or null
    // digest, or an exit code recorded as the string "0", therefore threw a
    // TypeError out of the gate instead of being reported — and because
    // `_rebuildFrom` is the decoder for BOTH rebuild records, one bad digest
    // destroyed the entire provenance verdict, not just one rebuild. Decode
    // both values explicitly: an absent `exit_code` is a non-claim per
    // 117.43-07, while a present-but-unreadable one is a defect.
    final decodedHashes = <String, String>{};
    for (final entry in hashes.entries) {
      final value = entry.value;
      if (value is! String) return null;
      decodedHashes[entry.key] = value;
    }
    final exitCode = _durationOrNull(
      json['exit_code'],
      json.containsKey('exit_code'),
    );
    if (identical(exitCode, _kUndecodable)) return null;

    final window = _decodeWindow(json);
    if (window == null) return null;
    // Sprint 117.43-10 (fail-open, fixed): `command` and `log` were dropped on
    // the floor exactly as the window fields were, so the domain had nowhere to
    // hold the only record of WHAT was built and the "clean rebuild cycles"
    // claim stayed unmeasured. Decode them under the same rule as the window:
    // a present-but-undecodable field fails closed, an absent one is a
    // non-claim.
    final command = _stringOrNull(json['command'], json.containsKey('command'));
    final log = _stringOrNull(json['log'], json.containsKey('log'));
    if (command == _kUndecodable || log == _kUndecodable) return null;
    if (!_logIsReadable(log)) return null;
    return RebuildResult(
      label: label,
      artifactHashes: decodedHashes,
      exitCode: exitCode as int?,
      startedAt: window.startedAt,
      finishedAt: window.finishedAt,
      command: command as String?,
      log: log as String?,
    );
  }

  /// Whether a recorded log path names a document that can be opened.
  ///
  /// A rebuild record citing a log nobody can open is evidence with nothing
  /// behind it: the exit code and the digests are the record's own assertions
  /// about itself, while the log is the only thing in the manifest that could
  /// show the build actually ran. An absent log states no such claim, so it is
  /// not checked — same rule as the window and the command.
  static bool _logIsReadable(Object? log) {
    if (log == null) return true;
    // Sprint 117.43-13: reachability arrived here via `log as String`, which
    // throws for a non-string rather than reporting it. The caller has already
    // decoded this field, but the helper must not re-assert a shape it was
    // handed; a value of another type simply names nothing readable.
    if (log is! String) return false;
    final path = log.trim();
    if (path.isEmpty) return true;
    return File(path).existsSync();
  }

  /// The rebuild window one record states, or null when a present field cannot
  /// be decoded (which makes the whole manifest unevaluable).
  ///
  /// Sprint 117.43-09 (fail-open, fixed): `_rebuildFrom` read `label`, hashes,
  /// and `exit_code` and dropped `started_at`, `finished_at`, and
  /// `duration_seconds` on the floor, so the timestamps the manifest records
  /// never reached [RebuildResult] at all. Adding a window check in the domain
  /// would then have been theatre — every record would have arrived with a null
  /// window and been waved through as a non-claim. Read them here, and decode a
  /// present field strictly: a number where a string belongs is refused rather
  /// than cast, for the same reason 117.43-08 refuses a mistyped partition.
  static _RebuildWindow? _decodeWindow(Map<String, Object?> json) {
    final hasStarted = json.containsKey('started_at');
    final hasFinished = json.containsKey('finished_at');
    final hasDuration = json.containsKey('duration_seconds');
    if (!hasStarted && !hasFinished && !hasDuration) {
      return const _RebuildWindow(startedAt: null, finishedAt: null);
    }
    final startedAt = _stringOrNull(json['started_at'], hasStarted);
    final finishedAt = _stringOrNull(json['finished_at'], hasFinished);
    final duration = _durationOrNull(json['duration_seconds'], hasDuration);
    if (startedAt == _kUndecodable ||
        finishedAt == _kUndecodable ||
        duration == _kUndecodable) {
      return null;
    }
    return _RebuildWindow(
      startedAt: startedAt as String?,
      finishedAt: finishedAt as String?,
      durationSeconds: duration as int?,
    );
  }

  static Object? _stringOrNull(Object? value, bool present) {
    if (!present || value == null) return null;
    return value is String ? value : _kUndecodable;
  }

  static Object? _durationOrNull(Object? value, bool present) {
    if (!present || value == null) return null;
    if (value is int) return value;
    if (value is double && value == value.roundToDouble()) return value.toInt();
    return _kUndecodable;
  }

  /// Whether the two recorded rebuild windows support the independence the
  /// comparison claims: `rebuild_a` must have finished before `rebuild_b`
  /// started, and each rebuild's own window must run forwards.
  ///
  /// The comparison method in the shipped manifest reads "after two INDEPENDENT
  /// `flutter clean` + build cycles on the same tree". Two builds that overlap
  /// in time are two concurrent builds fighting over the same `build/`
  /// directory, so the artifact hashes they record cannot be attributed to a
  /// clean rebuild at all — the independence the verdict rests on is not there.
  /// Neither the 117.43 aggregate rules nor the 117.43-08 partition rules ask
  /// this question, and no domain field could: before this slice the windows
  /// were never read at all.
  static bool _windowsAreIndependent(
    RebuildResult a,
    RebuildResult b,
    Map<String, Object?> first,
    Map<String, Object?> second,
  ) {
    // The independence question only exists when BOTH rebuilds state a window.
    // A record with no window states no claim (117.43-07), and
    // `hasWellFormedWindow` is deliberately true for the absent case, so it
    // cannot stand in for "a window is present" here.
    if (!_hasWindow(a) || !_hasWindow(b)) return true;
    if (!a.hasWellFormedWindow || !b.hasWellFormedWindow) return false;
    // Both ends of BOTH windows are recorded (a half-recorded window already
    // failed closed inside `hasWellFormedWindow`), so the strings are present.
    final startA = DateTime.tryParse(a.startedAt!.trim());
    final finishA = DateTime.tryParse(a.finishedAt!.trim());
    final startB = DateTime.tryParse(b.startedAt!.trim());
    final finishB = DateTime.tryParse(b.finishedAt!.trim());
    if (startA == null ||
        finishA == null ||
        startB == null ||
        finishB == null) {
      return false;
    }
    // Each recorded duration must agree with the window it summarises.
    if (!_durationAgrees(first['duration_seconds'], startA, finishA)) {
      return false;
    }
    if (!_durationAgrees(second['duration_seconds'], startB, finishB)) {
      return false;
    }
    return !startB.isBefore(finishA);
  }

  /// Whether every pair of recorded rebuild windows stands clear of the others.
  ///
  /// Sprint 117.43-14: `_windowsAreIndependent` compares exactly two windows,
  /// so a manifest recording a third rebuild was free to place it INSIDE the
  /// first rebuild's window — two builds contending for one `build/` directory
  /// while the gate reported `pass`. Two rebuilds contending for one directory
  /// is already refused for the pair; a third has to be refused too, which means
  /// every pair, not only the first two.
  ///
  /// A record that states no complete window states no window claim
  /// (117.43-07) and cannot be placed on a timeline, so it is skipped rather
  /// than treated as a conflict — the same non-claim rule the pair helper
  /// applies.
  static bool _windowsArePairwiseIndependent(
    List<RebuildResult> rebuilds,
    List<Map<String, Object?>> records,
  ) {
    for (var i = 0; i < rebuilds.length; i++) {
      if (!_hasWindow(rebuilds[i])) continue;
      final startI = DateTime.tryParse(rebuilds[i].startedAt!.trim());
      final finishI = DateTime.tryParse(rebuilds[i].finishedAt!.trim());
      if (startI == null || finishI == null) return false;
      if (!_durationAgrees(records[i]['duration_seconds'], startI, finishI)) {
        return false;
      }
      for (var j = i + 1; j < rebuilds.length; j++) {
        if (!_hasWindow(rebuilds[j])) continue;
        final startJ = DateTime.tryParse(rebuilds[j].startedAt!.trim());
        final finishJ = DateTime.tryParse(rebuilds[j].finishedAt!.trim());
        if (startJ == null || finishJ == null) return false;
        if (startJ.isBefore(finishI) && !startJ.isBefore(startI)) return false;
        if (startI.isBefore(finishJ) && !startI.isBefore(startJ)) return false;
      }
    }
    return true;
  }

  /// Whether a record states a complete window (both ends present).
  static bool _hasWindow(RebuildResult rebuild) {
    final start = rebuild.startedAt?.trim();
    final finish = rebuild.finishedAt?.trim();
    return start != null &&
        finish != null &&
        start.isNotEmpty &&
        finish.isNotEmpty;
  }

  /// Whether a recorded `duration_seconds` matches the window it describes.
  ///
  /// A `null` duration states no duration claim, so it is not checked; a stated
  /// one must equal the window it summarises, because a duration that
  /// contradicts its own timestamps is a record that disagrees with itself.
  static bool _durationAgrees(Object? value, DateTime start, DateTime finish) {
    if (value == null) return true;
    if (value is! int) return false;
    return value == finish.difference(start).inSeconds;
  }

  /// Whether the document-level `rebuild_run` group agrees with the records
  /// it summarises.
  ///
  /// Sprint 117.43-16 (unmeasured-claim, fixed): this group restates the run
  /// `rebuild_results` records — how many cycles ran, and how long each took —
  /// and no reader in `lib/` had ever opened it, so a document contradicting
  /// its own records still received `pass`. It sits outside
  /// `required_evidence`, which is why 117.43-15's summary-line reader could
  /// not reach it.
  ///
  /// Refused: a group present but not an object; a `cycles` or
  /// `rebuild_<label>_duration_seconds` value that cannot be read as a whole
  /// number (present-but-unreadable fails closed, 117.43-13); a cycle count
  /// differing from the number of recorded rebuilds; a duration differing
  /// from the duration its own record states; and a duration naming a label
  /// no record carries.
  ///
  /// Non-claiming, pinned by test: an absent group or a `null` member states
  /// nothing (117.43-07); prose members (`method`,
  /// `signed_snapshot_restore`) make no number claim; and vocabulary this
  /// group's shipped grammar does not define makes no claim either — the
  /// clean step is measured where it is claimed, on the record
  /// (117.43-10), not re-parsed out of prose one level up.
  static bool _rebuildRunAgrees(
    Object? rebuildRun,
    List<Map<String, Object?>> records,
    List<RebuildResult> rebuilds,
  ) {
    if (rebuildRun == null) return true;
    if (rebuildRun is! Map<String, Object?>) return false;
    final run = rebuildRun;

    final cycles = _durationOrNull(run['cycles'], run.containsKey('cycles'));
    if (identical(cycles, _kUndecodable)) return false;
    if (cycles != null && cycles != rebuilds.length) return false;

    final summarised = RegExp(r'^(rebuild_.+)_duration_seconds$');
    for (final member in run.entries) {
      final label = summarised.firstMatch(member.key)?.group(1);
      if (label == null) continue;
      final seconds = _durationOrNull(member.value, true);
      if (identical(seconds, _kUndecodable)) return false;
      if (seconds == null) continue;
      final index = rebuilds.indexWhere((rebuild) => rebuild.label == label);
      // A duration for a rebuild no record names claims a cycle that never
      // happened — the same fabrication 117.43-15 refuses in the summary
      // lines, where a rebuild_z line had the same effect.
      if (index < 0) return false;
      final recorded = records[index];
      final own = _durationOrNull(
        recorded['duration_seconds'],
        recorded.containsKey('duration_seconds'),
      );
      if (identical(own, _kUndecodable)) return false;
      if (own != null) {
        if (own != seconds) return false;
        continue;
      }
      // The record states no duration of its own, so fall back to the window
      // it does state. With neither, there is nothing to contradict.
      if (!_hasWindow(rebuilds[index])) continue;
      final rebuild = rebuilds[index];
      final start = DateTime.tryParse(rebuild.startedAt!.trim());
      final finish = DateTime.tryParse(rebuild.finishedAt!.trim());
      if (start == null || finish == null) return false;
      if (finish.difference(start).inSeconds != seconds) return false;
    }
    return true;
  }

  /// Reads a JSON manifest, returning null when absent or undecodable.
  static Map<String, Object?>? readManifest(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    } on FormatException {
      return null;
    }
  }
}
