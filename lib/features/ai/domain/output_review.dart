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

class OutputReview {
  const OutputReview({
    required this.generationId,
    required this.state,
    this.feedback,
  });
  final String generationId;
  final OutputReviewState state;
  final String? feedback;
}
