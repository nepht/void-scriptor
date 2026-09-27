/// Sprint 115.55 — Alpha Acceptance Gate contract.
///
/// The canonical objective of step 115.55 asks the surface to be evaluated
/// across nine evidence categories before declaring the Account & Cloud Center
/// ready for v1.3.0-alpha.1. The nine canonical outputs are transcribed here
/// in spec order and never invented:
///
/// `product_spec_acceptance`, `connector_manifest`, `quota_evidence`,
/// `icon_registry`, `responsive_results`, `accessibility_results`,
/// `security_privacy_review`, `billing_review`, `known_issues`.
///
/// The matrix is fail-closed like its siblings (115.49 – 115.54):
///
/// * a bucket outside the canonical set is rejected with [ArgumentError];
/// * a canonical bucket that was never recorded is rejected with [StateError];
/// * a bucket that claims `pass` without a concrete check, or with a check
///   that did not hold, is rejected with [ArgumentError] — an unverified pass
///   is a rubber stamp;
/// * a bucket that is not passing must say why, and a `blocked` bucket may
///   never carry checks, so an external boundary cannot be dressed up as a
///   local pass;
/// * [AccountAlphaAcceptanceReport.isPass] only turns true when every canonical
///   bucket passed, and [verdict] must be repeated verbatim in the committed
///   manifest.
library;

/// How an alpha acceptance bucket was evaluated.
enum AccountAlphaAcceptanceBucketStatus {
  /// The bucket ran locally and every recorded check held.
  pass,

  /// The bucket ran locally and at least one check failed.
  fail,

  /// The bucket cannot be evaluated locally (external boundary).
  blocked,

  /// Recorded as a target but not yet run.
  pending,
}

/// One recorded check inside an alpha acceptance bucket.
final class AccountAlphaAcceptanceCheck {
  AccountAlphaAcceptanceCheck({required this.name, required this.held}) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Check must be named.');
    }
  }

  /// What was asserted, e.g. `manifest_is_unverified`.
  final String name;

  /// Whether the assertion actually held in the recorded run.
  final bool held;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'name': name,
    'held': held,
  };
}

/// One recorded bucket of the alpha acceptance matrix.
final class AccountAlphaAcceptanceBucket {
  AccountAlphaAcceptanceBucket({
    required this.bucket,
    required this.status,
    required List<AccountAlphaAcceptanceCheck> checks,
    this.note = '',
  }) : checks = List<AccountAlphaAcceptanceCheck>.unmodifiable(checks) {
    if (bucket.trim().isEmpty) {
      throw ArgumentError.value(bucket, 'bucket', 'Bucket must be named.');
    }
    if (note.trim().length < 30 &&
        status != AccountAlphaAcceptanceBucketStatus.pass) {
      throw ArgumentError.value(
        note,
        'note',
        'A non-passing bucket must explain itself in at least 30 characters.',
      );
    }
  }

  /// Canonical bucket name; must match its report key.
  final String bucket;

  final AccountAlphaAcceptanceBucketStatus status;

  /// Concrete local checks. Empty for `blocked` and `pending`.
  final List<AccountAlphaAcceptanceCheck> checks;

  /// Why the bucket is not passing, or a scope clarification for a passing one.
  final String note;

  /// Number of concrete checks recorded by the run.
  int get measured => checks.length;

  /// True when this bucket is a local pass with every check holding.
  bool get allHeld =>
      status == AccountAlphaAcceptanceBucketStatus.pass &&
      checks.isNotEmpty &&
      checks.every((check) => check.held);

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'bucket': bucket,
    'status': status.name,
    'measured': measured,
    'checks': checks
        .map((check) => check.toPublicJson())
        .toList(growable: false),
    'note': note,
  };
}

/// The validated matrix for canonical step 115.55.
final class AccountAlphaAcceptanceReport {
  AccountAlphaAcceptanceReport._(this.results);

  /// Recorded buckets in canonical order.
  final Map<String, AccountAlphaAcceptanceBucket> results;

  /// True when every canonical bucket has a recorded, non-pending row.
  bool get isComplete => results.values.every(
    (row) => row.status != AccountAlphaAcceptanceBucketStatus.pending,
  );

