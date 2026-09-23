/// GA Artifact Packaging (Step 113.38).
///
/// Domain contract for the seven canonical GA packaging outputs —
/// `signed_artifacts`, `checksums`, `version_manifest`,
/// `dependency_manifest`, `schema_manifest`, `flag_manifest`, and
/// `licenses` — plus the evaluation state machine that decides whether the
/// candidate package is complete, incomplete, or absent.
///
/// Every output must record content: at least one non-blank artifact path
/// or checksum entry for list outputs, and a non-blank version number for
/// `version_manifest`. A null or blank value is a missing output, never an
/// implicit pass.
library;

/// Evaluation outcome of a GA artifact package.
enum GaPackagingState {
  /// Every required output is recorded with non-blank content.
  pass,

  /// Some output is missing, blank, or carries a blank item.
  fail,

  /// No output is recorded at all — nothing to evaluate.
  blocked,
}

/// Immutable snapshot of the seven GA packaging outputs.
class GaArtifactPackaging {
  const GaArtifactPackaging({
    this.signedArtifacts,
    this.checksums,
    this.versionManifest,
    this.dependencyManifest,
    this.schemaManifest,
    this.flagManifest,
    this.licenses,
  });

  /// Canonical output names, in roadmap order.
  static const List<String> requiredOutputNames = <String>[
    'signed_artifacts',
    'checksums',
    'version_manifest',
    'dependency_manifest',
    'schema_manifest',
    'flag_manifest',
    'licenses',
  ];

  /// Paths of the signed release artifacts (relative to the repository).
  final List<String>? signedArtifacts;

  /// Paths of checksum inventories covering the signed artifacts.
  final List<String>? checksums;

  /// The packaged version number (for example `1.2.0-rc.1`).
  final String? versionManifest;

  /// Paths proving the dependency inventory (lockfile, SBOM).
  final List<String>? dependencyManifest;

  /// Recorded schema identifiers (for example `database:62`).
  final List<String>? schemaManifest;

  /// Recorded feature-flag identifiers and their defaults.
  final List<String>? flagManifest;

  /// Paths of the project and third-party license records.
  final List<String>? licenses;

  /// Returns the canonical names of outputs that are missing or blank.
  ///
  /// An output counts as missing when its field is null, when a required
  /// field carries no items, or when any recorded item is blank.
  static List<String> missingOutputs(GaArtifactPackaging document) {
    final missing = <String>[];
    if (!_hasContent(document.signedArtifacts)) {
      missing.add('signed_artifacts');
    }
    if (!_hasContent(document.checksums)) {
      missing.add('checksums');
    }
    if (document.versionManifest == null ||
        document.versionManifest!.trim().isEmpty) {
      missing.add('version_manifest');
    }
    if (!_hasContent(document.dependencyManifest)) {
      missing.add('dependency_manifest');
    }
    if (!_hasContent(document.schemaManifest)) {
      missing.add('schema_manifest');
    }
    if (!_hasContent(document.flagManifest)) {
      missing.add('flag_manifest');
    }
    if (!_hasContent(document.licenses)) {
      missing.add('licenses');
    }
    return missing;
  }

  /// Evaluates a package: null or a package without any recorded field is
  /// [GaPackagingState.blocked]; any missing output fails with the
  /// canonical names in its notes; a complete package passes and retains
  /// its version plus the per-output item counts.
  static GaPackagingEvaluation evaluate(GaArtifactPackaging? document) {
    if (document == null || _isUnrecorded(document)) {
      return const GaPackagingEvaluation(
        state: GaPackagingState.blocked,
        notes: <String>['no ga artifact packaging recorded'],
      );
    }

    final missing = missingOutputs(document);
    if (missing.isNotEmpty) {
      return GaPackagingEvaluation(
        state: GaPackagingState.fail,
        notes: <String>[
          'ga artifact packaging incomplete: missing ${missing.join(', ')}',
        ],
      );
    }

    final notes = <String>[
      'version: ${document.versionManifest}',
      'signed_artifacts: ${document.signedArtifacts!.length} item',
      'checksums: ${document.checksums!.length} item',
      'dependency_manifest: ${document.dependencyManifest!.length} item',
      'schema_manifest: ${document.schemaManifest!.length} item',
      'flag_manifest: ${document.flagManifest!.length} item',
      'licenses: ${document.licenses!.length} item',
    ];
    return GaPackagingEvaluation(state: GaPackagingState.pass, notes: notes);
  }

  static bool _hasContent(List<String>? items) {
    if (items == null || items.isEmpty) return false;
    return items.every((item) => item.trim().isNotEmpty);
  }

  static bool _isUnrecorded(GaArtifactPackaging document) {
    return document.signedArtifacts == null &&
        document.checksums == null &&
        document.versionManifest == null &&
        document.dependencyManifest == null &&
        document.schemaManifest == null &&
        document.flagManifest == null &&
        document.licenses == null;
  }
}

/// Result of evaluating a [GaArtifactPackaging].
class GaPackagingEvaluation {
  const GaPackagingEvaluation({required this.state, required this.notes});

  final GaPackagingState state;
  final List<String> notes;
}
