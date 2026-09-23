/// Version, Changelog & Migration Notes (Step 113.37).
///
/// Domain contract for the six canonical release-documentation outputs —
/// version, changelog, migration_notes, compatibility_notes, recovery_notes,
/// deprecation_notes — plus the evaluation state machine that decides
/// whether the documentation is complete, incomplete, or absent.
///
/// Completing the version number is part of the step: `version` must be
/// recorded, never blank. Changelog, migration, compatibility, and recovery
/// notes must record at least one real item; empty deprecation_notes is a
/// recorded answer (nothing deprecated on this line).
library;

/// Evaluation outcome of a release documentation set.
enum ReleaseDocumentationState {
  /// Every required output is recorded with content where content is required.
  pass,

  /// Some output is missing, blank, or empty where content is required.
  fail,

  /// No output is recorded at all — nothing to evaluate.
  blocked,
}

/// Immutable snapshot of the six release-documentation outputs.
class ReleaseDocumentation {
  const ReleaseDocumentation({
    this.version,
    this.changelog,
    this.migrationNotes,
    this.compatibilityNotes,
    this.recoveryNotes,
    this.deprecationNotes,
  });

  /// Canonical output names, in roadmap order.
  static const List<String> requiredOutputNames = <String>[
    'version',
    'changelog',
    'migration_notes',
    'compatibility_notes',
    'recovery_notes',
    'deprecation_notes',
  ];

  /// Completed version number (for example `1.2.0-rc.1`).
  final String? version;

  /// What changed in this release, one entry per change.
  final List<String>? changelog;

  /// Upgrade/migration instructions and boundaries.
  final List<String>? migrationNotes;

  /// Compatibility contracts preserved by this release.
  final List<String>? compatibilityNotes;

  /// Recovery paths that must stay documented with the release.
  final List<String>? recoveryNotes;

  /// Deprecation policy and any deprecated surface; empty = none.
  final List<String>? deprecationNotes;

  /// Returns the canonical names of outputs that are missing or blank.
  ///
  /// An output counts as missing when its field is null, when a required
  /// field carries no items (version, changelog, migration, compatibility,
  /// recovery) or when any recorded item is blank. Empty `deprecation_notes`
  /// is a recorded answer, not a gap.
  static List<String> missingOutputs(ReleaseDocumentation document) {
    final missing = <String>[];
    if (document.version == null || document.version!.trim().isEmpty) {
      missing.add('version');
    }
    if (!_hasContent(document.changelog, requireItems: true)) {
      missing.add('changelog');
    }
    if (!_hasContent(document.migrationNotes, requireItems: true)) {
      missing.add('migration_notes');
    }
    if (!_hasContent(document.compatibilityNotes, requireItems: true)) {
      missing.add('compatibility_notes');
    }
    if (!_hasContent(document.recoveryNotes, requireItems: true)) {
      missing.add('recovery_notes');
    }
    if (!_hasContent(document.deprecationNotes)) {
      missing.add('deprecation_notes');
    }
    return missing;
  }

  /// Evaluates a document: null or a document without any recorded field is
  /// [ReleaseDocumentationState.blocked]; any missing output fails with the
  /// canonical names in its notes; a complete document passes and retains
  /// its version, per-output item counts, and every deprecation note.
  static ReleaseDocumentationEvaluation evaluate(
    ReleaseDocumentation? document,
  ) {
    if (document == null || _isUnrecorded(document)) {
      return const ReleaseDocumentationEvaluation(
        state: ReleaseDocumentationState.blocked,
        notes: <String>['no release documentation recorded'],
      );
    }

    final missing = missingOutputs(document);
    if (missing.isNotEmpty) {
      return ReleaseDocumentationEvaluation(
        state: ReleaseDocumentationState.fail,
        notes: <String>[
          'release documentation incomplete: missing ${missing.join(', ')}',
        ],
      );
    }

    final notes = <String>[
      'version: ${document.version}',
      'changelog: ${document.changelog!.length} item',
      'migration_notes: ${document.migrationNotes!.length} item',
      'compatibility_notes: ${document.compatibilityNotes!.length} item',
      'recovery_notes: ${document.recoveryNotes!.length} item',
      'deprecation_notes: ${document.deprecationNotes!.length} item',
      for (final note in document.deprecationNotes!) 'deprecation: $note',
    ];
    return ReleaseDocumentationEvaluation(
      state: ReleaseDocumentationState.pass,
      notes: notes,
    );
  }

  static bool _hasContent(List<String>? items, {bool requireItems = false}) {
    if (items == null) return false;
    if (requireItems && items.isEmpty) return false;
    return items.every((item) => item.trim().isNotEmpty);
  }

  static bool _isUnrecorded(ReleaseDocumentation document) {
    return document.version == null &&
        document.changelog == null &&
        document.migrationNotes == null &&
        document.compatibilityNotes == null &&
        document.recoveryNotes == null &&
        document.deprecationNotes == null;
  }
}

/// Result of evaluating a [ReleaseDocumentation].
class ReleaseDocumentationEvaluation {
  const ReleaseDocumentationEvaluation({
    required this.state,
    required this.notes,
  });

  final ReleaseDocumentationState state;
  final List<String> notes;
}