  int get passCount => results.values
      .where((row) => row.status == AccountAlphaAcceptanceBucketStatus.pass)
      .length;

  /// True only for a complete matrix whose every bucket passed.
  bool get isPass =>
      isComplete &&
      passCount == AccountCenterAlphaAcceptance.requiredEvidence.length;

  /// Machine-readable summary; the committed manifest must repeat this value.
  String get verdict => !isComplete
      ? 'INCOMPLETE'
      : isPass
      ? 'ALL_PASS'
      : 'COMPLETE_${passCount}_OF_'
            '${AccountCenterAlphaAcceptance.requiredEvidence.length}_PASS';

  AccountAlphaAcceptanceBucketStatus statusOf(String bucket) =>
      results[bucket]!.status;
}

/// Fail-closed Alpha Acceptance Gate matrix for step 115.55.
abstract final class AccountCenterAlphaAcceptance {
  /// Path of the committed evidence manifest.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_alpha_acceptance.json';

  /// `required_evidence` for canonical step 115.55, in spec order.
  static const List<String> requiredEvidence = <String>[
    'product_spec_acceptance',
    'connector_manifest',
    'quota_evidence',
    'icon_registry',
    'responsive_results',
    'accessibility_results',
    'security_privacy_review',
    'billing_review',
    'known_issues',
  ];

  /// Validates a bucket map against [requiredEvidence].
  static AccountAlphaAcceptanceReport buildReport(
    Map<String, AccountAlphaAcceptanceBucket> results,
  ) {
    for (final key in results.keys) {
      if (!requiredEvidence.contains(key)) {
        throw ArgumentError.value(
          key,
          'results',
          'Bucket outside the canonical required_evidence of step 115.55.',
        );
      }
    }
    final missing = requiredEvidence
        .where((bucket) => !results.containsKey(bucket))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Missing canonical bucket(s): ${missing.join(', ')}.');
    }
    final ordered = <String, AccountAlphaAcceptanceBucket>{
      for (final bucket in requiredEvidence) bucket: results[bucket]!,
    };
    for (final entry in ordered.entries) {
      _validate(entry.key, entry.value);
    }
    return AccountAlphaAcceptanceReport._(Map.unmodifiable(ordered));
  }

  static void _validate(String key, AccountAlphaAcceptanceBucket row) {
    if (row.bucket != key) {
      throw ArgumentError.value(
        row.bucket,
        'results',
        'Row labelled ${row.bucket} is stored under the canonical key $key.',
      );
    }
    final seen = <String>{};
    for (final check in row.checks) {
      if (!seen.add(check.name)) {
        throw ArgumentError.value(
          check.name,
          'results',
          'Bucket $key records the same check twice.',
        );
      }
    }
    switch (row.status) {
      case AccountAlphaAcceptanceBucketStatus.pass:
        if (row.checks.isEmpty) {
          throw ArgumentError.value(
            row.checks,
            'results',
            'Bucket $key claims pass without a recorded check.',
          );
        }
        final notHeld = row.checks
            .where((check) => !check.held)
            .map((check) => check.name)
            .toList(growable: false);
        if (notHeld.isNotEmpty) {
          throw ArgumentError.value(
            notHeld.join(', '),
            'results',
            'Bucket $key claims pass while ${notHeld.length} check(s) did not hold.',
          );
        }
      case AccountAlphaAcceptanceBucketStatus.fail:
      case AccountAlphaAcceptanceBucketStatus.blocked:
        if (trimmedNoteLength(row.note) < 30) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Bucket $key must explain itself in at least 30 characters.',
          );
        }
        if (row.status == AccountAlphaAcceptanceBucketStatus.blocked &&
            row.checks.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Bucket $key is blocked and may not carry local checks.',
          );
        }
      case AccountAlphaAcceptanceBucketStatus.pending:
        if (row.checks.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Bucket $key is pending and may not claim a recorded check.',
          );
        }
    }
  }

  /// Length of [note] ignoring surrounding whitespace, so a padded blank
  /// string cannot pass as an explanation.
  static int trimmedNoteLength(String note) => note.trim().length;
}
