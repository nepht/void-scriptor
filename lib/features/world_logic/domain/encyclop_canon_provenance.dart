// Sprint 111.4 - Canon, Provenance & Confidence Model.
// Domain-only contract for canon_status, source_reference, author_or_culture,
// confidence, assumptions, and revision_history.
// No persistence, UI, locale, network, wall clock, or random input.

library;

/// Status of a claim in the Wave 3 encyclopedia hierarchy.
enum CanonStatus { canon, rumor, myth, hypothesis, generated }

/// Reference to a source document or artifact supporting a claim.
class SourceReference {
  const SourceReference._({required this.referenceId, required this.kind});

  factory SourceReference.validated({
    required String referenceId,
    required String kind,
  }) {
    final ref = referenceId.trim();
    if (ref.isEmpty) {
      throw ArgumentError.value(
        referenceId,
        'referenceId',
        'referenceId cannot be empty',
      );
    }
    final k = kind.trim();
    if (k.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'kind cannot be empty');
    }
    return SourceReference._(referenceId: ref, kind: k);
  }

  final String referenceId;
  final String kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceReference &&
          other.referenceId == referenceId &&
          other.kind == kind);

  @override
  int get hashCode => Object.hash(referenceId, kind);

  @override
  String toString() => 'SourceReference($referenceId, $kind)';
}

/// Attribution of a claim to an author or culture.
class AuthorAttribution {
  const AuthorAttribution._({required this.id, required this.label});

  factory AuthorAttribution.validated({
    required String id,
    required String label,
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'label cannot be empty');
    }
    return AuthorAttribution._(id: trimmedId, label: trimmedLabel);
  }

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthorAttribution && other.id == id && other.label == label);

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'AuthorAttribution($id, $label)';
}

/// A revision event in the history of a claim.
class RevisionEntry {
  const RevisionEntry._({
    required this.revisionId,
    required this.recordedAtTick,
    required this.reason,
    required this.priorConfidence,
    required this.newConfidence,
  });

  factory RevisionEntry.validated({
    required String revisionId,
    required int recordedAtTick,
    required String reason,
    required double priorConfidence,
    required double newConfidence,
  }) {
    final trimmedRev = revisionId.trim();
    if (trimmedRev.isEmpty) {
      throw ArgumentError.value(
        revisionId,
        'revisionId',
        'revisionId cannot be empty',
      );
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'reason cannot be empty');
    }
    if (recordedAtTick < 0) {
      throw ArgumentError.value(
        recordedAtTick,
        'recordedAtTick',
        'recordedAtTick must be >= 0',
      );
    }
    if (priorConfidence < 0 || priorConfidence > 1) {
      throw ArgumentError.value(
        priorConfidence,
        'priorConfidence',
        'priorConfidence must be in [0, 1]',
      );
    }
    if (newConfidence < 0 || newConfidence > 1) {
      throw ArgumentError.value(
        newConfidence,
        'newConfidence',
        'newConfidence must be in [0, 1]',
      );
    }
    return RevisionEntry._(
      revisionId: trimmedRev,
      recordedAtTick: recordedAtTick,
      reason: trimmedReason,
      priorConfidence: priorConfidence,
      newConfidence: newConfidence,
    );
  }

  final String revisionId;
  final int recordedAtTick;
  final String reason;
  final double priorConfidence;
  final double newConfidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionEntry &&
          other.revisionId == revisionId &&
          other.recordedAtTick == recordedAtTick &&
          other.reason == reason &&
          other.priorConfidence == priorConfidence &&
          other.newConfidence == newConfidence);

  @override
  int get hashCode => Object.hash(
    revisionId,
    recordedAtTick,
    reason,
    priorConfidence,
    newConfidence,
  );

  @override
  String toString() =>
      'RevisionEntry($revisionId @ $recordedAtTick: $priorConfidence -> $newConfidence)';
}

/// An encyclopedia claim with canon status, source, attribution, confidence,
/// assumptions, and an immutable revision history.
class CanonClaim {
  const CanonClaim._({
    required this.claimId,
    required this.status,
    required this.sourceReference,
    required this.authorOrCulture,
    required this.confidence,
    required this.assumptions,
    required this.history,
  });

  factory CanonClaim.validated({
    required String claimId,
    required CanonStatus status,
    required String sourceReference,
    required String authorOrCulture,
    double confidence = 1.0,
    List<String> assumptions = const [],
    List<RevisionEntry> history = const [],
  }) {
    final trimmedClaim = claimId.trim();
    if (trimmedClaim.isEmpty) {
      throw ArgumentError.value(claimId, 'claimId', 'claimId cannot be empty');
    }
    final trimmedSrc = sourceReference.trim();
    if (trimmedSrc.isEmpty) {
      throw ArgumentError.value(
        sourceReference,
        'sourceReference',
        'sourceReference cannot be empty',
      );
    }
    final trimmedAuthor = authorOrCulture.trim();
    if (trimmedAuthor.isEmpty) {
      throw ArgumentError.value(
        authorOrCulture,
        'authorOrCulture',
        'authorOrCulture cannot be empty',
      );
    }
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'confidence must be in [0, 1]',
      );
    }
    final cleanedAssumptions = <String>[];
    for (final raw in assumptions) {
      final t = raw.trim();
      if (t.isEmpty) {
        throw ArgumentError.value(
          raw,
          'assumptions',
          'assumption entry cannot be empty',
        );
      }
      cleanedAssumptions.add(t);
    }
    return CanonClaim._(
      claimId: trimmedClaim,
      status: status,
      sourceReference: trimmedSrc,
      authorOrCulture: trimmedAuthor,
      confidence: confidence,
      assumptions: List<String>.unmodifiable(cleanedAssumptions),
      history: List<RevisionEntry>.unmodifiable(history),
    );
  }

  final String claimId;
  final CanonStatus status;
  final String sourceReference;
  final String authorOrCulture;
  final double confidence;
  final List<String> assumptions;
  final List<RevisionEntry> history;

  CanonClaim appendRevision({
    required String revisionId,
    required int recordedAtTick,
    required String reason,
    required double newConfidence,
  }) {
    final entry = RevisionEntry.validated(
      revisionId: revisionId,
      recordedAtTick: recordedAtTick,
      reason: reason,
      priorConfidence: confidence,
      newConfidence: newConfidence,
    );
    return CanonClaim._(
      claimId: claimId,
      status: status,
      sourceReference: sourceReference,
      authorOrCulture: authorOrCulture,
      confidence: entry.newConfidence,
      assumptions: assumptions,
      history: List<RevisionEntry>.unmodifiable([...history, entry]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanonClaim &&
          other.claimId == claimId &&
          other.status == status &&
          other.sourceReference == sourceReference &&
          other.authorOrCulture == authorOrCulture &&
          other.confidence == confidence &&
          _listEquals(other.assumptions, assumptions) &&
          _listEquals(other.history, history));

  @override
  int get hashCode => Object.hash(
    claimId,
    status,
    sourceReference,
    authorOrCulture,
    confidence,
    Object.hashAll(assumptions),
    Object.hashAll(history),
  );

  @override
  String toString() =>
      'CanonClaim($claimId, $status, conf=$confidence, history=${history.length})';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
