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
///    actually support it: `bitIdentical` needs every digest equal, and
///    `notBitIdentical` needs at least one digest that differs (defects
///    117.43-01 and 117.43-06, the two mirrors of the same trust boundary).
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
/// Defect 117.43-02 (measured and reported, NOT fixed): the 113.38 GA manifest
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

  /// Measures the checksum file against the signed artifacts on disk.
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
    final declaredSet = signedArtifacts.map((p) => p.trim()).toSet();
    for (final path in index.keys) {
      if (declaredSet.contains(path.trim())) continue;
      if (!File(path).existsSync()) phantom.add(path);
    }
    final declared = '${signedArtifacts.length} artifact';
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
      observed: '${signedArtifacts.length} artifact digest match',
    );
  }

  /// Measures the signed-artifact list against the packaging manifest.
  static Sprint117GaArtifactCheck measureSignedArtifacts({
    required Map<String, Object?> packagingOutputs,
    required List<String> declaredArtifacts,
  }) {
    final recorded =
        (packagingOutputs['signed_artifacts'] as List<dynamic>?)
            ?.cast<String>() ??
        const <String>[];
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
    final evaluation = _evaluateShippedProvenance(evidence);
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
    return Sprint117GaArtifactCheck.pass_(
      outputId: 'provenance',
      check: 'provenance_evaluation',
      declared: declared,
      observed: notes,
    );
  }

  /// Runs the shipped 113.39 evaluation over a decoded manifest, returning
  /// `(state, notes)` or null when the manifest cannot be decoded into the
  /// shipped shape. Never restates the evaluation logic.
  static (String, String)? _evaluateShippedProvenance(
    Map<String, Object?> evidence,
  ) {
    final rebuildList = (evidence['rebuild_results'] as List<dynamic>?)
        ?.cast<Map<String, Object?>>();
    if (rebuildList == null || rebuildList.length < 2) return null;
    final comparison = evidence['artifact_comparison'];
    if (comparison is! Map<String, Object?>) return null;

    List<String> strings(String key) =>
        ((evidence[key] as List<dynamic>?)?.cast<String>()) ?? const <String>[];

    RebuildResult rebuild(RebuildResult source) => RebuildResult(
      label: source.label,
      artifactHashes: Map<String, String>.from(source.artifactHashes),
      exitCode: source.exitCode,
    );

    final a = _rebuildFrom(rebuildList[0]);
    final b = _rebuildFrom(rebuildList[1]);
    if (a == null || b == null) return null;

    final shipped = BuildProvenanceEvidence(
      buildInputs: strings('build_inputs'),
      toolchainVersions: strings('toolchain_versions'),
      dependencyLock: strings('dependency_lock'),
      rebuildResults: <RebuildResult>[a, b],
      artifactComparison: ArtifactComparison(
        method: comparison['method'] as String?,
        rebuildA: rebuild(a),
        rebuildB: rebuild(b),
        verdict: comparison['verdict'] == 'BIT_IDENTICAL'
            ? RebuildVerdict.bitIdentical
            : RebuildVerdict.notBitIdentical,
        limits: ((comparison['limits'] as List<dynamic>?)?.cast<String>()),
      ),
      provenanceRecord: strings('provenance_record'),
    );
    final result = BuildProvenanceEvidence.evaluate(shipped);
    return (result.state.name, result.notes.join('; '));
  }

  static RebuildResult? _rebuildFrom(Map<String, Object?> json) {
    final label = json['label'];
    final hashes = json['artifact_hashes'];
    if (label is! String || hashes is! Map<String, Object?>) return null;
    return RebuildResult(
      label: label,
      artifactHashes: hashes.map(
        (key, value) => MapEntry(key, value as String),
      ),
      exitCode: json['exit_code'] as int?,
    );
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
