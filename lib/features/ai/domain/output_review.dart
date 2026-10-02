enum OutputReviewState {
  pending,
  approved,
  rejected;

  bool canTransitionTo(OutputReviewState next) {
    if (this == next) return false;
    return switch (this) {
      pending => next == approved || next == rejected,
      approved => next == rejected,
      rejected => next == approved || next == pending,
    };
  }
}

/// Thrown when a persisted review write is not a legal state transition.
///
/// The review row is beta evidence, so a caller cannot rewrite history: the
/// stored state is the source of truth and a forbidden next state fails loudly
/// instead of silently overwriting the record.
class OutputReviewTransitionError extends Error {
  OutputReviewTransitionError({
    required this.generationId,
    required this.from,
    required this.to,
  });

  final String generationId;
  final OutputReviewState from;
  final OutputReviewState to;

  @override
  String toString() =>
      'OutputReviewTransitionError: generation "$generationId" cannot move '
      'from ${from.name} to ${to.name}.';
}

class OutputReview {
  const OutputReview({
    required this.generationId,
    required this.state,
    this.feedback,
    this.createdAt,
    this.updatedAt,
  });
  final String generationId;
  final OutputReviewState state;
  final String? feedback;

  /// When the review was first recorded. Never rewritten by later writes, so
  /// it stays the earliest evidence time for this generation.
  final DateTime? createdAt;

  /// When the review was last written.
  final DateTime? updatedAt;
}
